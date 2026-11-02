import secrets
import re
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
from rest_framework.permissions import AllowAny, IsAuthenticated, IsAdminUser, BasePermission
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle, UserRateThrottle
from . import commerce, gateways
from .commerce import cash_total
from .serializers import EmployeeSerializer, DeliveryActionSerializer, CashReceiptSerializer, CashDueSerializer, CashHandoverSerializer
from rest_framework.pagination import CursorPagination
from .models import Product, ProductImage, DeliveryPersonnel, Order, OrderEvent, CustomerProfile, CustomerLoginChallenge, CashHandover, EmployeeDocument
from .serializers import ProductSerializer, DeliveryPersonnelSerializer, OrderSerializer, CheckoutSerializer, CustomerPhoneSerializer, CustomerProfileSerializer, normalize_customer_phone


class StoreCursorPagination(CursorPagination):
    page_size = 24
    page_size_query_param = 'page_size'
    max_page_size = 48


def collection_response(request, queryset, serializer, ordering, extra=None):
    """Opt-in pagination keeps existing bounded/internal list clients compatible."""
    if request.query_params.get('paginate') != 'true':
        return Response(serializer(queryset, many=True).data)
    paginator = StoreCursorPagination()
    paginator.ordering = ordering
    page = paginator.paginate_queryset(queryset, request)
    response = paginator.get_paginated_response(serializer(page, many=True).data)
    if extra:
        response.data.update(extra)
    return response


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
    return Response({'status': 'ok', 'service': 'Agaram Supermarket', 'api_version': 5})


@api_view(['GET'])
@authentication_classes([])
@permission_classes([AllowAny])
def store_config(request):
    return Response({'api_version': 5, 'store_name': 'Agaram Supermarket', 'currency': 'INR', 'delivery_charge': settings.DELIVERY_CHARGE,
                     'online_payments_enabled': False, 'payment_methods': ['cod'], 'cash_on_delivery_enabled': True, 'delivery_mode': 'on_demand', 'delivery_login_mode': 'phone_demo' if settings.DELIVERY_PHONE_LOGIN_ENABLED else 'password', 'customer_login_mode': 'otp' if settings.CUSTOMER_OTP_ENABLED else 'demo_code'})


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
    products = profile.wishlist.filter(is_active=True).select_related('image')
    if request.query_params.get('ids_only') == 'true':
        return Response(list(products.values_list('id', flat=True)))
    return collection_response(request, products, ProductSerializer, ('tamil_name', 'pk'))


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
    products = Product.objects.filter(is_active=True).select_related('image').order_by('tamil_name')
    if request.query_params.get('ids'):
        ids = request.query_params['ids'].split(',')
        if len(ids) > 100 or any(len(pk) > 64 for pk in ids):
            raise ValidationError({'ids': 'Request at most 100 product IDs at a time.'})
        products = products.filter(pk__in=ids)
    if request.query_params.get('category'):
        products = products.filter(category=request.query_params['category'])
    if request.query_params.get('search'):
        query = request.query_params['search'][:100]
        products = products.filter(Q(english_name__icontains=query) | Q(tamil_name__icontains=query) | Q(brand__icontains=query))
    return collection_response(request, products, ProductSerializer, ('tamil_name', 'pk'), {'categories': list(Product.objects.filter(is_active=True).order_by('category').values_list('category', flat=True).distinct())})


@api_view(['GET'])
@authentication_classes([])
@permission_classes([AllowAny])
def get_product_detail(request, pk):
    return Response(ProductSerializer(get_object_or_404(Product, pk=pk, is_active=True)).data)


