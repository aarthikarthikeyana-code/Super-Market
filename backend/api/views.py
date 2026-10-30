import hashlib
import hmac
import json
import secrets
import uuid
from datetime import timedelta
from decimal import Decimal
from django.conf import settings
from django.contrib.auth import authenticate, get_user_model
from django.contrib.auth.hashers import check_password, make_password
from django.db import transaction
from django.db.models import Q, Sum
from django.shortcuts import get_object_or_404
from django.utils import timezone
from django.utils.dateparse import parse_datetime
from rest_framework import status
from rest_framework.authtoken.models import Token
from rest_framework.decorators import api_view, permission_classes, throttle_classes, authentication_classes
from rest_framework.exceptions import ValidationError
from rest_framework.permissions import AllowAny, IsAuthenticated, IsAdminUser
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from . import commerce, gateways
from .models import Product, ProductImage, DeliveryPersonnel, Order, OrderEvent, CustomerProfile, CustomerLoginChallenge
from .serializers import ProductSerializer, DeliveryPersonnelSerializer, OrderSerializer, CheckoutSerializer, CustomerPhoneSerializer, CustomerProfileSerializer, normalize_customer_phone


class LoginThrottle(ScopedRateThrottle):
    scope = 'login'
    def allow_request(self, request, view):
        view.throttle_scope = self.scope
        return super().allow_request(request, view)


class SessionThrottle(LoginThrottle):
    scope = 'session'


def orders_queryset():
    return Order.objects.filter(customer__isnull=False).select_related('customer', 'assigned_to').prefetch_related('items__product__image', 'events')


@api_view(['GET'])
@authentication_classes([])
@permission_classes([AllowAny])
@throttle_classes([])
def health(request):
    return Response({'status': 'ok', 'service': 'Agaram Supermarket', 'api_version': 2})


@api_view(['GET'])
@authentication_classes([])
@permission_classes([AllowAny])
def store_config(request):
    return Response({'api_version': 2, 'store_name': 'Agaram Supermarket', 'currency': 'INR', 'delivery_charge': settings.DELIVERY_CHARGE,
                     'online_payments_enabled': settings.PAYMENT_GATEWAY_ENABLED and bool(settings.RAZORPAY_KEY_ID),
                     'test_mode': settings.RAZORPAY_KEY_ID.startswith('rzp_test_'), 'delivery_mode': 'on_demand', 'customer_login_mode': 'otp' if settings.CUSTOMER_OTP_ENABLED else 'demo_code'})


@api_view(['POST'])
@authentication_classes([])
@permission_classes([AllowAny])
@throttle_classes([SessionThrottle])
def customer_session(request):
    if settings.CUSTOMER_OTP_ENABLED:
        return Response({'detail': 'OTP sign-in is not configured yet. Please contact the store.'}, status=503)
    serializer = CustomerPhoneSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    phone = serializer.validated_data['phone']
    CustomerLoginChallenge.objects.filter(expires_at__lt=timezone.now()).delete()
    code = str(10000 + secrets.randbelow(90000))
    challenge = CustomerLoginChallenge.objects.create(phone=phone, code_hash=make_password(code), expires_at=timezone.now() + timedelta(minutes=5))
    return Response({'challenge_id': str(challenge.pk), 'demo_code': code, 'expires_in': 300, 'mode': 'demo_code'})


