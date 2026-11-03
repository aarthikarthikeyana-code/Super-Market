from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError
from django.db import transaction
from django.utils import timezone
from rest_framework.authtoken.models import Token
from rest_framework.exceptions import ValidationError
from .commerce import cash_total, is_grocery_category
from decimal import Decimal
from rest_framework import serializers
from .models import Product, ProductImage, DeliveryPersonnel, EmployeeCodeSequence, Order, OrderItem, OrderEvent, CustomerProfile, CashHandover


@transaction.atomic
def next_employee_code():
    year = timezone.localdate().year
    EmployeeCodeSequence.objects.get_or_create(year=year)
    sequence = EmployeeCodeSequence.objects.select_for_update().get(year=year)
    sequence.last_number += 1
    sequence.save(update_fields=['last_number'])
    return f'BB{year}{sequence.last_number:03d}'


class ProductSerializer(serializers.ModelSerializer):
    tamil_name = serializers.CharField(required=True, allow_blank=False, max_length=120)
    english_name = serializers.CharField(required=False, allow_blank=True, default='', max_length=120)
    category = serializers.CharField(max_length=60, default='Groceries')
    image_url = serializers.SerializerMethodField()
    image = serializers.PrimaryKeyRelatedField(queryset=ProductImage.objects.all(), required=False, allow_null=True)
    price = serializers.DecimalField(max_digits=10, decimal_places=2, min_value=Decimal('0.01'))
    stock_kg = serializers.DecimalField(max_digits=10, decimal_places=2, min_value=Decimal('0'))

    def get_image_url(self, product):
        return product.image.secure_url if product.image_id else ''

    def validate_category(self, category):
        if not is_grocery_category(category):
            raise serializers.ValidationError('This store sells groceries only; fresh fruit and vegetable categories are not supported.')
        return category

    class Meta:
        model = Product
        fields = ['id', 'english_name', 'tamil_name', 'brand', 'category', 'sku', 'price', 'unit',
                  'stock_kg', 'is_in_stock', 'description', 'image', 'image_url', 'is_active', 'updated_at']
        read_only_fields = ['id', 'updated_at']

    def validate_image(self, image):
        if image is None:
            return None
        if not image.secure_url.startswith('https://res.cloudinary.com/'):
            raise serializers.ValidationError('Upload a product photo before saving.')
        return image


class PublicDeliveryPersonnelSerializer(serializers.ModelSerializer):
    class Meta:
        model = DeliveryPersonnel
        fields = ['id', 'name', 'phone']


class DeliveryPersonnelSerializer(serializers.ModelSerializer):
    phone = serializers.RegexField(r'^\+?[0-9]{10,15}$', max_length=16)
    active_orders = serializers.SerializerMethodField()

    class Meta:
        model = DeliveryPersonnel
        fields = ['id', 'name', 'phone', 'status', 'is_active', 'active_orders']
        read_only_fields = ['status', 'active_orders']

    def get_active_orders(self, person):
        return person.assigned_orders.exclude(status__in=['Delivered', 'Cancelled']).count()


class OrderItemSerializer(serializers.ModelSerializer):
    image_url = serializers.SerializerMethodField()

    class Meta:
        model = OrderItem
        fields = ['product', 'english_name', 'tamil_name', 'quantity', 'unit', 'unit_price', 'total_price', 'image_url']

    def get_image_url(self, item):
        return item.product.image.secure_url if item.product and item.product.image else ''


class OrderEventSerializer(serializers.ModelSerializer):
    class Meta:
        model = OrderEvent
        fields = ['status', 'note', 'created_at']


class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True, read_only=True)
    assigned_to_details = PublicDeliveryPersonnelSerializer(source='assigned_to', read_only=True)
    events = OrderEventSerializer(many=True, read_only=True)

    class Meta:
        model = Order
        fields = ['order_id', 'customer_name', 'customer_phone', 'delivery_address', 'delivery_instructions',
                  'subtotal', 'delivery_charge', 'total_amount', 'payment_method', 'payment_status', 'status',
                  'assigned_to', 'assigned_to_details', 'estimated_delivery_at', 'delivery_note',
                  'created_at', 'updated_at', 'delivered_at', 'items', 'events',
                  'cash_collected_amount', 'cash_collected_at', 'cash_received_directly', 'delivery_attempts', 'cancellation_reason', 'cash_handover']
        read_only_fields = fields


class CheckoutItemSerializer(serializers.Serializer):
    product_id = serializers.CharField(max_length=64)
    quantity = serializers.IntegerField(min_value=1, max_value=100)


