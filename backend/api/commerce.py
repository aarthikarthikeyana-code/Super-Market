import uuid
from datetime import timedelta
from decimal import Decimal
from django.conf import settings
from django.contrib.auth import get_user_model
from django.db import transaction
from django.db.models import F, Sum
from django.utils import timezone
from rest_framework.exceptions import ValidationError
from .models import Product, Order, OrderItem, OrderEvent, DeliveryPersonnel
from . import delivery


# Store policy excludes fresh produce, while allowing dried fruit, juices and oils.
PRODUCE_CATEGORY_PATTERN = r'^\s*(?:(?:fresh\s+)?(?:fruits?|vegetables?)(?:\s*(?:&|and|/|-)\s*(?:fruits?|vegetables?))?|fresh\s+produce|produce|காய்கறிகள்|காய்கறி|பழங்கள்|பழம்)\s*$'


def is_grocery_category(category):
    import re
    return not re.fullmatch(PRODUCE_CATEGORY_PATTERN, category, re.IGNORECASE)


def grocery_products(queryset=None):
    return (queryset if queryset is not None else Product.objects.all()).filter(is_active=True).exclude(category__iregex=PRODUCE_CATEGORY_PATTERN)


def release_stock(order):
    if order.stock_released:
        return
    for item in order.items.order_by('product_id'):
        if item.product_id:
            Product.objects.filter(pk=item.product_id).update(stock_kg=F('stock_kg') + item.quantity)
    order.stock_released = True


@transaction.atomic
def expire_pending_orders():
    cutoff = timezone.now() - timedelta(minutes=30)
    for order in Order.objects.select_for_update().filter(status='Payment Pending', payment_status='pending', created_at__lt=cutoff).order_by('pk'):
        release_stock(order)
        order.status = 'Cancelled'
        order.payment_status = 'expired'
        order.save()
        OrderEvent.objects.create(order=order, status='Cancelled', note='Payment window expired. Reserved stock released.')


@transaction.atomic
def create_order(customer, data):
    # Serialize retries for this customer before reserving product stock.
    get_user_model().objects.select_for_update().get(pk=customer.pk)
    existing = Order.objects.filter(customer=customer, idempotency_key=data['idempotency_key']).first()
    if existing:
        return existing
    products = {p.pk: p for p in grocery_products(Product.objects.select_for_update()).filter(
        pk__in=[i['product_id'] for i in data['items']]).order_by('pk')}
    subtotal = Decimal('0.00')
    for item in data['items']:
        product = products.get(item['product_id'])
        if not product or not product.is_in_stock or product.stock_kg < item['quantity']:
            raise ValidationError({'items': 'A product is unavailable or has insufficient stock. Refresh your cart.'})
        subtotal += product.price * item['quantity']
    charge = Decimal(settings.DELIVERY_CHARGE)
    total = (subtotal + charge).quantize(Decimal('0.01'))
    if data.get('expected_total') is not None and data['expected_total'] != total:
        raise ValidationError({'detail': 'Prices or delivery charges changed. Go back to your cart and review checkout again.'})
    if total <= 0 or total > Decimal('500000.00'):
        raise ValidationError({'items': 'Order total must be between INR 0.01 and INR 500,000.'})
    if data.get('payment_method', 'cod') != 'cod':
        raise ValidationError({'payment_method': 'This store accepts cash on delivery only.'})
    order = Order.objects.create(
        customer=customer, idempotency_key=data['idempotency_key'], order_id='AG' + uuid.uuid4().hex[:20].upper(),
        customer_name=data['customer_name'], customer_phone=data['customer_phone'],
        delivery_address=data['delivery_address'], delivery_instructions=data['delivery_instructions'],
        subtotal=subtotal, delivery_charge=charge, total_amount=total,
        payment_method='cod', payment_status='cod', status='New',
    )
    for item in data['items']:
        p = products[item['product_id']]
        OrderItem.objects.create(order=order, product=p, english_name=p.english_name, tamil_name=p.tamil_name,
                                 quantity=item['quantity'], unit=p.unit, unit_price=p.price, total_price=p.price * item['quantity'])
        p.stock_kg -= item['quantity']
        p.save(update_fields=['stock_kg', 'updated_at'])
    OrderEvent.objects.create(order=order, status=order.status, note='Order placed. Pay cash when your groceries arrive.')
    return order


