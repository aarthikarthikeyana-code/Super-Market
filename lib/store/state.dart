import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api.dart';
import 'models.dart';

final storeApiProvider = Provider<StoreApi>((ref) => StoreApi());
final catalogProvider = FutureProvider<List<StoreProduct>>(
  (ref) => ref.watch(storeApiProvider).products(),
);
final storeConfigProvider = FutureProvider<Map<String, dynamic>>(
  (ref) => ref.watch(storeApiProvider).config(),
);
final customerAccountProvider = FutureProvider<Map<String, dynamic>?>(
  (ref) => ref.watch(storeApiProvider).restoreCustomerAccount(),
);
final customerProfileProvider = FutureProvider<Map<String, dynamic>>(
  (ref) => ref.watch(storeApiProvider).customerProfile(),
);
final wishlistProvider = FutureProvider<List<StoreProduct>>((ref) async {
  final account = await ref.watch(customerAccountProvider.future);
  if (account == null) return [];
  return ref.watch(storeApiProvider).wishlist();
});
final myOrdersProvider = FutureProvider<List<StoreOrder>>(
  (ref) => ref.watch(storeApiProvider).orders(),
);
final adminOrdersProvider = FutureProvider<List<StoreOrder>>(
  (ref) => ref.watch(storeApiProvider).orders(admin: true),
);
final adminDashboardProvider = FutureProvider<Map<String, dynamic>>(
  (ref) => ref.watch(storeApiProvider).dashboard(),
);
final deliveryTeamProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.watch(storeApiProvider).personnel(),
);

// Role management: 'admin' or 'employee'
class ActiveRoleNotifier extends Notifier<String> {
  @override
  String build() => 'admin';
  void setRole(String role) => state = role;
}
final activeRoleProvider = NotifierProvider<ActiveRoleNotifier, String>(
  ActiveRoleNotifier.new,
);

// Active Employee payload when switched to employee role
class ActiveEmployeeNotifier extends Notifier<Map<String, dynamic>?> {
  @override
  Map<String, dynamic>? build() => null;
  void setEmployee(Map<String, dynamic>? emp) => state = emp;
}
final activeEmployeeProvider = NotifierProvider<ActiveEmployeeNotifier, Map<String, dynamic>?>(
  ActiveEmployeeNotifier.new,
);


class StoreCart extends Notifier<List<CartLine>> {
  @override
  List<CartLine> build() {
    final api = ref.watch(storeApiProvider);
    Future.microtask(() => _restore(api));
    return [];
  }

  bool _edited = false;
  Future<void> _writes = Future.value();
  Future<void> _restore(StoreApi api) async {
    try {
      final saved = await api.storage.read(key: 'agaram_cart');
      if (saved == null) return;
      final rows = jsonDecode(saved) as List;
      final products = await api.products();
      if (!ref.mounted || _edited) return;
      final restored = <CartLine>[];
      for (final row in rows) {
        final product = products.where((p) => p.id == row['id']).firstOrNull;
        final quantity = row['quantity'];
        if (product != null &&
            product.available &&
            quantity is int &&
            quantity > 0) {
          restored.add(
            CartLine(
              product,
              quantity.clamp(1, product.stock.floor().clamp(1, 100)),
            ),
          );
        }
      }
      state = restored;
    } catch (_) {
      // Keep the saved cart for the next online restore; never substitute products.
    }
  }

  void _set(List<CartLine> lines) {
    _edited = true;
    state = lines;
    final storage = ref.read(storeApiProvider).storage;
    final payload = jsonEncode([
      for (final line in lines)
        {'id': line.product.id, 'quantity': line.quantity},
    ]);
    _writes = _writes
        .then((_) => storage.write(key: 'agaram_cart', value: payload))
        .catchError((Object _) {});
  }

  void add(StoreProduct product) {
    if (!product.available) return;
    final count =
        state.where((l) => l.product.id == product.id).firstOrNull?.quantity ??
        0;
    if (count >= product.stock.floor() || count >= 100) return;
    _set([
      ...state.where((l) => l.product.id != product.id),
      CartLine(product, count + 1),
    ]);
  }

  void change(String id, int delta) {
    _set([
      for (final line in state)
        if (line.product.id != id)
          line
        else if (line.quantity + delta > 0)
          CartLine(
            line.product,
            (line.quantity + delta).clamp(
              1,
              line.product.stock.floor().clamp(1, 100),
            ),
          ),
    ]);
  }

  void reconcile(List<StoreProduct> products) {
    final current = {for (final product in products) product.id: product};
    _set([
      for (final line in state)
        if (current[line.product.id]?.available == true)
          CartLine(
            current[line.product.id]!,
            line.quantity.clamp(
              1,
              current[line.product.id]!.stock.floor().clamp(1, 100),
            ),
          ),
    ]);
  }

  void remove(String id) =>
      _set(state.where((l) => l.product.id != id).toList());
  void clear() => _set([]);
  Future<void> flush() => _writes;
}

final storeCartProvider = NotifierProvider<StoreCart, List<CartLine>>(
  StoreCart.new,
);

void refreshCommerce(WidgetRef ref) {
  ref.invalidate(catalogProvider);
  ref.invalidate(myOrdersProvider);
  ref.invalidate(adminOrdersProvider);
  ref.invalidate(adminDashboardProvider);
  ref.invalidate(deliveryTeamProvider);
}
