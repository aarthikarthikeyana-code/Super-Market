import 'package:flutter/material.dart';
import '../data/sample_data.dart';
import '../models/models.dart';

enum AppViewMode {
  phoneFrame,
  fullScreen,
}

class AppState extends ChangeNotifier {
  // Navigation flow (0 to 13)
  int _currentStepIndex = 0;
  int get currentStepIndex => _currentStepIndex;

  AppViewMode _viewMode = AppViewMode.phoneFrame;
  AppViewMode get viewMode => _viewMode;

  // Flow titles & metadata for the 14 customer screens
  static const List<Map<String, String>> flowMetadata = [
    {
      'number': '01',
      'title': 'Splash / Welcome',
      'subtitle': 'Good Food Brighter Days • Fresh Groceries',
    },
    {
      'number': '02',
      'title': 'Login / Register with OTP',
      'subtitle': 'Phone number login & OTP verification',
    },
    {
      'number': '03',
      'title': 'Home / Discover',
      'subtitle': 'Browse Categories & Recommended produce',
    },
    {
      'number': '04',
      'title': 'Category Listing',
      'subtitle': 'Vegetables list with Tamil names',
    },
    {
      'number': '05',
      'title': 'Product Detail',
      'subtitle': 'தக்காளி ₹30/Kg with quality badges',
    },
    {
      'number': '06',
      'title': 'Search Not Found',
      'subtitle': 'Add to Order Request modal ("Pothina")',
    },
    {
      'number': '07',
      'title': 'Cart Review Items',
      'subtitle': 'Items list, quantity adjustments & total ₹82',
    },
    {
      'number': '08',
      'title': 'Delivery Address',
      'subtitle': 'Select or add address in Chennai',
    },
    {
      'number': '09',
      'title': 'Delivery Instructions',
      'subtitle': 'Optional notes for delivery partner',
    },
    {
      'number': '10',
      'title': 'Select Delivery Date',
      'subtitle': 'Calendar day picker (April 16, 2025)',
    },
    {
      'number': '11',
      'title': 'Select Time Slot',
      'subtitle': 'Slots A-D (04:00 PM - 06:00 PM)',
    },
    {
      'number': '12',
      'title': 'Order Summary',
      'subtitle': 'Confirmation & Only Cash on Delivery',
    },
    {
      'number': '13',
      'title': 'Order Success',
      'subtitle': 'Celebration & Order ID #ORD124578',
    },
    {
      'number': '14',
      'title': 'Order Tracking',
      'subtitle': 'Real-time status & Out for Delivery map',
    },
  ];

  // User auth state
  String phoneNumber = '98765 43210';
  String otpCode = '4321';
  bool isOtpSent = true;

  // Catalog & Navigation selection
  String selectedCategory = 'Pulses & Dals';
  String selectedSubcategory = 'All';
  late Product selectedProduct;

  // Cart
  final List<CartItem> _cartItems = [];
  List<CartItem> get cartItems => List.unmodifiable(_cartItems);

  // Address
  final List<DeliveryAddress> _addresses = List.from(SampleData.addresses);
  List<DeliveryAddress> get addresses => List.unmodifiable(_addresses);
  late DeliveryAddress selectedAddress;

  // Delivery preferences
  String deliveryInstructions = '';
  DateTime selectedDate = DateTime(2025, 4, 16);
  late TimeSlot selectedTimeSlot;

  // Order state
  CustomerOrder? activeOrder;

  // Customer item requests
  final List<RequestedItem> requestedItems = [];

  AppState() {
    selectedProduct = SampleData.products.first;
    selectedAddress = _addresses.first;
    selectedTimeSlot = SampleData.timeSlots[2]; // Slot C (04:00 PM - 06:00 PM)

    // Prepopulate cart with Toor Dal and Tomato
    _cartItems.add(CartItem(
      product: SampleData.products.firstWhere((p) => p.id == 'prod_toor_dal'),
      quantity: 1,
      unitSelected: '1 Kg',
    ));
    _cartItems.add(CartItem(
      product: SampleData.products.firstWhere((p) => p.id == 'prod_tomato'),
      quantity: 1,
      unitSelected: '1 Kg',
    ));

    _createDefaultOrder();
  }