class CheckoutSerializer(serializers.Serializer):
    idempotency_key = serializers.UUIDField()
    expected_total = serializers.DecimalField(max_digits=10, decimal_places=2, required=False, min_value=Decimal('0.01'))
    customer_name = serializers.CharField(min_length=2, max_length=100)
    customer_phone = serializers.RegexField(r'^\+?[0-9]{10,15}$', max_length=16)
    delivery_address = serializers.CharField(min_length=12, max_length=1000)
    delivery_instructions = serializers.CharField(max_length=500, required=False, allow_blank=True, default='')
    payment_method = serializers.ChoiceField(choices=['cod'], default='cod')
    items = CheckoutItemSerializer(many=True, allow_empty=False, max_length=100)

    def validate_items(self, items):
        ids = [item['product_id'] for item in items]
        if len(ids) != len(set(ids)):
            raise serializers.ValidationError('Combine duplicate products into a single cart item.')
        return items


def normalize_customer_phone(value):
    import re
    digits = re.sub(r'[\s()\-]', '', str(value or ''))
    if digits.startswith('+91'):
        digits = digits[3:]
    elif len(digits) == 12 and digits.startswith('91'):
        digits = digits[2:]
    if not re.fullmatch(r'[6-9][0-9]{9}', digits):
        raise serializers.ValidationError('Enter a valid 10-digit Indian mobile number.')
    return '+91' + digits


class CustomerPhoneSerializer(serializers.Serializer):
    phone = serializers.CharField(max_length=30)

    def validate_phone(self, value):
        return normalize_customer_phone(value)


class CustomerProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomerProfile
        fields = ['phone', 'name', 'address', 'delivery_instructions']
        read_only_fields = ['phone']

    def validate_address(self, value):
        value = value.strip()
        if value and not 12 <= len(value) <= 1000:
            raise serializers.ValidationError('Enter a complete address between 12 and 1000 characters.')
        return value


class EmployeeSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=False, min_length=8, max_length=128, trim_whitespace=False)
    active_orders = serializers.SerializerMethodField()
    cash_to_handover = serializers.SerializerMethodField()
    documents = serializers.SerializerMethodField()
    has_login = serializers.SerializerMethodField()
    ready_for_deliveries = serializers.BooleanField(read_only=True)

    class Meta:
        model = DeliveryPersonnel
        fields = ['id', 'employee_code', 'name', 'phone', 'email', 'password', 'has_login', 'is_active', 'status',
                  'address', 'city', 'pincode', 'emergency_contact_name', 'emergency_contact_phone',
                  'vehicle_type', 'vehicle_number', 'licence_number', 'licence_expiry', 'joining_date',
                  'id_proof_type', 'id_last_four', 'document_consent', 'documents_verified', 'verified_at',
                  'active_orders', 'cash_to_handover', 'documents', 'ready_for_deliveries']
        read_only_fields = ['id', 'employee_code', 'status', 'verified_at']

    def get_active_orders(self, person):
        return person.assigned_orders.exclude(status__in=['Delivered', 'Cancelled']).count()

    def get_cash_to_handover(self, person):
        return str(cash_total(person.cash_orders.filter(payment_status='collected', cash_handover__isnull=True)))

    def get_documents(self, person):
        return [{'id': str(d.pk), 'kind': d.kind, 'uploaded_at': d.uploaded_at} for d in person.documents.all()]

    def get_has_login(self, person):
        return bool(person.user_id and person.user.has_usable_password())

    def validate_password(self, password):
        try:
            validate_password(password)
        except DjangoValidationError as exc:
            raise ValidationError(list(exc.messages)) from None
        return password

    def validate_phone(self, phone):
        phone = normalize_customer_phone(phone)
        others = DeliveryPersonnel.objects.filter(phone__in=[phone, phone[3:]])
        if self.instance:
            others = others.exclude(pk=self.instance.pk)
        if others.exists():
            raise ValidationError('This mobile number already belongs to a delivery employee.')
        return phone

    def validate_emergency_contact_phone(self, value):
        return normalize_customer_phone(value)

    def validate(self, attrs):
        import re
        critical = ['name', 'phone', 'address', 'id_proof_type', 'id_last_four', 'vehicle_type', 'vehicle_number', 'licence_number', 'licence_expiry']
        if self.instance and 'documents_verified' not in attrs and any(key in attrs and attrs[key] != getattr(self.instance, key) for key in critical):
            attrs['documents_verified'] = False
        def value(key, default=''):
            return attrs.get(key, getattr(self.instance, key, default))
        required = ['name', 'phone', 'address', 'city', 'pincode', 'emergency_contact_name', 'emergency_contact_phone']
        for key in required:
            if not str(value(key)).strip():
                raise ValidationError({key: 'This field is required for employee onboarding.'})
        if len(str(value('address')).strip()) < 12:
            raise ValidationError({'address': 'Enter a complete residential address.'})
        if not re.fullmatch(r'[1-9][0-9]{5}', str(value('pincode'))):
            raise ValidationError({'pincode': 'Enter a valid 6-digit Indian pincode.'})
        if value('id_last_four') and not re.fullmatch(r'[A-Za-z0-9]{4}', value('id_last_four')):
            raise ValidationError({'id_last_four': 'Store only the last four characters, never a full Aadhaar number.'})
        if value('vehicle_type', 'bicycle') in ['motorcycle', 'car', 'van']:
            for key in ['vehicle_number', 'licence_number', 'licence_expiry']:
                if not value(key):
                    raise ValidationError({key: 'Required for motor vehicle delivery.'})
            if value('licence_expiry') < timezone.localdate() and value('documents_verified', False) and value('is_active', False):
                raise ValidationError({'licence_expiry': 'Renew the driving licence before assigning deliveries.'})
        if not self.instance or not self.instance.user_id or not self.instance.user.has_usable_password():
            if not attrs.get('password'):
                raise ValidationError({'password': 'Set a password for the employee login.'})
        if value('documents_verified', False) and (not value('document_consent', False) or not value('id_proof_type')):
            raise ValidationError({'documents_verified': 'Record employee consent and the ID type after checking the original documents.'})
        if self.instance and attrs.get('is_active') is False:
            if self.get_active_orders(self.instance):
                raise ValidationError({'is_active': 'Reassign active orders before deactivating this employee.'})
            if cash_total(self.instance.cash_orders.filter(payment_status='collected', cash_handover__isnull=True)):
                raise ValidationError({'is_active': 'Receive the outstanding cash handover before deactivating this employee.'})
        return attrs

    @transaction.atomic
    def create(self, attrs):
        password = attrs.pop('password', None)
        code = next_employee_code()
        user = get_user_model().objects.create_user(username='delivery_' + code.lower(), password=password, is_active=attrs.get('is_active', False))
        person = DeliveryPersonnel.objects.create(user=user, employee_code=code, **attrs)
        self._record_check(person)
        return person

    @transaction.atomic
    def update(self, person, attrs):
        password = attrs.pop('password', None)
        phone_changed = 'phone' in attrs and attrs['phone'] != person.phone
        record_check = 'documents_verified' in attrs
        if not person.user_id:
            person.employee_code = person.employee_code or next_employee_code()
            person.user = get_user_model().objects.create_user(username='delivery_' + person.employee_code.lower(), password=password)
        for key, value in attrs.items():
            setattr(person, key, value)
        person.user.is_active = person.is_active
        if password:
            person.user.set_password(password)
        person.user.save()
        if password or phone_changed or not person.is_active:
            Token.objects.filter(user=person.user).delete()
        person.save()
        if record_check:
            self._record_check(person)
        return person

    def _record_check(self, person):
        if person.documents_verified:
            person.verified_at = timezone.now()
            person.verified_by = self.context['request'].user
        else:
            person.verified_at = None
            person.verified_by = None
        person.save(update_fields=['verified_at', 'verified_by'])


