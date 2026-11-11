import uuid
from django.conf import settings
from django.db import models

class ProductImage(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    public_id = models.CharField(max_length=255, unique=True)
    secure_url = models.URLField(max_length=1000)
    uploaded_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT)
    created_at = models.DateTimeField(auto_now_add=True)


class ProductCategory(models.Model):
    name = models.CharField(max_length=60, unique=True)
    position = models.PositiveIntegerField(default=100)

    class Meta:
        ordering = ['position', 'id']


class ProductCodeSequence(models.Model):
    id = models.PositiveSmallIntegerField(primary_key=True, default=1)
    last_number = models.PositiveIntegerField(default=0)


class Product(models.Model):
    id = models.CharField(max_length=64, primary_key=True)
    tamil_name = models.CharField(max_length=120)
    english_name = models.CharField(max_length=120, blank=True)
    category = models.CharField(max_length=60, default='Vegetables')
    price = models.DecimalField(max_digits=10, decimal_places=2)
    base_price = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    offer_percent = models.DecimalField(max_digits=5, decimal_places=2, default=0)
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
    image_url = models.URLField(max_length=500, blank=True, default='')
    badges = models.JSONField(default=list)

    class Meta:
        indexes = [models.Index(fields=['tamil_name', 'id'], name='product_catalog_cursor_idx')]

    def __str__(self):
        return f"{self.tamil_name} ({self.english_name})"


class StockMovement(models.Model):
    MOVEMENT_TYPES = [
        ('opening', 'Opening stock'),
        ('restock', 'Stock received'),
        ('adjustment', 'Stock adjustment'),
        ('sale', 'Order reserved'),
        ('return', 'Stock returned'),
    ]

    product = models.ForeignKey(Product, on_delete=models.PROTECT, related_name='stock_movements')
    order = models.ForeignKey('Order', null=True, blank=True, on_delete=models.SET_NULL, related_name='stock_movements')
    delta = models.DecimalField(max_digits=12, decimal_places=2)
    unit = models.CharField(max_length=40)
    movement_type = models.CharField(max_length=16, choices=MOVEMENT_TYPES)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [
            models.Index(fields=['movement_type', '-created_at'], name='stock_move_type_date_idx'),
            models.Index(fields=['product', '-created_at'], name='stock_move_product_date_idx'),
        ]


class DeliveryAddress(models.Model):
    title = models.CharField(max_length=60, default='Home')
    address_line = models.CharField(max_length=255)
    city = models.CharField(max_length=100, default='Chennai')
    pincode = models.CharField(max_length=20, default='600023')
    is_default = models.BooleanField(default=False)

    def __str__(self):
        return f"{self.title}: {self.address_line}, {self.city} - {self.pincode}"


class EmployeeCodeSequence(models.Model):
    year = models.PositiveSmallIntegerField(primary_key=True)
    last_number = models.PositiveIntegerField(default=0)


