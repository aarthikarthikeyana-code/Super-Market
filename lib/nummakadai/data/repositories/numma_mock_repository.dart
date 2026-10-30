import '../models/numma_models.dart';

class NummaMockRepository {
  static final NummaMockRepository _instance = NummaMockRepository._internal();
  factory NummaMockRepository() => _instance;
  NummaMockRepository._internal();

  // Products
  final List<NummaProduct> _products = [
    const NummaProduct(
      id: 'p1',
      nameEnglish: 'Raw Rice',
      nameTamil: 'அரிசி',
      weight: '1 kg',
      sku: 'R001',
      price: 72.0,
      stockQuantity: 120,
      stockStatus: StockStatus.inStock,
      category: 'அரிசி',
      brand: 'Ponni',
      description: 'First quality Ponni raw rice, cleaned and sorted.',
      imageUrl: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=300&q=80',
    ),
    const NummaProduct(
      id: 'p2',
      nameEnglish: 'Toor Dal',
      nameTamil: 'துவரம் பருப்பு',
      weight: '1 kg',
      sku: 'D002',
      price: 128.0,
      stockQuantity: 8,
      stockStatus: StockStatus.lowStock,
      category: 'பருப்பு வகைகள்',
      brand: 'Tata',
      description: 'Premium unpolished toor dal for delicious traditional sambar.',
      imageUrl: 'https://images.unsplash.com/photo-1585994112847-1979ad2c8d20?auto=format&fit=crop&w=300&q=80',
    ),
    const NummaProduct(
      id: 'p3',
      nameEnglish: 'Urad Dal',
      nameTamil: 'உளுத்தம் பருப்பு',
      weight: '1 kg',
      sku: 'U003',
      price: 95.0,
      stockQuantity: 0,
      stockStatus: StockStatus.outOfStock,
      category: 'பருப்பு வகைகள்',
      brand: 'Aachi',
      description: 'White whole urad dal ideal for soft fluffy idlis.',
      imageUrl: 'https://images.unsplash.com/photo-1596797038530-2c107229654b?auto=format&fit=crop&w=300&q=80',
    ),
    const NummaProduct(
      id: 'p4',
      nameEnglish: 'Groundnut Oil',
      nameTamil: 'எண்ணெய்',
      weight: '1 L',
      sku: 'O004',
      price: 165.0,
      stockQuantity: 65,
      stockStatus: StockStatus.inStock,
      category: 'எண்ணெய் வகைகள்',
      brand: 'Fortune',
      description: 'Pure cold pressed traditional groundnut cooking oil.',
      imageUrl: 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&w=300&q=80',
    ),
    const NummaProduct(
      id: 'p5',
      nameEnglish: 'Chilli Powder',
      nameTamil: 'மிளகாய் தூள்',
      weight: '500 g',
      sku: 'P005',
      price: 98.0,
      stockQuantity: 12,
      stockStatus: StockStatus.lowStock,
      category: 'மசாலா பொருட்கள்',
      brand: 'Aachi',
      description: 'Bright red spicy Guntur chilli powder ground to perfection.',
      imageUrl: 'https://images.unsplash.com/photo-1599599810769-bcde5a160d32?auto=format&fit=crop&w=300&q=80',
    ),
    const NummaProduct(
      id: 'p6',
      nameEnglish: 'Chana Dal',
      nameTamil: 'கடலைப் பருப்பு',
      weight: '1 kg',
      sku: 'K006',
      price: 105.0,
      stockQuantity: 56,
      stockStatus: StockStatus.inStock,
      category: 'பருப்பு வகைகள்',
      brand: 'Tata',
      description: 'Crisp bengal gram split dal, best for masala vada.',
      imageUrl: 'https://images.unsplash.com/photo-1515543237350-b3eea1ec8082?auto=format&fit=crop&w=300&q=80',
    ),
    const NummaProduct(
      id: 'p7',
      nameEnglish: 'Masoor Dal',
      nameTamil: 'மசூர் பருப்பு',
      weight: '1 kg',
      sku: 'R005',
      price: 112.0,
      stockQuantity: 12,
      stockStatus: StockStatus.lowStock,
      category: 'பருப்பு வகைகள்',
      brand: '24 Mantra Organic',
      description: 'Organic red masoor dal, quickly digestible and high protein.',
      imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=300&q=80',
    ),
  ];

