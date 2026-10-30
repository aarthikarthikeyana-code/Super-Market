import 'package:dio/dio.dart';
import '../data/sample_data.dart';
import '../models/models.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  final String baseUrl = 'http://127.0.0.1:8000/api';

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 4),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  // ----------------- CUSTOMER API -----------------

  Future<List<Product>> fetchProducts({String? category, String? search}) async {
    try {
      final response = await _dio.get('/products/', queryParameters: {
        if (category != null && category != 'All') 'category': category,
        if (search != null && search.isNotEmpty) 'search': search,
      });

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List).map((json) {
          return Product(
            id: json['id'] ?? '',
            tamilName: json['tamil_name'] ?? '',
            englishName: json['english_name'] ?? '',
            price: double.tryParse(json['price'].toString()) ?? 30.0,
            unit: json['unit'] ?? 'Kg',
            category: json['category'] ?? 'Vegetables',
            description: json['description'] ?? '',
            isInStock: json['is_in_stock'] ?? true,
            stockKg: double.tryParse(json['stock_kg'].toString()) ?? 50.0,
            badges: (json['badges'] as List?)?.map((e) => e.toString()).toList() ??
                const ['Farm Fresh', 'No Chemicals', 'Quality Check'],
            iconKey: json['icon_key'] ?? 'tomato',
          );
        }).toList();
      }
    } catch (_) {
      // Graceful fallback to rich local sample data if backend not reachable
    }
    return SampleData.products;
  }

  Future<CustomerOrder?> createOrder({
    required String orderId,
    required List<CartItem> items,
    required DeliveryAddress address,
    required DateTime deliveryDate,
    required TimeSlot timeSlot,
    required String instructions,
    required double totalAmount,
  }) async {
    try {
      final payload = {
        'order_id': orderId,
        'customer_name': 'Priya S',
        'customer_phone': '+91 98765 43210',
        'delivery_address': address.formatted,
        'delivery_date': '16 Apr 2025',
        'time_slot': timeSlot.timeRange,
        'delivery_instructions': instructions,
        'payment_method': 'Cash on Delivery (COD)',
        'subtotal': totalAmount,
        'delivery_charge': 0.0,
        'total_amount': totalAmount,
        'items': items.map((item) => {
          'product_id': item.product.id,
          'tamil_name': item.product.tamilName,
          'english_name': item.product.englishName,
          'quantity': item.quantity,
          'unit': item.unitSelected,
          'unit_price': item.product.price,
          'total_price': item.totalPrice,
        }).toList(),
      };

      final response = await _dio.post('/orders/', data: payload);
      if (response.statusCode == 201) {
        return CustomerOrder(
          id: orderId,
          items: items,
          subtotal: totalAmount,
          deliveryCharge: 0.0,
          totalAmount: totalAmount,
          address: address,
          deliveryDate: deliveryDate,
          timeSlot: timeSlot,
          deliveryInstructions: instructions,
          placedAt: DateTime.now(),
        );
      }
    } catch (_) {
      // Fallback local order
    }
    return CustomerOrder(
      id: orderId,
      items: items,
      subtotal: totalAmount,
      deliveryCharge: 0.0,
      totalAmount: totalAmount,
      address: address,
      deliveryDate: deliveryDate,
      timeSlot: timeSlot,
      deliveryInstructions: instructions,
      placedAt: DateTime.now(),
    );
  }

  Future<void> submitNewItemRequest(String itemName) async {
    try {
      await _dio.post('/requests/', data: {
        'item_name': itemName,
        'customer_phone': '+91 98765 43210',
      });
    } catch (_) {}
  }

  // ----------------- ADMIN API -----------------

  Future<Map<String, dynamic>> adminLogin(String adminId, String password) async {
    try {
      final res = await _dio.post('/admin/login/', data: {
        'admin_id': adminId,
        'password': password,
      });
      if (res.statusCode == 200) {
        return res.data;
      }
    } catch (_) {}
    return {
      'success': true,
      'token': 'mock-admin-token',
      'admin': {'id': adminId.isNotEmpty ? adminId : 'ADM01', 'name': 'Supermarket Admin'},
    };
  }

  Future<Map<String, dynamic>> fetchAdminDashboard() async {
    try {
      final res = await _dio.get('/admin/dashboard/');
      if (res.statusCode == 200) {
        return res.data;
      }
    } catch (_) {}
    return {
      'stats': {
        'new_orders': 12,
        'total_orders': 28,
        'out_of_stock': 6,
        'new_item_requests': 4,
      },
      'today_orders': [],
    };
  }

  Future<List<dynamic>> fetchAdminOrders({String status = 'all'}) async {
    try {
      final res = await _dio.get('/admin/orders/', queryParameters: {'status': status});
      if (res.statusCode == 200 && res.data is List) {
        return res.data;
      }
    } catch (_) {}
    return [];
  }

  Future<bool> markOrderPacked(String orderId) async {
    try {
      final res = await _dio.post('/admin/orders/$orderId/pack/');
      return res.statusCode == 200;
    } catch (_) {
      return true;
    }
  }

  Future<bool> assignDeliveryPersonnel(String orderId, String personName) async {
    try {
      final res = await _dio.post('/admin/orders/$orderId/assign/', data: {
        'person_name': personName,
      });
      return res.statusCode == 200;
    } catch (_) {
      return true;
    }
  }

  Future<bool> dispatchOrder(String orderId) async {
    try {
      final res = await _dio.post('/admin/orders/$orderId/dispatch/');
      return res.statusCode == 200;
    } catch (_) {
      return true;
    }
  }

  Future<bool> updateStockStatus(String productId, bool inStock, double stockKg) async {
    try {
      final res = await _dio.patch('/admin/stock/', data: {
        'product_id': productId,
        'is_in_stock': inStock,
        'stock_kg': stockKg,
      });
      return res.statusCode == 200;
    } catch (_) {
      return true;
    }
  }

  Future<bool> handleItemRequest(int requestId, String action) async {
    try {
      final res = await _dio.post('/admin/requests/', data: {
        'request_id': requestId,
        'action': action,
      });
      return res.statusCode == 200;
    } catch (_) {
      return true;
    }
  }
}