# Naming vocabulary, not catalog records. Unknown names stay for manual review.
GROCERY_TAMIL_NAMES = {
    'rice': 'அரிசி', 'ponni rice': 'பொன்னி அரிசி', 'ponni boiled rice': 'பொன்னி புழுங்கல் அரிசி',
    'boiled rice': 'புழுங்கல் அரிசி', 'raw rice': 'பச்சரிசி', 'idli rice': 'இட்லி அரிசி',
    'basmati rice': 'பாசுமதி அரிசி', 'brown rice': 'பழுப்பு அரிசி',
    'toor dal': 'துவரம் பருப்பு', 'tur dal': 'துவரம் பருப்பு', 'arhar dal': 'துவரம் பருப்பு',
    'urad dal': 'உளுத்தம் பருப்பு', 'black gram': 'உளுத்தம் பருப்பு',
    'moong dal': 'பாசிப் பருப்பு', 'mung dal': 'பாசிப் பருப்பு', 'green gram': 'பச்சைப் பயறு',
    'chana dal': 'கடலைப் பருப்பு', 'bengal gram': 'கடலைப் பருப்பு',
    'chickpeas': 'கொண்டைக்கடலை', 'kabuli chana': 'வெள்ளைக் கொண்டைக்கடலை',
    'black chana': 'கருப்புக் கொண்டைக்கடலை', 'masoor dal': 'மசூர் பருப்பு',
    'wheat': 'கோதுமை', 'wheat flour': 'கோதுமை மாவு', 'atta': 'கோதுமை மாவு',
    'whole wheat atta': 'முழுக் கோதுமை மாவு', 'maida': 'மைதா மாவு',
    'rice flour': 'அரிசி மாவு', 'gram flour': 'கடலை மாவு', 'besan': 'கடலை மாவு',
    'rava': 'ரவை', 'sooji': 'ரவை', 'semolina': 'ரவை', 'vermicelli': 'சேமியா',
    'sugar': 'சர்க்கரை', 'brown sugar': 'நாட்டுச் சர்க்கரை', 'jaggery': 'வெல்லம்',
    'salt': 'உப்பு', 'rock salt': 'கல் உப்பு', 'iodized salt': 'அயோடின் உப்பு',
    'groundnut oil': 'கடலை எண்ணெய்', 'peanut oil': 'கடலை எண்ணெய்',
    'sesame oil': 'நல்லெண்ணெய்', 'gingelly oil': 'நல்லெண்ணெய்',
    'coconut oil': 'தேங்காய் எண்ணெய்', 'sunflower oil': 'சூரியகாந்தி எண்ணெய்',
    'ghee': 'நெய்', 'butter': 'வெண்ணெய்', 'milk': 'பால்', 'curd': 'தயிர்',
    'turmeric': 'மஞ்சள்', 'turmeric powder': 'மஞ்சள் தூள்', 'chilli powder': 'மிளகாய்த் தூள்',
    'chili powder': 'மிளகாய்த் தூள்', 'red chilli powder': 'மிளகாய்த் தூள்',
    'coriander powder': 'மல்லித் தூள்', 'cumin powder': 'சீரகத் தூள்',
    'sambar powder': 'சாம்பார் பொடி', 'rasam powder': 'ரசப் பொடி',
    'garam masala': 'கரம் மசாலா', 'mustard': 'கடுகு', 'mustard seeds': 'கடுகு',
    'cumin': 'சீரகம்', 'cumin seeds': 'சீரகம்', 'fennel seeds': 'சோம்பு',
    'fenugreek': 'வெந்தயம்', 'fenugreek seeds': 'வெந்தயம்', 'black pepper': 'மிளகு',
    'pepper': 'மிளகு', 'cardamom': 'ஏலக்காய்', 'cloves': 'கிராம்பு',
    'cinnamon': 'பட்டை', 'tamarind': 'புளி', 'asafoetida': 'பெருங்காயம்',
    'red chilli': 'காய்ந்த மிளகாய்', 'coriander seeds': 'மல்லி',
    'tea': 'தேயிலை', 'tea powder': 'தேயிலைத் தூள்', 'coffee': 'காபி',
    'coffee powder': 'காபித் தூள்', 'honey': 'தேன்', 'cashew': 'முந்திரி',
    'cashew nuts': 'முந்திரி', 'almonds': 'பாதாம்', 'raisins': 'உலர் திராட்சை',
    'dates': 'பேரீச்சம்பழம்', 'peanuts': 'நிலக்கடலை', 'roasted gram': 'பொட்டுக்கடலை',
    'oats': 'ஓட்ஸ்', 'poha': 'அவல்', 'flattened rice': 'அவல்', 'sago': 'ஜவ்வரிசி',
    'ragi flour': 'கேழ்வரகு மாவு', 'ragi': 'கேழ்வரகு', 'millet': 'சிறுதானியம்',
    'bajra': 'கம்பு', 'jowar': 'சோளம்', 'thinai': 'தினை',
    'onion': 'வெங்காயம்', 'tomato': 'தக்காளி', 'potato': 'உருளைக்கிழங்கு',
    'carrot': 'கேரட்', 'beans': 'பீன்ஸ்', 'brinjal': 'கத்திரிக்காய்',
    'garlic': 'பூண்டு', 'ginger': 'இஞ்சி', 'coconut': 'தேங்காய்',
    'curry leaves': 'கறிவேப்பிலை', 'mint': 'புதினா', 'coriander leaves': 'கொத்தமல்லி',
}


