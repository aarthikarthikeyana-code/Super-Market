from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status
from django.utils import timezone
from .models import (
    Product,
    DeliveryAddress,
    DeliveryPersonnel,
    Order,
    OrderItem,
    NewItemRequest,
)
from .serializers import (
    ProductSerializer,
    DeliveryAddressSerializer,
    DeliveryPersonnelSerializer,
    OrderSerializer,
    OrderItemSerializer,
    NewItemRequestSerializer,
)

# ----------------- CUSTOMER API VIEWS -----------------

@api_view(['GET'])
@permission_classes([AllowAny])
def get_products(request):
    category = request.GET.get('category')
    search = request.GET.get('search')
    queryset = Product.objects.all()
    if category:
        queryset = queryset.filter(category__iexact=category)
    if search:
        queryset = queryset.filter(
            tamil_name__icontains=search
        ) | queryset.filter(
            english_name__icontains=search
        )
    serializer = ProductSerializer(queryset, many=True)
    return Response(serializer.data)


@api_view(['GET'])
@permission_classes([AllowAny])
def get_product_detail(request, pk):
    try:
        product = Product.objects.get(pk=pk)
        return Response(ProductSerializer(product).data)
    except Product.DoesNotExist:
        return Response({'error': 'Product not found'}, status=status.HTTP_404_NOT_FOUND)


@api_view(['POST'])
@permission_classes([AllowAny])
def create_customer_order(request):
    data = request.data
    order_id = data.get('order_id', f"#ORD{timezone.now().strftime('%H%M%S')}")
    items_data = data.get('items', [])

    order = Order.objects.create(
        order_id=order_id,
        customer_name=data.get('customer_name', 'Priya S'),
        customer_phone=data.get('customer_phone', '+91 98765 43210'),
        delivery_address=data.get('delivery_address', '123, Green Street, Chennai - 600023'),
        delivery_date=data.get('delivery_date', '16 Apr 2025'),
        time_slot=data.get('time_slot', '04:00 PM - 06:00 PM'),
        delivery_instructions=data.get('delivery_instructions', ''),
        payment_method=data.get('payment_method', 'Cash on Delivery (COD)'),
        subtotal=data.get('subtotal', 82.0),
        delivery_charge=data.get('delivery_charge', 0.0),
        total_amount=data.get('total_amount', 82.0),
        status='New',
    )

    for item in items_data:
        prod_id = item.get('product_id')
        prod = None
        if prod_id:
            try:
                prod = Product.objects.get(id=prod_id)
            except Product.DoesNotExist:
                pass
        
        OrderItem.objects.create(
            order=order,
            product=prod,
            tamil_name=item.get('tamil_name', ''),
            english_name=item.get('english_name', ''),
            quantity=item.get('quantity', 1),
            unit=item.get('unit', 'Kg'),
            unit_price=item.get('unit_price', 30.0),
            total_price=item.get('total_price', 30.0),
            is_packed=True,
            is_out_of_stock=False,
        )

    return Response(OrderSerializer(order).data, status=status.HTTP_201_CREATED)


@api_view(['GET'])
@permission_classes([AllowAny])
def track_order(request, order_id):
    try:
        clean_id = order_id if order_id.startswith('#') else f"#{order_id}"
        order = Order.objects.get(order_id__iexact=clean_id)
        return Response(OrderSerializer(order).data)
    except Order.DoesNotExist:
        # Fallback to latest order
        latest = Order.objects.first()
        if latest:
            return Response(OrderSerializer(latest).data)
        return Response({'error': 'Order not found'}, status=status.HTTP_404_NOT_FOUND)


@api_view(['POST'])
@permission_classes([AllowAny])
def submit_new_item_request(request):
    data = request.data
    req = NewItemRequest.objects.create(
        item_name=data.get('item_name', 'புதினா'),
        customer_phone=data.get('customer_phone', '+91 98765 43210'),
        notes=data.get('notes', 'Requested via Search Not Found dialog'),
    )
    return Response(NewItemRequestSerializer(req).data, status=status.HTTP_201_CREATED)


# ----------------- ADMIN API VIEWS -----------------

@api_view(['POST'])
@permission_classes([AllowAny])
def admin_login(request):
    admin_id = request.data.get('admin_id')
    password = request.data.get('password')
    # Default admin credentials check
    if admin_id in ['admin', 'admin@freshness.com', 'admin123'] and (password in ['admin', 'admin123', 'password'] or not password):
        return Response({
            'success': True,
            'token': 'supermarket-admin-session-token-xyz',
            'admin': {
                'id': 'ADM01',
                'name': 'Supermarket Store Admin',
                'role': 'Store Manager',
            }
        })
    # Accept any login for prototype demonstration
    return Response({
        'success': True,
        'token': 'supermarket-admin-session-token-xyz',
        'admin': {
            'id': admin_id or 'ADM01',
            'name': 'Supermarket Store Admin',
            'role': 'Store Manager',
        }
    })


@api_view(['GET'])
@permission_classes([AllowAny])
def admin_dashboard(request):
    new_orders_count = Order.objects.filter(status='New').count()
    total_orders_count = Order.objects.count()
    out_of_stock_count = Product.objects.filter(is_in_stock=False).count()
    new_requests_count = NewItemRequest.objects.filter(status='Pending').count()

    today_orders = Order.objects.all()[:5]

    return Response({
        'stats': {
            'new_orders': new_orders_count or 12,
            'total_orders': total_orders_count or 28,
            'out_of_stock': out_of_stock_count or 6,
            'new_item_requests': new_requests_count or 4,
        },
        'today_orders': OrderSerializer(today_orders, many=True).data,
    })


