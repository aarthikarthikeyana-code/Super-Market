import uuid
from django.conf import settings
from django.db import models

class ProductImage(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    public_id = models.CharField(max_length=255, unique=True)
    secure_url = models.URLField(max_length=1000)
    uploaded_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT)
    created_at = models.DateTimeField(auto_now_add=True)


class Product(models.Model):
    id = models.CharField(max_length=64, primary_key=True)
    tamil_name = models.CharField(max_length=120)
    english_name = models.CharField(max_length=120)
    category = models.CharField(max_length=60, default='Vegetables')
    price = models.DecimalField(max_digits=10, decimal_places=2)
    unit = models.CharField(max_length=40, default='Kg')
    stock_kg = models.DecimalField(max_digits=10, decimal_places=2, default=0.0)
    is_in_stock = models.BooleanField(default=True)
    description = models.TextField(blank=True)
    brand = models.CharField(max_length=100, blank=True)
    sku = models.CharField(max_length=80, blank=True)
    is_active = models.BooleanField(default=False, db_index=True)
    image = models.ForeignKey(ProductImage, null=True, blank=True, on_delete=models.SET_NULL)
    updated_at = models.DateTimeField(auto_now=True)
    icon_key = models.CharField(max_length=40, default='tomato')
    badges = models.JSONField(default=list)

    def __str__(self):
        return f"{self.tamil_name} ({self.english_name})"


class DeliveryAddress(models.Model):
    title = models.CharField(max_length=60, default='Home')
    address_line = models.CharField(max_length=255)
    city = models.CharField(max_length=100, default='Chennai')
    pincode = models.CharField(max_length=20, default='600023')
    is_default = models.BooleanField(default=False)

    def __str__(self):
        return f"{self.title}: {self.address_line}, {self.city} - {self.pincode}"


class DeliveryPersonnel(models.Model):
    STATUS_CHOICES = (
        ('Available', 'Available'),
        ('Busy', 'Busy'),
    )
    is_active = models.BooleanField(default=False)
    name = models.CharField(max_length=100)
    phone = models.CharField(max_length=30)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='Available')

    def __str__(self):
        return f"{self.name} ({self.status})"


class Order(models.Model):
    STATUS_CHOICES = (
        ('Payment Pending', 'Payment Pending'),
        ('Cancelled', 'Cancelled'),
        ('New', 'New'),
        ('Preparing', 'Preparing'),
        ('Packed', 'Packed'),
        ('Out for Delivery', 'Out for Delivery'),
        ('Delivered', 'Delivered'),
    )

    customer = models.ForeignKey(settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.PROTECT, related_name='store_orders')
    idempotency_key = models.UUIDField(null=True, blank=True)
    payment_status = models.CharField(max_length=20, default='pending')
    razorpay_order_id = models.CharField(max_length=100, null=True, blank=True, unique=True)
    razorpay_payment_id = models.CharField(max_length=100, null=True, blank=True, unique=True)
    stock_released = models.BooleanField(default=False)
    estimated_delivery_at = models.DateTimeField(null=True, blank=True)
    delivery_note = models.CharField(max_length=255, blank=True)
    updated_at = models.DateTimeField(auto_now=True)
    order_id = models.CharField(max_length=32, unique=True)
    customer_name = models.CharField(max_length=100, default='')
    customer_phone = models.CharField(max_length=30, default='')
    delivery_address = models.TextField(default='')
    delivery_date = models.CharField(max_length=50, default='', blank=True)
    time_slot = models.CharField(max_length=50, default='', blank=True)
    delivery_instructions = models.TextField(blank=True, default='')
    payment_method = models.CharField(max_length=50, default='Cash on Delivery (COD)')
    subtotal = models.DecimalField(max_digits=10, decimal_places=2, default=0.0)
    delivery_charge = models.DecimalField(max_digits=10, decimal_places=2, default=0.0)
    total_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0.0)
    status = models.CharField(max_length=30, choices=STATUS_CHOICES, default='New')
    assigned_to = models.ForeignKey(
        DeliveryPersonnel,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='assigned_orders'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    packed_at = models.DateTimeField(null=True, blank=True)
    dispatched_at = models.DateTimeField(null=True, blank=True)
    delivered_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ['-created_at']
        constraints = [models.UniqueConstraint(fields=['customer', 'idempotency_key'], name='unique_customer_checkout')]

    def __str__(self):
        return f"{self.order_id} - {self.status}"


class OrderItem(models.Model):
    order = models.ForeignKey(Order, related_name='items', on_delete=models.CASCADE)
    product = models.ForeignKey(Product, null=True, blank=True, on_delete=models.SET_NULL)
    tamil_name = models.CharField(max_length=120)
    english_name = models.CharField(max_length=120)
    quantity = models.IntegerField(default=1)
    unit = models.CharField(max_length=40, default='Kg')
    unit_price = models.DecimalField(max_digits=10, decimal_places=2)
    total_price = models.DecimalField(max_digits=10, decimal_places=2)
    is_packed = models.BooleanField(default=False)
    is_out_of_stock = models.BooleanField(default=False)

    def __str__(self):
        return f"{self.tamil_name} x {self.quantity}"


class NewItemRequest(models.Model):
    STATUS_CHOICES = (
        ('Pending', 'Pending'),
        ('Approved', 'Approved'),
        ('Rejected', 'Rejected'),
    )
    item_name = models.CharField(max_length=120)
    customer_phone = models.CharField(max_length=30, default='')
    requested_at = models.DateTimeField(auto_now_add=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='Pending')
    notes = models.TextField(blank=True, default='')

    def __str__(self):
        return f"{self.item_name} - {self.status}"


class OrderEvent(models.Model):
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='events')
    status = models.CharField(max_length=30)
    note = models.CharField(max_length=255, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['created_at', 'id']


class CustomerProfile(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='customer_profile')
    phone = models.CharField(max_length=16, unique=True)
    wishlist = models.ManyToManyField(Product, blank=True, related_name='saved_by_customers')
    name = models.CharField(max_length=100, blank=True)
    address = models.TextField(blank=True)
    delivery_instructions = models.CharField(max_length=500, blank=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.phone


class CustomerLoginChallenge(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    phone = models.CharField(max_length=16)
    code_hash = models.CharField(max_length=128)
    expires_at = models.DateTimeField()
    attempts = models.PositiveSmallIntegerField(default=0)
    used = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