  void _createDefaultOrder() {
    activeOrder = CustomerOrder(
      id: '#ORD124578',
      items: List.from(_cartItems),
      subtotal: totalCartAmount,
      deliveryCharge: 0.0,
      totalAmount: totalCartAmount,
      address: selectedAddress,
      deliveryDate: selectedDate,
      timeSlot: selectedTimeSlot,
      deliveryInstructions: deliveryInstructions.isNotEmpty
          ? deliveryInstructions
          : 'Please call before arriving',
      status: OrderDeliveryStatus.outForDelivery,
      placedAt: DateTime(2025, 4, 16, 10, 30),
    );
  }

  // Cart Calculations
  double get totalCartAmount {
    double sum = 0;
    for (var item in _cartItems) {
      sum += item.totalPrice;
    }
    return sum;
  }

  int get totalCartItemCount {
    int count = 0;
    for (var item in _cartItems) {
      count += item.quantity;
    }
    return count;
  }

  void addToCart(Product product, {int qty = 1, String? unit, double? customPrice}) {
    final effectiveUnit = unit ?? product.unit;
    final index = _cartItems.indexWhere(
      (item) => item.product.id == product.id && item.unitSelected == effectiveUnit,
    );
    if (index >= 0) {
      _cartItems[index].quantity += qty;
    } else {
      _cartItems.add(CartItem(
        product: product,
        quantity: qty,
        unitSelected: effectiveUnit,
        customUnitPrice: customPrice,
      ));
    }
    notifyListeners();
  }

  void buyNow(Product product, {int qty = 1, String? unit, double? customPrice}) {
    addToCart(product, qty: qty, unit: unit, customPrice: customPrice);
    _currentStepIndex = 6; // Go straight to Cart / Checkout review
    notifyListeners();
  }

  void selectCategory(String category, {String? subcategory}) {
    selectedCategory = category;
    selectedSubcategory = subcategory ?? 'All';
    notifyListeners();
  }

  void selectSubcategory(String subcategory) {
    selectedSubcategory = subcategory;
    notifyListeners();
  }

  void incrementItem(String productId) {
    final index = _cartItems.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _cartItems[index].quantity++;
      notifyListeners();
    }
  }

  void decrementItem(String productId) {
    final index = _cartItems.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (_cartItems[index].quantity > 1) {
        _cartItems[index].quantity--;
      } else {
        _cartItems.removeAt(index);
      }
      notifyListeners();
    }
  }

  void selectProduct(Product product) {
    selectedProduct = product;
    notifyListeners();
  }

  void selectAddress(DeliveryAddress address) {
    selectedAddress = address;
    notifyListeners();
  }

  void addAddress(DeliveryAddress newAddress) {
    _addresses.add(newAddress);
    selectedAddress = newAddress;
    notifyListeners();
  }

  void setInstructions(String text) {
    deliveryInstructions = text;
    notifyListeners();
  }

  void setDate(DateTime date) {
    selectedDate = date;
    notifyListeners();
  }

  void setTimeSlot(TimeSlot slot) {
    selectedTimeSlot = slot;
    notifyListeners();
  }

  void requestCustomItem(String itemName) {
    requestedItems.add(RequestedItem(
      name: itemName,
      requestedAt: DateTime.now(),
    ));
    notifyListeners();
  }

  void placeOrder() {
    activeOrder = CustomerOrder(
      id: '#ORD124578',
      items: List.from(_cartItems),
      subtotal: totalCartAmount,
      deliveryCharge: 0.0,
      totalAmount: totalCartAmount,
      address: selectedAddress,
      deliveryDate: selectedDate,
      timeSlot: selectedTimeSlot,
      deliveryInstructions: deliveryInstructions,
      status: OrderDeliveryStatus.outForDelivery,
      placedAt: DateTime.now(),
    );
    _currentStepIndex = 12; // Go to Order Success (index 12 is screen 13)
    notifyListeners();
  }

  // Flow navigation
  void goToStep(int index) {
    if (index >= 0 && index < flowMetadata.length) {
      _currentStepIndex = index;
      notifyListeners();
    }
  }

  void nextStep() {
    if (_currentStepIndex < flowMetadata.length - 1) {
      _currentStepIndex++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStepIndex > 0) {
      _currentStepIndex--;
      notifyListeners();
    }
  }

  void toggleViewMode() {
    _viewMode = _viewMode == AppViewMode.phoneFrame
        ? AppViewMode.fullScreen
        : AppViewMode.phoneFrame;
    notifyListeners();
  }
}