@api_view(['GET'])
@permission_classes([IsAdminUser])
def suggest_tamil_product_name(request):
    name = request.query_params.get('english_name', '').strip()
    if not name or len(name) > 120:
        raise ValidationError({'english_name': 'Enter an English product name, up to 120 characters.'})
    normalized = re.sub(r'[\s_-]+', ' ', name.casefold()).strip()
    quantity = ''
    pack = re.search(r'\s+(\d+(?:\.\d+)?)\s*(kg|kilograms?|g|gm|gms|grams?|l|ltr|litres?|liters?|ml|pack|pcs)\.?$', normalized)
    if pack:
        units = {'kg': 'கிலோ', 'g': 'கிராம்', 'gm': 'கிராம்', 'gms': 'கிராம்',
                 'l': 'லிட்டர்', 'ltr': 'லிட்டர்', 'ml': 'மில்லி', 'pack': 'பேக்', 'pcs': 'எண்ணிக்கை'}
        unit = pack[2]
        unit = 'kg' if unit.startswith('kilogram') else 'g' if unit.startswith('gram') else 'l' if unit.startswith(('liter', 'litre')) else unit
        quantity = ' ' + pack[1] + ' ' + units[unit]
        normalized = normalized[:pack.start()].strip()
    translated = GROCERY_TAMIL_NAMES.get(normalized)
    return Response({'tamil_name': translated + quantity if translated else '',
                     'matched': bool(translated), 'requires_review': True})


@api_view(['GET', 'POST'])
@permission_classes([IsAdminUser])
def admin_products(request):
    if request.method == 'GET':
        products = Product.objects.filter(is_active=True).select_related('image').order_by('tamil_name')
        if request.query_params.get('search'):
            products = products.filter(Q(english_name__icontains=request.query_params['search'][:100]) | Q(tamil_name__icontains=request.query_params['search'][:100]) | Q(brand__icontains=request.query_params['search'][:100]))
        return collection_response(request, products, ProductSerializer, ('tamil_name', 'pk'))
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
        return collection_response(request, orders_queryset().filter(customer=request.user), OrderSerializer, ('-created_at', '-pk'))
    profile = get_object_or_404(CustomerProfile, user=request.user)
    serializer = CheckoutSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    if normalize_customer_phone(serializer.validated_data['customer_phone']) != profile.phone:
        raise ValidationError({'customer_phone': 'Use the phone number of the signed-in account.'})
    serializer.validated_data['customer_phone'] = profile.phone
    commerce.expire_pending_orders()
    order = commerce.create_order(request.user, serializer.validated_data)
    return Response({'order': OrderSerializer(order).data, 'checkout': None}, status=201)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def customer_order_detail(request, order_id):
    order = get_object_or_404(orders_queryset(), order_id=order_id, customer=request.user)
    return Response({'order': OrderSerializer(order).data, 'checkout': None})


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def cancel_checkout(request, order_id):
    get_object_or_404(Order, order_id=order_id, customer=request.user)
    order = commerce.cancel_order(order_id, customer=request.user)
    return Response(OrderSerializer(order).data)


