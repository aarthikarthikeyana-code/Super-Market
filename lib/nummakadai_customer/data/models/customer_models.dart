enum CustomerOrderStatus { placed, preparing, outForDelivery, delivered, cancelled }

class ProductSizeOption {
  final String size;
  final double price;
  final double? oldPrice;

  const ProductSizeOption({
    required this.size,
    required this.price,
    this.oldPrice,
  });
}

class CustomerProduct {
  final String id;
  final String nameTamil;
  final String nameEnglish;
  final String brand;
  final double rating;
  final int reviewsCount;
  final double price;
  final double oldPrice;
  final String discount;
  final String imageUrl;
  final String category;
  final List<ProductSizeOption> sizes;
  final String description;

  const CustomerProduct({
    required this.id,
    required this.nameTamil,
    required this.nameEnglish,
    required this.brand,
    this.rating = 4.5,
    this.reviewsCount = 2123,
    required this.price,
    required this.oldPrice,
    required this.discount,
    required this.imageUrl,
    required this.category,
    required this.sizes,
    this.description = 'Pure and unpolished traditional high-grade grocery produce.',
  });
}

class CustomerCartItem {
  final CustomerProduct product;
  final ProductSizeOption selectedSize;
  int quantity;

  CustomerCartItem({
    required this.product,
    required this.selectedSize,
    this.quantity = 1,
  });

  double get subtotal => selectedSize.price * quantity;
}

class CustomerAddress {
  final String id;
  final String type; // Home, Office, Others
  final String addressLine;
  final String cityPin;
  final bool isDefault;

  const CustomerAddress({
    required this.id,
    required this.type,
    required this.addressLine,
    required this.cityPin,
    this.isDefault = false,
  });
}

class CustomerDeliverySlot {
  final String dateLabel; // Today, Tomorrow, Fri, Sat
  final String dateNum;   // 22 Oct, 23 Oct...
  final String timeRange; // 10:00 AM - 12:00 PM

  const CustomerDeliverySlot({
    required this.dateLabel,
    required this.dateNum,
    required this.timeRange,
  });
}

class CustomerOrderRecord {
  final String orderId;
  final DateTime orderDate;
  final String timeSlot;
  final List<CustomerCartItem> items;
  final double totalAmount;
  final CustomerOrderStatus status;
  final CustomerAddress address;

  const CustomerOrderRecord({
    required this.orderId,
    required this.orderDate,
    required this.timeSlot,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.address,
  });
}

class CustomerCategory {
  final String id;
  final String nameTamil;
  final String nameEnglish;
  final String imageUrl;

  const CustomerCategory({
    required this.id,
    required this.nameTamil,
    required this.nameEnglish,
    required this.imageUrl,
  });
}

class CustomerBrand {
  final String id;
  final String name;
  final String categoryTag;

  const CustomerBrand({
    required this.id,
    required this.name,
    this.categoryTag = 'Popular',
  });
}
