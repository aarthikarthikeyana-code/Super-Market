import hashlib
import hmac
import uuid
from datetime import timedelta
from decimal import Decimal
from django.conf import settings
from django.contrib.auth import get_user_model
from django.db import transaction
from django.db.models import F
from django.utils import timezone
from rest_framework.exceptions import ValidationError
from .gateways import razorpay_request
from .models import Product, Order, OrderItem, OrderEvent, DeliveryPersonnel


def checkout_data(order):
    return {
        'key_id': settings.RAZORPAY_KEY_ID,
        'razorpay_order_id': order.razorpay_order_id,
        'amount': int(order.total_amount * 100),
        'currency': 'INR',
        'test_mode': settings.RAZORPAY_KEY_ID.startswith('rzp_test_'),
    } if order.razorpay_order_id and order.payment_status == 'pending' else None


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
    products = {p.pk: p for p in Product.objects.select_for_update().filter(
        pk__in=[i['product_id'] for i in data['items']], is_active=True).order_by('pk')}
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
    online = data['payment_method'] == 'razorpay'
    order = Order.objects.create(
        customer=customer, idempotency_key=data['idempotency_key'], order_id='AG' + uuid.uuid4().hex[:20].upper(),
        customer_name=data['customer_name'], customer_phone=data['customer_phone'],
        delivery_address=data['delivery_address'], delivery_instructions=data['delivery_instructions'],
        subtotal=subtotal, delivery_charge=charge, total_amount=total,
        payment_method='razorpay' if online else 'cod', payment_status='pending' if online else 'cod',
        status='Payment Pending' if online else 'New',
    )
    for item in data['items']:
        p = products[item['product_id']]
        OrderItem.objects.create(order=order, product=p, english_name=p.english_name, tamil_name=p.tamil_name,
                                 quantity=item['quantity'], unit=p.unit, unit_price=p.price, total_price=p.price * item['quantity'])
        p.stock_kg -= item['quantity']
        p.save(update_fields=['stock_kg', 'updated_at'])
    if online:
        result = razorpay_request('POST', 'orders', {'amount': int(total * 100), 'currency': 'INR', 'receipt': order.order_id,
                                                   'notes': {'agaram_order_id': order.order_id}})
        if not result.get('id'):
            from .errors import ServiceUnavailable
            raise ServiceUnavailable('Payment order could not be created. Please retry.')
        order.razorpay_order_id = result['id']
        order.save(update_fields=['razorpay_order_id', 'updated_at'])
    OrderEvent.objects.create(order=order, status=order.status, note='Order created.')
    return order


def verify_signature(order, payment_id, signature):
    message = f'{order.razorpay_order_id}|{payment_id}'.encode()
    expected = hmac.new(settings.RAZORPAY_KEY_SECRET.encode(), message, hashlib.sha256).hexdigest()
    if not signature or not hmac.compare_digest(expected, signature):
        raise ValidationError({'detail': 'Payment signature verification failed.'})


def confirm_payment(order, payment_id):
    payment = razorpay_request('GET', f'payments/{payment_id}')
    if (payment.get('order_id') != order.razorpay_order_id or payment.get('currency') != 'INR'
            or payment.get('amount') != int(order.total_amount * 100)):
        raise ValidationError({'detail': 'Payment does not match this order.'})
    if payment.get('status') == 'authorized':
        if order.status == 'Cancelled' or order.stock_released:
            raise ValidationError({'detail': 'This checkout has expired. The payment will not be captured. Place a new order.'})
        payment = razorpay_request('POST', f'payments/{payment_id}/capture', {'amount': int(order.total_amount * 100), 'currency': 'INR'})
    if payment.get('status') != 'captured':
        raise ValidationError({'detail': 'Payment is not captured yet. Refresh this order shortly.'})
    with transaction.atomic():
        locked = Order.objects.select_for_update().get(pk=order.pk)
        if locked.payment_status == 'paid':
            if locked.razorpay_payment_id != payment_id:
                raise ValidationError({'detail': 'A different payment has already been recorded.'})
            return locked
        if Order.objects.exclude(pk=locked.pk).filter(razorpay_payment_id=payment_id).exists():
            raise ValidationError({'detail': 'This payment is already attached to another order.'})
        locked.razorpay_payment_id = payment_id
        if locked.stock_released or locked.status == 'Cancelled':
            locked.payment_status = 'review'
            OrderEvent.objects.create(order=locked, status=locked.status, note='Late payment received; contact the store for refund or fulfillment review.')
        else:
            locked.payment_status = 'paid'
            locked.status = 'New'
            OrderEvent.objects.create(order=locked, status='New', note='Payment verified and captured.')
        locked.save()
        return locked


def refresh_personnel_status(person_id):
    if person_id:
        busy = Order.objects.filter(assigned_to_id=person_id).exclude(status__in=['Delivered', 'Cancelled']).exists()
        DeliveryPersonnel.objects.filter(pk=person_id).update(status='Busy' if busy else 'Available')


@transaction.atomic
def transition_order(order_id, next_status, note='', person_id=None, eta=None):
    order = Order.objects.select_for_update().get(order_id=order_id, customer__isnull=False)
    valid = {'New': 'Preparing', 'Preparing': 'Packed', 'Packed': 'Out for Delivery', 'Out for Delivery': 'Delivered'}
    if order.payment_status not in ['paid', 'cod']:
        raise ValidationError({'detail': 'Only paid or cash-on-delivery orders can be fulfilled.'})
    if next_status and next_status != order.status and valid.get(order.status) != next_status:
        raise ValidationError({'status': 'This order cannot move to that status. Follow the delivery sequence.'})
    old_person = order.assigned_to_id
    if person_id is not None:
        if order.status in ['Delivered', 'Cancelled']:
            raise ValidationError({'detail': 'Completed orders cannot be reassigned.'})
        person = DeliveryPersonnel.objects.filter(pk=person_id, is_active=True).first()
        if not person:
            raise ValidationError({'assigned_to': 'Choose an active delivery person.'})
        order.assigned_to = person
    if next_status == 'Out for Delivery' and not order.assigned_to_id:
        raise ValidationError({'assigned_to': 'Assign a delivery person before dispatching.'})
    if eta is not None:
        if eta <= timezone.now():
            raise ValidationError({'estimated_delivery_at': 'Estimated arrival must be in the future.'})
        order.estimated_delivery_at = eta
    if note:
        order.delivery_note = note
    if next_status and next_status != order.status:
        order.status = next_status
        field = {'Packed': 'packed_at', 'Out for Delivery': 'dispatched_at', 'Delivered': 'delivered_at'}.get(next_status)
        if field:
            setattr(order, field, timezone.now())
        if next_status == 'Packed':
            order.items.update(is_packed=True)
    order.save()
    OrderEvent.objects.create(order=order, status=order.status, note=note or ('Delivery person assigned.' if person_id else 'Order status updated.'))
    refresh_personnel_status(old_person)
    refresh_personnel_status(order.assigned_to_id)
    return order