@api_view(['GET'])
@permission_classes([IsAdminUser])
def admin_dashboard(request):
    orders = orders_queryset()
    fulfilled = orders.filter(payment_status__in=['paid', 'cod', 'collected']).exclude(status='Cancelled')
    return Response({'total_products': Product.objects.filter(is_active=True).count(),
                     'total_orders': fulfilled.count(), 'awaiting_payment': orders.filter(payment_status='pending').count(),
                     'active_deliveries': fulfilled.filter(status='Out for Delivery').count(),
                     'new_orders': fulfilled.filter(status='New').count(),
                     'revenue': str(fulfilled.filter(payment_status__in=['paid', 'collected']).aggregate(total=Sum('total_amount'))['total'] or Decimal('0.00')),
                     'cash_collected': str(orders.filter(payment_status='collected').aggregate(total=Sum('cash_collected_amount'))['total'] or Decimal('0.00')),
                     'cash_received_by_store': str(CashHandover.objects.aggregate(total=Sum('amount'))['total'] or Decimal('0.00')),
                     'cash_with_employees': str(orders.filter(payment_status='collected', cash_collected_for__isnull=False, cash_handover__isnull=True).aggregate(total=Sum('cash_collected_amount'))['total'] or Decimal('0.00')),
                     'cash_due': str(orders.filter(payment_status='cod').exclude(status='Cancelled').aggregate(total=Sum('total_amount'))['total'] or Decimal('0.00')),
                     'delivery_attempted': fulfilled.filter(status='Delivery Attempted').count(),
                     'packed': fulfilled.filter(status='Packed').count(),
                     'delivered': fulfilled.filter(status='Delivered').count(),
                     'low_stock': Product.objects.filter(is_active=True, stock_kg__lte=5).count(),
                     'recent_orders': OrderSerializer(orders[:10], many=True).data})


@api_view(['GET'])
@permission_classes([IsAdminUser])
def admin_orders(request):
    orders = orders_queryset()
    if request.query_params.get('status'):
        orders = orders.filter(status=request.query_params['status'])
    return collection_response(request, orders, OrderSerializer, ('-created_at', '-pk'))


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
    for field in ['cash_collected', 'stock_returned']:
        if field in request.data and type(request.data[field]) is not bool:
            raise ValidationError({field: 'Use true or false.'})
    if request.data.get('status') == 'Cancelled':
        reason = str(request.data.get('cancellation_reason', '')).strip()
        if len(reason) > 255:
            raise ValidationError({'cancellation_reason': 'Use at most 255 characters.'})
        order = commerce.cancel_order(order_id, reason=reason, stock_returned=request.data.get('stock_returned', False))
    else:
        from rest_framework import serializers
        cash_amount = None
        if request.data.get('cash_collected_amount') is not None:
            cash_amount = serializers.DecimalField(max_digits=10, decimal_places=2, min_value=Decimal('0.01')).run_validation(request.data['cash_collected_amount'])
        order = commerce.transition_order(order_id, request.data.get('status'), note, person_id, eta,
                                          cash_collected=request.data.get('cash_collected', False), cash_amount=cash_amount, actor=request.user)
    return Response(OrderSerializer(order).data)


@api_view(['GET', 'POST'])
@permission_classes([IsAdminUser])
def admin_delivery_personnel(request):
    if request.method == 'GET':
        people = DeliveryPersonnel.objects.select_related('user').prefetch_related('documents')
        if request.query_params.get('search'):
            query = request.query_params['search'][:100]
            people = people.filter(Q(name__icontains=query) | Q(phone__icontains=query) | Q(employee_code__icontains=query))
        if request.query_params.get('ready') == 'true':
            people = people.filter(is_active=True, documents_verified=True, user__is_active=True, user__is_staff=False).filter(Q(vehicle_type__in=['walking', 'bicycle']) | Q(licence_expiry__gte=timezone.localdate()))
        return collection_response(request, people, EmployeeSerializer, ('name', 'pk'))
    serializer = EmployeeSerializer(data=request.data, context={'request': request})
    serializer.is_valid(raise_exception=True)
    serializer.save()
    return Response(serializer.data, status=201)


@api_view(['GET', 'PATCH'])
@permission_classes([IsAdminUser])
@transaction.atomic
def admin_delivery_person_detail(request, pk):
    person = get_object_or_404(DeliveryPersonnel.objects.select_for_update(), pk=pk)
    if request.method == 'GET':
        return Response(EmployeeSerializer(person).data)
    if request.data.get('is_active') is False and person.assigned_orders.exclude(status__in=['Delivered', 'Cancelled']).exists():
        raise ValidationError({'detail': 'Reassign active orders before deactivating this delivery person.'})
    serializer = EmployeeSerializer(person, data=request.data, partial=True, context={'request': request})
    serializer.is_valid(raise_exception=True)
    serializer.save()
    return Response(serializer.data)


