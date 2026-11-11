import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'models.dart';

class StoreException implements Exception {
  final String message;
  final int? statusCode;
  StoreException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class StoreApi {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://super-market-33m1.onrender.com/api',
  );
  final Dio dio;
  final feedChanges = ValueNotifier<int>(0);
  final FlutterSecureStorage storage;
  // Public catalog data only. Never retain customer, staff or cash responses.
  final _publicCache = <String, ({DateTime expires, String json})>{};
  int _cacheGeneration = 0;
  void clearPublicCache() {
    _cacheGeneration++;
    _publicCache.clear();
  }

  String? adminToken;
  String? deliveryToken;
  String staffWorkspace = '/';
  final staffChanges = ValueNotifier<int>(0);

  Future<void> restoreStaffSession() async {
    try {
      final saved = await storage.read(key: 'agaram_staff_session');
      if (saved == null) return;
      final data = jsonDecode(saved);
      if (data is! Map) return;
      adminToken = data['admin_token'] is String ? data['admin_token'] : null;
      deliveryToken = data['delivery_token'] is String
          ? data['delivery_token']
          : null;
      final workspace = data['workspace'];
      staffWorkspace = workspace == '/admin' || workspace == '/delivery'
          ? workspace as String
          : '/';
    } catch (_) {
      // An unreadable local session requires sign-in; no private data is restored.
      adminToken = null;
      deliveryToken = null;
      staffWorkspace = '/';
    }
  }

  Future<void> _saveStaffSession() async {
    await storage.write(
      key: 'agaram_staff_session',
      value: jsonEncode({
        'admin_token': adminToken,
        'delivery_token': deliveryToken,
        'workspace': staffWorkspace,
      }),
    );
  }