@api_view(['POST'])
@authentication_classes([])
@permission_classes([AllowAny])
@throttle_classes([SessionThrottle])
def verify_customer_session(request):
    if settings.CUSTOMER_OTP_ENABLED:
        return Response({'detail': 'SMS OTP sign-in is not configured yet.'}, status=503)
    try:
        challenge_id = uuid.UUID(str(request.data.get('challenge_id', '')))
    except (ValueError, TypeError):
        raise ValidationError({'detail': 'Request a new verification code.'}) from None
    code = str(request.data.get('code', ''))
    with transaction.atomic():
        challenge = get_object_or_404(CustomerLoginChallenge.objects.select_for_update(), pk=challenge_id)
        if challenge.used or challenge.expires_at <= timezone.now() or challenge.attempts >= 5:
            return Response({'detail': 'This code has expired or was already used. Request a new code.'}, status=400)
        if len(code) != 5 or not code.isdigit() or not check_password(code, challenge.code_hash):
            challenge.attempts += 1
            challenge.save(update_fields=['attempts'])
            return Response({'detail': 'Incorrect code. Enter the 5-digit code shown on this screen.'}, status=400)
        challenge.used = True
        challenge.save(update_fields=['used'])
        phone = challenge.phone
        user, _ = get_user_model().objects.get_or_create(
            username='customer_' + phone[1:], defaults={'password': make_password(None)})
        if user.is_staff or user.is_superuser or not user.is_active:
            return Response({'detail': 'This customer account is unavailable.'}, status=403)
        profile, created = CustomerProfile.objects.get_or_create(user=user, defaults={'phone': phone})
        token, _ = Token.objects.get_or_create(user=user)
    return Response({'token': token.key, 'profile': CustomerProfileSerializer(profile).data,
                     'created': created, 'phone_verified': False}, status=201 if created else 200)


@api_view(['GET', 'PATCH'])
@permission_classes([IsAuthenticated])
def customer_profile(request):
    profile = get_object_or_404(CustomerProfile, user=request.user)
    if request.method == 'PATCH':
        serializer = CustomerProfileSerializer(profile, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)
    return Response(CustomerProfileSerializer(profile).data)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def customer_wishlist(request):
    profile = get_object_or_404(CustomerProfile, user=request.user)
    return Response(ProductSerializer(profile.wishlist.filter(is_active=True).select_related('image').order_by('english_name'), many=True).data)


@api_view(['POST', 'DELETE'])
@permission_classes([IsAuthenticated])
def customer_wishlist_item(request, pk):
    profile = get_object_or_404(CustomerProfile, user=request.user)
    product = get_object_or_404(Product, pk=pk, **({'is_active': True} if request.method == 'POST' else {}))
    if request.method == 'POST':
        profile.wishlist.add(product)
    else:
        profile.wishlist.remove(product)
    return Response(status=204)


@api_view(['POST'])
@authentication_classes([])
@permission_classes([AllowAny])
@throttle_classes([LoginThrottle])
def admin_login(request):
    identifier = str(request.data.get('admin_id', '')).strip()
    password = request.data.get('password', '')
    if not identifier or not isinstance(password, str) or not password:
        raise ValidationError({'detail': 'Enter your admin email and password.'})
    user_model = get_user_model()
    account = user_model.objects.filter(Q(username__iexact=identifier) | Q(email__iexact=identifier)).first()
    user = authenticate(request, username=account.username if account else identifier, password=password)
    if not user or not user.is_staff or not user.is_active:
        return Response({'detail': 'Invalid admin email or password.'}, status=401)
    token, _ = Token.objects.get_or_create(user=user)
    return Response({'token': token.key, 'admin': {'name': user.get_full_name() or 'Store administrator', 'email': user.email}})


@api_view(['POST'])
@permission_classes([IsAdminUser])
def admin_logout(request):
    request.auth.delete()
    return Response(status=204)


@api_view(['GET'])
@authentication_classes([])
@permission_classes([AllowAny])
def get_products(request):
    products = Product.objects.filter(is_active=True).select_related('image').order_by('english_name')
    if request.query_params.get('category'):
        products = products.filter(category=request.query_params['category'])
    if request.query_params.get('search'):
        query = request.query_params['search'][:100]
        products = products.filter(Q(english_name__icontains=query) | Q(tamil_name__icontains=query) | Q(brand__icontains=query))
    return Response(ProductSerializer(products, many=True).data)


@api_view(['GET'])
@authentication_classes([])
@permission_classes([AllowAny])
def get_product_detail(request, pk):
    return Response(ProductSerializer(get_object_or_404(Product, pk=pk, is_active=True)).data)


