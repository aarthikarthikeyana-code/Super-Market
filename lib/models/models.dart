enum OrderDeliveryStatus {
  preparing,
  packed,
  outForDelivery,
  delivered,
}

class Product {
  final String id;
  final String tamilName;
  final String englishName;
  final double price;
  final String unit;
  final String category;
  final String? subcategory;
  final String description;
  final bool isInStock;
  final double stockKg;
  final List<String> badges;
  final String iconKey;
  final String? imageUrl;
  final List<String> availableWeights;
  final Map<String, double>? weightPrices;

  const Product({
    required this.id,
    required this.tamilName,
    required this.englishName,
    required this.price,
    required this.unit,
    required this.category,
    this.subcategory,
    required this.description,
    this.isInStock = true,
    this.stockKg = 50.0,
    this.badges = const ['Farm Fresh', 'No Chemicals', 'Quality Check'],
    required this.iconKey,
    this.imageUrl,
    this.availableWeights = const ['250 g', '500 g', '1 Kg', '2 Kg', '5 Kg'],
    this.weightPrices,
  });

  String get formattedPrice => '₹${price.toStringAsFixed(0)} / $unit';

  double getPriceForWeight(String weight) {
    if (weightPrices != null && weightPrices!.containsKey(weight)) {
      return weightPrices![weight]!;
    }
    if (weight == '250 g') return (price * 0.25).roundToDouble();
    if (weight == '500 g') return (price * 0.5).roundToDouble();
    if (weight == '1 Kg') return price;
    if (weight == '2 Kg') return (price * 1.95).roundToDouble();
    if (weight == '5 Kg') return (price * 4.8).roundToDouble();
    return price;
  }
}

class CartItem {
  final Product product;
  int quantity;
  String unitSelected;
  final double? customUnitPrice;

  CartItem({
    required this.product,
    this.quantity = 1,
    String? unitSelected,
    this.customUnitPrice,
  }) : unitSelected = unitSelected ?? product.unit;

  double get unitPrice => customUnitPrice ?? product.getPriceForWeight(unitSelected);
  double get totalPrice => unitPrice * quantity;
}

class DeliveryAddress {
  final String id;
  final String title;
  final String addressLine;
  final String city;
  final String pincode;
  final bool isDefault;

  const DeliveryAddress({
    required this.id,
    required this.title,
    required this.addressLine,
    required this.city,
    required this.pincode,
    this.isDefault = false,
  });

  String get formatted => '$addressLine, $city - $pincode';
}

class TimeSlot {
  final String id;
  final String letter;
  final String timeRange;
  final bool isAvailable;

  const TimeSlot({
    required this.id,
    required this.letter,
    required this.timeRange,
    this.isAvailable = true,
  });
}

class CustomerOrder {
  final String id;
  final List<CartItem> items;
  final double subtotal;
  final double deliveryCharge;
  final double totalAmount;
  final DeliveryAddress address;
  final DateTime deliveryDate;
  final TimeSlot timeSlot;
  final String deliveryInstructions;
  final String paymentMethod;
  final OrderDeliveryStatus status;
  final DateTime placedAt;

  const CustomerOrder({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.deliveryCharge,
    required this.totalAmount,
    required this.address,
    required this.deliveryDate,
    required this.timeSlot,
    required this.deliveryInstructions,
    this.paymentMethod = 'Cash on Delivery (COD)',
    this.status = OrderDeliveryStatus.outForDelivery,
    required this.placedAt,
  });
}

class RequestedItem {
  final String name;
  final DateTime requestedAt;
  final String status;

  const RequestedItem({
    required this.name,
    required this.requestedAt,
    this.status = 'Pending Review',
  });
}
