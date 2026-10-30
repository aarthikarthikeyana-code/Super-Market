import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/numma_models.dart';
import '../../data/repositories/numma_mock_repository.dart';

// Repository Provider
final nummaRepoProvider = Provider<NummaMockRepository>((ref) {
  return NummaMockRepository();
});

// Current active flow step (1 to 15 for the 15 screens)
class NummaActiveStepNotifier extends Notifier<int> {
  @override
  int build() => 2; // Default to Dashboard (Screen 2)
  void setStep(int step) => state = step;
}
final nummaStepProvider = NotifierProvider<NummaActiveStepNotifier, int>(
  NummaActiveStepNotifier.new,
);

// Tab selection for bottom navigation (0: Dashboard, 1: Products, 2: Orders, 3: Customers, 4: More)
class NummaBottomNavNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void setIndex(int idx) => state = idx;
}
final nummaBottomNavProvider = NotifierProvider<NummaBottomNavNotifier, int>(
  NummaBottomNavNotifier.new,
);

// Selected Order for Order Details
class NummaSelectedOrderNotifier extends Notifier<NummaOrder?> {
  @override
  NummaOrder? build() {
    final orders = ref.watch(nummaRepoProvider).orders;
    return orders.isNotEmpty ? orders.first : null;
  }
  void setOrder(NummaOrder order) => state = order;
}
final nummaSelectedOrderProvider = NotifierProvider<NummaSelectedOrderNotifier, NummaOrder?>(
  NummaSelectedOrderNotifier.new,
);

// Products Provider
class NummaProductsNotifier extends Notifier<List<NummaProduct>> {
  @override
  List<NummaProduct> build() {
    return ref.watch(nummaRepoProvider).products;
  }

  void addProduct(NummaProduct p) {
    ref.read(nummaRepoProvider).addProduct(p);
    state = List.from(ref.read(nummaRepoProvider).products);
  }

  void updateStock(String id, int qty) {
    ref.read(nummaRepoProvider).updateProductStock(id, qty);
    state = List.from(ref.read(nummaRepoProvider).products);
  }

  void deleteProduct(String id) {
    ref.read(nummaRepoProvider).deleteProduct(id);
    state = List.from(ref.read(nummaRepoProvider).products);
  }
}
final nummaProductsProvider = NotifierProvider<NummaProductsNotifier, List<NummaProduct>>(
  NummaProductsNotifier.new,
);

// Orders Provider
class NummaOrdersNotifier extends Notifier<List<NummaOrder>> {
  @override
  List<NummaOrder> build() {
    return ref.watch(nummaRepoProvider).orders;
  }

  void updateStatus(String orderId, OrderStatus status) {
    ref.read(nummaRepoProvider).updateOrderStatus(orderId, status);
    state = List.from(ref.read(nummaRepoProvider).orders);
  }
}
final nummaOrdersProvider = NotifierProvider<NummaOrdersNotifier, List<NummaOrder>>(
  NummaOrdersNotifier.new,
);

// Categories Provider
class NummaCategoriesNotifier extends Notifier<List<NummaCategory>> {
  @override
  List<NummaCategory> build() {
    return ref.watch(nummaRepoProvider).categories;
  }

  void addCategory(NummaCategory cat) {
    ref.read(nummaRepoProvider).addCategory(cat);
    state = List.from(ref.read(nummaRepoProvider).categories);
  }

  void updateCategory(String id, String nameTa, String nameEn) {
    final list = ref.read(nummaRepoProvider).categories;
    final idx = list.indexWhere((c) => c.id == id);
    if (idx != -1) {
      list[idx] = NummaCategory(
        id: id,
        nameTamil: nameTa,
        nameEnglish: nameEn,
        productCount: list[idx].productCount,
        iconKey: list[idx].iconKey,
      );
      state = List.from(list);
    }
  }

  void deleteCategory(String id) {
    ref.read(nummaRepoProvider).deleteCategory(id);
    state = List.from(ref.read(nummaRepoProvider).categories);
  }
}
final nummaCategoriesProvider = NotifierProvider<NummaCategoriesNotifier, List<NummaCategory>>(
  NummaCategoriesNotifier.new,
);

// Brands Provider
class NummaBrandsNotifier extends Notifier<List<NummaBrand>> {
  @override
  List<NummaBrand> build() {
    return ref.watch(nummaRepoProvider).brands;
  }

  void addBrand(NummaBrand b) {
    ref.read(nummaRepoProvider).addBrand(b);
    state = List.from(ref.read(nummaRepoProvider).brands);
  }

  void updateBrand(String id, String name) {
    final list = ref.read(nummaRepoProvider).brands;
    final idx = list.indexWhere((b) => b.id == id);
    if (idx != -1) {
      list[idx] = NummaBrand(
        id: id,
        name: name,
        productCount: list[idx].productCount,
        logoText: name.substring(0, name.length > 2 ? 2 : name.length).toUpperCase(),
      );
      state = List.from(list);
    }
  }

  void deleteBrand(String id) {
    ref.read(nummaRepoProvider).deleteBrand(id);
    state = List.from(ref.read(nummaRepoProvider).brands);
  }
}
final nummaBrandsProvider = NotifierProvider<NummaBrandsNotifier, List<NummaBrand>>(
  NummaBrandsNotifier.new,
);

// Banners Provider
class NummaBannersNotifier extends Notifier<List<NummaBanner>> {
  @override
  List<NummaBanner> build() {
    return ref.watch(nummaRepoProvider).banners;
  }

  void toggleBanner(String id) {
    ref.read(nummaRepoProvider).toggleBanner(id);
    state = List.from(ref.read(nummaRepoProvider).banners);
  }

  void addBanner(NummaBanner b) {
    ref.read(nummaRepoProvider).addBanner(b);
    state = List.from(ref.read(nummaRepoProvider).banners);
  }

  void updateBanner(String id, String title, String subtitle) {
    final list = ref.read(nummaRepoProvider).banners;
    final idx = list.indexWhere((b) => b.id == id);
    if (idx != -1) {
      list[idx] = NummaBanner(
        id: id,
        title: title,
        subtitle: subtitle,
        tag: list[idx].tag,
        isActive: list[idx].isActive,
        imageUrl: list[idx].imageUrl,
      );
      state = List.from(list);
    }
  }

  void deleteBanner(String id) {
    ref.read(nummaRepoProvider).deleteBanner(id);
    state = List.from(ref.read(nummaRepoProvider).banners);
  }
}
final nummaBannersProvider = NotifierProvider<NummaBannersNotifier, List<NummaBanner>>(
  NummaBannersNotifier.new,
);

// Customers Provider
final nummaCustomersProvider = Provider<List<NummaCustomer>>((ref) {
  return ref.watch(nummaRepoProvider).customers;
});

// Delivery Agents Provider
final nummaDeliveryAgentsProvider = Provider<List<NummaDeliveryAgent>>((ref) {
  return ref.watch(nummaRepoProvider).deliveryAgents;
});