@api_view(['GET', 'POST'])
@permission_classes([IsAdminUser])
def admin_products(request):
    if request.method == 'GET':
        products = Product.objects.filter(is_active=True).select_related('image').order_by('english_name')
        return Response(ProductSerializer(products, many=True).data)
    serializer = ProductSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    product = serializer.save(id='P' + uuid.uuid4().hex, is_active=True)
    return Response(ProductSerializer(product).data, status=201)


@api_view(['PATCH', 'DELETE'])
@permission_classes([IsAdminUser])
def admin_product_detail(request, pk):
    with transaction.atomic():
        product = get_object_or_404(Product.objects.select_for_update(), pk=pk, is_active=True)
        if request.method == 'DELETE':
            product.is_active = False
            product.save(update_fields=['is_active', 'updated_at'])
            return Response(status=204)
        serializer = ProductSerializer(product, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
    return Response(serializer.data)


@api_view(['POST'])
@permission_classes([IsAdminUser])
def upload_product_image(request):
    file = request.FILES.get('image')
    if not file:
        raise ValidationError({'image': 'Choose a product photo.'})
    result = gateways.upload_image(file)
    image = ProductImage.objects.create(public_id=result['public_id'], secure_url=result['secure_url'], uploaded_by=request.user)
    return Response({'id': str(image.pk), 'image_url': image.secure_url}, status=201)


@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def customer_orders(request):
    if request.method == 'GET':
        return Response(OrderSerializer(orders_queryset().filter(customer=request.user), many=True).data)
    profile = get_object_or_404(CustomerProfile, user=request.user)
    serializer = CheckoutSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    if normalize_customer_phone(serializer.validated_data['customer_phone']) != profile.phone:
        raise ValidationError({'customer_phone': 'Use the phone number of the signed-in account.'})
    serializer.validated_data['customer_phone'] = profile.phone
    commerce.expire_pending_orders()
    order = commerce.create_order(request.user, serializer.validated_data)
    return Response({'order': OrderSerializer(order).data, 'checkout': commerce.checkout_data(order)}, status=201)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def customer_order_detail(request, order_id):
    order = get_object_or_404(orders_queryset(), order_id=order_id, customer=request.user)
    return Response({'order': OrderSerializer(order).data, 'checkout': commerce.checkout_data(order)})


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def verify_payment(request, order_id):
    order = get_object_or_404(orders_queryset(), order_id=order_id, customer=request.user)
    payment_id = str(request.data.get('razorpay_payment_id', ''))
    if not payment_id.startswith('pay_') or len(payment_id) > 100 or not order.razorpay_order_id:
        raise ValidationError({'detail': 'Invalid payment reference.'})
    commerce.verify_signature(order, payment_id, str(request.data.get('razorpay_signature', '')))
    order = commerce.confirm_payment(order, payment_id)
    return Response(OrderSerializer(order).data)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def cancel_checkout(request, order_id):
    with transaction.atomic():
        order = get_object_or_404(Order.objects.select_for_update(), order_id=order_id, customer=request.user)
        if order.status == 'Cancelled' and order.payment_status in ['expired', 'cancelled']:
            return Response(OrderSerializer(order).data)
        if order.status != 'Payment Pending' or order.payment_status != 'pending':
            raise ValidationError({'detail': 'Only an unpaid checkout can be cancelled here. Contact the store for other orders.'})
        commerce.release_stock(order)
        order.status = 'Cancelled'
        order.payment_status = 'cancelled'
        order.save()
        OrderEvent.objects.create(order=order, status='Cancelled', note='Unpaid checkout cancelled by customer.')
    return Response(OrderSerializer(order).data)


@api_view(['POST'])
@authentication_classes([])
@permission_classes([AllowAny])
@throttle_classes([])
def razorpay_webhook(request):
    if not settings.RAZORPAY_WEBHOOK_SECRET:
        return Response({'detail': 'Webhook is not configured.'}, status=503)
    expected = hmac.new(settings.RAZORPAY_WEBHOOK_SECRET.encode(), request.body, hashlib.sha256).hexdigest()
    if not hmac.compare_digest(expected, request.headers.get('X-Razorpay-Signature', '')):
        return Response({'detail': 'Invalid webhook signature.'}, status=400)
    try:
        data = json.loads(request.body)
        if data.get('event') not in ['payment.captured', 'order.paid']:
            return Response({'received': True})
        payment = data['payload']['payment']['entity']
        order = Order.objects.filter(razorpay_order_id=payment['order_id']).first()
        if order:
            commerce.confirm_payment(order, payment['id'])
    except (KeyError, ValueError, TypeError):
        return Response({'detail': 'Invalid webhook payload.'}, status=400)
    return Response({'received': True})


@api_view(['GET'])
@permission_classes([IsAdminUser])
def admin_dashboard(request):
    orders = orders_queryset()
    fulfilled = orders.filter(payment_status__in=['paid', 'cod']).exclude(status='Cancelled')
    return Response({'total_products': Product.objects.filter(is_active=True).count(),
                     'total_orders': fulfilled.count(), 'awaiting_payment': orders.filter(payment_status='pending').count(),
                     'active_deliveries': fulfilled.filter(status='Out for Delivery').count(),
                     'new_orders': fulfilled.filter(status='New').count(),
                     'revenue': str(fulfilled.filter(payment_status='paid').aggregate(total=Sum('total_amount'))['total'] or Decimal('0.00')),
                     'delivered': fulfilled.filter(status='Delivered').count(),
                     'low_stock': Product.objects.filter(is_active=True, stock_kg__lte=5).count(),
                     'recent_orders': OrderSerializer(orders[:10], many=True).data})


@api_view(['GET'])
@permission_classes([IsAdminUser])
def admin_orders(request):
    orders = orders_queryset()
    if request.query_params.get('status'):
        orders = orders.filter(status=request.query_params['status'])
    return Response(OrderSerializer(orders, many=True).data)


@api_view(['PATCH'])
@permission_classes([IsAdminUser])
def admin_order_update(request, order_id):
    get_object_or_404(Order, order_id=order_id, customer__isnull=False)
    note = str(request.data.get('delivery_note', ''))
    if len(note) > 255:
        raise ValidationError({'delivery_note': 'Use at most 255 characters.'})
    eta = None
    if request.data.get('estimated_delivery_at'):
        eta = parse_datetime(str(request.data['estimated_delivery_at']))
        if not eta or timezone.is_naive(eta):
            raise ValidationError({'estimated_delivery_at': 'Use an ISO 8601 timestamp with timezone.'})
    person_id = request.data.get('assigned_to')
    if person_id is not None:
        try:
            person_id = int(person_id)
        except (ValueError, TypeError):
            raise ValidationError({'assigned_to': 'Choose a valid delivery person.'}) from None
    order = commerce.transition_order(order_id, request.data.get('status'), note, person_id, eta)
    return Response(OrderSerializer(order).data)


@api_view(['GET', 'POST'])
@permission_classes([IsAdminUser])
def admin_delivery_personnel(request):
    if request.method == 'GET':
        return Response(DeliveryPersonnelSerializer(DeliveryPersonnel.objects.filter(is_active=True).order_by('name'), many=True).data)
    serializer = DeliveryPersonnelSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    serializer.save()
    return Response(serializer.data, status=201)


@api_view(['PATCH'])
@permission_classes([IsAdminUser])
def admin_delivery_person_detail(request, pk):
    person = get_object_or_404(DeliveryPersonnel, pk=pk)
    if request.data.get('is_active') is False and person.assigned_orders.exclude(status__in=['Delivered', 'Cancelled']).exists():
        raise ValidationError({'detail': 'Reassign this person?s active orders before deactivating.'})
    serializer = DeliveryPersonnelSerializer(person, data=request.data, partial=True)
    serializer.is_valid(raise_exception=True)
    serializer.save()
    return Response(serializer.data)
