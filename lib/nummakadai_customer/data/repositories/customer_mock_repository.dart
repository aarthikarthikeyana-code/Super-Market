import '../models/customer_models.dart';

class CustomerMockRepository {
  static final CustomerMockRepository _instance = CustomerMockRepository._internal();
  factory CustomerMockRepository() => _instance;
  CustomerMockRepository._internal();

  // Categories
  final List<CustomerCategory> categories = [
    const CustomerCategory(id: 'c1', nameTamil: 'அரிசி', nameEnglish: 'Rice & Grains', imageUrl: 'assets/images/products/rice.png'),
    const CustomerCategory(id: 'c2', nameTamil: 'பருப்பு வகைகள்', nameEnglish: 'Dals & Pulses', imageUrl: 'assets/images/products/dal.png'),
    const CustomerCategory(id: 'c3', nameTamil: 'மாவு வகைகள்', nameEnglish: 'Atta & Flours', imageUrl: 'assets/images/products/dal.png'),
    const CustomerCategory(id: 'c4', nameTamil: 'சமையல் எண்ணெய்', nameEnglish: 'Cooking Oils & Ghee', imageUrl: 'assets/images/products/oil.png'),
    const CustomerCategory(id: 'c5', nameTamil: 'மசாலா பொருட்கள்', nameEnglish: 'Spices & Masalas', imageUrl: 'assets/images/products/masala.png'),
    const CustomerCategory(id: 'c6', nameTamil: 'பால் பொருட்கள்', nameEnglish: 'Dairy Products', imageUrl: 'assets/images/products/vegetables.png'),
    const CustomerCategory(id: 'c7', nameTamil: 'உணவு தானியங்கள்', nameEnglish: 'Food Grains', imageUrl: 'assets/images/products/rice.png'),
    const CustomerCategory(id: 'c8', nameTamil: 'பேக்கேஜ்ட் உணவுகள்', nameEnglish: 'Packaged Foods', imageUrl: 'assets/images/products/dal.png'),
    const CustomerCategory(id: 'c9', nameTamil: 'பானங்கள்', nameEnglish: 'Beverages & Tea', imageUrl: 'assets/images/products/oil.png'),
    const CustomerCategory(id: 'c10', nameTamil: 'சுத்தம் & பராமரிப்பு', nameEnglish: 'Cleaning & Care', imageUrl: 'assets/images/products/vegetables.png'),
  ];

  // Brands
  final List<CustomerBrand> brands = [
    const CustomerBrand(id: 'b1', name: 'Aachi', categoryTag: 'Popular'),
    const CustomerBrand(id: 'b2', name: 'Tata', categoryTag: 'Popular'),
    const CustomerBrand(id: 'b3', name: 'Fortune', categoryTag: 'Popular'),
    const CustomerBrand(id: 'b4', name: '24 Mantra Organic', categoryTag: 'Premium'),
    const CustomerBrand(id: 'b5', name: "Pothy's", categoryTag: 'All Brands'),
    const CustomerBrand(id: 'b6', name: 'Ponni', categoryTag: 'Popular'),
    const CustomerBrand(id: 'b7', name: 'India Gate', categoryTag: 'Premium'),
    const CustomerBrand(id: 'b8', name: 'Britannia', categoryTag: 'Popular'),
  ];

  // Products
  final List<CustomerProduct> products = [
    const CustomerProduct(
      id: 'p1',
      nameTamil: 'துவரம் பருப்பு',
      nameEnglish: 'Aachi Toor Dal',
      brand: 'Aachi',
      rating: 4.5,
      reviewsCount: 2123,
      price: 142.0,
      oldPrice: 165.0,
      discount: '14% OFF',
      imageUrl: 'assets/images/products/dal.png',
      category: 'பருப்பு வகைகள்',
      sizes: [
        ProductSizeOption(size: '500 g', price: 142.0, oldPrice: 165.0),
        ProductSizeOption(size: '1 kg', price: 275.0, oldPrice: 310.0),
        ProductSizeOption(size: '5 kg', price: 660.0, oldPrice: 750.0),
      ],
    ),
    const CustomerProduct(
      id: 'p2',
      nameTamil: 'அரிசி',
      nameEnglish: 'Ponni Boiled Rice',
      brand: 'Ponni',
      rating: 4.8,
      reviewsCount: 1850,
      price: 325.0,
      oldPrice: 380.0,
      discount: '15% OFF',
      imageUrl: 'assets/images/products/rice.png',
      category: 'அரிசி',
      sizes: [
        ProductSizeOption(size: '1 kg', price: 72.0, oldPrice: 85.0),
        ProductSizeOption(size: '5 kg', price: 325.0, oldPrice: 380.0),
        ProductSizeOption(size: '10 kg', price: 640.0, oldPrice: 720.0),
      ],
    ),
    const CustomerProduct(
      id: 'p3',
      nameTamil: 'சமையல் எண்ணெய்',
      nameEnglish: 'Fortune Groundnut Oil',
      brand: 'Fortune',
      rating: 4.6,
      reviewsCount: 940,
      price: 165.0,
      oldPrice: 195.0,
      discount: '15% OFF',
      imageUrl: 'assets/images/products/oil.png',
      category: 'சமையல் எண்ணெய்',
      sizes: [
        ProductSizeOption(size: '500 ml', price: 88.0, oldPrice: 100.0),
        ProductSizeOption(size: '1 L', price: 165.0, oldPrice: 195.0),
        ProductSizeOption(size: '5 L', price: 790.0, oldPrice: 920.0),
      ],
    ),
    const CustomerProduct(
      id: 'p4',
      nameTamil: 'மிளகாய் தூள்',
      nameEnglish: 'Aachi Chilli Powder',
      brand: 'Aachi',
      rating: 4.7,
      reviewsCount: 1420,
      price: 98.0,
      oldPrice: 115.0,
      discount: '15% OFF',
      imageUrl: 'assets/images/products/masala.png',
      category: 'மசாலா பொருட்கள்',
      sizes: [
        ProductSizeOption(size: '200 g', price: 42.0, oldPrice: 50.0),
        ProductSizeOption(size: '500 g', price: 98.0, oldPrice: 115.0),
        ProductSizeOption(size: '1 kg', price: 190.0, oldPrice: 220.0),
      ],
    ),
  ];

  // Addresses
  final List<CustomerAddress> addresses = [
    const CustomerAddress(
      id: 'addr_1',
      type: 'Home',
      addressLine: '123, Anna Nagar,',
      cityPin: 'Chennai - 600040',
      isDefault: true,
    ),
    const CustomerAddress(
      id: 'addr_2',
      type: 'Office',
      addressLine: 'ABC Tech Park, Taramani,',
      cityPin: 'Chennai - 600113',
      isDefault: false,
    ),
  ];

  // Delivery Slots
  final List<CustomerDeliverySlot> slots = [
    const CustomerDeliverySlot(dateLabel: 'Today', dateNum: '22 Oct', timeRange: '10:00 AM – 12:00 PM'),
    const CustomerDeliverySlot(dateLabel: 'Today', dateNum: '22 Oct', timeRange: '12:00 PM – 02:00 PM'),
    const CustomerDeliverySlot(dateLabel: 'Today', dateNum: '22 Oct', timeRange: '04:00 PM – 06:00 PM'),
    const CustomerDeliverySlot(dateLabel: 'Today', dateNum: '22 Oct', timeRange: '06:00 PM – 08:00 PM'),
  ];
}