# Delivery employee access, assigned orders, private documents and cash receipts.
class IsDeliveryEmployee(BasePermission):
    def has_permission(self, request, view):
        user = request.user
        return bool(user and user.is_authenticated and user.is_active and not user.is_staff
                    and DeliveryPersonnel.objects.filter(user=user, is_active=True).exists())


class DeliveryLoginThrottle(UserRateThrottle):
    scope = 'login'


def employee_info(person):
    return {key: getattr(person, key) for key in ['id', 'employee_code', 'name', 'phone', 'vehicle_type', 'vehicle_number', 'documents_verified']}


@api_view(['POST'])
@authentication_classes([])
@permission_classes([AllowAny])
@throttle_classes([DeliveryLoginThrottle])
def employee_login(request):
    code = str(request.data.get('employee_code', '')).strip().upper()
    password = request.data.get('password', '')
    person = DeliveryPersonnel.objects.select_related('user').filter(employee_code=code, is_active=True).first()
    message = 'Invalid employee ID or mobile number.' if settings.DELIVERY_PHONE_LOGIN_ENABLED else 'Invalid employee ID or password.'
    if not person or not person.user_id or not person.user.is_active or person.user.is_staff or person.user.is_superuser:
        raise ValidationError({'detail': message})
    if settings.DELIVERY_PHONE_LOGIN_ENABLED and 'phone' in request.data:
        try:
            phone = normalize_customer_phone(request.data['phone'])
            registered = normalize_customer_phone(person.phone)
        except (ValidationError, TypeError):
            raise ValidationError({'detail': message}) from None
        if not secrets.compare_digest(phone, registered):
            raise ValidationError({'detail': message})
        user = person.user
    else:
        user = authenticate(request, username=person.user.username, password=password) if isinstance(password, str) else None
        if not user:
            raise ValidationError({'detail': message})
    token, _ = Token.objects.get_or_create(user=user)
    return Response({'token': token.key, 'employee': employee_info(person)})


@api_view(['POST'])
@permission_classes([IsDeliveryEmployee])
def employee_logout(request):
    request.auth.delete()
    return Response(status=204)


@api_view(['GET'])
@permission_classes([IsDeliveryEmployee])
def employee_dashboard(request):
    person = request.user.delivery_employee
    orders = Order.objects.filter(assigned_to=person, customer__isnull=False)
    cash = person.cash_orders.filter(payment_status='collected')
    return Response({'employee': employee_info(person), 'assigned': orders.exclude(status__in=['Delivered', 'Cancelled']).count(),
                     'delivered': orders.filter(status='Delivered').count(),
                     'cash_to_collect': str(orders.filter(payment_status='cod').exclude(status='Cancelled').aggregate(total=Sum('total_amount'))['total'] or Decimal('0.00')),
                     'cash_collected': str(cash_total(cash)), 'cash_to_handover': str(cash_total(cash.filter(cash_handover__isnull=True))),
                     'handovers': [{'id': str(h.pk), 'amount': str(h.amount), 'received_at': h.received_at} for h in person.cash_handovers.all()[:20]]})


def own_orders(user):
    return Order.objects.filter(customer__isnull=False, assigned_to__user=user).select_related('assigned_to').prefetch_related('items__product__image', 'events')


@api_view(['GET'])
@permission_classes([IsDeliveryEmployee])
def employee_orders(request):
    orders = own_orders(request.user)
    if request.query_params.get('scope') == 'active':
        orders = orders.exclude(status__in=['Delivered', 'Cancelled'])
    elif request.query_params.get('scope') == 'completed':
        orders = orders.filter(status__in=['Delivered', 'Cancelled'])
    return collection_response(request, orders, OrderSerializer, ('-created_at', '-pk'))


@api_view(['GET', 'PATCH'])
@permission_classes([IsDeliveryEmployee])
def employee_order(request, order_id):
    order = get_object_or_404(own_orders(request.user), order_id=order_id)
    if request.method == 'PATCH':
        serializer = DeliveryActionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        order = commerce.transition_order(order_id, data['status'], data['delivery_note'],
                                          cash_collected=data['cash_collected'], cash_amount=data.get('cash_collected_amount'), actor=request.user)
    return Response(OrderSerializer(order).data)


