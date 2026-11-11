import 'dart:math';

double amount(dynamic value) => double.tryParse('$value') ?? 0;
String money(num value) => '₹${value.toStringAsFixed(2)}';
String productLabel(Map<String, dynamic> data) {
  final tamil = '${data['tamil_name'] ?? ''}'.trim();
  return tamil.isNotEmpty ? tamil : '${data['english_name'] ?? ''}'.trim();
}

String newUuid() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final s = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${s.substring(0, 8)}-${s.substring(8, 12)}-${s.substring(12, 16)}-${s.substring(16, 20)}-${s.substring(20)}';
}

class StoreProduct {
  final String id,
      englishName,
      tamilName,
      category,
      brand,
      unit,
      description,
      imageUrl,
      imageId,
      sku;
  final double price, stock;
  final double offerPercent;
  final bool inStock;
  final bool published;
  final double? rawMrp;
  const StoreProduct({
    required this.id,
    required String name,
    this.tamilName = '',
    required this.category,
    this.brand = '',
    required this.unit,
    this.description = '',
    this.imageUrl = '',
    this.imageId = '',
    this.sku = '',
    required this.price,
    required this.stock,
    this.inStock = true,
    this.published = true,
    this.rawMrp,
    this.offerPercent = 0,
  }) : englishName = name;
  String get name => tamilName.trim().isNotEmpty ? tamilName : englishName;
  double get mrp {
    if (rawMrp != null && rawMrp!.isFinite && rawMrp! > price) return rawMrp!;
    return price;
  }

  int get discountPercent {
    if (rawMrp != null && rawMrp!.isFinite && rawMrp! > price) {
      return (((rawMrp! - price) / rawMrp!) * 100).round();
    }
    if (offerPercent > 0 && offerPercent.isFinite) {
      return offerPercent.round();
    }
    return 0;
  }
  factory StoreProduct.fromJson(Map<String, dynamic> j) => StoreProduct(
    published: j['is_active'] != false,
    id: '${j['id']}',
    name: j['english_name'] ?? '',
    tamilName: j['tamil_name'] ?? '',
    category: j['category'] ?? '',
    brand: j['brand'] ?? '',
    unit: j['unit'] ?? '',
    description: j['description'] ?? '',
    imageUrl: j['image'] != null ? j['image_url'] ?? '' : '',
    imageId: j['image']?.toString() ?? '',
    sku: j['sku'] ?? '',
    price: amount(j['price']),
    stock: amount(j['stock_kg']),
    inStock: j['is_in_stock'] == true,
    rawMrp: j['mrp'] != null ? amount(j['mrp']) : null,
    offerPercent: amount(j['offer_percent']),
  );
  bool get available => published && inStock && stock >= 1;
  Map<String, dynamic> toJson() => {
    'is_active': published,
    'id': id,
    'english_name': englishName,
    'tamil_name': tamilName,
    'category': category,
    'brand': brand,
    'unit': unit,
    'description': description,
    'image_url': imageUrl,
    'image': imageId,
    'sku': sku,
    'price': price.toStringAsFixed(2),
    'stock_kg': stock,
    'is_in_stock': inStock,
    if (rawMrp != null) 'mrp': rawMrp,
    'offer_percent': offerPercent,
  };
}

class CartLine {
  final StoreProduct product;
  final int quantity;
  const CartLine(this.product, this.quantity);
  double get total => product.price * quantity;
}

class StoreOrder {
  final Map<String, dynamic> data;
  StoreOrder(this.data);
  String get id => data['order_id'] ?? '';
  String get shortId =>
      id.length > 8 ? '#${id.substring(id.length - 8)}' : '#$id';
  String get nextAction =>
      {
        'New': 'Next: accept & prepare the items',
        'Preparing': 'Next: check items & mark packed',
        'Packed': data['assigned_to'] == null
            ? 'Next: assign a delivery employee'
            : 'Waiting for employee pickup',
        'Out for Delivery': 'Employee delivers · collect cash + customer code',
        'Delivery Attempted': 'Needs attention · arrange retry or return',
        'Delivered': paymentStatus != 'collected'
            ? 'Delivery complete · paid online'
            : data['cash_handover'] == null &&
                  data['cash_received_directly'] != true
            ? 'Delivery complete · cash handover pending'
            : 'Delivery complete · cash received by store',
        'Cancelled':
            'Cancelled · ${data['cancellation_reason'] ?? 'No cash due'}',
      }[status] ??
      'Open order for details';
  String get status => data['status'] ?? '';
  String get paymentStatus => data['payment_status'] ?? '';
  double get total => amount(data['total_amount']);
  List<Map<String, dynamic>> get items =>
      List<Map<String, dynamic>>.from(data['items'] ?? []);
  List<Map<String, dynamic>> get events =>
      List<Map<String, dynamic>>.from(data['events'] ?? []);
  bool get awaitingPayment =>
      paymentStatus == 'pending' && status == 'Payment Pending';
  bool get canFulfill =>
      ['paid', 'cod'].contains(paymentStatus) &&
      !['Delivered', 'Cancelled'].contains(status);
  bool get canCancel =>
      status == 'New' && paymentStatus == 'cod' || awaitingPayment;
  String? get nextStatus => {
    'New': 'Preparing',
    'Preparing': 'Packed',
    'Packed': 'Out for Delivery',
    'Out for Delivery': 'Delivered',
    'Delivery Attempted': 'Out for Delivery',
  }[status];
}

class StorePage<T> {
  final List<T> items;
  final String? nextCursor;
  final Map<String, dynamic> metadata;
  const StorePage({
    required this.items,
    this.nextCursor,
    this.metadata = const {},
  });
}
