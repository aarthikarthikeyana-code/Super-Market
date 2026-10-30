import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'models.dart';

class StoreException implements Exception {
  final String message;
  StoreException(this.message);
  @override
  String toString() => message;
}

class StoreApi {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://super-market-33m1.onrender.com/api',
  );
  final Dio dio;
  final FlutterSecureStorage storage;
  String? adminToken;
  String? _customerToken;
  Map<String, dynamic>? _customerAccount;
  Future<Map<String, dynamic>?>? _restoringCustomer;
  StoreApi({Dio? client, FlutterSecureStorage? secureStorage})
    : dio =
          client ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 60),
              sendTimeout: const Duration(seconds: 60),
            ),
          ),
      storage = secureStorage ?? const FlutterSecureStorage();
  Future<dynamic> request(
    String method,
    String path, {
    dynamic data,
    bool admin = false,
    bool customer = false,
  }) async {
    String? token;
    if (admin) {
      token = adminToken;
      if (token == null) {
        throw StoreException('Please sign in as an administrator.');
      }
    }
    if (customer) token = await customerToken();
    try {
      final response = await dio.request(
        path,
        data: data,
        options: Options(
          method: method,
          headers: token == null ? {} : {'Authorization': 'Token $token'},
        ),
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && admin) adminToken = null;
      final body = e.response?.data;
      if (body is Map) {
        final detail = body['detail'];
        if (detail != null) throw StoreException('$detail');
        throw StoreException(
          body.entries
              .map(
                (e) =>
                    '${e.key}: ${e.value is List ? (e.value as List).join(' ') : e.value}',
              )
              .join('\n'),
        );
      }
      if (e.response?.statusCode == 404) {
        throw StoreException(
          'The store service is being updated. Please try again shortly.',
        );
      }
      throw StoreException(
        'Unable to reach the store. Check your connection and try again.',
      );
    }
  }

  Future<Map<String, dynamic>?> restoreCustomerAccount() async {
    if (_customerAccount != null) {
      return Map<String, dynamic>.from(_customerAccount!['profile']);
    }
    return _restoringCustomer ??= _restoreCustomer().whenComplete(
      () => _restoringCustomer = null,
    );
  }

  Future<Map<String, dynamic>?> _restoreCustomer() async {
    final saved = await storage.read(key: 'agaram_customer_account');
    if (saved == null) return null;
    final account = Map<String, dynamic>.from(jsonDecode(saved));
    if (account['token'] is! String || account['profile'] is! Map) {
      await storage.delete(key: 'agaram_customer_account');
      return null;
    }
    _customerAccount = account;
    _customerToken = account['token'];
    return Map<String, dynamic>.from(account['profile']);
  }

  Future<String> customerToken() async {
    await restoreCustomerAccount();
    if (_customerToken == null) {
      throw StoreException('Enter your mobile number to continue.');
    }
    return _customerToken!;
  }

  Future<Map<String, dynamic>> requestCustomerCode(String phone) async {
    final configuration = await config();
    if (configuration['customer_login_mode'] != 'demo_code') {
      throw StoreException(
        'The store is being updated for phone sign-in. Please try again shortly.',
      );
    }
    return Map<String, dynamic>.from(
      await request('POST', '/session/', data: {'phone': phone}),
    );
  }

  Future<Map<String, dynamic>> verifyCustomerCode(
    String challengeId,
    String code,
  ) async {
    final data = Map<String, dynamic>.from(
      await request(
        'POST',
        '/session/verify/',
        data: {'challenge_id': challengeId, 'code': code},
      ),
    );
    final profile = Map<String, dynamic>.from(data['profile']);
    final account = {'token': data['token'], 'profile': profile};
    await storage.write(
      key: 'agaram_customer_account',
      value: jsonEncode(account),
    );
    _customerAccount = account;
    _customerToken = data['token'];
    await storage.delete(key: 'agaram_customer_token');
    await storage.delete(key: 'agaram_delivery_details');
    return profile;
  }

  Future<List<StoreProduct>> wishlist() async =>
      (await request('GET', '/customer/wishlist/', customer: true) as List)
          .map((j) => StoreProduct.fromJson(Map<String, dynamic>.from(j)))
          .toList();

  Future<void> setWishlist(String id, bool saved) async {
    await request(
      saved ? 'POST' : 'DELETE',
      '/customer/wishlist/${Uri.encodeComponent(id)}/',
      customer: true,
    );
  }

  Future<Map<String, dynamic>> customerProfile() async {
    final profile = Map<String, dynamic>.from(
      await request('GET', '/customer/profile/', customer: true),
    );
    await _saveProfileCache(profile);
    return profile;
  }

  Future<Map<String, dynamic>> saveCustomerProfile(
    Map<String, dynamic> details,
  ) async {
    final profile = Map<String, dynamic>.from(
      await request(
        'PATCH',
        '/customer/profile/',
        customer: true,
        data: details,
      ),
    );
    await _saveProfileCache(profile);
    return profile;
  }

  Future<void> _saveProfileCache(Map<String, dynamic> profile) async {
    final account = {'token': _customerToken, 'profile': profile};
    await storage.write(
      key: 'agaram_customer_account',
      value: jsonEncode(account),
    );
    _customerAccount = account;
  }

  Future<void> logoutCustomer() async {
    await _restoringCustomer;
    for (final key in [
      'agaram_customer_account',
      'agaram_customer_token',
      'agaram_delivery_details',
      'agaram_checkout',
      'agaram_cart',
    ]) {
      await storage.delete(key: key);
    }
    _customerToken = null;
    _customerAccount = null;
  }

  Future<void> login(String email, String password) async {
    await config();
    final data = await request(
      'POST',
      '/admin/login/',
      data: {'admin_id': email.trim(), 'password': password},
    );
    adminToken = data['token'] as String;
  }

  Future<void> logout() async {
    try {
      if (adminToken != null) {
        await request('POST', '/admin/logout/', admin: true);
      }
    } finally {
      adminToken = null;
    }
  }

  Future<List<StoreProduct>> products() async {
    await config();
    final rows = await request('GET', '/products/') as List;
    return rows
        .where((j) => j['is_active'] == true)
        .map((j) => StoreProduct.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }

  Future<Map<String, dynamic>> config() async {
    final data = Map<String, dynamic>.from(await request('GET', '/config/'));
    if (data['api_version'] != 2) {
      throw StoreException(
        'The store is being updated. Please try again shortly.',
      );
    }
    return data;
  }

  Future<List<StoreOrder>> orders({bool admin = false}) async => (await request(
    'GET',
    admin ? '/admin/orders/' : '/orders/',
    admin: admin,
    customer: !admin,
  ) as List).map((j) => StoreOrder(Map<String, dynamic>.from(j))).toList();
  Future<Map<String, dynamic>> order(String id) async =>
      Map<String, dynamic>.from(
        await request('GET', '/orders/$id/', customer: true),
      );
  Future<Map<String, dynamic>> checkout(Map<String, dynamic> payload) async {
    final fingerprint = jsonEncode(payload);
    final stored = await storage.read(key: 'agaram_checkout');
    final previous = stored == null ? null : jsonDecode(stored) as Map;
    final key = previous?['fingerprint'] == fingerprint
        ? previous!['key'] as String
        : newUuid();
    await storage.write(
      key: 'agaram_checkout',
      value: jsonEncode({'fingerprint': fingerprint, 'key': key}),
    );
    final response = Map<String, dynamic>.from(
      await request(
        'POST',
        '/orders/',
        customer: true,
        data: {...payload, 'idempotency_key': key},
      ),
    );
    final order = StoreOrder(Map<String, dynamic>.from(response['order']));
    if (order.status == 'Cancelled') {
      await finishCheckout();
      throw StoreException(
        'This checkout has expired or was cancelled. Try again to place a new order.',
      );
    }
    return response;
  }

  Future<void> finishCheckout() => storage.delete(key: 'agaram_checkout');
  Future<void> cancelCheckout(String orderId) async {
    await request('POST', '/orders/$orderId/cancel/', customer: true);
    await finishCheckout();
  }

  Future<StoreOrder> verifyPayment(
    String orderId,
    String paymentId,
    String signature,
  ) async => StoreOrder(
    Map<String, dynamic>.from(
      await request(
        'POST',
        '/orders/$orderId/verify-payment/',
        customer: true,
        data: {
          'razorpay_payment_id': paymentId,
          'razorpay_signature': signature,
        },
      ),
    ),
  );
  Future<Map<String, dynamic>> upload(List<int> bytes, String name) async =>
      Map<String, dynamic>.from(
        await request(
          'POST',
          '/admin/images/',
          admin: true,
          data: FormData.fromMap({
            'image': MultipartFile.fromBytes(bytes, filename: name),
          }),
        ),
      );
  Future<void> saveProduct(Map<String, dynamic> data, {String? id}) async {
    await request(
      id == null ? 'POST' : 'PATCH',
      id == null ? '/admin/products/' : '/admin/products/$id/',
      admin: true,
      data: data,
    );
  }

  Future<void> deleteProduct(String id) async {
    await request('DELETE', '/admin/products/$id/', admin: true);
  }

  Future<Map<String, dynamic>> dashboard() async => Map<String, dynamic>.from(
    await request('GET', '/admin/dashboard/', admin: true),
  );
  Future<List<Map<String, dynamic>>> personnel() async =>
      List<Map<String, dynamic>>.from(
        await request('GET', '/admin/delivery-personnel/', admin: true),
      );
  Future<void> savePerson(Map<String, dynamic> data, {int? id}) async {
    await request(
      id == null ? 'POST' : 'PATCH',
      id == null
          ? '/admin/delivery-personnel/'
          : '/admin/delivery-personnel/$id/',
      admin: true,
      data: data,
    );
  }

  Future<void> updateOrder(String id, Map<String, dynamic> data) async {
    await request('PATCH', '/admin/orders/$id/', admin: true, data: data);
  }
}
