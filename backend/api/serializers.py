from rest_framework import serializers
from .models import (
    Product,
    DeliveryAddress,
    DeliveryPersonnel,
    Order,
    OrderItem,
    NewItemRequest,
)

class ProductSerializer(serializers.ModelSerializer):
    class Meta:
        model = Product
        fields = '__all__'


class DeliveryAddressSerializer(serializers.ModelSerializer):
    class Meta:
        model = DeliveryAddress
        fields = '__all__'


class DeliveryPersonnelSerializer(serializers.ModelSerializer):
    class Meta:
        model = DeliveryPersonnel
        fields = '__all__'


class OrderItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = OrderItem
        fields = '__all__'


class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True, read_only=True)
    assigned_to_details = DeliveryPersonnelSerializer(source='assigned_to', read_only=True)

    class Meta:
        model = Order
        fields = '__all__'


class NewItemRequestSerializer(serializers.ModelSerializer):
    class Meta:
        model = NewItemRequest
        fields = '__all__'
