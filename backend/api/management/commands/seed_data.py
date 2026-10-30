from django.core.management.base import BaseCommand
from api.models import (
    Product,
    DeliveryAddress,
    DeliveryPersonnel,
    Order,
    OrderItem,
    NewItemRequest,
)

class Command(BaseCommand):
    help = 'Seeds initial supermarket catalog, orders, and delivery staff'

    def handle(self, *args, **options):
        self.stdout.write('Seeding supermarket data...')

        products_data = [
            {
                'id': 'prod_tomato',
                'tamil_name': 'தக்காளி',
                'english_name': 'Tomato',
                'category': 'Vegetables',
                'price': 30.0,
                'unit': 'Kg',
                'stock_kg': 50.0,
                'is_in_stock': True,
                'description': 'Fresh and naturally grown tomatoes from local farms.',
                'icon_key': 'tomato',
                'badges': ['Farm Fresh', 'No Chemicals', 'Quality Check'],
            },
            {
                'id': 'prod_onion',
                'tamil_name': 'வெங்காயம்',
                'english_name': 'Onion',
                'category': 'Vegetables',
                'price': 28.0,
                'unit': 'Kg',
                'stock_kg': 0.0,
                'is_in_stock': False, # Out of stock in Admin Stock Check
                'description': 'Crisp, pungent fresh farm onions, directly sourced.',
                'icon_key': 'onion',
                'badges': ['Farm Fresh', 'Direct Sourced', 'Quality Check'],
            },
            {
                'id': 'prod_potato',
                'tamil_name': 'உருளைக்கிழங்கு',
                'english_name': 'Potato',
                'category': 'Roots',
                'price': 40.0,
                'unit': 'Kg',
                'stock_kg': 40.0,
                'is_in_stock': True,
                'description': 'Naturally harvested farm potatoes, rich in nutrients.',
                'icon_key': 'potato',
                'badges': ['Farm Fresh', 'No Chemicals', 'Quality Check'],
            },
            {
                'id': 'prod_carrot',
                'tamil_name': 'கேரட்',
                'english_name': 'Carrot',
                'category': 'Roots',
                'price': 24.0,
                'unit': '500 g',
                'stock_kg': 30.0,
                'is_in_stock': True,
                'description': 'Sweet, crunchy organic orange carrots packed with vitamins.',
                'icon_key': 'carrot',
                'badges': ['Farm Fresh', '100% Organic', 'Quality Check'],
            },
            {
                'id': 'prod_brinjal',
                'tamil_name': 'கத்திரிக்காய்',
                'english_name': 'Brinjal',
                'category': 'Vegetables',
                'price': 35.0,
                'unit': 'Kg',
                'stock_kg': 20.0,
                'is_in_stock': True,
                'description': 'Glossy purple tender brinjals from village gardens.',
                'icon_key': 'brinjal',
                'badges': ['Farm Fresh', 'No Chemicals', 'Quality Check'],
            },
            {
                'id': 'prod_drumstick',
                'tamil_name': 'முருங்கைக்காய்',
                'english_name': 'Drumstick',
                'category': 'Vegetables',
                'price': 15.0,
                'unit': 'Piece',
                'stock_kg': 15.0,
                'is_in_stock': True,
                'description': 'Aromatic, tender drumsticks ideal for authentic sambar.',
                'icon_key': 'drumstick',
                'badges': ['Farm Fresh', 'Traditional', 'Quality Check'],
            },
            {
                'id': 'prod_beans',
                'tamil_name': 'பீன்ஸ்',
                'english_name': 'Beans',
                'category': 'Vegetables',
                'price': 60.0,
                'unit': 'Kg',
                'stock_kg': 10.0,
                'is_in_stock': True,
                'description': 'Fresh stringless green beans picked at dawn.',
                'icon_key': 'beans',
                'badges': ['Farm Fresh', 'Crisp Harvest', 'Quality Check'],
            },
            {
                'id': 'prod_mint',
                'tamil_name': 'புதினா',
                'english_name': 'Mint',
                'category': 'Greens',
                'price': 10.0,
                'unit': 'Bunch',
                'stock_kg': 0.0,
                'is_in_stock': False,
                'description': 'Fragrant, aromatic freshly plucked organic mint leaves.',
                'icon_key': 'mint',
                'badges': ['Farm Fresh', 'Aromatic', 'Quality Check'],
            },
        ]

        for p_data in products_data:
            Product.objects.update_or_create(id=p_data['id'], defaults=p_data)

        # Delivery Personnel
        personnel = [
            {'name': 'Karthik', 'phone': '+91 98765 43211', 'status': 'Available'},
            {'name': 'Suresh', 'phone': '+91 98765 43212', 'status': 'Available'},
            {'name': 'Manoj', 'phone': '+91 98765 43213', 'status': 'Busy'},
        ]
        for person in personnel:
            DeliveryPersonnel.objects.update_or_create(name=person['name'], defaults=person)

        # Addresses
        DeliveryAddress.objects.update_or_create(
            title='Home',
            defaults={
                'address_line': '123, Green Street',
                'city': 'Chennai',
                'pincode': '600023',
                'is_default': True,
            }
        )

        # Sample Orders
        karthik = DeliveryPersonnel.objects.filter(name='Karthik').first()

        order_1, _ = Order.objects.update_or_create(
            order_id='#ORD124578',
            defaults={
                'customer_name': 'Priya S',
                'customer_phone': '+91 98765 43210',
                'delivery_address': '123, Green Street, Chennai - 600023',
                'delivery_date': '16 Apr 2025',
                'time_slot': '04:00 PM - 06:00 PM',
                'delivery_instructions': 'Cut vegetables, leave at door',
                'subtotal': 82.0,
                'delivery_charge': 0.0,
                'total_amount': 82.0,
                'status': 'Out for Delivery',
                'assigned_to': karthik,
            }
        )
        OrderItem.objects.filter(order=order_1).delete()
        OrderItem.objects.create(order=order_1, tamil_name='தக்காளி', english_name='Tomato', quantity=1, unit='Kg', unit_price=30.0, total_price=30.0, is_packed=True)
        OrderItem.objects.create(order=order_1, tamil_name='கேரட்', english_name='Carrot', quantity=1, unit='500 g', unit_price=24.0, total_price=24.0, is_packed=True)
        OrderItem.objects.create(order=order_1, tamil_name='வெங்காயம்', english_name='Onion', quantity=1, unit='Kg', unit_price=28.0, total_price=28.0, is_packed=False, is_out_of_stock=True)

        # More sample orders matching Screen 03 Order List
        Order.objects.update_or_create(
            order_id='#ORD124577',
            defaults={
                'customer_name': 'Anand K',
                'customer_phone': '+91 98765 43214',
                'delivery_address': '45, Anna Nagar, Chennai',
                'delivery_date': '16 Apr 2025',
                'time_slot': '09:00 AM - 11:00 AM',
                'total_amount': 140.0,
                'status': 'Preparing',
            }
        )
        Order.objects.update_or_create(
            order_id='#ORD124576',
            defaults={
                'customer_name': 'Divya R',
                'customer_phone': '+91 98765 43215',
                'delivery_address': '88, T. Nagar, Chennai',
                'delivery_date': '15 Apr 2025',
                'time_slot': '08:00 PM - 09:00 PM',
                'total_amount': 96.0,
                'status': 'Packed',
            }
        )
        Order.objects.update_or_create(
            order_id='#ORD124575',
            defaults={
                'customer_name': 'Murugan V',
                'customer_phone': '+91 98765 43216',
                'delivery_address': '12, Velachery, Chennai',
                'delivery_date': '15 Apr 2025',
                'time_slot': '06:00 PM - 07:00 PM',
                'total_amount': 110.0,
                'status': 'Out for Delivery',
                'assigned_to': karthik,
            }
        )

        # New Item Request matching Screen 07
        NewItemRequest.objects.update_or_create(
            item_name='புதினா',
            defaults={
                'customer_phone': '+91 98765 43210',
                'status': 'Pending',
                'notes': 'Requested on 16 Apr 2025, 10:22 AM',
            }
        )

        self.stdout.write(self.style.SUCCESS('Successfully seeded supermarket data!'))