@api_view(['POST'])
@permission_classes([IsAdminUser])
def employee_document_upload(request, pk):
    person = get_object_or_404(DeliveryPersonnel, pk=pk)
    if not person.document_consent:
        raise ValidationError({'detail': 'Record employee consent before uploading onboarding documents.'})
    kind = request.data.get('kind')
    if kind not in dict(EmployeeDocument._meta.get_field('kind').choices):
        raise ValidationError({'kind': 'Choose a valid document type.'})
    file = request.FILES.get('document')
    if not file:
        raise ValidationError({'document': 'Choose a JPEG, PNG or WebP document photo.'})
    result = gateways.upload_employee_document(file)
    document = EmployeeDocument.objects.create(employee=person, kind=kind, public_id=result['public_id'], format=result['format'], uploaded_by=request.user)
    if kind != 'photo':
        DeliveryPersonnel.objects.filter(pk=pk).update(documents_verified=False, verified_at=None, verified_by=None)
    return Response({'id': str(document.pk), 'kind': document.kind}, status=201)


@api_view(['GET', 'DELETE'])
@permission_classes([IsAdminUser])
def employee_document(request, pk, document_id):
    document = get_object_or_404(EmployeeDocument, pk=document_id, employee_id=pk)
    if request.method == 'DELETE':
        gateways.delete_employee_document(document)
        document.delete()
        DeliveryPersonnel.objects.filter(pk=pk).update(documents_verified=False, verified_at=None, verified_by=None)
        return Response(status=204)
    return Response({'url': gateways.employee_document_url(document), 'expires_in': 60})


@api_view(['GET'])
@permission_classes([IsDeliveryEmployee])
def employee_receipts(request):
    return collection_response(request, request.user.delivery_employee.cash_handovers.all(), CashReceiptSerializer, ('-received_at', '-pk'))


@api_view(['GET'])
@permission_classes([IsAdminUser])
def admin_employee_receipts(request, pk):
    person = get_object_or_404(DeliveryPersonnel, pk=pk)
    return collection_response(request, person.cash_handovers.all(), CashReceiptSerializer, ('-received_at', '-pk'))


@api_view(['GET', 'POST'])
@permission_classes([IsAdminUser])
def employee_cash_handover(request, pk):
    person = get_object_or_404(DeliveryPersonnel, pk=pk)
    due = person.cash_orders.filter(payment_status='collected', cash_handover__isnull=True).order_by('cash_collected_at')
    if request.method == 'GET':
        if request.query_params.get('paginate') == 'true':
            return collection_response(request, due, CashDueSerializer, ('cash_collected_at', 'pk'), {'cash_to_handover': str(cash_total(due))})
        return Response({'cash_to_handover': str(cash_total(due)),
                         'orders': [{'order_id': o.order_id, 'amount': str(o.cash_collected_amount), 'collected_at': o.cash_collected_at} for o in due],
                         'receipts': [{'id': str(h.pk), 'amount': str(h.amount), 'received_at': h.received_at} for h in person.cash_handovers.all()[:20]]})
    serializer = CashHandoverSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    data = serializer.validated_data
    with transaction.atomic():
        orders = list(Order.objects.select_for_update().filter(order_id__in=data['order_ids'], cash_collected_for=person, payment_status='collected').order_by('pk'))
        DeliveryPersonnel.objects.select_for_update().get(pk=pk)
        existing = CashHandover.objects.filter(idempotency_key=data['idempotency_key']).first()
        if existing:
            if existing.employee_id != pk or existing.amount != data['amount'] or set(existing.orders.values_list('order_id', flat=True)) != set(data['order_ids']):
                raise ValidationError({'detail': 'This cash receipt reference was already used for another handover.'})
            return Response({'id': str(existing.pk), 'amount': str(existing.amount), 'received_at': existing.received_at})
        if len(orders) != len(data['order_ids']) or any(o.cash_handover_id for o in orders) or sum((o.cash_collected_amount for o in orders), Decimal('0.00')) != data['amount']:
            raise ValidationError({'detail': 'Cash due changed or the amount does not match the selected orders. Refresh and check again.'})
        receipt = CashHandover.objects.create(employee=person, idempotency_key=data['idempotency_key'], amount=data['amount'], received_by=request.user)
        Order.objects.filter(pk__in=[o.pk for o in orders]).update(cash_handover=receipt)
    return Response({'id': str(receipt.pk), 'amount': str(receipt.amount), 'received_at': receipt.received_at}, status=201)