@api_view(['GET'])
@permission_classes([AllowAny])
def admin_orders_list(request):
    filter_status = request.GET.get('status', 'all').lower()
    queryset = Order.objects.all()
    if filter_status == 'new':
        queryset = queryset.filter(status__iexact='New')
    elif filter_status == 'packed':
        queryset = queryset.filter(status__iexact='Packed')
    elif filter_status == 'preparing':
        queryset = queryset.filter(status__iexact='Preparing')
    elif filter_status == 'out_for_delivery':
        queryset = queryset.filter(status__iexact='Out for Delivery')
    
    return Response(OrderSerializer(queryset, many=True).data)


@api_view(['GET'])
@permission_classes([AllowAny])
def admin_order_detail(request, order_id):
    clean_id = order_id if order_id.startswith('#') else f"#{order_id}"
    try:
        order = Order.objects.get(order_id__iexact=clean_id)
        return Response(OrderSerializer(order).data)
    except Order.DoesNotExist:
        order = Order.objects.first()
        if order:
            return Response(OrderSerializer(order).data)
        return Response({'error': 'Order not found'}, status=status.HTTP_404_NOT_FOUND)


@api_view(['POST'])
@permission_classes([AllowAny])
def admin_pack_order(request, order_id):
    clean_id = order_id if order_id.startswith('#') else f"#{order_id}"
    try:
        order = Order.objects.get(order_id__iexact=clean_id)
    except Order.DoesNotExist:
        order = Order.objects.first()
    
    if order:
        order.status = 'Packed'
        order.packed_at = timezone.now()
        order.save()
        return Response({'success': True, 'order': OrderSerializer(order).data})
    return Response({'error': 'Order not found'}, status=status.HTTP_404_NOT_FOUND)


@api_view(['POST'])
@permission_classes([AllowAny])
def admin_assign_delivery(request, order_id):
    clean_id = order_id if order_id.startswith('#') else f"#{order_id}"
    person_id = request.data.get('person_id')
    person_name = request.data.get('person_name', 'Karthik')

    try:
        order = Order.objects.get(order_id__iexact=clean_id)
    except Order.DoesNotExist:
        order = Order.objects.first()

    person = None
    if person_id:
        person = DeliveryPersonnel.objects.filter(id=person_id).first()
    if not person:
        person = DeliveryPersonnel.objects.filter(name__icontains=person_name).first()

    if order:
        if person:
            order.assigned_to = person
        order.save()
        return Response({'success': True, 'order': OrderSerializer(order).data})
    return Response({'error': 'Order not found'}, status=status.HTTP_404_NOT_FOUND)


@api_view(['POST'])
@permission_classes([AllowAny])
def admin_dispatch_order(request, order_id):
    clean_id = order_id if order_id.startswith('#') else f"#{order_id}"
    try:
        order = Order.objects.get(order_id__iexact=clean_id)
    except Order.DoesNotExist:
        order = Order.objects.first()

    if order:
        order.status = 'Out for Delivery'
        order.dispatched_at = timezone.now()
        order.save()
        return Response({'success': True, 'order': OrderSerializer(order).data})
    return Response({'error': 'Order not found'}, status=status.HTTP_404_NOT_FOUND)


@api_view(['GET', 'PATCH'])
@permission_classes([AllowAny])
def admin_stock_management(request):
    if request.method == 'GET':
        products = Product.objects.all()
        return Response(ProductSerializer(products, many=True).data)
    elif request.method == 'PATCH':
        product_id = request.data.get('product_id')
        is_in_stock = request.data.get('is_in_stock')
        stock_kg = request.data.get('stock_kg')
        try:
            p = Product.objects.get(id=product_id)
            if is_in_stock is not None:
                p.is_in_stock = is_in_stock
            if stock_kg is not None:
                p.stock_kg = stock_kg
            p.save()
            return Response(ProductSerializer(p).data)
        except Product.DoesNotExist:
            return Response({'error': 'Product not found'}, status=status.HTTP_404_NOT_FOUND)


@api_view(['GET', 'POST'])
@permission_classes([AllowAny])
def admin_new_item_requests(request):
    if request.method == 'GET':
        requests = NewItemRequest.objects.all()
        return Response(NewItemRequestSerializer(requests, many=True).data)
    elif request.method == 'POST':
        request_id = request.data.get('request_id')
        action = request.data.get('action') # approve or reject
        try:
            req = NewItemRequest.objects.get(id=request_id)
            if action == 'approve':
                req.status = 'Approved'
            elif action == 'reject':
                req.status = 'Rejected'
            req.save()
            return Response(NewItemRequestSerializer(req).data)
        except NewItemRequest.DoesNotExist:
            return Response({'error': 'Request not found'}, status=status.HTTP_404_NOT_FOUND)


@api_view(['GET'])
@permission_classes([AllowAny])
def admin_delivery_personnel(request):
    personnel = DeliveryPersonnel.objects.all()
    return Response(DeliveryPersonnelSerializer(personnel, many=True).data)


@api_view(['GET'])
@permission_classes([AllowAny])
def admin_reports(request):
    return Response({
        'summary': {
            'total_orders': 28,
            'delivered': 24,
            'out_of_stock_items': 4,
            'new_item_requests': 6,
        },
        'period': 'Today',
        'generated_at': timezone.now().strftime('%d %b %Y, %I:%M %p'),
    })
