from django.db import models

class Product(models.Model):
    id = models.CharField(max_length=64, primary_key=True)
    tamil_name = models.CharField(max_length=120)
    english_name = models.CharField(max_length=120)
    category = models.CharField(max_length=60, default='Vegetables')
    price = models.DecimalField(max_digits=10, decimal_places=2)
    unit = models.CharField(max_length=40, default='Kg')
    stock_kg = models.DecimalField(max_digits=10, decimal_places=2, default=50.0)
    is_in_stock = models.BooleanField(default=True)
    description = models.TextField(blank=True)
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
    name = models.CharField(max_length=100)
    phone = models.CharField(max_length=30)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='Available')

    def __str__(self):
        return f"{self.name} ({self.status})"


class Order(models.Model):
    STATUS_CHOICES = (
        ('New', 'New'),
        ('Preparing', 'Preparing'),
        ('Packed', 'Packed'),
        ('Out for Delivery', 'Out for Delivery'),
        ('Delivered', 'Delivered'),
    )

    order_id = models.CharField(max_length=32, unique=True)
    customer_name = models.CharField(max_length=100, default='Priya S')
    customer_phone = models.CharField(max_length=30, default='+91 98765 43210')
    delivery_address = models.TextField(default='123, Green Street, Chennai - 600023')
    delivery_date = models.CharField(max_length=50, default='16 Apr 2025')
    time_slot = models.CharField(max_length=50, default='04:00 PM - 06:00 PM')
    delivery_instructions = models.TextField(blank=True, default='')
    payment_method = models.CharField(max_length=50, default='Cash on Delivery (COD)')
    subtotal = models.DecimalField(max_digits=10, decimal_places=2, default=82.0)
    delivery_charge = models.DecimalField(max_digits=10, decimal_places=2, default=0.0)
    total_amount = models.DecimalField(max_digits=10, decimal_places=2, default=82.0)
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
    is_packed = models.BooleanField(default=True)
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
    customer_phone = models.CharField(max_length=30, default='+91 98765 43210')
    requested_at = models.DateTimeField(auto_now_add=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='Pending')
    notes = models.TextField(blank=True, default='')

    def __str__(self):
        return f"{self.item_name} - {self.status}"