class DeliveryPersonnel(models.Model):
    STATUS_CHOICES = (
        ('Available', 'Available'),
        ('Busy', 'Busy'),
    )
    is_active = models.BooleanField(default=False)
    name = models.CharField(max_length=100)
    phone = models.CharField(max_length=30)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='Available')
    user = models.OneToOneField(settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.PROTECT, related_name='delivery_employee')
    employee_code = models.CharField(max_length=16, unique=True, null=True, blank=True)
    email = models.EmailField(blank=True)
    address = models.TextField(blank=True)
    city = models.CharField(max_length=100, blank=True)
    pincode = models.CharField(max_length=6, blank=True)
    emergency_contact_name = models.CharField(max_length=100, blank=True)
    emergency_contact_phone = models.CharField(max_length=16, blank=True)
    vehicle_type = models.CharField(max_length=16, choices=[('walking', 'Walking'), ('bicycle', 'Bicycle'), ('motorcycle', 'Motorcycle / scooter'), ('car', 'Car'), ('van', 'Van')], default='bicycle')
    vehicle_number = models.CharField(max_length=20, blank=True)
    licence_number = models.CharField(max_length=30, blank=True)
    licence_expiry = models.DateField(null=True, blank=True)
    joining_date = models.DateField(null=True, blank=True)
    id_proof_type = models.CharField(max_length=24, choices=[('', 'Not provided'), ('masked_aadhaar', 'Masked Aadhaar'), ('voter_id', 'Voter ID'), ('passport', 'Passport'), ('driving_licence', 'Driving licence'), ('other', 'Other ID')], blank=True)
    id_last_four = models.CharField(max_length=4, blank=True)
    document_consent = models.BooleanField(default=False)
    documents_verified = models.BooleanField(default=False)
    verified_at = models.DateTimeField(null=True, blank=True)
    verified_by = models.ForeignKey(settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL, related_name='delivery_checks_recorded')

    class Meta:
        indexes = [models.Index(fields=['name', 'id'], name='employee_name_cursor_idx')]

    @property
    def ready_for_deliveries(self):
        from django.utils import timezone
        licence_valid = self.vehicle_type in ['walking', 'bicycle'] or bool(self.licence_expiry and self.licence_expiry >= timezone.localdate())
        return bool(self.is_active and self.user_id and self.user.is_active and not self.user.is_staff and self.user.has_usable_password() and self.documents_verified and licence_valid)

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
        ('Delivery Attempted', 'Delivery Attempted'),
        ('Delivered', 'Delivered'),
    )

    customer = models.ForeignKey(settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.PROTECT, related_name='store_orders')
    idempotency_key = models.UUIDField(null=True, blank=True)
    payment_status = models.CharField(max_length=20, default='pending')
    cash_collected_amount = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    cash_collected_at = models.DateTimeField(null=True, blank=True)
    cash_received_directly = models.BooleanField(default=False)
    cash_collected_by = models.ForeignKey(settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL, related_name='cash_collections_recorded')
    cash_collected_for = models.ForeignKey(DeliveryPersonnel, null=True, blank=True, on_delete=models.PROTECT, related_name='cash_orders')
    cash_handover = models.ForeignKey('CashHandover', null=True, blank=True, on_delete=models.PROTECT, related_name='orders')
    delivery_attempts = models.PositiveSmallIntegerField(default=0)
    cancellation_reason = models.CharField(max_length=255, blank=True)
    delivery_code_nonce = models.UUIDField(null=True, blank=True)
    delivery_code_expires_at = models.DateTimeField(null=True, blank=True)
    delivery_code_attempts = models.PositiveSmallIntegerField(default=0)
    delivery_code_verified_at = models.DateTimeField(null=True, blank=True)
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
    address_details = models.JSONField(default=dict, blank=True)
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
        indexes = [models.Index(fields=['customer', '-created_at', '-id'], name='customer_order_cursor_idx'),
                   models.Index(fields=['assigned_to', '-created_at', '-id'], name='delivery_order_cursor_idx'),
                   models.Index(fields=['-created_at', '-id'], name='orders_created_cursor_idx'),
                   models.Index(fields=['cash_collected_for', 'cash_handover', 'cash_collected_at', 'id'], name='cash_due_employee_cursor_idx')]
        indexes += [models.Index(fields=['status', '-created_at', '-id'], name='orders_stage_cursor_idx')]

    def __str__(self):
        return f"{self.order_id} - {self.status}"


class DeliveryLocation(models.Model):
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='locations')
    employee = models.ForeignKey(DeliveryPersonnel, on_delete=models.CASCADE)
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=10, decimal_places=6)
    accuracy = models.FloatField()
    captured_at = models.DateTimeField()
    received_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [models.Index(fields=['order', '-captured_at', '-id'], name='delivery_location_order_idx')]


class CashHandover(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    idempotency_key = models.UUIDField(unique=True)
    employee = models.ForeignKey(DeliveryPersonnel, on_delete=models.PROTECT, related_name='cash_handovers')
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    received_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name='cash_handovers_received')
    received_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-received_at']
        indexes = [models.Index(fields=['employee', '-received_at', '-id'], name='employee_cash_cursor_idx')]


class EmployeeDocument(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    employee = models.ForeignKey(DeliveryPersonnel, on_delete=models.CASCADE, related_name='documents')
    kind = models.CharField(max_length=24, choices=[('identity', 'Identity proof'), ('address', 'Address proof'), ('licence', 'Driving licence'), ('registration', 'Vehicle registration'), ('insurance', 'Vehicle insurance'), ('photo', 'Employee photo')])
    public_id = models.CharField(max_length=255, unique=True)
    format = models.CharField(max_length=8)
    uploaded_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT)
    uploaded_at = models.DateTimeField(auto_now_add=True)


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
    address_details = models.JSONField(default=dict, blank=True)
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
