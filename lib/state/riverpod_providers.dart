import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/api_service.dart';

enum ActiveAppMode {
  customerFlow,
  adminFlow,
}

// ----------------- GLOBAL APP MODE NOTIFIER -----------------

class ActiveAppModeNotifier extends Notifier<ActiveAppMode> {
  @override
  ActiveAppMode build() => ActiveAppMode.customerFlow;

  void setMode(ActiveAppMode mode) {
    state = mode;
  }
}

final activeAppModeProvider =
    NotifierProvider<ActiveAppModeNotifier, ActiveAppMode>(
  ActiveAppModeNotifier.new,
);

// ----------------- CUSTOMER NOTIFIERS -----------------

class CustomerStepNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setStep(int step) {
    state = step;
  }
}

final customerStepProvider =
    NotifierProvider<CustomerStepNotifier, int>(
  CustomerStepNotifier.new,
);

final productsProvider = FutureProvider<List<Product>>((ref) async {
  return ApiService().fetchProducts();
});

// ----------------- ADMIN STATE NOTIFIER -----------------

class AdminState {
  final int stepIndex;
  final bool isLoggedIn;
  final String adminId;
  final String selectedTab; // 'All', 'New', 'Packed'
  final String selectedOrderId;
  final Map<String, bool> packingChecklist;
  final String selectedDeliveryPerson;
  final String orderStatus;
  final Map<String, dynamic> stockData;
  final String requestStatus; // 'Pending', 'Approved', 'Rejected'

  const AdminState({
    this.stepIndex = 0,
    this.isLoggedIn = true,
    this.adminId = 'ADM01',
    this.selectedTab = 'All',
    this.selectedOrderId = '#ORD124578',
    this.packingChecklist = const {
      'prod_tomato': true,
      'prod_carrot': true,
      'prod_onion': false, // Marked Out of Stock
    },
    this.selectedDeliveryPerson = 'Karthik',
    this.orderStatus = 'Preparing',
    this.stockData = const {
      'prod_tomato': {'stock': 50, 'inStock': true},
      'prod_onion': {'stock': 0, 'inStock': false},
      'prod_potato': {'stock': 40, 'inStock': true},
      'prod_carrot': {'stock': 30, 'inStock': true},
      'prod_brinjal': {'stock': 20, 'inStock': true},
      'prod_drumstick': {'stock': 15, 'inStock': true},
      'prod_beans': {'stock': 10, 'inStock': true},
      'prod_mint': {'stock': 0, 'inStock': false},
    },
    this.requestStatus = 'Pending',
  });

  AdminState copyWith({
    int? stepIndex,
    bool? isLoggedIn,
    String? adminId,
    String? selectedTab,
    String? selectedOrderId,
    Map<String, bool>? packingChecklist,
    String? selectedDeliveryPerson,
    String? orderStatus,
    Map<String, dynamic>? stockData,
    String? requestStatus,
  }) {
    return AdminState(
      stepIndex: stepIndex ?? this.stepIndex,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      adminId: adminId ?? this.adminId,
      selectedTab: selectedTab ?? this.selectedTab,
      selectedOrderId: selectedOrderId ?? this.selectedOrderId,
      packingChecklist: packingChecklist ?? this.packingChecklist,
      selectedDeliveryPerson: selectedDeliveryPerson ?? this.selectedDeliveryPerson,
      orderStatus: orderStatus ?? this.orderStatus,
      stockData: stockData ?? this.stockData,
      requestStatus: requestStatus ?? this.requestStatus,
    );
  }
}

class AdminNotifier extends Notifier<AdminState> {
  @override
  AdminState build() => const AdminState();

  void setStep(int index) {
    if (index >= 0 && index < 12) {
      state = state.copyWith(stepIndex: index);
    }
  }

  void nextStep() {
    if (state.stepIndex < 11) {
      state = state.copyWith(stepIndex: state.stepIndex + 1);
    }
  }

  void prevStep() {
    if (state.stepIndex > 0) {
      state = state.copyWith(stepIndex: state.stepIndex - 1);
    }
  }

  void login(String id) {
    state = state.copyWith(isLoggedIn: true, adminId: id, stepIndex: 1); // Go to Dashboard
  }

  void setTab(String tab) {
    state = state.copyWith(selectedTab: tab);
  }

  void selectOrder(String orderId) {
    state = state.copyWith(selectedOrderId: orderId);
  }

  void togglePackItem(String productId) {
    final updated = Map<String, bool>.from(state.packingChecklist);
    updated[productId] = !(updated[productId] ?? false);
    state = state.copyWith(packingChecklist: updated);
  }

  void markOrderPacked() {
    ApiService().markOrderPacked(state.selectedOrderId);
    state = state.copyWith(orderStatus: 'Packed', stepIndex: 8); // Go to Assign Driver
  }

  void selectDeliveryPerson(String name) {
    state = state.copyWith(selectedDeliveryPerson: name);
  }

  void assignDriver() {
    ApiService().assignDeliveryPersonnel(state.selectedOrderId, state.selectedDeliveryPerson);
    state = state.copyWith(stepIndex: 9); // Go to Dispatch Order
  }

  void dispatchOrder() {
    ApiService().dispatchOrder(state.selectedOrderId);
    state = state.copyWith(orderStatus: 'Out for Delivery', stepIndex: 10); // Go to Delivery Tracking
  }

  void toggleProductStock(String productId) {
    final currentStock = Map<String, dynamic>.from(state.stockData);
    if (currentStock.containsKey(productId)) {
      final item = Map<String, dynamic>.from(currentStock[productId]);
      final newStatus = !(item['inStock'] as bool);
      item['inStock'] = newStatus;
      currentStock[productId] = item;
      ApiService().updateStockStatus(productId, newStatus, (item['stock'] as num).toDouble());
      state = state.copyWith(stockData: currentStock);
    }
  }

  void approveNewItem() {
    ApiService().handleItemRequest(1, 'approve');
    state = state.copyWith(requestStatus: 'Approved');
  }

  void rejectNewItem() {
    ApiService().handleItemRequest(1, 'reject');
    state = state.copyWith(requestStatus: 'Rejected');
  }
}

final adminProvider = NotifierProvider<AdminNotifier, AdminState>(
  AdminNotifier.new,
);
