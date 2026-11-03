"""Bounded, database-backed snapshots for the staff operations dashboard."""
from datetime import datetime, time, timedelta
from decimal import Decimal

from django.db.models import Count, Q, Sum
from django.conf import settings
from django.utils import timezone

from .commerce import PRODUCE_CATEGORY_PATTERN
from .models import CashHandover, DeliveryPersonnel, Order, OrderEvent, Product
from .serializers import OrderSerializer, ProductSerializer


def dashboard_data(user):
    now = timezone.now()
    today = timezone.localdate(now)
    start = timezone.make_aware(datetime.combine(today, time.min))
    end = start + timedelta(days=1)
    orders = Order.objects.filter(customer__isnull=False)
    accepted = Q(payment_status__in=['paid', 'cod', 'collected']) & ~Q(status='Cancelled')
    held = Q(payment_status='collected', cash_collected_for__isnull=False, cash_handover__isnull=True)
    received = Q(payment_status='collected') & (Q(cash_handover__isnull=False) | Q(cash_received_directly=True))
    stats = orders.aggregate(
        orders_placed=Count('pk'),
        cancelled_orders=Count('pk', filter=Q(status='Cancelled')),
        total_orders=Count('pk', filter=accepted), awaiting_payment=Count('pk', filter=Q(payment_status='pending')),
        new_orders=Count('pk', filter=accepted & Q(status='New')),
        preparing=Count('pk', filter=accepted & Q(status='Preparing')),
        packed=Count('pk', filter=accepted & Q(status='Packed')),
        packed_unassigned=Count('pk', filter=accepted & Q(status='Packed', assigned_to__isnull=True)),
        assigned=Count('pk', filter=accepted & Q(status='Packed', assigned_to__isnull=False)),
        active_deliveries=Count('pk', filter=accepted & Q(status='Out for Delivery')),
        delivered=Count('pk', filter=accepted & Q(status='Delivered')),
        delivery_attempted=Count('pk', filter=accepted & Q(status='Delivery Attempted')),
        delayed=Count('pk', filter=Q(status='Out for Delivery', estimated_delivery_at__lt=now)),
        cash_collected=Sum('cash_collected_amount', filter=Q(payment_status='collected')),
        cash_with_employees=Sum('cash_collected_amount', filter=held),
        pending_handover_orders=Count('pk', filter=held),
        cash_review_orders=Count('pk', filter=Q(payment_status='collected', cash_collected_for__isnull=True, cash_handover__isnull=True, cash_received_directly=False)),
        cash_direct=Sum('cash_collected_amount', filter=Q(payment_status='collected', cash_received_directly=True)),
        cash_received_orders=Count('pk', filter=received),
        cash_due=Sum('total_amount', filter=Q(payment_status='cod') & ~Q(status='Cancelled')),
        revenue=Sum('total_amount', filter=Q(payment_status__in=['paid', 'collected']) & ~Q(status='Cancelled')),
    )
    for key in ['cash_collected', 'cash_with_employees', 'cash_direct', 'cash_due', 'revenue']:
        stats[key] = str(stats[key] or Decimal('0.00'))
    receipts = CashHandover.objects.select_related('employee', 'received_by')
    stats['cash_received_by_store'] = str((receipts.aggregate(total=Sum('amount'))['total'] or Decimal('0.00')) + Decimal(stats['cash_direct']))
    stats['cash_unallocated'] = str(max(Decimal('0.00'), Decimal(stats['cash_collected']) - Decimal(stats['cash_received_by_store']) - Decimal(stats['cash_with_employees'])))
    current = orders.filter(created_at__gte=start, created_at__lt=end)
    today_stages = dict(current.order_by().values('status').annotate(total=Count('pk')).values_list('status', 'total'))
    daily = {
        'date': today.isoformat(), 'new': today_stages.get('New', 0), 'preparing': today_stages.get('Preparing', 0),
        'packed': today_stages.get('Packed', 0), 'out_for_delivery': today_stages.get('Out for Delivery', 0),
        'delivered': orders.filter(delivered_at__gte=start, delivered_at__lt=end, status='Delivered').count(),
        'needs_attention': current.filter(Q(status__in=['New', 'Delivery Attempted']) | Q(status='Packed', assigned_to__isnull=True) | Q(status='Out for Delivery', estimated_delivery_at__lt=now)).count(),
    }
    products = Product.objects.exclude(category__iregex=PRODUCE_CATEGORY_PATTERN).select_related('image')
    inventory = products.aggregate(
        published=Count('pk', filter=Q(is_active=True)), hidden=Count('pk', filter=Q(is_active=False)),
        low_stock=Count('pk', filter=Q(is_active=True, is_in_stock=True, stock_kg__gt=0, stock_kg__lte=5)),
        out_of_stock=Count('pk', filter=Q(is_active=True) & (Q(stock_kg__lte=0) | Q(is_in_stock=False))),
        recently_updated=Count('pk', filter=Q(updated_at__gte=start, updated_at__lt=end)),
    )
    people = DeliveryPersonnel.objects.select_related('user').annotate(
        active_jobs=Count('assigned_orders', filter=Q(assigned_orders__customer__isnull=False) & ~Q(assigned_orders__status__in=['Delivered', 'Cancelled'])),
        road_jobs=Count('assigned_orders', filter=Q(assigned_orders__customer__isnull=False, assigned_orders__status='Out for Delivery')),
    )
    ready = people.filter(is_active=True, documents_verified=True, user__is_active=True, user__is_staff=False).exclude(user__password__startswith='!').filter(Q(vehicle_type__in=['walking', 'bicycle']) | Q(licence_expiry__gte=today))
    team = {'available': ready.filter(active_jobs=0).count(), 'on_delivery': people.filter(road_jobs__gt=0).count(),
            'inactive': people.filter(is_active=False).count(), 'offline': None,
            'needs_verification': people.filter(is_active=True).count() - ready.count()}
    cash_people = list(orders.filter(held).values('cash_collected_for_id', 'cash_collected_for__name', 'cash_collected_for__employee_code', 'cash_collected_for__phone').annotate(amount=Sum('cash_collected_amount'), delivered_orders=Count('pk')).order_by('-amount', 'cash_collected_for_id')[:6])
    cash_rows = [{'id': p['cash_collected_for_id'], 'name': p['cash_collected_for__name'], 'phone': p['cash_collected_for__phone'],
                  'employee_code': p['cash_collected_for__employee_code'], 'cash_to_handover': str(p['amount']),
                  'delivered_orders': p['delivered_orders'], 'amount_submitted': None, 'difference': None} for p in cash_people]
    team_rows = [{'id': p.pk, 'name': p.name, 'phone': p.phone, 'employee_code': p.employee_code,
                  'is_active': p.is_active, 'ready_for_deliveries': p.ready_for_deliveries,
                  'active_orders': p.active_jobs, 'on_delivery': p.road_jobs} for p in people.order_by('name', 'pk')[:4]]
    alerts = []
    for key, title, detail, count in [
        ('new', 'Orders to prepare', 'Accept new orders and start packing.', stats['new_orders']),
        ('assignment', 'Ready for assignment', 'Packed orders need a delivery employee.', stats['packed_unassigned']),
        ('delayed', 'Delivery needs a check-in', 'The recorded arrival estimate has passed.', stats['delayed']),
        ('attempted', 'Unsuccessful deliveries', 'Arrange a retry or confirm returned items.', stats['delivery_attempted']),
        ('cash', 'Cash awaiting handover', 'Confirm receipt after counting the cash.', stats['pending_handover_orders']),
        ('cash_review', 'Cash needs reconciliation', 'Review cash collected without a store or employee allocation.', stats['cash_review_orders']),
        ('stock', 'Low-stock products', 'Review published products with up to 5 units.', inventory['low_stock']),
    ]:
        if count:
            alerts.append({'key': key, 'title': title, 'detail': detail, 'count': count})
    if stats['packed_unassigned'] and not team['available']:
        alerts.append({'key': 'team', 'title': 'No available delivery employee', 'detail': 'Review workload and employee readiness.', 'count': stats['packed_unassigned']})
    events = list(OrderEvent.objects.filter(order__customer__isnull=False).select_related('order').order_by('-created_at', '-pk')[:8])
    activity = [{'type': 'order', 'title': e.status, 'detail': e.note, 'order_id': e.order.order_id, 'at': e.created_at} for e in events]
    recent_receipts = [{'id': str(r.pk), 'employee': r.employee.name, 'employee_id': r.employee_id, 'amount': str(r.amount), 'at': r.received_at} for r in receipts.order_by('-received_at')[:6]]
    activity += [{'type': 'cash', 'title': 'Cash received', 'detail': r['employee'], 'amount': r['amount'], 'at': r['at']} for r in recent_receipts]
    activity += [{'type': 'product', 'title': 'Product updated', 'detail': p.tamil_name, 'at': p.updated_at} for p in products.order_by('-updated_at', 'pk')[:4]]
    activity.sort(key=lambda row: row['at'], reverse=True)
    details = orders.select_related('assigned_to').prefetch_related('items__product__image', 'events')
    stats.update({
        'generated_at': now, 'today': daily, 'inventory': inventory, 'total_products': inventory['published'], 'low_stock': inventory['low_stock'],
        'alerts': alerts, 'team': team, 'team_preview': team_rows,
        'active_delivery_preview': OrderSerializer(details.filter(status='Out for Delivery').order_by('dispatched_at', 'pk')[:4], many=True).data,
        'cash_employees': cash_rows, 'cash_submissions': [], 'cash_submission_supported': False,
        'cash_receipts': recent_receipts, 'recent_activity': activity[:8],
        'recent_products': ProductSerializer(products.filter(is_active=True).order_by('-updated_at', 'pk')[:4], many=True).data,
        'recent_orders': OrderSerializer(details.order_by('-created_at', '-pk')[:6], many=True).data,
        'categories': list(products.order_by('category').values_list('category', flat=True).distinct()),
        'brands': list(products.exclude(brand='').order_by('brand').values_list('brand', flat=True).distinct()),
        'admin_profile': {'name': user.get_full_name() or user.get_username(), 'email': user.email},
        'store': {'name': 'Agaram Supermarket', 'currency': 'INR', 'cash_on_delivery': True, 'delivery_mode': 'on_demand', 'delivery_charge': settings.DELIVERY_CHARGE},
    })
    return stats
