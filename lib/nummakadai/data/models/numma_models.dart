enum StockStatus { inStock, lowStock, outOfStock }

enum OrderStatus { pending, processing, outForDelivery, delivered, cancelled }

enum CustomerType { regular, newCustomer, premium, inactive }

class NummaProduct {
  final String id;
  final String nameEnglish;
  final String nameTamil;
  final String weight;
  final String sku;
  final double price;
  final int stockQuantity;
  final StockStatus stockStatus;
  final String category;
  final String brand;
  final String description;
  final String imageUrl;

  const NummaProduct({
    required this.id,
    required this.nameEnglish,
    required this.nameTamil,
    required this.weight,
    required this.sku,
    required this.price,
    required this.stockQuantity,
    required this.stockStatus,
    required this.category,
    required this.brand,
    this.description = '',
    required this.imageUrl,
  });

  NummaProduct copyWith({
    String? id,
    String? nameEnglish,
    String? nameTamil,
    String? weight,
    String? sku,
    double? price,
    int? stockQuantity,
    StockStatus? stockStatus,
    String? category,
    String? brand,
    String? description,
    String? imageUrl,
  }) {
    return NummaProduct(
      id: id ?? this.id,
      nameEnglish: nameEnglish ?? this.nameEnglish,
      nameTamil: nameTamil ?? this.nameTamil,
      weight: weight ?? this.weight,
      sku: sku ?? this.sku,
      price: price ?? this.price,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      stockStatus: stockStatus ?? this.stockStatus,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

class NummaOrderItem {
  final NummaProduct product;
  final int quantity;
  final double price;

  const NummaOrderItem({
    required this.product,
    required this.quantity,
    required this.price,
  });

  double get subtotal => price * quantity;
}

class NummaOrder {
  final String orderId;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final DateTime orderDate;
  final String timeSlot;
  final double itemsTotal;
  final double deliveryCharge;
  final double totalAmount;
  final OrderStatus status;
  final List<NummaOrderItem> items;

  const NummaOrder({
    required this.orderId,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.orderDate,
    required this.timeSlot,
    required this.itemsTotal,
    this.deliveryCharge = 40.0,
    required this.totalAmount,
    required this.status,
    required this.items,
  });

  NummaOrder copyWith({
    OrderStatus? status,
  }) {
    return NummaOrder(
      orderId: orderId,
      customerName: customerName,
      customerPhone: customerPhone,
      deliveryAddress: deliveryAddress,
      orderDate: orderDate,
      timeSlot: timeSlot,
      itemsTotal: itemsTotal,
      deliveryCharge: deliveryCharge,
      totalAmount: totalAmount,
      status: status ?? this.status,
      items: items,
    );
  }
}

class NummaCategory {
  final String id;
  final String nameTamil;
  final String nameEnglish;
  final int productCount;
  final String iconKey;

  const NummaCategory({
    required this.id,
    required this.nameTamil,
    required this.nameEnglish,
    required this.productCount,
    required this.iconKey,
  });
}

class NummaBrand {
  final String id;
  final String name;
  final int productCount;
  final String logoText;

  const NummaBrand({
    required this.id,
    required this.name,
    required this.productCount,
    required this.logoText,
  });
}

class NummaCustomer {
  final String id;
  final String name;
  final String phone;
  final CustomerType type;
  final int totalOrders;
  final double totalSpent;
  final String address;

  const NummaCustomer({
    required this.id,
    required this.name,
    required this.phone,
    required this.type,
    this.totalOrders = 1,
    this.totalSpent = 500.0,
    this.address = 'Anna Nagar, Chennai',
  });
}

class NummaDeliveryAgent {
  final String id;
  final String name;
  final int assignedOrders;
  final String distance;
  final bool isActive;
  final List<NummaOrder> orders;

  const NummaDeliveryAgent({
    required this.id,
    required this.name,
    required this.assignedOrders,
    required this.distance,
    required this.isActive,
    required this.orders,
  });
}

class NummaBanner {
  final String id;
  final String title;
  final String subtitle;
  final String tag;
  final bool isActive;
  final String imageUrl;

  const NummaBanner({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.tag,
    this.isActive = true,
    required this.imageUrl,
  });

  NummaBanner copyWith({bool? isActive}) {
    return NummaBanner(
      id: id,
      title: title,
      subtitle: subtitle,
      tag: tag,
      isActive: isActive ?? this.isActive,
      imageUrl: imageUrl,
    );
  }
}

