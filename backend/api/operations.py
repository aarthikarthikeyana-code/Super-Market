"""Bounded, database-backed snapshots for the staff operations dashboard."""
from datetime import datetime, time, timedelta
from decimal import Decimal

from django.db.models import Count, Q, Sum
from django.db.models.functions import TruncDate, TruncHour, TruncMonth
from django.conf import settings
from django.utils import timezone

from .commerce import PRODUCE_CATEGORY_PATTERN
from .models import CashHandover, CustomerProfile, DeliveryPersonnel, Order, OrderEvent, Product, StockMovement
from .serializers import OrderSerializer, ProductSerializer


def dashboard_data(user):
    now = timezone.now()
    today = timezone.localdate(now)
    start = timezone.make_aware(datetime.combine(today, time.min))
    end = start + timedelta(days=1)
    orders = Order.objects.filter(customer__isnull=False)
    accepted = Q(payment_status__in=['paid', 'cod', 'collected']) & ~Q(status='Cancelled')
    sales = Q(payment_status__in=['paid', 'collected']) & ~Q(status='Cancelled')
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

    week_start = start - timedelta(days=today.weekday())
    month_start = start.replace(day=1)
    next_month = (month_start.replace(day=28) + timedelta(days=4)).replace(day=1)
    period_ranges = {
        'today': (start, end),
        'week': (week_start, week_start + timedelta(days=7)),
        'month': (month_start, next_month),
        'all': (None, None),
    }
    period_stats = {}
    for period, (period_start, period_end) in period_ranges.items():
        scoped = orders
        if period_start is not None:
            scoped = scoped.filter(created_at__gte=period_start, created_at__lt=period_end)
        totals = scoped.aggregate(
            orders=Count('pk', filter=accepted),
            sales=Sum('total_amount', filter=sales),
        )
        period_stats[period] = {
            'orders': totals['orders'] or 0,
            'sales': str(totals['sales'] or Decimal('0.00')),
            'completed': scoped.filter(accepted & Q(status='Delivered')).count(),
            'attempted': scoped.filter(accepted & Q(status='Delivery Attempted')).count(),
            'cancelled': scoped.filter(status='Cancelled').count(),
            'out_for_delivery': scoped.filter(accepted & Q(status='Out for Delivery')).count(),
        }

    chart_series = {}
    revenue_series = {}
    chart_configs = {
        'today': (start, end, TruncHour('created_at', tzinfo=timezone.get_current_timezone())),
        'week': (week_start, week_start + timedelta(days=7), TruncDate('created_at', tzinfo=timezone.get_current_timezone())),
        'month': (month_start, next_month, TruncDate('created_at', tzinfo=timezone.get_current_timezone())),
        'all': (None, None, TruncMonth('created_at', tzinfo=timezone.get_current_timezone())),
    }
    for period, (period_start, period_end, truncation) in chart_configs.items():
        scoped = orders
        if period_start is not None:
            scoped = scoped.filter(created_at__gte=period_start, created_at__lt=period_end)
        buckets = (
            scoped.annotate(bucket=truncation)
            .values('bucket')
            .annotate(
                value=Count('pk', filter=accepted),
                revenue=Sum('total_amount', filter=sales),
            )
            .order_by('bucket')
        )
        bucket_values = {}
        bucket_revenue = {}
        for row in buckets:
            bucket = row['bucket']
            if period == 'today':
                label = timezone.localtime(bucket).strftime('%H:%M')
            elif period == 'week':
                label = bucket.strftime('%a')
            elif period == 'month':
                label = bucket.strftime('%d')
            else:
                label = bucket.strftime('%b %y')
            bucket_values[label] = row['value'] or 0
            bucket_revenue[label] = str(row['revenue'] or Decimal('0.00'))

        if period == 'today':
            labels = [(start + timedelta(hours=hour)).strftime('%H:%M') for hour in range(24)]
        elif period == 'week':
            labels = [
                (week_start + timedelta(days=day)).strftime('%a')
                for day in range(7)
            ]
        elif period == 'month':
            labels = [f'{day:02d}' for day in range(1, (next_month - month_start).days + 1)]
        else:
            first_order = orders.order_by('created_at').values_list('created_at', flat=True).first()
            if first_order is None:
                labels = []
            else:
                first_month = timezone.localtime(first_order).replace(day=1)
                month_count = (today.year - first_month.year) * 12 + today.month - first_month.month + 1
                labels = [
                    (first_month + timedelta(days=32 * offset)).replace(day=1).strftime('%b %y')
                    for offset in range(month_count)
                ]
        points = [
            {'label': label, 'value': bucket_values.get(label, 0)}
            for label in labels
        ]
        chart_series[period] = points
        revenue_series[period] = [
            {'label': label, 'value': bucket_revenue.get(label, '0.00')}
            for label in labels
        ]

    products = Product.objects.exclude(category__iregex=PRODUCE_CATEGORY_PATTERN).select_related('image')
    inventory = products.aggregate(
        published=Count('pk', filter=Q(is_active=True)), hidden=Count('pk', filter=Q(is_active=False)),
        low_stock=Count('pk', filter=Q(is_active=True, is_in_stock=True, stock_kg__gt=0, stock_kg__lte=5)),
        out_of_stock=Count('pk', filter=Q(is_active=True) & (Q(stock_kg__lte=0) | Q(is_in_stock=False))),
        recently_updated=Count('pk', filter=Q(updated_at__gte=start, updated_at__lt=end)),
    )
    inventory_categories = list(
        products.filter(is_active=True)
        .values('category')
        .annotate(products=Count('pk'))
        .order_by('-products', 'category')[:8]
    )
    for period, (period_start, period_end) in period_ranges.items():
        updated = products
        if period_start is not None:
            updated = updated.filter(updated_at__gte=period_start, updated_at__lt=period_end)
        period_stats[period]['inventory_updates'] = updated.count()

    receipt_base = StockMovement.objects.filter(
        movement_type__in=['opening', 'restock'],
        delta__gt=0,
    ).exclude(product__category__iregex=PRODUCE_CATEGORY_PATTERN).select_related('product')
    inventory_stock_series = {}
    inventory_stock_receipts = {}
    for period, (period_start, period_end) in period_ranges.items():
        scoped_receipts = receipt_base
        if period_start is not None:
            scoped_receipts = scoped_receipts.filter(
                created_at__gte=period_start,
                created_at__lt=period_end,
            )
        period_stats[period]['stock_receipts'] = scoped_receipts.count()
        truncation = chart_configs[period][2]
        bucket_counts = {
            row['bucket']: row['count']
            for row in scoped_receipts.annotate(bucket=truncation)
            .values('bucket')
            .annotate(count=Count('pk'))
            .order_by('bucket')
        }
        if period != 'all':
            labels = [point['label'] for point in chart_series[period]]
        else:
            first_receipt = scoped_receipts.order_by('created_at').values_list('created_at', flat=True).first()
            if first_receipt is None:
                labels = []
            else:
                first_month = timezone.localtime(first_receipt).replace(day=1)
                month_count = (today.year - first_month.year) * 12 + today.month - first_month.month + 1
                labels = [
                    (first_month + timedelta(days=32 * offset)).replace(day=1).strftime('%b %y')
                    for offset in range(month_count)
                ]
        points = []
        for label in labels:
            matching_bucket = next(
                (
                    bucket
                    for bucket in bucket_counts
                    if (
                        timezone.localtime(bucket).strftime('%H:%M')
                        if period == 'today'
                        else bucket.strftime('%a')
                        if period == 'week'
                        else bucket.strftime('%d')
                        if period == 'month'
                        else bucket.strftime('%b %y')
                    ) == label
                ),
                None,
            )
            points.append({'label': label, 'value': bucket_counts.get(matching_bucket, 0)})
        inventory_stock_series[period] = points
        inventory_stock_receipts[period] = list(
            scoped_receipts.order_by('-created_at', '-pk')
            .values(
                'delta', 'unit', 'created_at', 'movement_type',
                'product__tamil_name', 'product__english_name', 'product__category',
            )[:25]
        )

    low_stock_products = list(
        products.filter(
            is_active=True,
            is_in_stock=True,
            stock_kg__gt=0,
            stock_kg__lte=5,
        )
        .order_by('stock_kg', 'category', 'tamil_name')
        .values('tamil_name', 'english_name', 'category', 'unit', 'stock_kg')[:25]
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
        'generated_at': now, 'today': daily, 'period_stats': period_stats,
        'orders_series': chart_series, 'revenue_series': revenue_series,
        'inventory_stock_series': inventory_stock_series,
        'inventory_stock_receipts': inventory_stock_receipts,
        'low_stock_products': low_stock_products,
        'inventory_categories': inventory_categories,
        'total_customers': CustomerProfile.objects.count(),
        'inventory': inventory, 'total_products': inventory['published'], 'low_stock': inventory['low_stock'],
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