def refresh_personnel_status(person_id):
    if person_id:
        busy = Order.objects.filter(assigned_to_id=person_id).exclude(status__in=['Delivered', 'Cancelled']).exists()
        DeliveryPersonnel.objects.filter(pk=person_id).update(status='Busy' if busy else 'Available')


@transaction.atomic
def cancel_order(order_id, *, customer=None, reason='', stock_returned=False):
    order = Order.objects.select_for_update().get(order_id=order_id, customer__isnull=False)
    if customer is not None and order.customer_id != customer.pk:
        raise ValidationError({'detail': 'This order belongs to another account.'})
    if order.status == 'Cancelled':
        return order
    if customer is not None:
        allowed = ['New', 'Payment Pending']
    else:
        allowed = ['New', 'Preparing', 'Packed', 'Delivery Attempted', 'Payment Pending']
        if not reason.strip():
            raise ValidationError({'cancellation_reason': 'Enter a reason for cancelling the order.'})
    if order.status not in allowed or order.payment_status not in ['cod', 'pending']:
        raise ValidationError({'detail': 'This order cannot be cancelled here. Contact the store for assistance.'})
    if customer is None and order.status not in ['New', 'Payment Pending'] and not stock_returned:
        raise ValidationError({'stock_returned': 'Confirm that the undelivered items are back in store before restoring stock.'})
    release_stock(order)
    order.status = 'Cancelled'
    order.payment_status = 'cancelled'
    order.cancellation_reason = reason.strip() or 'Cancelled by customer before preparation.'
    order.save()
    OrderEvent.objects.create(order=order, status='Cancelled', note=order.cancellation_reason)
    refresh_personnel_status(order.assigned_to_id)
    return order


def transition_order(order_id, next_status, note='', person_id=None, eta=None,
                     *, cash_collected=False, cash_amount=None, actor=None, delivery_code='', cash_received_by_store=False):
    failure = None
    with transaction.atomic():
        try:
            result = _transition_order(order_id, next_status, note, person_id, eta,
                                      cash_collected=cash_collected, cash_amount=cash_amount,
                                      actor=actor, delivery_code=delivery_code, cash_received_by_store=cash_received_by_store)
        except delivery.InvalidDeliveryCode as exc:
            failure = exc
    if failure:
        raise failure
    return result