  List<NummaProduct> get products => List.unmodifiable(_products);

  void addProduct(NummaProduct product) {
    _products.insert(0, product);
  }

  void updateProductStock(String id, int newQuantity) {
    final index = _products.indexWhere((p) => p.id == id);
    if (index != -1) {
      final p = _products[index];
      final status = newQuantity <= 0
          ? StockStatus.outOfStock
          : (newQuantity < 15 ? StockStatus.lowStock : StockStatus.inStock);
      _products[index] = p.copyWith(stockQuantity: newQuantity, stockStatus: status);
    }
  }

  void updateProduct(NummaProduct updated) {
    final index = _products.indexWhere((p) => p.id == updated.id);
    if (index != -1) {
      _products[index] = updated;
    }
  }

  void deleteProduct(String id) {
    _products.removeWhere((p) => p.id == id);
  }

  // Categories
  final List<NummaCategory> _categories = [
    const NummaCategory(id: 'c1', nameTamil: 'அரிசி', nameEnglish: 'Rice & Grains', productCount: 24, iconKey: 'rice'),
    const NummaCategory(id: 'c2', nameTamil: 'பருப்பு வகைகள்', nameEnglish: 'Dals & Pulses', productCount: 18, iconKey: 'dal'),
    const NummaCategory(id: 'c3', nameTamil: 'மாவு வகைகள்', nameEnglish: 'Flours & Atta', productCount: 12, iconKey: 'flour'),
    const NummaCategory(id: 'c4', nameTamil: 'எண்ணெய் வகைகள்', nameEnglish: 'Cooking Oils & Ghee', productCount: 15, iconKey: 'oil'),
    const NummaCategory(id: 'c5', nameTamil: 'மசாலா பொருட்கள்', nameEnglish: 'Spices & Masalas', productCount: 32, iconKey: 'masala'),
    const NummaCategory(id: 'c6', nameTamil: 'காய்கறிகள்', nameEnglish: 'Fresh Vegetables', productCount: 25, iconKey: 'vegetables'),
    const NummaCategory(id: 'c7', nameTamil: 'பால் பொருட்கள்', nameEnglish: 'Dairy & Eggs', productCount: 18, iconKey: 'dairy'),
    const NummaCategory(id: 'c8', nameTamil: 'சிற்றுண்டிகள்', nameEnglish: 'Snacks & Biscuits', productCount: 20, iconKey: 'snacks'),
  ];

  List<NummaCategory> get categories => List.unmodifiable(_categories);

  void addCategory(NummaCategory cat) {
    _categories.add(cat);
  }

  void deleteCategory(String id) {
    _categories.removeWhere((c) => c.id == id);
  }

  // Brands
  final List<NummaBrand> _brands = [
    const NummaBrand(id: 'b1', name: 'Aachi', productCount: 32, logoText: 'Aachi'),
    const NummaBrand(id: 'b2', name: 'Tata', productCount: 28, logoText: 'TATA'),
    const NummaBrand(id: 'b3', name: 'Fortune', productCount: 19, logoText: 'Fortune'),
    const NummaBrand(id: 'b4', name: '24 Mantra Organic', productCount: 16, logoText: '24 M'),
    const NummaBrand(id: 'b5', name: "Prabhu's", productCount: 14, logoText: 'P'),
    const NummaBrand(id: 'b6', name: 'Ponni', productCount: 21, logoText: 'Ponni'),
    const NummaBrand(id: 'b7', name: 'Britannia', productCount: 11, logoText: 'Britannia'),
  ];