class DeliveryActionSerializer(serializers.Serializer):
    status = serializers.ChoiceField(choices=['Out for Delivery', 'Delivery Attempted', 'Delivered'])
    delivery_note = serializers.CharField(required=False, allow_blank=True, max_length=255, default='')
    cash_collected = serializers.BooleanField(required=False, default=False)
    cash_collected_amount = serializers.DecimalField(required=False, max_digits=10, decimal_places=2, min_value=Decimal('0.01'))
    delivery_code = serializers.RegexField(r'^\d{5}$', required=False, default='', max_length=5)
    def to_internal_value(self, data):
        extra = set(data) - set(self.fields)
        if extra:
            raise ValidationError({'detail': 'Employees can only update delivery progress and cash for their assigned orders.'})
        if 'cash_collected' in data and type(data['cash_collected']) is not bool:
            raise ValidationError({'cash_collected': 'Use true or false.'})
        return super().to_internal_value(data)


class CashReceiptSerializer(serializers.ModelSerializer):
    class Meta:
        model = CashHandover
        fields = ['id', 'amount', 'received_at']


class CashDueSerializer(serializers.ModelSerializer):
    amount = serializers.DecimalField(source='cash_collected_amount', max_digits=10, decimal_places=2, read_only=True)
    collected_at = serializers.DateTimeField(source='cash_collected_at', read_only=True)
    class Meta:
        model = Order
        fields = ['order_id', 'amount', 'collected_at']


class CashHandoverSerializer(serializers.Serializer):
    idempotency_key = serializers.UUIDField()
    order_ids = serializers.ListField(child=serializers.CharField(max_length=32), allow_empty=False, max_length=200)
    amount = serializers.DecimalField(max_digits=12, decimal_places=2, min_value=Decimal('0.01'))
    def validate_order_ids(self, value):
        if len(value) != len(set(value)):
            raise ValidationError('Choose each order once.')
        return value
