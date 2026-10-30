from django.contrib import admin
from .models import Product, ProductImage, Order, OrderItem, DeliveryPersonnel, OrderEvent

@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = ['english_name', 'category', 'price', 'stock_kg', 'is_active']
    list_filter = ['is_active', 'category']
    search_fields = ['english_name', 'tamil_name', 'sku']

class OrderItemInline(admin.TabularInline):
    model = OrderItem
    extra = 0
    readonly_fields = ['product', 'english_name', 'tamil_name', 'quantity', 'unit', 'unit_price', 'total_price']
    can_delete = False

@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = ['order_id', 'customer_name', 'total_amount', 'payment_status', 'status', 'assigned_to']
    readonly_fields = [f.name for f in Order._meta.fields]
    inlines = [OrderItemInline]
    def has_add_permission(self, request):
        return False
    def has_delete_permission(self, request, obj=None):
        return False

admin.site.register(DeliveryPersonnel)