def _transition_order(order_id, next_status, note='', person_id=None, eta=None,
                      *, cash_collected=False, cash_amount=None, actor=None, delivery_code='', cash_received_by_store=False):
    order = Order.objects.select_for_update().get(order_id=order_id, customer__isnull=False)
    if cash_received_by_store and (not actor or not actor.is_staff or next_status != 'Delivered'):
        raise ValidationError({'cash_received_by_store': 'Only an administrator completing delivery can record cash received directly by the store.'})
    employee_actor = bool(actor and not actor.is_staff and order.assigned_to_id and order.assigned_to.user_id == actor.pk and order.assigned_to.ready_for_deliveries)
    if actor and not actor.is_staff:
        if not employee_actor or person_id is not None or next_status not in ['Out for Delivery', 'Delivery Attempted', 'Delivered'] or order.status not in ['Packed', 'Out for Delivery', 'Delivery Attempted', 'Delivered']:
            raise ValidationError({'detail': 'You can only deliver orders currently assigned to your active, verified employee account.'})
    if order.status == 'Delivered' and next_status == 'Delivered' and order.payment_status == 'collected' and cash_collected and cash_amount == order.cash_collected_amount:
        return order
    if order.status in ['Delivered', 'Cancelled']:
        raise ValidationError({'detail': 'Completed orders cannot be changed.'})
    valid = {'New': ['Preparing'], 'Preparing': ['Packed'], 'Packed': ['Out for Delivery'],
             'Out for Delivery': ['Delivered', 'Delivery Attempted'], 'Delivery Attempted': ['Out for Delivery']}
    if order.payment_status not in ['paid', 'cod']:
        raise ValidationError({'detail': 'This historical payment needs store review before fulfillment.'})
    if next_status and next_status != order.status and next_status not in valid.get(order.status, []):
        raise ValidationError({'status': 'Follow the order preparation and delivery sequence.'})
    if (cash_collected or cash_amount is not None) and next_status != 'Delivered':
        raise ValidationError({'cash_collected': 'Record cash only when completing a delivery.'})
    if next_status == 'Delivery Attempted' and not note.strip():
        raise ValidationError({'delivery_note': 'Enter why delivery could not be completed.'})
    if next_status == 'Delivered':
        if order.payment_status == 'cod' and (not cash_collected or cash_amount != order.total_amount or not actor):
            raise ValidationError({'cash_collected': 'Collect and confirm the exact cash amount first.'})
        delivery.verify_code(order, delivery_code)
    old_person = order.assigned_to_id
    if person_id is not None:
        if order.status == 'Out for Delivery' and person_id != order.assigned_to_id:
            raise ValidationError({'assigned_to': 'Record an unsuccessful attempt before transferring an active delivery to another employee.'})
        person = DeliveryPersonnel.objects.select_for_update().filter(pk=person_id, is_active=True).first()
        if not person or not person.ready_for_deliveries:
            raise ValidationError({'assigned_to': 'Choose an active employee with login, verified documents and a valid driving licence where applicable.'})
        order.assigned_to = person
        if old_person != person.pk:
            order.delivery_code_nonce = None
            order.delivery_code_expires_at = None
    if next_status in ['Out for Delivery', 'Delivered', 'Delivery Attempted']:
        person = DeliveryPersonnel.objects.select_for_update().filter(pk=order.assigned_to_id, is_active=True).first()
        if not person or not person.ready_for_deliveries:
            raise ValidationError({'assigned_to': 'Assign an active, verified delivery employee before dispatching or completing delivery.'})
    if next_status == 'Delivered' and order.payment_status == 'cod':
        if not cash_collected or cash_amount != order.total_amount or not actor or not (actor.is_staff or employee_actor):
            raise ValidationError({'cash_collected': 'Confirm the exact order total was collected in cash before marking delivered.'})
        order.cash_collected_amount = cash_amount
        order.cash_collected_at = timezone.now()
        order.cash_collected_by = actor
        order.cash_collected_for = None if cash_received_by_store else order.assigned_to
        order.cash_received_directly = cash_received_by_store
        order.payment_status = 'collected'
    if eta is not None:
        if eta <= timezone.now():
            raise ValidationError({'estimated_delivery_at': 'Estimated arrival must be in the future.'})
        order.estimated_delivery_at = eta
    if note:
        order.delivery_note = note
    changed = next_status and next_status != order.status
    if changed:
        order.status = next_status
        field = {'Packed': 'packed_at', 'Out for Delivery': 'dispatched_at', 'Delivered': 'delivered_at'}.get(next_status)
        if field:
            setattr(order, field, timezone.now())
        if next_status == 'Packed':
            order.items.update(is_packed=True)
        if next_status == 'Out for Delivery':
            delivery.issue_code(order)
        if next_status == 'Delivered':
            order.delivery_code_verified_at = timezone.now()
            order.delivery_code_nonce = None
        if next_status == 'Delivery Attempted':
            order.delivery_attempts += 1
            order.estimated_delivery_at = None
    order.save()
    message = note or (f'Delivery assigned to {order.assigned_to.name}.' if person_id else 'Order status updated.')
    if changed and next_status == 'Delivered' and order.payment_status == 'collected':
        collector = order.assigned_to.name if employee_actor else 'store administrator'
        message = f'Customer delivery code verified. INR {order.total_amount} collected by {collector}.' + (f' {note}' if note else '')
        if cash_received_by_store:
            message += ' Cash received directly by store.'
    OrderEvent.objects.create(order=order, status=order.status, note=message[:255])
    refresh_personnel_status(old_person)
    refresh_personnel_status(order.assigned_to_id)
    return order


def cash_total(queryset):
    return queryset.aggregate(total=Sum('cash_collected_amount'))['total'] or Decimal('0.00')
