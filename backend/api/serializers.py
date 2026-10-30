from decimal import Decimal
from rest_framework import serializers
from .models import Product, ProductImage, DeliveryPersonnel, Order, OrderItem, OrderEvent, CustomerProfile


class ProductSerializer(serializers.ModelSerializer):
    tamil_name = serializers.CharField(required=False, allow_blank=True, default='')
    image_url = serializers.CharField(source='image.secure_url', read_only=True, default='')
    image = serializers.PrimaryKeyRelatedField(queryset=ProductImage.objects.all(), required=False, allow_null=True)
    price = serializers.DecimalField(max_digits=10, decimal_places=2, min_value=Decimal('0.01'))
    stock_kg = serializers.DecimalField(max_digits=10, decimal_places=2, min_value=Decimal('0'))

    class Meta:
        model = Product
        fields = ['id', 'english_name', 'tamil_name', 'brand', 'category', 'sku', 'price', 'unit',
                  'stock_kg', 'is_in_stock', 'description', 'image', 'image_url', 'is_active', 'updated_at']
        read_only_fields = ['id', 'updated_at']

    def validate_image(self, image):
        if not image.secure_url.startswith('https://res.cloudinary.com/'):
            raise serializers.ValidationError('Upload a product photo before saving.')
        return image


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
    assigned_to_details = DeliveryPersonnelSerializer(source='assigned_to', read_only=True)
    events = OrderEventSerializer(many=True, read_only=True)

    class Meta:
        model = Order
        fields = ['order_id', 'customer_name', 'customer_phone', 'delivery_address', 'delivery_instructions',
                  'subtotal', 'delivery_charge', 'total_amount', 'payment_method', 'payment_status', 'status',
                  'assigned_to', 'assigned_to_details', 'estimated_delivery_at', 'delivery_note',
                  'created_at', 'updated_at', 'delivered_at', 'items', 'events']
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
    payment_method = serializers.ChoiceField(choices=['razorpay', 'cod'])
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