  List<NummaBrand> get brands => List.unmodifiable(_brands);

  void addBrand(NummaBrand b) {
    _brands.add(b);
  }

  void deleteBrand(String id) {
    _brands.removeWhere((b) => b.id == id);
  }

  // Orders
  final List<NummaOrder> _orders = [
    NummaOrder(
      orderId: '#NK20251022',
      customerName: 'Priya S',
      customerPhone: '+91 98765 43210',
      deliveryAddress: '123, Anna Nagar, Chennai – 600020',
      orderDate: DateTime(2024, 10, 22, 10, 32),
      timeSlot: '10:00 AM - 12:00 PM',
      itemsTotal: 437.0,
      deliveryCharge: 40.0,
      totalAmount: 477.0,
      status: OrderStatus.pending,
      items: [
        NummaOrderItem(
          product: const NummaProduct(
            id: 'p1',
            nameEnglish: 'Raw Rice',
            nameTamil: 'அரிசி',
            weight: '1 kg',
            sku: 'R001',
            price: 72.0,
            stockQuantity: 120,
            stockStatus: StockStatus.inStock,
            category: 'அரிசி',
            brand: 'Ponni',
            imageUrl: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=300&q=80',
          ),
          quantity: 2,
          price: 72.0,
        ),
        NummaOrderItem(
          product: const NummaProduct(
            id: 'p2',
            nameEnglish: 'Toor Dal',
            nameTamil: 'துவரம் பருப்பு',
            weight: '1 kg',
            sku: 'D002',
            price: 128.0,
            stockQuantity: 8,
            stockStatus: StockStatus.lowStock,
            category: 'பருப்பு வகைகள்',
            brand: 'Tata',
            imageUrl: 'https://images.unsplash.com/photo-1585994112847-1979ad2c8d20?auto=format&fit=crop&w=300&q=80',
          ),
          quantity: 1,
          price: 128.0,
        ),
        NummaOrderItem(
          product: const NummaProduct(
            id: 'p4',
            nameEnglish: 'Groundnut Oil',
            nameTamil: 'எண்ணெய்',
            weight: '1 L',
            sku: 'O004',
            price: 165.0,
            stockQuantity: 65,
            stockStatus: StockStatus.inStock,
            category: 'எண்ணெய் வகைகள்',
            brand: 'Fortune',
            imageUrl: 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&w=300&q=80',
          ),
          quantity: 1,
          price: 165.0,
        ),
      ],
    ),
    NummaOrder(
      orderId: '#NK20251021',
      customerName: 'Arun K',
      customerPhone: '+91 98765 43211',
      deliveryAddress: '45, Technology Park, OMR, Chennai – 600096',
      orderDate: DateTime(2024, 10, 21, 14, 15),
      timeSlot: '02:00 PM - 04:00 PM',
      itemsTotal: 1200.0,
      deliveryCharge: 40.0,
      totalAmount: 1240.0,
      status: OrderStatus.processing,
      items: [
        NummaOrderItem(
          product: const NummaProduct(
            id: 'p1',
            nameEnglish: 'Raw Rice',
            nameTamil: 'அரிசி',
            weight: '1 kg',
            sku: 'R001',
            price: 72.0,
            stockQuantity: 120,
            stockStatus: StockStatus.inStock,
            category: 'அரிசி',
            brand: 'Ponni',
            imageUrl: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=300&q=80',
          ),
          quantity: 5,
          price: 72.0,
        ),
      ],
    ),
    NummaOrder(
      orderId: '#NK20251020',
      customerName: 'Meena R',
      customerPhone: '+91 98765 43212',
      deliveryAddress: '88, Gandhi Road, Adyar, Chennai – 600020',
      orderDate: DateTime(2024, 10, 20, 19, 45),
      timeSlot: '06:00 PM - 08:00 PM',
      itemsTotal: 500.0,
      deliveryCharge: 40.0,
      totalAmount: 540.0,
      status: OrderStatus.delivered,
      items: [],
    ),
    NummaOrder(
      orderId: '#NK20251019',
      customerName: 'Karthik V',
      customerPhone: '+91 98765 43213',
      deliveryAddress: '12, 2nd Main Rd, T. Nagar, Chennai – 600017',
      orderDate: DateTime(2024, 10, 19, 12, 10),
      timeSlot: '12:00 PM - 02:00 PM',
      itemsTotal: 980.0,
      deliveryCharge: 0.0,
      totalAmount: 980.0,
      status: OrderStatus.cancelled,
      items: [],
    ),
  ];

