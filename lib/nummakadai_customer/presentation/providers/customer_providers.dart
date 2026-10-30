import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/customer_models.dart';
import '../../data/repositories/customer_mock_repository.dart';

// Repository Provider
final customerRepoProvider = Provider<CustomerMockRepository>((ref) {
  return CustomerMockRepository();
});

// Active Screen Step (1 to 15)
class CustomerFlowStepNotifier extends Notifier<int> {
  @override
  int build() => 4; // Default to Screen 4 (Home Screen)
  void setStep(int step) => state = step;
}
final customerFlowStepProvider = NotifierProvider<CustomerFlowStepNotifier, int>(
  CustomerFlowStepNotifier.new,
);

// Bottom Navigation Index (0: Home, 1: Categories, 2: Cart, 3: Orders, 4: Account)
class CustomerBottomNavNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void setIndex(int idx) => state = idx;
}
final customerBottomNavProvider = NotifierProvider<CustomerBottomNavNotifier, int>(
  CustomerBottomNavNotifier.new,
);

// Cart Provider
class CustomerCartNotifier extends Notifier<List<CustomerCartItem>> {
  @override
  List<CustomerCartItem> build() {
    final repo = ref.watch(customerRepoProvider);
    // Pre-populate with initial items per reference design
    return [
      CustomerCartItem(
        product: repo.products[0],
        selectedSize: repo.products[0].sizes[1], // 1 kg - ₹275
        quantity: 1,
      ),
      CustomerCartItem(
        product: repo.products[1],
        selectedSize: repo.products[1].sizes[1], // 5 kg - ₹325
        quantity: 1,
      ),
      CustomerCartItem(
        product: repo.products[2],
        selectedSize: repo.products[2].sizes[1], // 1 L - ₹165
        quantity: 1,
      ),
    ];
  }

  void addToCart(CustomerProduct product, ProductSizeOption size, int qty) {
    final existingIdx = state.indexWhere(
      (item) => item.product.id == product.id && item.selectedSize.size == size.size,
    );
    if (existingIdx != -1) {
      state[existingIdx].quantity += qty;
      state = List.from(state);
    } else {
      state = [...state, CustomerCartItem(product: product, selectedSize: size, quantity: qty)];
    }
  }

  void updateQuantity(int index, int delta) {
    final item = state[index];
    final newQty = item.quantity + delta;
    if (newQty <= 0) {
      state = List.from(state)..removeAt(index);
    } else {
      item.quantity = newQty;
      state = List.from(state);
    }
  }

  void removeItem(int index) {
    state = List.from(state)..removeAt(index);
  }

  void clearCart() {
    state = [];
  }

  double get itemsTotal => state.fold(0.0, (sum, item) => sum + item.subtotal);
  double get deliveryCharge => 0.0; // FREE per reference
  double get grandTotal => itemsTotal + deliveryCharge;
}
final customerCartProvider = NotifierProvider<CustomerCartNotifier, List<CustomerCartItem>>(
  CustomerCartNotifier.new,
);

// Selected Product for Details Screen
class SelectedProductNotifier extends Notifier<CustomerProduct> {
  @override
  CustomerProduct build() {
    final repo = ref.watch(customerRepoProvider);
    return repo.products.first;
  }
  void setProduct(CustomerProduct p) => state = p;
}
final selectedProductProvider = NotifierProvider<SelectedProductNotifier, CustomerProduct>(
  SelectedProductNotifier.new,
);

// Selected Address
class SelectedAddressNotifier extends Notifier<CustomerAddress> {
  @override
  CustomerAddress build() {
    final repo = ref.watch(customerRepoProvider);
    return repo.addresses.first;
  }
  void setAddress(CustomerAddress addr) => state = addr;
}
final selectedAddressProvider = NotifierProvider<SelectedAddressNotifier, CustomerAddress>(
  SelectedAddressNotifier.new,
);

// Selected Delivery Date & Slot
class SelectedDeliverySlotNotifier extends Notifier<CustomerDeliverySlot> {
  @override
  CustomerDeliverySlot build() {
    return const CustomerDeliverySlot(
      dateLabel: 'Today',
      dateNum: '22 Oct',
      timeRange: '10:00 AM – 12:00 PM',
    );
  }
  void setSlot(CustomerDeliverySlot slot) => state = slot;
}
final selectedDeliverySlotProvider = NotifierProvider<SelectedDeliverySlotNotifier, CustomerDeliverySlot>(
  SelectedDeliverySlotNotifier.new,
);

// Orders List Provider
class CustomerOrdersNotifier extends Notifier<List<CustomerOrderRecord>> {
  @override
  List<CustomerOrderRecord> build() {
    final repo = ref.watch(customerRepoProvider);
    return [
      CustomerOrderRecord(
        orderId: '#NK20251022',
        orderDate: DateTime.now(),
        timeSlot: 'Today, 10:00 AM – 12:00 PM',
        items: [
          CustomerCartItem(product: repo.products[0], selectedSize: repo.products[0].sizes[1], quantity: 1),
          CustomerCartItem(product: repo.products[1], selectedSize: repo.products[1].sizes[1], quantity: 1),
          CustomerCartItem(product: repo.products[2], selectedSize: repo.products[2].sizes[1], quantity: 1),
        ],
        totalAmount: 765.0,
        status: CustomerOrderStatus.preparing,
        address: repo.addresses[0],
      ),
      CustomerOrderRecord(
        orderId: '#NK20251018',
        orderDate: DateTime.now().subtract(const Duration(days: 4)),
        timeSlot: '18 Oct, 04:00 PM – 06:00 PM',
        items: [
          CustomerCartItem(product: repo.products[0], selectedSize: repo.products[0].sizes[0], quantity: 2),
          CustomerCartItem(product: repo.products[3], selectedSize: repo.products[3].sizes[1], quantity: 3),
        ],
        totalAmount: 1240.0,
        status: CustomerOrderStatus.delivered,
        address: repo.addresses[0],
      ),
    ];
  }

  void placeOrder(CustomerOrderRecord order) {
    state = [order, ...state];
  }
}
final customerOrdersProvider = NotifierProvider<CustomerOrdersNotifier, List<CustomerOrderRecord>>(
  CustomerOrdersNotifier.new,
);