  Future<void> useAdminWorkspace() async {
    staffWorkspace = '/admin';
    await _saveStaffSession();
  }

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
    bool employee = false,
  }) async {
    String? token;
    if (admin) {
      token = adminToken;
      if (token == null) {
        throw StoreException('Please sign in as an administrator.');
      }
    }
    if (customer) token = await customerToken();
    if (employee) {
      token = deliveryToken;
      if (token == null) {
        throw StoreException('Sign in with your delivery employee ID.');
      }
    }
    final uri = Uri.parse(path);
    final locationUpdate = method == 'POST' && uri.path.endsWith('/tracking/');
    final cacheable =
        method == 'GET' &&
        !admin &&
        !customer &&
        !employee &&
        (uri.path == '/config/' ||
            uri.path == '/catalog/browse/' ||
            (uri.path == '/products/' &&
                uri.queryParameters['paginate'] == 'true'));
    final cached = cacheable ? _publicCache[path] : null;
    if (cached != null && cached.expires.isAfter(DateTime.now())) {
      return jsonDecode(cached.json);
    }
    final cacheGeneration = _cacheGeneration;
    try {
      final response = await dio.request(
        path,
        data: data,
        options: Options(
          method: method,
          headers: token == null ? {} : {'Authorization': 'Token $token'},
        ),
      );
      if (cacheable && cacheGeneration == _cacheGeneration) {
        _publicCache.removeWhere(
          (_, entry) => !entry.expires.isAfter(DateTime.now()),
        );
        if (_publicCache.length >= 32) {
          _publicCache.remove(_publicCache.keys.first);
        }
        _publicCache[path] = (
          expires: DateTime.now().add(const Duration(seconds: 20)),
          json: jsonEncode(response.data),
        );
      }
      if (method != 'GET' && !locationUpdate) clearPublicCache();
      if (method != 'GET' &&
          !locationUpdate &&
          !path.contains('login') &&
          !path.contains('logout') &&
          !path.contains('session')) {
        feedChanges.value++;
      }
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && (admin || employee)) {
        if (admin) adminToken = null;
        if (employee) deliveryToken = null;
        staffChanges.value++;
        await _saveStaffSession();
      }
      final body = e.response?.data;
      if (body is Map) {
        final detail = body['detail'];
        if (detail != null) {
          throw StoreException('$detail', statusCode: e.response?.statusCode);
        }
        throw StoreException(
          body.entries
              .map(
                (e) =>
                    '${e.key}: ${e.value is List ? (e.value as List).join(' ') : e.value}',
              )
              .join('\n'),
          statusCode: e.response?.statusCode,
        );
      }
      if (e.response?.statusCode == 404) {
        throw StoreException(
          'The store service is being updated. Please try again shortly.',
          statusCode: e.response?.statusCode,
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
    staffWorkspace = '/admin';
    await _saveStaffSession();
    staffChanges.value++;
  }

  Future<void> logout() async {
    try {
      if (adminToken != null) {
        await request('POST', '/admin/logout/', admin: true);
      }
    } finally {
      adminToken = null;
      staffWorkspace = '/';
      await _saveStaffSession();
      staffChanges.value++;
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

  Future<StorePage<T>> _page<T>(
    String path,
    T Function(Map<String, dynamic>) decode, {
    String? cursor,
    Map<String, String> filters = const {},
    bool admin = false,
    bool customer = false,
    bool employee = false,
  }) async {
    final data = await request(
      'GET',
      Uri(
        path: path,
        queryParameters: {
          'paginate': 'true',
          'page_size': '24',
          'cursor': ?cursor,
          ...filters,
        },
      ).toString(),
      admin: admin,
      customer: customer,
      employee: employee,
    );
    if (data is! Map || data['results'] is! List) {
      throw StoreException(
        'The store needs an update for scrolling lists. Please try again after deployment.',
      );
    }
    final next = data['next'];
    final nextCursor = next == null
        ? null
        : Uri.parse('$next').queryParameters['cursor'];
    if (next != null && (nextCursor == null || nextCursor.isEmpty)) {
      throw StoreException(
        'Unable to continue this list. Pull down to refresh.',
      );
    }
    return StorePage(
      items: (data['results'] as List)
          .map((j) => decode(Map<String, dynamic>.from(j)))
          .toList(),
      nextCursor: nextCursor,
      metadata: Map<String, dynamic>.from(data),
    );
  }

  Future<Map<String, dynamic>> browseCatalog() async =>
      Map<String, dynamic>.from(await request('GET', '/catalog/browse/'));

  Future<Map<String, dynamic>> lookupPincode(String pincode) async =>
      Map<String, dynamic>.from(
        await request('GET', '/address/pincode/$pincode/'),
      );

  Future<Map<String, dynamic>> reverseGeocode(double lat, double lon) async =>
      Map<String, dynamic>.from(
        await request(
          'GET',
          Uri(
            path: '/address/reverse-geocode/',
            queryParameters: {
              'lat': lat.toStringAsFixed(6),
              'lon': lon.toStringAsFixed(6),
            },
          ).toString(),
        ),
      );

  Future<StorePage<StoreProduct>> productPage({
    String? cursor,
    String search = '',
    String category = 'All',
    String? brand,
    double? minPrice,
    double? maxPrice,
    String? ordering,
    bool? inStock,
    String? collection,
    bool admin = false,
    String publication = 'published',
    String? stockFilter,
  }) async {
    if (cursor == null) await config();
    return _page(
      admin ? '/admin/products/' : '/products/',
      StoreProduct.fromJson,
      cursor: cursor,
      admin: admin,
      filters: {
        if (admin) 'publication': publication,
        if (admin && stockFilter != null) 'stock': stockFilter,
        if (search.isNotEmpty) 'search': search,
        if (category != 'All' && category.isNotEmpty) 'category': category,
        if (brand != null && brand.isNotEmpty && brand != 'All') 'brand': brand,
        if (minPrice != null) 'min_price': minPrice.toString(),
        if (maxPrice != null) 'max_price': maxPrice.toString(),
        if (ordering != null && ordering.isNotEmpty) 'ordering': ordering,
        if (inStock == true) 'in_stock': 'true',
        if (collection != null && collection.isNotEmpty)
          'collection': collection,
      },
    );
  }

  Future<StorePage<StoreOrder>> orderPage({
    String? cursor,
    bool admin = false,
    String status = 'All',
    bool employee = false,
    bool history = false,
    String search = '',
    String? assigned,
    String? date,
    String? period,
  }) => _page(
    employee
        ? '/delivery/orders/'
        : admin
        ? '/admin/orders/'
        : '/orders/',
    (j) => StoreOrder(j),
    cursor: cursor,
    admin: admin,
    customer: !admin && !employee,
    employee: employee,
    filters: {
      if (search.isNotEmpty) 'search': search,
      if (assigned != null && assigned.isNotEmpty) 'assigned': assigned,
      'date': ?date,
      if (admin && period != null && period.isNotEmpty) 'period': period,
      if (status != 'All') 'status': status,
      if (employee) 'scope': history ? 'completed' : 'active',
    },
  );
  Future<StorePage<Map<String, dynamic>>> employeePage({
    String? cursor,
    String search = '',
    bool ready = false,
    bool cashPending = false,
  }) => _page(
    '/admin/delivery-personnel/',
    (j) => j,
    cursor: cursor,
    admin: true,
    filters: {
      if (search.isNotEmpty) 'search': search,
      if (ready) 'ready': 'true',
      if (cashPending) 'cash': 'pending',
    },
  );
  Future<StorePage<StoreProduct>> wishlistPage(String? cursor) => _page(
    '/customer/wishlist/',
    StoreProduct.fromJson,
    cursor: cursor,
    customer: true,
  );
  Future<List<String>> wishlistIds() async => (await request(
    'GET',
    '/customer/wishlist/?ids_only=true',
    customer: true,
  ) as List).map((id) => '$id').toList();
  Future<StorePage<Map<String, dynamic>>> cashDuePage(int id, String? cursor) =>
      _page(
        '/admin/delivery-personnel/$id/cash-handover/',
        (j) => j,
        cursor: cursor,
        admin: true,
      );
  Future<StorePage<Map<String, dynamic>>> adminRequestPage(String? cursor) =>
      _page('/admin/search-requests/', (j) => j, cursor: cursor, admin: true);
  Future<StorePage<Map<String, dynamic>>> receiptPage({
    int? employeeId,
    String? cursor,
  }) => _page(
    employeeId == null
        ? '/delivery/receipts/'
        : '/admin/delivery-personnel/$employeeId/receipts/',
    (j) => j,
    cursor: cursor,
    admin: employeeId != null,
    employee: employeeId == null,
  );

  Future<List<StoreProduct>> productsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    await config();
    final products = <StoreProduct>[];
    for (var start = 0; start < ids.length; start += 100) {
      final batch = ids.skip(start).take(100).join(',');
      final rows = await request(
        'GET',
        Uri(path: '/products/', queryParameters: {'ids': batch}).toString(),
      ) as List;
      products.addAll(
        rows.map((j) => StoreProduct.fromJson(Map<String, dynamic>.from(j))),
      );
    }
    return products;
  }

  Future<Map<String, dynamic>> config() async {
    final data = Map<String, dynamic>.from(await request('GET', '/config/'));
    if (data['api_version'] != 5) {
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

  Future<Map<String, dynamic>> upload(List<int> bytes, String name) async {
    if (bytes.isEmpty) {
      throw StoreException('This photo is empty. Please choose another photo.');
    }
    if (bytes.length > 8 * 1024 * 1024) {
      throw StoreException('Choose an image smaller than 8 MB.');
    }
    return Map<String, dynamic>.from(
      await request(
        'POST',
        '/admin/images/',
        admin: true,
        data: FormData.fromMap({
          'image': MultipartFile.fromBytes(bytes, filename: name),
        }),
      ),
    );
  }

  Future<void> saveProduct(Map<String, dynamic> data, {String? id}) async {
    await request(
      id == null ? 'POST' : 'PATCH',
      id == null ? '/admin/products/' : '/admin/products/$id/',
      admin: true,
      data: data,
    );
  }

  Future<String?> suggestTamilName(String english) async {
    final data = await request(
      'GET',
      Uri(
        path: '/admin/products/tamil-name/',
        queryParameters: {'english_name': english},
      ).toString(),
      admin: true,
    ).timeout(const Duration(seconds: 12));
    return data['matched'] == true ? data['tamil_name'] as String : null;
  }

  Future<List<String>> productCategories() async {
    final data = await request(
      'GET',
      '/admin/product-categories/',
      admin: true,
    );
    return List<String>.from(data['categories']);
  }

  Future<String> createProductCategory(String name) async {
    final data = await request(
      'POST',
      '/admin/product-categories/',
      admin: true,
      data: {'name': name},
    );
    return data['name'] as String;
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
  Future<Map<String, dynamic>> savePerson(
    Map<String, dynamic> data, {
    int? id,
  }) async {
    return Map<String, dynamic>.from(
      await request(
        id == null ? 'POST' : 'PATCH',
        id == null
            ? '/admin/delivery-personnel/'
            : '/admin/delivery-personnel/$id/',
        admin: true,
        data: data,
      ),
    );
  }

  Future<Map<String, dynamic>> employeeRecord(int id) async =>
      Map<String, dynamic>.from(
        await request('GET', '/admin/delivery-personnel/$id/', admin: true),
      );
  Future<void> uploadEmployeeDocument(
    int id,
    String kind,
    List<int> bytes,
    String name,
  ) async {
    await request(
      'POST',
      '/admin/delivery-personnel/$id/documents/',
      admin: true,
      data: FormData.fromMap({
        'kind': kind,
        'document': MultipartFile.fromBytes(bytes, filename: name),
      }),
    );
  }

  Future<String> employeeDocumentUrl(int id, String documentId) async =>
      (await request(
        'GET',
        '/admin/delivery-personnel/$id/documents/$documentId/',
        admin: true,
      ))['url'];
  Future<void> deleteEmployeeDocument(int id, String documentId) async {
    await request(
      'DELETE',
      '/admin/delivery-personnel/$id/documents/$documentId/',
      admin: true,
    );
  }

  Future<Map<String, dynamic>> cashHandover(int id) async =>
      Map<String, dynamic>.from(
        await request(
          'GET',
          '/admin/delivery-personnel/$id/cash-handover/',
          admin: true,
        ),
      );
  Future<Map<String, dynamic>> receiveCash(
    int id,
    Map<String, dynamic> data,
  ) async => Map<String, dynamic>.from(
    await request(
      'POST',
      '/admin/delivery-personnel/$id/cash-handover/',
      admin: true,
      data: data,
    ),
  );

  Future<void> deliveryLogin(String identifier, String password) async {
    await config();
    final result = await request(
      'POST',
      '/delivery/login/',
      data: {'employee_code': identifier.trim(), 'password': password},
    );
    deliveryToken = result['token'];
    staffWorkspace = '/delivery';
    await _saveStaffSession();
    staffChanges.value++;
  }

  Future<void> deliveryLogout() async {
    try {
      if (deliveryToken != null) {
        await request('POST', '/delivery/logout/', employee: true);
      }
    } finally {
      deliveryToken = null;
      if (staffWorkspace == '/delivery') staffWorkspace = '/';
      await _saveStaffSession();
      staffChanges.value++;
    }
  }

  Future<Map<String, dynamic>> deliveryDashboard() async =>
      Map<String, dynamic>.from(
        await request('GET', '/delivery/dashboard/', employee: true),
      );
  Future<List<StoreOrder>> deliveryOrders() async =>
      (await request('GET', '/delivery/orders/', employee: true) as List)
          .map((j) => StoreOrder(Map<String, dynamic>.from(j)))
          .toList();
  Future<StoreOrder> deliveryOrder(String id) async => StoreOrder(
    Map<String, dynamic>.from(
      await request('GET', '/delivery/orders/$id/', employee: true),
    ),
  );
  Future<StoreOrder> updateDelivery(
    String id,
    Map<String, dynamic> data,
  ) async => StoreOrder(
    Map<String, dynamic>.from(
      await request(
        'PATCH',
        '/delivery/orders/$id/',
        employee: true,
        data: data,
      ),
    ),
  );

  Future<StoreOrder> updateOrder(String id, Map<String, dynamic> data) async =>
      StoreOrder(
        Map<String, dynamic>.from(
          await request('PATCH', '/admin/orders/$id/', admin: true, data: data),
        ),
      );

  Future<StoreOrder> adminOrder(String id) async => StoreOrder(
    Map<String, dynamic>.from(
      await request('GET', '/admin/orders/$id/', admin: true),
    ),
  );

  Future<void> assignPackedOrders(List<String> ids, int employeeId) async {
    await request(
      'POST',
      '/admin/orders/assign/',
      admin: true,
      data: {'order_ids': ids, 'assigned_to': employeeId},
    );
  }

  Future<Map<String, dynamic>> deliveryTracking(
    String id, {
    bool admin = false,
    bool employee = false,
  }) async => Map<String, dynamic>.from(
    await request(
      'GET',
      '/orders/$id/tracking/',
      admin: admin,
      employee: employee,
      customer: !admin && !employee,
    ),
  );

  Future<void> shareDeliveryLocation(
    String id,
    Map<String, dynamic> location,
  ) async {
    await request(
      'POST',
      '/orders/$id/tracking/',
      employee: true,
      data: location,
    );
  }

  Future<void> refreshDeliveryCode(String id) async {
    await request('POST', '/orders/$id/delivery-code/', customer: true);
  }
}