  List<NummaOrder> get orders => List.unmodifiable(_orders);

  void updateOrderStatus(String orderId, OrderStatus status) {
    final index = _orders.indexWhere((o) => o.orderId == orderId);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(status: status);
    }
  }

  // Customers
  final List<NummaCustomer> _customers = [
    const NummaCustomer(id: 'c1', name: 'Priya S', phone: '+91 98765 43210', type: CustomerType.regular, totalOrders: 14, totalSpent: 6420.0),
    const NummaCustomer(id: 'c2', name: 'Arun K', phone: '+91 98764 32109', type: CustomerType.newCustomer, totalOrders: 2, totalSpent: 1850.0),
    const NummaCustomer(id: 'c3', name: 'Meena R', phone: '+91 76543 21098', type: CustomerType.premium, totalOrders: 36, totalSpent: 18450.0),
    const NummaCustomer(id: 'c4', name: 'Karthik V', phone: '+91 65432 10987', type: CustomerType.regular, totalOrders: 8, totalSpent: 4210.0),
    const NummaCustomer(id: 'c5', name: 'Divya M', phone: '+91 54321 09876', type: CustomerType.newCustomer, totalOrders: 1, totalSpent: 750.0),
  ];

  List<NummaCustomer> get customers => List.unmodifiable(_customers);

  // Delivery Agents
  late final List<NummaDeliveryAgent> _deliveryAgents = [
    NummaDeliveryAgent(
      id: 'd1',
      name: 'Ramesh K',
      assignedOrders: 2,
      distance: '5 km',
      isActive: true,
      orders: [
        _orders[0],
        _orders[1],
      ],
    ),
    NummaDeliveryAgent(
      id: 'd2',
      name: 'Suresh M',
      assignedOrders: 3,
      distance: '8 km',
      isActive: true,
      orders: [
        _orders[2],
      ],
    ),
  ];

  List<NummaDeliveryAgent> get deliveryAgents => List.unmodifiable(_deliveryAgents);

  // Banners
  final List<NummaBanner> _banners = [
    const NummaBanner(
      id: 'b1',
      title: 'Everyday Essentials',
      subtitle: 'at Your Doorstep',
      tag: 'Fresh Harvest',
      isActive: true,
      imageUrl: 'assets/images/splash_harvest_basket.jpg',
    ),
    const NummaBanner(
      id: 'b2',
      title: 'Fresh Groceries',
      subtitle: 'Healthy Homes',
      tag: '100% Organic',
      isActive: true,
      imageUrl: 'assets/images/vine_tomatoes_detail.jpg',
    ),
    const NummaBanner(
      id: 'b3',
      title: 'Special Offers',
      subtitle: 'Up to 50% OFF',
      tag: 'Super Saver',
      isActive: true,
      imageUrl: 'assets/images/delivery_scooter_hero.jpg',
    ),
  ];

  List<NummaBanner> get banners => List.unmodifiable(_banners);

  void toggleBanner(String id) {
    final index = _banners.indexWhere((b) => b.id == id);
    if (index != -1) {
      _banners[index] = _banners[index].copyWith(isActive: !_banners[index].isActive);
    }
  }

  void addBanner(NummaBanner banner) {
    _banners.add(banner);
  }

  void deleteBanner(String id) {
    _banners.removeWhere((b) => b.id == id);
  }
}

