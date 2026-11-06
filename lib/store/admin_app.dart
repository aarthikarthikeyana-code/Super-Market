import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'api.dart';
import 'models.dart';
import 'state.dart';
import 'widgets.dart';
import 'delivery_staff.dart';
import 'delivery_app.dart';
import 'paged_feed.dart';
import 'employee_picker.dart';
import 'delivery_tracking.dart';
import 'admin_dashboard.dart';
import 'admin_pages.dart';

class AdminConsoleScreen extends ConsumerStatefulWidget {
  const AdminConsoleScreen({super.key});
  @override
  ConsumerState<AdminConsoleScreen> createState() => _AdminConsoleState();
}

class _AdminConsoleState extends ConsumerState<AdminConsoleScreen> {
  bool _signedIn = false;
  int _tab = 0;
  String _orderFilter = 'Active', _orderSearch = '', _teamSearch = '';
  bool _unassignedOnly = false, _todayOnly = false;
  Map<String, dynamic> _stageCounts = {};
  final Set<String> _selectedOrders = {};
  bool _batchBusy = false, _selectOrders = false;
  String? _quickOrderId;
  String _productFilter = 'all', _productSearch = '';
  String? _productCategory, _productBrand;
  Map<String, dynamic>? _assignmentEmployee;
  final _orderSearchInput = TextEditingController(),
      _productSearchInput = TextEditingController(),
      _teamSearchInput = TextEditingController();
  final _orderSearchFocus = FocusNode();
  Timer? _productDebounce;
  Timer? _searchDebounce, _teamDebounce;
  Timer? _poll;
  late final StoreApi _api;
  @override
  void initState() {
    super.initState();
    final api = ref.read(storeApiProvider);
    _api = api;
    _signedIn = api.adminToken != null;
    api.staffChanges.addListener(_staffChanged);
    if (_signedIn) _checkAndSeedCatalog();
    _poll = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_signedIn) {
        ref.read(storeApiProvider).feedChanges.value++;
        ref.invalidate(adminOrdersProvider);
        ref.invalidate(adminDashboardProvider);
        if (_tab == 5) ref.invalidate(deliveryTeamProvider);
      }
    });
  }

  @override
  void dispose() {
    _orderSearchInput.dispose();
    _productSearchInput.dispose();
    _teamSearchInput.dispose();
    _orderSearchFocus.dispose();
    _productDebounce?.cancel();
    _searchDebounce?.cancel();
    _teamDebounce?.cancel();
    _api.staffChanges.removeListener(_staffChanged);
    _poll?.cancel();
    super.dispose();
  }

  void _staffChanged() {
    if (mounted) {
      setState(() => _signedIn = _api.adminToken != null);
      if (_signedIn) _checkAndSeedCatalog();
    }
  }

  Future<void> _logout() async {
    try {
      await ref.read(storeApiProvider).logout();
    } catch (e) {
      if (mounted) showStoreError(context, e);
    }
    if (!mounted) return;
    ref.read(activeRoleProvider.notifier).setRole('admin');
    ref.read(activeEmployeeProvider.notifier).setEmployee(null);
    refreshCommerce(ref);
    context.go('/');
  }

  void _loginSuccess() {
    refreshCommerce(ref);
    setState(() => _signedIn = true);
    _checkAndSeedCatalog();
  }

  @override
  Widget build(BuildContext context) {
    final activeRole = ref.watch(activeRoleProvider);
    final activeEmployee = ref.watch(activeEmployeeProvider);

    if (_signedIn && activeRole == 'employee') {
      return PopScope(
        canPop: false,
        child: Theme(
          data: storeTheme(),
          child: EmployeeConsoleScreen(
            employee: activeEmployee,
            onSwitchToAdmin: () {
              ref.read(activeRoleProvider.notifier).setRole('admin');
            },
          ),
        ),
      );
    }

    return PopScope(
      canPop: !_signedIn,
      child: Theme(
        data: operationsTheme(),
        child: !_signedIn
            ? AdminSignInScreen(onSuccess: _loginSuccess)
            : Scaffold(
                appBar: _header(),
                body: AdminCanvas(
                  child: switch (_tab) {
                    0 => _overview(),
                    1 => _orders(),
                    2 => _products(),
                    3 => OperationsDeliveryControl(onOrder: _openOrder),
                    4 => OperationsMore(onOpen: _openMore),
                    5 => _team(),
                    6 => OperationsCashControl(onReceive: _receiveCash),
                    _ => OperationsReports(
                      onOrders: _showOrders,
                      onInventory: _showInventory,
                    ),
                  },
                ),
                bottomNavigationBar: AdminBottomNavigation(
                  selected: _tab <= 4 ? _tab : 4,
                  onSelected: (index) => setState(() => _tab = index),
                ),
              ),
      ),
    );
  }

  PreferredSizeWidget _header() {
    final snapshot = ref.watch(adminDashboardProvider);
    final data = snapshot.asData?.value;
    final alerts = List<Map<String, dynamic>>.from(data?['alerts'] ?? []);
    final profile = Map<String, dynamic>.from(data?['admin_profile'] ?? {});
    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      toolbarHeight: 60,
      title: Row(
        children: [
          const AdminIcon(Icons.storefront_rounded, size: 34),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AGARAM',
                  style: TextStyle(
                    fontSize: 15,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w800,
                    color: opsForestGreen,
                  ),
                ),
                Text(
                  const [
                    'Operations dashboard',
                    'Order management',
                    'Product catalogue',
                    'Delivery control',
                    'Store tools',
                    'Delivery team',
                    'Cash handover',
                    'Reports & analytics',
                  ][_tab],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: opsMuted),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Search orders',
          onPressed: () {
            setState(() => _tab = 1);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _orderSearchFocus.requestFocus();
            });
          },
          icon: const Icon(Icons.search_rounded, size: 21),
        ),
        IconButton(
          tooltip: 'Operational alerts',
          onPressed: _showAlerts,
          icon: Badge(
            isLabelVisible: alerts.isNotEmpty,
            label: Text('${alerts.length}'),
            child: const Icon(Icons.notifications_none_rounded, size: 21),
          ),
        ),
        IconButton(
          tooltip: 'Admin profile',
          onPressed: _showProfile,
          icon: CircleAvatar(
            radius: 15,
            backgroundColor: opsGlassMint,
            child: Text(
              profile['name'] == null ? 'A' : opsInitial('${profile['name']}'),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: opsForestGreen,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  void _showOrders(String stage, {Map<String, dynamic>? employee}) {
    final today = stage.startsWith('Today ');
    final selected = today ? stage.substring(6) : stage;
    setState(() {
      _tab = 1;
      _orderFilter = selected == 'Unassigned'
          ? 'Packed'
          : today && selected == 'Delivered'
          ? 'Delivered Today'
          : today && selected == 'Active'
          ? 'Today Attention'
          : selected;
      _unassignedOnly = stage == 'Unassigned';
      _todayOnly = today && !['Delivered', 'Active'].contains(selected);
      _orderSearch = '';
      _orderSearchInput.clear();
      _selectedOrders.clear();
      _selectOrders = false;
      _assignmentEmployee = employee;
    });
  }

  void _showInventory(String filter) {
    setState(() {
      _tab = 2;
      _productFilter = filter;
      _productCategory = null;
      _productBrand = null;
      _productSearch = '';
      _productSearchInput.clear();
    });
  }

  void _showCategory(String category) {
    setState(() {
      _tab = 2;
      _productFilter = 'all';
      _productCategory = category;
      _productBrand = null;
      _productSearch = '';
      _productSearchInput.clear();
    });
  }

  Future<void> _receiveCash(Map<String, dynamic> person) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Theme(
          data: operationsTheme(),
          child: EmployeeCashScreen(person: person),
        ),
      ),
    );
    if (mounted) refreshCommerce(ref);
  }

  Future<void> _showProfile() async {
    try {
      final data = await ref.read(adminDashboardProvider.future);
      if (!mounted) return;
      final profile = Map<String, dynamic>.from(data['admin_profile'] ?? {});
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFFFDF9),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDE8E1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Modern Avatar
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE9F8EF), Color(0xFFDDF3E6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: const Color(0xFF16A05D).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person_outline_rounded,
                      size: 38,
                      color: Color(0xFF0D6F47),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${profile['name'] ?? 'Administrator'}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF15211A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${profile['email'] ?? ''}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF69756F),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5F8EC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Store administrator',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0D6F47),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Action options
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFDDE8E1)),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF3FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.sync_rounded,
                            color: Color(0xFF1976D2),
                            size: 20,
                          ),
                        ),
                        title: const Text(
                          'Refresh Store Data',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF69756F),
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          refreshCommerce(ref);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Logout button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD32F2F),
                      side: const BorderSide(color: Color(0xFFFFCDD2)),
                      backgroundColor: const Color(0xFFFFEBEE),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(
                      Icons.power_settings_new_rounded,
                      size: 20,
                    ),
                    label: const Text(
                      'Logout',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _logout();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) showStoreError(context, e);
    }
  }

  Future<void> _showAlerts() async {
    try {
      final data = await ref.read(adminDashboardProvider.future);
      if (!mounted) return;
      final alerts = List<Map<String, dynamic>>.from(data['alerts'] ?? []);
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const OpsHeading('Operational alerts'),
                if (alerts.isEmpty)
                  const OpsEmpty(
                    'All caught up',
                    'No action is currently required.',
                    icon: Icons.task_alt,
                  )
                else
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final alert in alerts)
                          ListTile(
                            title: Text('${alert['title']}'),
                            subtitle: Text('${alert['detail']}'),
                            trailing: Text('${alert['count']}'),
                            onTap: () {
                              Navigator.pop(ctx);
                              final key = alert['key'];
                              if (key == 'cash') {
                                setState(() => _tab = 6);
                              } else if (key == 'stock') {
                                _showInventory('low');
                              } else if (key == 'team') {
                                setState(() => _tab = 5);
                              } else {
                                _showOrders(
                                  key == 'cash_review'
                                      ? 'Cash Review'
                                      : key == 'assignment'
                                      ? 'Unassigned'
                                      : key == 'delayed'
                                      ? 'Delayed'
                                      : key == 'attempted'
                                      ? 'Delivery Attempted'
                                      : 'New',
                                );
                              }
                            },
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) showStoreError(context, e);
    }
  }

  Future<void> _openMore(String action) async {
    if (action == 'team') {
      setState(() => _tab = 5);
      return;
    }
    if (action == 'inventory' || action == 'low') {
      _showInventory(action == 'low' ? 'low' : 'all');
      return;
    }
    if (action == 'cash') {
      setState(() => _tab = 6);
      return;
    }
    if (action == 'reports') {
      setState(() => _tab = 7);
      return;
    }
    if (action == 'cancelled') {
      _showOrders('Cancelled');
      return;
    }
    if (action == 'profile') {
      await _showProfile();
      return;
    }
    if (action == 'logout') {
      await _logout();
      return;
    }
    if (action == 'requests') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Theme(
            data: operationsTheme(),
            child: const Scaffold(
              appBar: null,
              body: SafeArea(child: OperationsRequests()),
            ),
          ),
        ),
      );
      return;
    }
    try {
      final data = await ref.read(adminDashboardProvider.future);
      if (!mounted) return;
      final facet = action == 'categories' || action == 'brands';
      final values = List<String>.from(data[action] ?? []);
      final store = Map<String, dynamic>.from(data['store'] ?? {});
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  facet
                      ? action == 'categories'
                            ? 'Categories'
                            : 'Brands'
                      : action == 'slots'
                      ? 'Delivery Slots'
                      : 'Store Settings',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                if (facet) ...[
                  if (values.isEmpty)
                    const OpsEmpty(
                      'No data yet',
                      'Categories and brands come from your saved products.',
                    ),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final value in values)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Card(
                              child: ListTile(
                                leading: AdminIcon(
                                  action == 'categories'
                                      ? Icons.category_outlined
                                      : Icons.sell_outlined,
                                  color: action == 'categories'
                                      ? opsForestGreen
                                      : opsInfo,
                                  background: action == 'categories'
                                      ? opsMint
                                      : opsInfoBg,
                                ),
                                title: Text(value),
                                subtitle: const Text('Browse products'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  setState(() {
                                    _tab = 2;
                                    _productFilter = 'all';
                                    _productSearch = '';
                                    _productSearchInput.clear();
                                    _productCategory = action == 'categories'
                                        ? value
                                        : null;
                                    _productBrand = action == 'brands'
                                        ? value
                                        : null;
                                  });
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ] else if (action == 'slots') ...[
                  OpsEmpty(
                    store['delivery_mode'] == 'on_demand'
                        ? 'On-demand delivery'
                        : 'No delivery slots configured',
                    'Set an arrival estimate on each assigned order. There are no scheduled delivery slots to manage.',
                    icon: Icons.schedule,
                  ),
                ] else ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const AdminIcon(Icons.storefront_outlined),
                    title: const Text('Store'),
                    subtitle: Text('${store['name'] ?? 'No data yet'}'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const AdminIcon(
                      Icons.payments_outlined,
                      background: opsInfoBg,
                      color: opsInfo,
                    ),
                    title: const Text('Payment'),
                    subtitle: Text(
                      store['cash_on_delivery'] == true
                          ? 'Cash on delivery'
                          : 'No payment configuration available',
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const AdminIcon(
                      Icons.local_shipping_outlined,
                      background: opsWarningBg,
                      color: opsWarning,
                    ),
                    title: const Text('Delivery charge'),
                    subtitle: Text(
                      store['delivery_charge'] == null
                          ? 'No data yet'
                          : money(amount(store['delivery_charge'])),
                    ),
                  ),
                  const Text(
                    'Current store configuration. Contact your store operator to change these settings.',
                    style: TextStyle(fontSize: 12, color: opsMuted),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) showStoreError(context, e);
    }
  }

  Widget _overview() => OperationsDashboard(
    onOrders: _showOrders,
    onInventory: _showInventory,
    onCategory: _showCategory,
    onAddProduct: () => _editProduct(),
    onCreateEmployee: () => _editPerson(),
    onTeam: () => setState(() => _tab = 5),
    onCash: () => setState(() => _tab = 6),
    onDelivery: () => setState(() => _tab = 3),
    onReports: () => setState(() => _tab = 7),
    onOrder: _openOrder,
    onProduct: _editProduct,
    onReceiveCash: _receiveCash,
  );

  Future<void> _editProduct([StoreProduct? product]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ProductEditorScreen(product: product)),
    );
    if (mounted && result == true) refreshCommerce(ref);
  }

  bool _seedingChecked = false;

  void _checkAndSeedCatalog() {
    if (_seedingChecked || !_signedIn) return;
    _seedingChecked = true;
    _seedCatalogInBackground();
  }

  Future<void> _seedCatalogInBackground() async {
    try {
      final api = ref.read(storeApiProvider);
      if (api.adminToken == null) return;
      final existing = await api.products();
      final existingNames = existing
          .map((p) => p.tamilName.trim().toLowerCase())
          .toSet();

      bool addedAny = false;
      for (final item in kCuratedFortyGroceryProducts) {
        final name = (item['tamil_name'] as String).trim().toLowerCase();
        if (existingNames.contains(name)) continue;

        String? imageId;
        try {
          final dio = api.dio;
          final res = await dio.get<List<int>>(
            item['image_url'] as String,
            options: Options(responseType: ResponseType.bytes),
          );
          if (res.data != null && res.data!.isNotEmpty) {
            final uploadRes = await api.upload(res.data!, '${item['sku']}.jpg');
            imageId = uploadRes['id'] as String?;
          }
        } catch (_) {}

        await api.saveProduct({
          'english_name': item['english_name'],
          'tamil_name': item['tamil_name'],
          'brand': item['brand'],
          'category': item['category'],
          'price': item['price'],
          'stock_kg': item['stock_kg'],
          'unit': item['unit'],
          'description': item['description'],
          'sku': item['sku'],
          'image': ?imageId,
          'is_in_stock': true,
          'is_active': true,
        });
        existingNames.add(name);
        addedAny = true;
      }
      if (addedAny && mounted) {
        refreshCommerce(ref);
      }
    } catch (_) {
      // Background seeder is silent and resilient
    }
  }

  Widget _products() {
    final api = ref.watch(storeApiProvider);
    return PagedFeed<StoreProduct>(
      queryKey: (
        'adminProducts',
        api.adminToken,
        _productFilter,
        _productSearch,
        _productCategory,
        _productBrand,
      ),
      changes: api.feedChanges,
      load: (cursor) => api.productPage(
        cursor: cursor,
        admin: true,
        search: _productSearch,
        publication: ['published', 'hidden'].contains(_productFilter)
            ? _productFilter
            : 'all',
        stockFilter: ['low', 'out'].contains(_productFilter)
            ? _productFilter
            : null,
        category: _productCategory ?? 'All',
        brand: _productBrand,
      ),
      identity: (p) => p.id,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      header: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminWorkflowBanner(
              title: 'Your product catalogue',
              subtitle: 'Add products, check stock and control availability.',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Products',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF15211A),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A05D),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(
                    'Add Product',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  onPressed: () => _editProduct(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDDE8E1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _productSearchInput,
                decoration: const InputDecoration(
                  hintText: 'Search products by name, SKU...',
                  hintStyle: TextStyle(fontSize: 13, color: Color(0xFF69756F)),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Color(0xFF69756F),
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (value) {
                  _productDebounce?.cancel();
                  _productDebounce = Timer(
                    const Duration(milliseconds: 350),
                    () {
                      if (mounted) {
                        setState(() => _productSearch = value.trim());
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final filter in <(String, String)>[
                    ('All', 'all'),
                    ('Published', 'published'),
                    ('Hidden', 'hidden'),
                    ('Low Stock', 'low'),
                    ('Out of Stock', 'out'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          filter.$1,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: _productFilter == filter.$2
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: _productFilter == filter.$2
                                ? Colors.white
                                : const Color(0xFF15211A),
                          ),
                        ),
                        selected: _productFilter == filter.$2,
                        selectedColor: const Color(0xFF16A05D),
                        backgroundColor: Colors.white,
                        surfaceTintColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: _productFilter == filter.$2
                                ? const Color(0xFF16A05D)
                                : const Color(0xFFDDE8E1),
                          ),
                        ),
                        showCheckmark: false,
                        onSelected: (_) =>
                            setState(() => _productFilter = filter.$2),
                      ),
                    ),
                ],
              ),
            ),
            if (_productCategory != null || _productBrand != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F7EE),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFC7EBD4), width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.category_rounded, size: 16, color: Color(0xFF0F7645)),
                      const SizedBox(width: 8),
                      Text(
                        'Category: ',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F7645),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => setState(() {
                          _productCategory = null;
                          _productBrand = null;
                        }),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Color(0xFF16A05D),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      emptyTitle: 'No products in this view',
      emptyMessage: 'Add real products or choose a different filter.',
      itemBuilder: (_, product, _) => OperationsProductCard(
        product: product,
        onEdit: () => _editProduct(product),
        onStock: () => _editStock(product),
        onPublication: () => _togglePublication(product),
      ),
    );
  }

  Future<void> _togglePublication(StoreProduct product) async {
    try {
      await ref.read(storeApiProvider).saveProduct({
        'is_active': !product.published,
      }, id: product.id);
      if (mounted) refreshCommerce(ref);
    } catch (e) {
      if (mounted) showStoreError(context, e);
    }
  }

  Future<void> _editStock(StoreProduct product) async {
    final input = TextEditingController(text: product.stock.toStringAsFixed(2));
    var available = product.inStock;
    final form = GlobalKey<FormState>();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: const Text('Update stock'),
          content: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.tamilName.isNotEmpty
                      ? product.tamilName
                      : product.englishName,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: input,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Stock quantity',
                  ),
                  validator: (s) {
                    final value = double.tryParse(s ?? '');
                    return value == null ||
                            !value.isFinite ||
                            value < 0 ||
                            value > 99999999
                        ? 'Enter a valid stock quantity'
                        : null;
                  },
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: available,
                  onChanged: (v) => update(() => available = v ?? false),
                  title: const Text('Available for sale'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (form.currentState!.validate()) {
                  Navigator.pop(ctx, {
                    'stock_kg': input.text.trim(),
                    'is_in_stock': available,
                  });
                }
              },
              child: const Text('Save stock'),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      try {
        await ref.read(storeApiProvider).saveProduct(result, id: product.id);
        if (mounted) refreshCommerce(ref);
      } catch (e) {
        if (mounted) showStoreError(context, e);
      }
    }
    // Dialog route can still be completing its closing animation.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    input.dispose();
  }

  Widget _orders() {
    final api = ref.watch(storeApiProvider);
    return PagedFeed<StoreOrder>(
      queryKey: (
        'adminOrders',
        api.adminToken,
        _orderFilter,
        _orderSearch,
        _unassignedOnly,
        _todayOnly,
      ),
      changes: api.feedChanges,
      load: (cursor) => api.orderPage(
        cursor: cursor,
        admin: true,
        status: _orderFilter,
        search: _orderSearch,
        assigned: _unassignedOnly ? 'unassigned' : null,
        date: _todayOnly
            ? DateTime.now().toIso8601String().split('T').first
            : null,
      ),
      onMetadata: (metadata) {
        final counts = Map<String, dynamic>.from(
          metadata['stage_counts'] ?? {},
        );
        counts['All'] = counts.values.fold<int>(
          0,
          (sum, value) => sum + (value as num).toInt(),
        );
        counts['Active'] =
            (counts['All'] as int) -
            ((counts['Delivered'] as num?)?.toInt() ?? 0) -
            ((counts['Cancelled'] as num?)?.toInt() ?? 0);
        if (mounted && counts.toString() != _stageCounts.toString()) {
          setState(() => _stageCounts = counts);
        }
      },
      header: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminWorkflowBanner(
              title: 'Manage orders',
              subtitle: 'Prepare, pack and assign. Your team handles delivery.',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final group in ['Active', 'Delivered', 'Cancelled']) ...[
                  if (group != 'Active') const SizedBox(width: 6),
                  Expanded(
                    child: FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        backgroundColor: _orderGroup == group
                            ? opsForestGreen
                            : Colors.white,
                        foregroundColor: _orderGroup == group
                            ? Colors.white
                            : opsMuted,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 10,
                        ),
                      ),
                      onPressed: () => _showOrders(group),
                      child: Text(group, style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _orderSearchInput,
              focusNode: _orderSearchFocus,
              decoration: const InputDecoration(
                hintText: 'Search order, customer or mobile',
                prefixIcon: Icon(Icons.search, size: 20),
              ),
              onChanged: (value) {
                _searchDebounce?.cancel();
                _searchDebounce = Timer(const Duration(milliseconds: 350), () {
                  if (mounted) {
                    setState(() {
                      _orderSearch = value.trim();
                      _selectedOrders.clear();
                    });
                  }
                });
              },
            ),
            if (_assignmentEmployee != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: InputChip(
                  label: Text('Assign to ${_assignmentEmployee!['name']}'),
                  onDeleted: () => setState(() => _assignmentEmployee = null),
                ),
              ),
            if (_orderGroup == 'Active') ...[
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final stage in <(String, String)>[
                      ('All active', 'Active'),
                      ('New', 'New'),
                      ('Preparing', 'Preparing'),
                      ('Packed', 'Packed'),
                      ('Assigned', 'Assigned'),
                      ('On delivery', 'Out for Delivery'),
                      ('Attempted', 'Delivery Attempted'),
                      ('Delayed', 'Delayed'),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(
                            _stageCounts.containsKey(stage.$2)
                                ? '${stage.$1} (${_stageCounts[stage.$2]})'
                                : stage.$1,
                          ),
                          selected: _orderFilter == stage.$2,
                          onSelected: (_) => setState(() {
                            _orderFilter = stage.$2;
                            _selectedOrders.clear();
                            _selectOrders = false;
                          }),
                        ),
                      ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilterChip(
                    label: const Text('Needs employee'),
                    selected: _unassignedOnly,
                    onSelected: (value) => setState(() {
                      _unassignedOnly = value;
                      _orderFilter = 'Active';
                      _selectedOrders.clear();
                    }),
                  ),
                  FilterChip(
                    label: const Text('Today'),
                    selected: _todayOnly,
                    onSelected: (value) => setState(() {
                      _todayOnly = value;
                      _selectedOrders.clear();
                    }),
                  ),
                  TextButton.icon(
                    onPressed: _batchBusy
                        ? null
                        : () => setState(() {
                            _selectOrders = !_selectOrders;
                            _selectedOrders.clear();
                            if (_selectOrders) _orderFilter = 'Packed';
                          }),
                    icon: Icon(
                      _selectOrders ? Icons.close : Icons.checklist_rounded,
                      size: 16,
                    ),
                    label: Text(
                      _selectOrders ? 'Cancel selection' : 'Select orders',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
            if (![
              'Active',
              'New',
              'Preparing',
              'Packed',
              'Assigned',
              'Out for Delivery',
              'Delivered',
              'Cancelled',
            ].contains(_orderFilter))
              InputChip(
                label: Text(
                  _orderFilter == 'Today Attention'
                      ? 'Needs attention · today'
                      : _orderFilter,
                ),
                onDeleted: () => _showOrders(_orderGroup),
              ),
            if (_selectedOrders.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _batchBusy ? null : _assignSelected,
                    icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                    label: Text(
                      _batchBusy
                          ? 'Assigning…'
                          : 'Assign ${_selectedOrders.length} packed orders',
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      identity: (o) => o.id,
      emptyTitle: 'No orders in this stage',
      emptyMessage: 'Choose another stage or pull down to refresh.',
      itemBuilder: (_, order, _) => _selectOrders && order.status == 'Packed'
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 34,
                  child: Checkbox(
                    value: _selectedOrders.contains(order.id),
                    onChanged: _batchBusy
                        ? null
                        : (value) {
                            if (value == true && _selectedOrders.length >= 50) {
                              showStoreError(
                                context,
                                StoreException(
                                  'Assign up to 50 packed orders at a time.',
                                ),
                              );
                              return;
                            }
                            setState(() {
                              if (value == true) {
                                _selectedOrders.add(order.id);
                              } else {
                                _selectedOrders.remove(order.id);
                              }
                            });
                          },
                  ),
                ),
                Expanded(
                  child: AdminOrderCard(
                    order: order,
                    onTap: () => _openOrder(order),
                    actionLabel: _orderActionLabel(order),
                    onAction: _quickOrderId == null
                        ? () => _quickOrder(order)
                        : null,
                  ),
                ),
              ],
            )
          : AdminOrderCard(
              order: order,
              onTap: () => _openOrder(order),
              actionLabel: _orderActionLabel(order),
              onAction: _quickOrderId == null ? () => _quickOrder(order) : null,
            ),
    );
  }

  String get _orderGroup => _orderFilter == 'Cancelled'
      ? 'Cancelled'
      : [
          'Delivered',
          'Delivered Today',
          'Cash Handover Complete',
          'Pending Handover',
        ].contains(_orderFilter)
      ? 'Delivered'
      : 'Active';

  String _orderActionLabel(StoreOrder order) => switch (order.status) {
    'New' => 'Start Preparing',
    'Preparing' => 'Mark Packed',
    'Packed' =>
      order.data['assigned_to'] == null
          ? 'Assign Employee'
          : 'Waiting for pickup',
    'Out for Delivery' => 'Track delivery',
    'Delivered' =>
      order.paymentStatus == 'collected' &&
              order.data['cash_handover'] == null &&
              order.data['cash_received_directly'] != true
          ? 'Receive cash'
          : 'Completed · view record',
    'Cancelled' => 'View cancellation',
    _ => 'Review order',
  };

  Future<void> _quickOrder(StoreOrder order) async {
    if (_quickOrderId != null) return;
    if (order.status == 'New' || order.status == 'Preparing') {
      final confirmed = await showModalBottomSheet<bool>(
        context: context,
        showDragHandle: true,
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_orderActionLabel(order)} · ${order.shortId}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                for (final item in order.items.take(5))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('${productLabel(item)} x ${item['quantity']}'),
                  ),
                if (order.items.length > 5)
                  Text('+ ${order.items.length - 5} more items'),
                const SizedBox(height: 16),
                Text(
                  order.status == 'Preparing'
                      ? 'Confirm all items are checked and packed before making this order available for pickup.'
                      : 'Accept this order and start preparing the items.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: opsMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(_orderActionLabel(order)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      if (confirmed != true || !mounted) return;
      setState(() => _quickOrderId = order.id);
      try {
        await ref.read(storeApiProvider).updateOrder(order.id, {
          'status': order.nextStatus,
        });
        if (mounted) refreshCommerce(ref);
      } catch (e) {
        if (mounted) showStoreError(context, e);
      } finally {
        if (mounted) setState(() => _quickOrderId = null);
      }
      return;
    }
    if (order.status == 'Packed' && order.data['assigned_to'] == null) {
      final person =
          _assignmentEmployee ?? await showAdminEmployeePicker(context);
      if (person == null || !mounted) return;
      setState(() => _quickOrderId = order.id);
      try {
        await ref.read(storeApiProvider).updateOrder(order.id, {
          'assigned_to': person['id'],
        });
        if (mounted) refreshCommerce(ref);
      } catch (e) {
        if (mounted) showStoreError(context, e);
      } finally {
        if (mounted) setState(() => _quickOrderId = null);
      }
      return;
    }
    if (_orderActionLabel(order) == 'Receive cash' &&
        order.data['assigned_to'] != null) {
      try {
        final person = await ref
            .read(storeApiProvider)
            .employeeRecord(order.data['assigned_to'] as int);
        if (mounted) await _receiveCash(person);
      } catch (e) {
        if (mounted) showStoreError(context, e);
      }
      return;
    }
    await _openOrder(order);
  }

  Future<void> _assignSelected() async {
    if (_batchBusy || _selectedOrders.isEmpty) return;
    final employee =
        _assignmentEmployee ?? await showAdminEmployeePicker(context);
    if (employee == null || !mounted) return;
    setState(() => _batchBusy = true);
    try {
      await ref
          .read(storeApiProvider)
          .assignPackedOrders(_selectedOrders.toList(), employee['id'] as int);
      if (mounted) {
        setState(_selectedOrders.clear);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Packed orders assigned to ${employee['name']}.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) showStoreError(context, e);
    } finally {
      if (mounted) setState(() => _batchBusy = false);
    }
  }

  Future<void> _openOrder(StoreOrder order) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdminOrderScreen(initialOrder: order)),
    );
    if (mounted) refreshCommerce(ref);
  }

  Widget _team() {
    final api = ref.watch(storeApiProvider);
    return PagedFeed<Map<String, dynamic>>(
      queryKey: ('adminTeam', api.adminToken, _teamSearch),
      changes: api.feedChanges,
      load: (cursor) => api.employeePage(cursor: cursor, search: _teamSearch),
      header: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Delivery team',
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _editPerson(),
                  icon: const Icon(Icons.add, size: 17),
                  label: const Text('Employee'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final metric in <(String, String, IconData, Color, Color)>[
                  (
                    'Available',
                    'available',
                    Icons.person_outline,
                    opsForestGreen,
                    opsMint,
                  ),
                  (
                    'On delivery',
                    'on_delivery',
                    Icons.route_outlined,
                    opsInfo,
                    opsInfoBg,
                  ),
                  (
                    'Inactive',
                    'inactive',
                    Icons.person_off_outlined,
                    opsMuted,
                    Color(0xFFEDF1EE),
                  ),
                ])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: AdminMetricCard(
                        label: metric.$1,
                        value:
                            '${ref.watch(adminDashboardProvider).asData?.value['team']?[metric.$2] ?? '—'}',
                        icon: metric.$3,
                        color: metric.$4,
                        background: metric.$5,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _teamSearchInput,
              decoration: const InputDecoration(
                hintText: 'Search name, employee ID or mobile',
                prefixIcon: Icon(Icons.search, size: 20),
              ),
              onChanged: (s) {
                _teamDebounce?.cancel();
                _teamDebounce = Timer(const Duration(milliseconds: 350), () {
                  if (mounted) setState(() => _teamSearch = s.trim());
                });
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      identity: (p) => '${p['id']}',
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      emptyTitle: 'Set up your delivery team',
      emptyMessage:
          'Create real delivery employee accounts and assign their work.',
      emptyAction: 'Create employee',
      onEmptyAction: () => _editPerson(),
      itemBuilder: (_, p, _) => OpsPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: opsGlassMint,
                  child: Text(
                    opsInitial('${p['name'] ?? ''}'),
                    style: const TextStyle(
                      color: opsForestGreen,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${p['name'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${p['employee_code'] ?? 'Complete onboarding'}',
                        style: const TextStyle(fontSize: 11, color: opsMuted),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: AdminStatusBadge(
                    p['is_active'] != true
                        ? 'Inactive'
                        : p['ready_for_deliveries'] != true
                        ? 'Onboarding'
                        : '${p['status']}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${p['phone'] ?? ''}',
              style: const TextStyle(fontSize: 12, color: opsMuted),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: opsBaseCream,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${p['active_orders'] ?? 0} active orders',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      '${money(amount(p['cash_to_handover']))} cash held',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: opsForestGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              children: [
                TextButton.icon(
                  onPressed: () => _editPerson(p),
                  icon: const Icon(Icons.person_outline, size: 16),
                  label: const Text('Profile', style: TextStyle(fontSize: 11)),
                ),
                TextButton.icon(
                  onPressed: p['ready_for_deliveries'] == true
                      ? () => _showOrders('Unassigned', employee: p)
                      : null,
                  icon: const Icon(Icons.route, size: 16),
                  label: const Text('Assign', style: TextStyle(fontSize: 11)),
                ),
                TextButton.icon(
                  onPressed: amount(p['cash_to_handover']) > 0
                      ? () => _receiveCash(p)
                      : null,
                  icon: const Icon(Icons.payments_outlined, size: 16),
                  label: const Text(
                    'Receive cash',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openEmployee(Map<String, dynamic> person) {
    ref.read(activeEmployeeProvider.notifier).setEmployee(person);
    ref.read(activeRoleProvider.notifier).setRole('employee');
  }

  Future<void> _editPerson([Map<String, dynamic>? person]) async {
    final selected = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => Theme(
          data: operationsTheme(),
          child: EmployeeEditorScreen(person: person),
        ),
      ),
    );
    if (!mounted) return;
    ref.invalidate(deliveryTeamProvider);
    if (selected != null) _openEmployee(selected);
  }
}

// Employee portal uses the authenticated delivery API, never the admin feed.
class EmployeeConsoleScreen extends StatelessWidget {
  final Map<String, dynamic>? employee;
  final VoidCallback onSwitchToAdmin;
  const EmployeeConsoleScreen({
    super.key,
    this.employee,
    required this.onSwitchToAdmin,
  });
  @override
  Widget build(BuildContext context) => DeliveryConsoleScreen(
    initialEmployeeCode: employee?['employee_code'] as String?,
    onExit: onSwitchToAdmin,
  );
}

class AdminSignInScreen extends ConsumerStatefulWidget {
  final VoidCallback onSuccess;
  const AdminSignInScreen({super.key, required this.onSuccess});
  @override
  ConsumerState<AdminSignInScreen> createState() => _AdminSignInState();
}

class _AdminSignInState extends ConsumerState<AdminSignInScreen> {
  final _email = TextEditingController(), _password = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _busy = false, _hidden = true;
  String? _error;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate() || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(storeApiProvider).login(_email.text, _password.text);
      if (mounted) widget.onSuccess();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: opsBaseCream,
    appBar: AppBar(
      leading: BackButton(
        color: opsInk,
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        },
      ),
    ),
    body: AdminCanvas(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF087532).withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: opsGlassMint,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.storefront_rounded,
                            color: opsGreen,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Center(
                      child: Text(
                        'AGARAM',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: opsForestGreen,
                          letterSpacing: 2.2,
                        ),
                      ),
                    ),
                    const Center(
                      child: Text(
                        'STORE OPERATIONS',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: opsGreen,
                          letterSpacing: 2.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        'assets/images/storefront-harvest.png',
                        height: 110,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        excludeFromSemantics: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Admin Sign In',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: opsInk,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Sign in to manage inventory, orders, and store staff.',
                      style: TextStyle(
                        color: opsMuted,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 26),
                    TextFormField(
                      controller: _email,
                      enabled: !_busy,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.username],
                      decoration: InputDecoration(
                        labelText: 'Admin email',
                        prefixIcon: const Icon(
                          Icons.person_outline_rounded,
                          color: opsGreen,
                        ),
                        fillColor: opsBaseCream.withOpacity(0.6),
                      ),
                      validator: (s) => (s?.trim().isEmpty ?? true)
                          ? 'Enter your admin email'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      enabled: !_busy,
                      obscureText: _hidden,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _login(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: opsGreen,
                        ),
                        fillColor: opsBaseCream.withOpacity(0.6),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _hidden = !_hidden),
                          icon: Icon(
                            _hidden
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: opsMuted,
                          ),
                        ),
                      ),
                      validator: (s) =>
                          (s?.isEmpty ?? true) ? 'Enter your password' : null,
                    ),
                    const SizedBox(height: 16),
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: opsRedBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: opsRed,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: opsRed,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: _busy ? null : _login,
                        style: FilledButton.styleFrom(
                          backgroundColor: opsGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          _busy ? 'Signing in...' : 'Sign In to Workspace',
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Center(
                      child: Text(
                        'Authorized store staff only.',
                        style: TextStyle(color: opsMuted, fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class ProductEditorScreen extends ConsumerStatefulWidget {
  final StoreProduct? product;
  const ProductEditorScreen({super.key, this.product});
  @override
  ConsumerState<ProductEditorScreen> createState() => _ProductEditorState();
}

class _ProductEditorState extends ConsumerState<ProductEditorScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name,
      _tamil,
      _brand,
      _category,
      _price,
      _stock,
      _unit,
      _description,
      _offer;
  String _imageId = '', _imageUrl = '';
  String _unitKind = 'kg';
  List<String> _categories = [];
  String? _categoryError;
  bool _loadingCategories = true;

  bool _busy = false, _uploading = false, _available = true, _published = true;
  Timer? _nameDebounce;
  int _nameGeneration = 0;
  bool _suggestingName = false, _applyingName = false;
  String _nameHint =
      'Type Tanglish (arisi) or Tamil. Converted names stay editable.';
  bool get _namePending =>
      _suggestingName || (_nameDebounce?.isActive ?? false);
  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.englishName ?? '');
    _tamil = TextEditingController(text: p?.tamilName ?? '');
    _brand = TextEditingController(text: p?.brand ?? '');
    _category = TextEditingController(text: p?.category ?? '');
    _price = TextEditingController(text: p?.mrp.toStringAsFixed(2) ?? '');
    _stock = TextEditingController(text: p?.stock.toStringAsFixed(2) ?? '');
    final unit = RegExp(
      r'^(\d+(?:\.\d+)?)\s*(kg|g)$',
      caseSensitive: false,
    ).firstMatch(p?.unit.trim() ?? '');
    _unitKind = unit?.group(2)?.toLowerCase() ?? 'kg';
    _unit = TextEditingController(text: unit?.group(1) ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _offer = TextEditingController(
      text: p == null ? '' : p.offerPercent.toString(),
    );
    _imageId = p?.imageId ?? '';
    _imageUrl = p?.imageUrl ?? '';
    _available = p?.inStock ?? true;
    _published = p?.published ?? true;
    _tamil.addListener(_queueTamilName);
    _price.addListener(_priceChanged);
    _offer.addListener(_priceChanged);
    _unit.addListener(_priceChanged);
    _loadCategories();
  }

  void _priceChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loadingCategories = true;
      _categoryError = null;
    });
    try {
      final categories = await ref.read(storeApiProvider).productCategories();
      if (!mounted) return;
      setState(() {
        _categories = [...categories];
        if (_category.text.isNotEmpty &&
            !_categories.contains(_category.text)) {
          _categories.add(_category.text);
        }
        if (_category.text.isEmpty && _categories.isNotEmpty) {
          _category.text = _categories.first;
        }
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _categoryError = 'Could not load categories. Tap retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _newCategory() async {
    String input = '';
    final api = ref.read(storeApiProvider);
    bool saving = false;
    String? error;
    final name = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('New grocery category'),
          content: TextField(
            onChanged: (value) => input = value,
            autofocus: true,
            maxLength: 60,
            enabled: !saving,
            decoration: InputDecoration(
              labelText: 'Category name',
              errorText: error,
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (input.trim().isEmpty) {
                        update(() => error = 'Enter a category name');
                        return;
                      }
                      update(() {
                        saving = true;
                        error = null;
                      });
                      try {
                        final name = await api.createProductCategory(
                          input.trim(),
                        );
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext, name);
                        }
                      } catch (_) {
                        if (dialogContext.mounted) {
                          update(() {
                            saving = false;
                            error = 'Could not save category. Try again.';
                          });
                        }
                      }
                    },
              child: Text(saving ? 'Saving...' : 'Save'),
            ),
          ],
        ),
      ),
    );
    if (name != null && mounted) {
      setState(() {
        if (!_categories.contains(name)) _categories.add(name);
        _category.text = name;
      });
    }
  }

  void _queueTamilName() {
    if (_applyingName) return;
    _nameGeneration++;
    _nameDebounce?.cancel();
    setState(() => _suggestingName = false);
    if (RegExp(r'[A-Za-z]').hasMatch(_tamil.text)) {
      _nameDebounce = Timer(
        const Duration(milliseconds: 800),
        _suggestTamilName,
      );
    }
  }

  Future<void> _suggestTamilName() async {
    _nameDebounce?.cancel();
    final input = _tamil.text.trim();
    if (!RegExp(r'[A-Za-z]').hasMatch(input)) return;
    final generation = ++_nameGeneration;
    setState(() => _suggestingName = true);
    try {
      final tamil = await ref.read(storeApiProvider).suggestTamilName(input);
      if (!mounted ||
          generation != _nameGeneration ||
          input != _tamil.text.trim()) {
        return;
      }
      if (tamil != null && tamil.isNotEmpty) {
        _name.text = input;
        _applyingName = true;
        _tamil.value = TextEditingValue(
          text: tamil,
          selection: TextSelection.collapsed(offset: tamil.length),
        );
        _applyingName = false;
        setState(
          () => _nameHint = 'Tamil name converted. Please review the spelling.',
        );
      }
    } catch (_) {
      if (mounted && generation == _nameGeneration) {
        setState(
          () => _nameHint = 'Conversion unavailable. Enter Tamil directly or tap Convert Tamil to retry.',
        );
      }
    } finally {
      if (mounted && generation == _nameGeneration) {
        setState(() => _suggestingName = false);
      }
    }
  }

  @override
  void dispose() {
    _nameGeneration++;
    _nameDebounce?.cancel();
    for (final c in [
      _name,
      _tamil,
      _brand,
      _category,
      _price,
      _stock,
      _unit,
      _description,
      _offer,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _photo() async {
    if (_busy || _uploading) return;
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 88,
      );
      if (image == null || !mounted) return;
      setState(() => _uploading = true);
      final data = await ref
          .read(storeApiProvider)
          .upload(await image.readAsBytes(), image.name);
      if (mounted) {
        setState(() {
          _imageId = data['id'];
          _imageUrl = data['image_url'];
        });
      }
    } catch (e) {
      if (mounted) showStoreError(context, e);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (_busy ||
        _uploading ||
        _namePending ||
        !_form.currentState!.validate()) {
      return;
    }
    if (_imageId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload a product photo before saving.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(storeApiProvider).saveProduct({
        'english_name': _name.text.trim(),
        'tamil_name': _tamil.text.trim(),
        'brand': _brand.text.trim(),
        'category': _category.text.trim(),
        'base_price': _price.text.trim(),
        'offer_percent': _offer.text.trim().isEmpty ? '0' : _offer.text.trim(),
        'stock_kg': double.parse(_stock.text).toStringAsFixed(2),
        'unit': '${_unit.text.trim()} $_unitKind',
        'description': _description.text.trim(),
        'image': _imageId.isEmpty ? null : _imageId,
        'is_in_stock': _available,
        'is_active': _published,
      }, id: widget.product?.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showStoreError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy && !_uploading,
    child: Theme(
      data: operationsTheme(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.product == null ? 'Add new product' : 'Edit product',
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: FilledButton.icon(
              onPressed: _busy || _uploading || _namePending ? null : _save,
              icon: const Icon(Icons.check_rounded, size: 19),
              label: Text(
                _busy
                    ? 'Saving product…'
                    : widget.product == null
                    ? (_published
                          ? 'Save & publish product'
                          : 'Save hidden product')
                    : 'Save changes',
              ),
            ),
          ),
        ),
        body: AdminCanvas(
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                OpsPanel(
                  padding: EdgeInsets.zero,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _busy || _uploading ? null : _photo,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 110,
                            height: 120,
                            decoration: BoxDecoration(
                              color: opsMint,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: opsBorder),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _imageUrl.isNotEmpty
                                ? ProductPhoto(
                                    _imageUrl,
                                    height: 120,
                                    fit: BoxFit.contain,
                                  )
                                : const Icon(
                                    Icons.add_a_photo_outlined,
                                    size: 30,
                                    color: opsForestGreen,
                                  ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _imageUrl.isEmpty
                                      ? 'Product photo'
                                      : 'Change photo',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  '1000 × 1000 recommended\nJPG, PNG or WebP · Max 8 MB',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: opsMuted,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (_uploading)
                                  const LinearProgressIndicator()
                                else
                                  const AdminStatusBadge(
                                    'Product photo required',
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OpsPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const OpsHeading('Basic information'),
                      _field(
                        _tamil,
                        'Product name (Tanglish to Tamil)',
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          return text.isEmpty ||
                                  !RegExp(r'[஀-௿]').hasMatch(text) ||
                                  RegExp(r'[A-Za-z]').hasMatch(text)
                              ? 'Enter a Tamil product name or wait for conversion'
                              : null;
                        },
                      ),
                      if (_suggestingName)
                        const LinearProgressIndicator(minHeight: 2),
                      Text(
                        _nameHint,
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.5,
                          color: opsMuted,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _busy || _uploading || _suggestingName
                              ? null
                              : _suggestTamilName,
                          icon: const Icon(Icons.auto_awesome, size: 16),
                          label: const Text('Convert Tamil'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                OpsPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const OpsHeading('Catalogue'),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              key: ValueKey((
                                'product-category',
                                _category.text,
                                _categories.length,
                              )),
                              initialValue: _categories.contains(_category.text)
                                  ? _category.text
                                  : null,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                              ),
                              items: _categories
                                  .map(
                                    (name) => DropdownMenuItem(
                                      value: name,
                                      child: Text(
                                        name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _busy || _loadingCategories
                                  ? null
                                  : (value) => setState(
                                      () => _category.text = value ?? '',
                                    ),
                              validator: (value) =>
                                  value == null ? 'Select a category' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: _busy || _loadingCategories
                                ? null
                                : _newCategory,
                            icon: const Icon(Icons.add),
                            label: const Text('New Category'),
                          ),
                        ],
                      ),
                      if (_loadingCategories) const LinearProgressIndicator(),
                      if (_categoryError != null)
                        TextButton(
                          onPressed: _loadCategories,
                          child: Text(_categoryError!),
                        ),
                      const SizedBox(height: 16),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'kg', label: Text('kg')),
                          ButtonSegment(value: 'g', label: Text('g')),
                        ],
                        selected: {_unitKind},
                        onSelectionChanged: _busy
                            ? null
                            : (values) =>
                                  setState(() => _unitKind = values.first),
                      ),
                      const SizedBox(height: 12),
                      _field(
                        _unit,
                        'Selling quantity ($_unitKind)',
                        numeric: true,
                        validator: (value) {
                          final quantity = double.tryParse(value ?? '');
                          return quantity == null ||
                                  !quantity.isFinite ||
                                  quantity <= 0 ||
                                  quantity > 99999999 ||
                                  !RegExp(r'^\d+(\.\d{1,2})?$')
                                      .hasMatch(value?.trim() ?? '')
                              ? 'Enter a positive quantity, up to 2 decimals'
                              : null;
                        },
                      ),
                      Text(
                        'Selling unit: ${_unit.text} $_unitKind',
                        style: const TextStyle(color: opsMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                OpsPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const OpsHeading('Pricing & inventory'),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _field(
                              _price,
                              'Price (INR)',
                              numeric: true,
                              validator: (s) {
                                final v = double.tryParse(s ?? '');
                                return v == null ||
                                        !v.isFinite ||
                                        v <= 0 ||
                                        v > 99999999 ||
                                        !RegExp(r'^[0-9]+(\.[0-9]{1,2})?$')
                                            .hasMatch(s?.trim() ?? '')
                                    ? 'Enter a valid price'
                                    : null;
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _field(
                              _stock,
                              'Stock (units)',
                              numeric: true,
                              validator: (s) {
                                final v = double.tryParse(s ?? '');
                                return v == null ||
                                        !v.isFinite ||
                                        v < 0 ||
                                        v > 99999999 ||
                                        !RegExp(r'^\d+(\.\d{1,2})?$')
                                            .hasMatch(s?.trim() ?? '')
                                    ? 'Enter a stock quantity with up to 2 decimals'
                                    : null;
                              },
                            ),
                          ),
                        ],
                      ),
                      _field(
                        _offer,
                        'Offer (%) - optional',
                        numeric: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return null;
                          }
                          final offer = double.tryParse(value);
                          return offer == null ||
                                  !offer.isFinite ||
                                  offer < 0 ||
                                  offer >= 100 ||
                                  !RegExp(r'^\d+(\.\d{1,2})?$')
                                      .hasMatch(value.trim())
                              ? 'Enter a percentage from 0 to 99.99'
                              : null;
                        },
                      ),
                      Builder(
                        builder: (_) {
                          final price = double.tryParse(_price.text) ?? 0;
                          final offer = double.tryParse(_offer.text) ?? 0;
                          if (!price.isFinite ||
                              price <= 0 ||
                              !offer.isFinite ||
                              offer < 0 ||
                              offer >= 100) {
                            return const SizedBox.shrink();
                          }
                          return Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              if (offer > 0) ...[
                                Text(
                                  money(price),
                                  style: const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: opsMuted,
                                  ),
                                ),
                              ],
                              Text(
                                'Selling price ${money(price * (1 - offer / 100))}',
                                style: const TextStyle(
                                  color: opsForestGreen,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                OpsPanel(
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    maintainState: true,
                    title: const Text('More details'),
                    subtitle: const Text('Brand and description'),
                    children: [
                      const SizedBox(height: 12),
                      _field(_brand, 'Brand (optional)'),
                      if (widget.product?.sku.isNotEmpty ?? false)
                        Text('Product code: ${widget.product!.sku}'),
                      _field(_description, 'Product description', lines: 3),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                OpsPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const OpsHeading('Availability'),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Available for purchase'),
                        subtitle: const Text('Stock is checked at checkout.'),
                        value: _available,
                        onChanged: _busy
                            ? null
                            : (v) => setState(() => _available = v),
                      ),
                      const Divider(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Publish in customer store'),
                        subtitle: const Text(
                          'Hidden products stay in inventory and order history.',
                        ),
                        value: _published,
                        onChanged: _busy
                            ? null
                            : (v) => setState(() => _published = v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool numeric = false,
    int lines = 1,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      key: ValueKey(label),
      controller: controller,
      enabled: !_busy && !_uploading,
      maxLines: lines,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : null,
      decoration: InputDecoration(labelText: label),
      validator:
          validator ??
          (s) => required && (s?.trim().isEmpty ?? true)
              ? 'This field is required'
              : null,
    ),
  );
}

const List<Map<String, dynamic>> kCuratedFortyGroceryProducts = [
  {
    'tamil_name': 'பாசுமதி அரிசி',
    'english_name': 'Basmati Rice',
    'category': 'Groceries',
    'brand': 'SK',
    'price': '120.00',
    'stock_kg': '23.00',
    'unit': '1 kg',
    'description': 'Long-grain basmati rice for biryani, pulao and other fragrant rice dishes.',
    'sku': '',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793685421/agaram/products/i47ksc7pgxtmnw5kwhwz.jpg',
  },
  {
    'tamil_name': 'பொன்னி அரிசி',
    'english_name': 'Ponni Boiled Rice',
    'category': 'Groceries',
    'brand': 'Agaram',
    'price': '80.00',
    'stock_kg': '12.00',
    'unit': '1 kg',
    'description': 'Ponni rice for everyday South Indian meals, steamed rice and variety rice dishes.',
    'sku': '',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793685090/agaram/products/j420mhfbqksyory8lf0r.jpg',
  },
  {
    'tamil_name': 'தூய பச்சரிசி',
    'english_name': 'Pure Raw Rice',
    'category': 'Groceries',
    'brand': 'Agaram',
    'price': '65.00',
    'stock_kg': '60.00',
    'unit': '1 kg',
    'description': 'First-grade raw rice for sweet pongal, murukku batter, kozhukattai and temple prasadam.',
    'sku': 'agmp0009',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793940679/agaram/products/t1nms0y2g4hxtpgwk6la.jpg',
  },
  {
    'tamil_name': 'சீரக சம்பா பிரியாணி அரிசி',
    'english_name': 'Seeraga Samba Biryani Rice',
    'category': 'Groceries',
    'brand': 'Agaram',
    'price': '145.00',
    'stock_kg': '40.00',
    'unit': '1 kg',
    'description': 'Traditional tiny grain scented Seeraga Samba rice for authentic Dindigul biryani.',
    'sku': 'agmp0007',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793940680/agaram/products/vpg0yawnujgktsht1ji1.jpg',
  },
  {
    'tamil_name': 'இட்லி அரிசி',
    'english_name': 'Special Idli Rice',
    'category': 'Groceries',
    'brand': 'Agaram',
    'price': '55.00',
    'stock_kg': '80.00',
    'unit': '1 kg',
    'description': 'Short bold parboiled grain rice designed for extra-soft, spongy idlis and dosas.',
    'sku': 'agmp0008',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793940683/agaram/products/k4hcqiuzbxjyr0dlpgs4.jpg',
  },
  {
    'tamil_name': 'சூரியகாந்தி சமையல் எண்ணெய்',
    'english_name': 'Fortune Sunlite Sunflower Oil',
    'category': 'எண்ணெய் வகைகள்',
    'brand': 'Fortune',
    'price': '140.00',
    'stock_kg': '45.00',
    'unit': '1 L',
    'description': 'Refined sunflower cooking oil enriched with vitamins A & D for healthy everyday cooking.',
    'sku': 'OIL-SUN-1L',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793879484/agaram/products/m1qgktzdnrvpioy29je9.jpg',
  },
  {
    'tamil_name': 'கோல்ட் வின்னர் கடலை எண்ணெய்',
    'english_name': 'Gold Winner Groundnut Oil',
    'category': 'எண்ணெய் வகைகள்',
    'brand': 'Gold Winner',
    'price': '195.00',
    'stock_kg': '30.00',
    'unit': '1 L',
    'description': 'Filtered traditional groundnut peanut oil for crisp snacks, dosas and deep frying.',
    'sku': 'OIL-GND-1L',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793879495/agaram/products/ke8gvsrcdi9aseifwyx3.jpg',
  },
  {
    'tamil_name': 'இதயம் நல்லெண்ணெய்',
    'english_name': 'Idhayam Gingelly Sesame Oil',
    'category': 'எண்ணெய் வகைகள்',
    'brand': 'Idhayam',
    'price': '240.00',
    'stock_kg': '45.00',
    'unit': '1 kg',
    'description': 'First-press sesame gingelly oil for traditional South Indian gravies, dosas and podis.',
    'sku': 'agmp0034',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793940674/agaram/products/jzol5xtggts8yzywv6ao.jpg',
  },
  {
    'tamil_name': 'நந்தினி சுத்தமான பசு நெய்',
    'english_name': 'Nandini Pure Cow Ghee',
    'category': 'எண்ணெய் வகைகள்',
    'brand': 'Nandini',
    'price': '285.00',
    'stock_kg': '35.00',
    'unit': '500 g',
    'description': 'Golden granular aromatic pure cow ghee for sweets, pongal, dosas and daily meals.',
    'sku': 'agmp0036',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793940677/agaram/products/akprjnznasskpkk9oxsl.jpg',
  },
  {
    'tamil_name': 'விவிடி தூய தேங்காய் எண்ணெய்',
    'english_name': 'VVD Pure Coconut Oil',
    'category': 'எண்ணெய் வகைகள்',
    'brand': 'VVD',
    'price': '160.00',
    'stock_kg': '30.00',
    'unit': '500 g',
    'description': '100% pure filtered coconut oil for Kerala & South Indian cooking, avial and baking.',
    'sku': 'agmp0035',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793940685/agaram/products/tglgs2lyz4n5ve4crqgn.jpg',
  },
  {
    'tamil_name': 'கருப்பு கொண்டைக்கடலை',
    'english_name': 'Black Chickpeas Kala Chana',
    'category': 'பருப்பு வகைகள்',
    'brand': 'Tata Sampann',
    'price': '85.00',
    'stock_kg': '40.00',
    'unit': '1 kg',
    'description': 'Protein-dense brown unpolished kala chana for sundal, kadala curry and healthy sprouts.',
    'sku': 'agmp0058',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793941669/agaram/products/grllrulo70mx8pwmddfa.png',
  },
  {
    'tamil_name': 'கருப்பு உளுந்து',
    'english_name': 'Black Urad Dal Whole',
    'category': 'பருப்பு வகைகள்',
    'brand': 'Tata Sampann',
    'price': '68.00',
    'stock_kg': '45.00',
    'unit': '1 kg',
    'description': 'Whole black gram with skin intact for traditional ulundhu kali, healthy porridge and dal makhani.',
    'sku': 'agmp0061',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793941678/agaram/products/thju0jkfe1gbu3ojxd8q.png',
  },
  {
    'tamil_name': 'கடலைப்பருப்பு',
    'english_name': 'Chana Dal Premium',
    'category': 'பருப்பு வகைகள்',
    'brand': 'Agaram',
    'price': '60.00',
    'stock_kg': '30.00',
    'unit': '2',
    'description': 'Split Bengal gram for paruppu vadai, kootu, chutneys and tempering.',
    'sku': '',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793796147/agaram/products/upm7lcfytez74ggo5vur.jpg',
  },
  {
    'tamil_name': 'பச்சைப் பயறு',
    'english_name': 'Green Gram',
    'category': 'பருப்பு வகைகள்',
    'brand': '',
    'price': '75.00',
    'stock_kg': '27.00',
    'unit': '3',
    'description': 'Whole mung beans for sundal, curries, pesarattu and sprouted preparations.',
    'sku': '',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793796234/agaram/products/xhqidpj3u4ebrzhiqyfg.jpg',
  },
  {
    'tamil_name': 'வெள்ளை கொண்டைக்கடலை',
    'english_name': 'Kabuli White Chickpeas',
    'category': 'பருப்பு வகைகள்',
    'brand': 'Tata Sampann',
    'price': '110.00',
    'stock_kg': '35.00',
    'unit': '1 kg',
    'description': 'Plump tender white kabuli chickpeas for restaurant-style chana masala, sundal and salads.',
    'sku': 'agmp0059',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793941671/agaram/products/prg2lqicgsuqu6wlwzop.jpg',
  },
  {
    'tamil_name': 'பாசிப்பருப்பு',
    'english_name': 'Moong Dal Yellow',
    'category': 'பருப்பு வகைகள்',
    'brand': 'Agaram',
    'price': '80.00',
    'stock_kg': '13.00',
    'unit': '2',
    'description': 'Yellow split mung beans for pongal, kootu, dal and payasam.',
    'sku': '',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793796061/agaram/products/uxfd1jbpc3foput0thki.jpg',
  },
  {
    'tamil_name': 'மசூர் பருப்பு',
    'english_name': 'Red Masoor Dal Split',
    'category': 'பருப்பு வகைகள்',
    'brand': 'Tata Sampann',
    'price': '72.00',
    'stock_kg': '35.00',
    'unit': '1 kg',
    'description': 'Quick-cooking split red masoor lentils rich in protein and fiber for hearty sambar and soup.',
    'sku': 'agmp0062',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793941680/agaram/products/ikutgrr6pvnlpvehtvii.png',
  },
  {
    'tamil_name': 'துவரம்பருப்பு',
    'english_name': 'Toor Dal Premium',
    'category': 'பருப்பு வகைகள்',
    'brand': 'Agaram',
    'price': '200.00',
    'stock_kg': '46.00',
    'unit': '1',
    'description': 'Split pigeon peas for preparing sambar, dal and traditional lentil dishes.',
    'sku': '',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793703133/agaram/products/lttld3dljf0jz8ai8a3q.jpg',
  },
  {
    'tamil_name': 'உளுத்தம் பருப்பு',
    'english_name': 'Urad Dal Whole White',
    'category': 'பருப்பு வகைகள்',
    'brand': 'Agaram',
    'price': '60.00',
    'stock_kg': '44.00',
    'unit': '1',
    'description': 'Split, skinned black gram for idli and dosa batter, tempering and traditional recipes.',
    'sku': '',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793703335/agaram/products/h1xy0wu5p4dqfjwkzfw4.jpg',
  },
  {
    'tamil_name': '3 ரோஸஸ் தேயிலை',
    'english_name': 'Brooke Bond 3 Roses Tea',
    'category': 'பானங்கள்',
    'brand': '3 Roses',
    'price': '185.00',
    'stock_kg': '40.00',
    'unit': '250 g',
    'description': 'Perfect blend of color and strength for an invigorating cup of South Indian milk tea.',
    'sku': 'agmp0046',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793940673/agaram/products/lsovtlashgp6ebf5tljp.jpg',
  },
  {
    'tamil_name': 'தாஜ் மஹால் தேயிலை',
    'english_name': 'Brooke Bond Taj Mahal Tea',
    'category': 'பானங்கள்',
    'brand': 'Taj Mahal',
    'price': '210.00',
    'stock_kg': '40.00',
    'unit': '250g',
    'description': 'Exquisite tea crafted from fine tea leaves with golden liquor and invigorating aroma.',
    'sku': 'BEV-TAJ-250G',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793879493/agaram/products/ff4gikymku0houuf3cnt.jpg',
  },
  {
    'tamil_name': 'புரூ இன்ஸ்டண்ட் காபி தூள்',
    'english_name': 'Bru Instant Coffee',
    'category': 'பானங்கள்',
    'brand': 'Bru',
    'price': '190.00',
    'stock_kg': '35.00',
    'unit': '100g',
    'description': 'Rich blend of fine robusta and arabica coffee beans with chicory for aromatic South Indian filter taste.',
    'sku': 'BEV-BRU-100G',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793879491/agaram/products/iktnogkhc3pftdkbsdny.jpg',
  },
  {
    'tamil_name': 'ரெட் லேபிள் தேயிலை',
    'english_name': 'Red Label Natural Care Tea',
    'category': 'பானங்கள்',
    'brand': 'Red Label',
    'price': '190.00',
    'stock_kg': '35.00',
    'unit': '250 g',
    'description': 'Infused with ayurvedic herbs like tulsi, ginger and mulethi for natural immunity and health.',
    'sku': 'agmp0047',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793940709/agaram/products/pmtb3w2hhtsnxecodpot.jpg',
  },
  {
    'tamil_name': 'ஆச்சி மிளகுத் தூள்',
    'english_name': 'Aachi Black Pepper Powder',
    'category': 'மசாலா வகைகள்',
    'brand': 'Aachi',
    'price': '62.00',
    'stock_kg': '40.00',
    'unit': '50g',
    'description': 'Finely ground Malabar black pepper powder delivering sharp pungency and warmth.',
    'sku': 'SPICE-PEP-50G',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793879494/agaram/products/nfq401i5u12wpdqitr5f.jpg',
  },
  {
    'tamil_name': 'ஆச்சி மல்லித் தூள்',
    'english_name': 'Aachi Coriander Powder',
    'category': 'மசாலா வகைகள்',
    'brand': 'Aachi',
    'price': '42.00',
    'stock_kg': '40.00',
    'unit': '200 g',
    'description': 'Pure roasted coriander seeds dhaniya powder for rich curry aroma and thick gravy.',
    'sku': 'agmp0037',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793940665/agaram/products/fyebwb233zhlcpc60lzg.jpg',
  },
  {
    'tamil_name': 'ஆச்சி சீரகத் தூள்',
    'english_name': 'Aachi Cumin Powder',
    'category': 'மசாலா வகைகள்',
    'brand': 'Aachi',
    'price': '68.00',
    'stock_kg': '45.00',
    'unit': '100g',
    'description': 'Fragrant pure ground jeera cumin powder, essential for rasam, curries and tadka.',
    'sku': 'SPICE-JEE-100G',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793879497/agaram/products/dd8uigu5yxxfemo7skog.jpg',
  },
  {
    'tamil_name': 'ஆச்சி கரம் மசாலா',
    'english_name': 'Aachi Garam Masala',
    'category': 'மசாலா வகைகள்',
    'brand': 'Aachi',
    'price': '45.00',
    'stock_kg': '35.00',
    'unit': '100 g',
    'description': 'Special aromatic whole spice blend of cinnamon, cardamom and cloves for biryani and curries.',
    'sku': 'agmp0038',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793940667/agaram/products/n68q14ndrovz7o8lrizk.jpg',
  },
  {
    'tamil_name': 'மிளகாய்த் தூள்',
    'english_name': 'Aachi Red Chilli Powder',
    'category': 'மசாலா வகைகள்',
    'brand': 'Aachi',
    'price': '50.00',
    'stock_kg': '29.00',
    'unit': '1kg',
    'description': 'Ground red chilli powder for adding heat and colour to curries, gravies and marinades.',
    'sku': '',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793872493/agaram/products/if6em4lwi9iijhc7pafi.jpg',
  },
  {
    'tamil_name': 'ஆச்சி சாம்பார் பொடி',
    'english_name': 'Aachi Sambar Powder',
    'category': 'மசாலா வகைகள்',
    'brand': 'Aachi',
    'price': '38.00',
    'stock_kg': '50.00',
    'unit': '100g',
    'description': 'Authentic South Indian aromatic sambar masala blend crafted with premium roasted spices.',
    'sku': 'SPICE-SAM-100G',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793879489/agaram/products/mv7pg7bht3zhnhf3bdod.jpg',
  },
  {
    'tamil_name': 'மஞ்சள் தூள்',
    'english_name': 'Aachi Turmeric Powder',
    'category': 'மசாலா வகைகள்',
    'brand': 'Aachi',
    'price': '15.00',
    'stock_kg': '49.00',
    'unit': '500g',
    'description': 'Ground turmeric for adding its characteristic golden colour and earthy flavour to everyday cooking.',
    'sku': '',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793872855/agaram/products/qkvuixdgyleknsebnpep.jpg',
  },
  {
    'tamil_name': 'சோம்பு',
    'english_name': 'Fennel Seeds Perunjeeragam',
    'category': 'மசாலா வகைகள்',
    'brand': 'Tata Sampann',
    'price': '45.00',
    'stock_kg': '30.00',
    'unit': '100 g',
    'description': 'Sweet fragrant whole fennel seeds for biryani, non-veg curries and after-meal digestion.',
    'sku': 'agmp0056',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793941663/agaram/products/xojee3kjtgszwgtsxekx.png',
  },
  {
    'tamil_name': 'வெந்தயம்',
    'english_name': 'Fenugreek Seeds Venthayam',
    'category': 'மசாலா வகைகள்',
    'brand': 'Tata Sampann',
    'price': '32.00',
    'stock_kg': '35.00',
    'unit': '200 g',
    'description': 'Golden aromatic fenugreek seeds for cooling vendhaya kali, kara kulambu and idli batter.',
    'sku': 'agmp0055',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793941660/agaram/products/n1g0fgjaxkxwxopd5tnp.png',
  },
  {
    'tamil_name': 'ஏலக்காய்',
    'english_name': 'Green Cardamom Elakkai',
    'category': 'மசாலா வகைகள்',
    'brand': 'Tata Sampann',
    'price': '135.00',
    'stock_kg': '15.00',
    'unit': '50 g',
    'description': 'Fragrant green cardamom whole pods for royal South Indian payasam, kesari and chai.',
    'sku': 'agmp0054',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793941656/agaram/products/yprbjmi3uyyaiyiduktq.png',
  },
  {
    'tamil_name': 'எல்.ஜி பெருங்காயத் தூள்',
    'english_name': 'LG Compounded Asafoetida',
    'category': 'மசாலா வகைகள்',
    'brand': 'LG',
    'price': '55.00',
    'stock_kg': '50.00',
    'unit': '50 g',
    'description': 'Aromatic hing powder for comforting digestion, sambar, rasam and tempering.',
    'sku': 'agmp0039',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793940676/agaram/products/kdi7bmuipjlvuzggoblq.jpg',
  },
  {
    'tamil_name': 'கடுகு',
    'english_name': 'Mustard Seeds Kadugu',
    'category': 'மசாலா வகைகள்',
    'brand': 'Tata Sampann',
    'price': '35.00',
    'stock_kg': '40.00',
    'unit': '200 g',
    'description': 'Crisp pungent small black mustard seeds essential for South Indian tempering and pickles.',
    'sku': 'agmp0051',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793941646/agaram/products/nw2cvkwgrp2vkdly6abo.png',
  },
  {
    'tamil_name': 'கிராம்பு',
    'english_name': 'Whole Cloves Krambu',
    'category': 'மசாலா வகைகள்',
    'brand': 'Tata Sampann',
    'price': '95.00',
    'stock_kg': '20.00',
    'unit': '50 g',
    'description': 'Premium aromatic whole cloves for fragrant biryani, kashayam, chai and spice tempering.',
    'sku': 'agmp0053',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793941652/agaram/products/cir7jifsedxoofwhx0zk.png',
  },
  {
    'tamil_name': 'சீரகம்',
    'english_name': 'Whole Jeera Cumin Seeds',
    'category': 'மசாலா வகைகள்',
    'brand': 'Tata Sampann',
    'price': '75.00',
    'stock_kg': '35.00',
    'unit': '200 g',
    'description': 'Aromatic whole cumin seeds for tempering, jeera rice, rasam and digestive health.',
    'sku': 'agmp0052',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793941649/agaram/products/vrd9vo2czcq5mc7up5nz.png',
  },
  {
    'tamil_name': 'ஆச்சி குலாப் ஜாமூன் மிக்ஸ்',
    'english_name': 'Aachi Gulab Jamun Ready Mix',
    'category': 'மளிகைப் பொருட்கள்',
    'brand': 'Aachi',
    'price': '70.00',
    'stock_kg': '35.00',
    'unit': '200 g',
    'description': 'Delicious instant sweet mix yielding 40 soft melt-in-mouth gulab jamuns.',
    'sku': 'agmp0048',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793940708/agaram/products/t0dv92qqbdfenty0vuxy.jpg',
  },
  {
    'tamil_name': 'தூய வெள்ளை சர்க்கரை',
    'english_name': 'Pure Refined White Sugar',
    'category': 'மளிகைப் பொருட்கள்',
    'brand': 'Agaram',
    'price': '48.00',
    'stock_kg': '80.00',
    'unit': '1 kg',
    'description': 'Sparkling white sulphur-free refined sugar crystals for sweets, beverages and daily tea.',
    'sku': 'SUG-WHT-1KG',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793879490/agaram/products/x9u4zmnalfjvz1ry8rat.jpg',
  },
  {
    'tamil_name': 'வேர்க்கடலை / நிலக்கடலை',
    'english_name': 'Raw Peanuts Groundnuts',
    'category': 'மளிகைப் பொருட்கள்',
    'brand': 'Tata Sampann',
    'price': '95.00',
    'stock_kg': '50.00',
    'unit': '1 kg',
    'description': 'Selected raw shelled whole pink groundnuts for roasting, peanut chutney, chikki and rice.',
    'sku': 'agmp0060',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793941675/agaram/products/pqf5fvo9q14fapwc4vt4.png',
  },
  {
    'tamil_name': 'டாடா உப்பு',
    'english_name': 'Tata Salt Vacuum Evaporated Iodised',
    'category': 'மளிகைப் பொருட்கள்',
    'brand': 'Tata',
    'price': '28.00',
    'stock_kg': '60.00',
    'unit': '1 kg',
    'description': 'Desh ka Namak, vacuum evaporated iodised salt for purity and optimal iodine nutrition.',
    'sku': 'SALT-TAT-1KG',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793879487/agaram/products/dbvnhdnh6trqzajofeeq.jpg',
  },
  {
    'tamil_name': 'கெட்டி அவல்',
    'english_name': 'Thick White Poha Aval',
    'category': 'மளிகைப் பொருட்கள்',
    'brand': 'Tata Sampann',
    'price': '42.00',
    'stock_kg': '45.00',
    'unit': '500 g',
    'description': 'Wholesome thick flattened rice flakes for quick breakfast upma, aval payasam and mixture.',
    'sku': 'agmp0057',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793941666/agaram/products/pv3duau6avde6dtdbkrs.png',
  },
  {
    'tamil_name': 'பஜ்ஜி போண்டா மாவு மிக்ஸ்',
    'english_name': 'Aachi Bajji Bonda Flour Mix',
    'category': 'மாவு வகைகள்',
    'brand': 'Aachi',
    'price': '45.00',
    'stock_kg': '40.00',
    'unit': '500 g',
    'description': 'Authentic South Indian spiced ready mix for crispy golden onion pakoda, raw banana and potato bajjis.',
    'sku': 'agmp0064',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793941685/agaram/products/c4yjyhoaewnycwmbmvos.png',
  },
  {
    'tamil_name': 'அனில் வறுக்காத சேமியா',
    'english_name': 'Anil Plain Vermicelli Semiya',
    'category': 'மாவு வகைகள்',
    'brand': 'Anil',
    'price': '45.00',
    'stock_kg': '55.00',
    'unit': '500g',
    'description': 'Non-sticky wheat vermicelli semiya for preparing traditional payasam, upma and kheer.',
    'sku': 'FLOUR-SEM-500G',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793879496/agaram/products/gb26xnpl0otoroa0avxd.jpg',
  },
  {
    'tamil_name': 'வறுத்த ரவை',
    'english_name': 'Double Roasted Sooji Rava',
    'category': 'மாவு வகைகள்',
    'brand': 'Naga',
    'price': '52.00',
    'stock_kg': '40.00',
    'unit': '500 g',
    'description': 'Hygienically roasted durum wheat semolina for quick lump-free rava kesari and upma.',
    'sku': 'agmp0028',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793940681/agaram/products/m5tzbue5ojnhzbpln3sb.jpg',
  },
  {
    'tamil_name': 'இடியாப்ப அரிசி மாவு',
    'english_name': 'Idiyappam Rice Flour',
    'category': 'மாவு வகைகள்',
    'brand': 'Anil',
    'price': '48.00',
    'stock_kg': '35.00',
    'unit': '500 g',
    'description': 'Steamed fine white rice flour for smooth string hoppers idiyappam and kozhukattai.',
    'sku': 'agmp0029',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793940669/agaram/products/xhuevgxu6eczy0qyyvvo.jpg',
  },
  {
    'tamil_name': 'மைதா மாவு',
    'english_name': 'Naga Maida Flour',
    'category': 'மாவு வகைகள்',
    'brand': 'Naga',
    'price': '46.00',
    'stock_kg': '30.00',
    'unit': '500 g',
    'description': 'Premium high-stretch refined wheat flour for flaky layered Malabar parotta, samosas and sweets.',
    'sku': 'agmp0065',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793941686/agaram/products/omssnnegttrsq9thb3ou.png',
  },
  {
    'tamil_name': 'கடலை மாவு',
    'english_name': 'Pure Besan Gram Flour',
    'category': 'மாவு வகைகள்',
    'brand': 'Agaram',
    'price': '58.00',
    'stock_kg': '40.00',
    'unit': '500 g',
    'description': 'Finely ground 100% Bengal gram flour for bajji, bonda, pakoda and festive sweets.',
    'sku': 'agmp0030',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793940671/agaram/products/zldsdzphzfswf18c1n1y.jpg',
  },
  {
    'tamil_name': 'கேழ்வரகு மாவு',
    'english_name': 'Pure Ragi Flour',
    'category': 'மாவு வகைகள்',
    'brand': 'Tata Sampann',
    'price': '55.00',
    'stock_kg': '35.00',
    'unit': '500 g',
    'description': '100% whole grain finger millet ragi flour rich in calcium for soft ragi dosa, adai and puttu.',
    'sku': 'agmp0063',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793941683/agaram/products/pcr1jkvgqtyplezdliks.png',
  },
  {
    'tamil_name': 'கோதுமை மாவு',
    'english_name': 'Whole wheat Atta',
    'category': 'மாவு வகைகள்',
    'brand': '',
    'price': '100.00',
    'stock_kg': '49.00',
    'unit': '3',
    'description': 'Whole wheat flour for preparing chapati, roti, paratha and other wheat-based dishes.',
    'sku': '',
    'image_url': 'https://res.cloudinary.com/kbs5o32p/image/upload/v1793796369/agaram/products/gratz210bp6th63esbow.jpg',
  },
];

class AdminOrderScreen extends ConsumerStatefulWidget {
  final StoreOrder initialOrder;
  const AdminOrderScreen({super.key, required this.initialOrder});
  @override
  ConsumerState<AdminOrderScreen> createState() => _AdminOrderState();
}

class _AdminOrderState extends ConsumerState<AdminOrderScreen> {
  late StoreOrder _order;
  int? _person;
  String _personName = '';
  bool _busy = false;
  Timer? _detailPoll;
  String? _refreshError;
  final _note = TextEditingController(), _minutes = TextEditingController();
  @override
  void initState() {
    super.initState();
    _order = widget.initialOrder;
    _person = _order.data['assigned_to'];
    _personName = '${_order.data['assigned_to_details']?['name'] ?? ''}';
    _note.text = _order.data['delivery_note'] ?? '';
    _reloadOrder();
    _detailPoll = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!_busy) _reloadOrder();
    });
  }

  Future<void> _reloadOrder() async {
    try {
      final order = await ref.read(storeApiProvider).adminOrder(_order.id);
      if (mounted) {
        setState(() {
          _order = order;
          _person = order.data['assigned_to'];
          _personName = '${order.data['assigned_to_details']?['name'] ?? ''}';
          _refreshError = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _refreshError =
              'Could not refresh this order. Refresh before changing it.',
        );
      }
    }
  }

  @override
  void dispose() {
    _detailPoll?.cancel();
    _note.dispose();
    _minutes.dispose();
    super.dispose();
  }

  Future<void> _update({
    String? next,
    Map<String, dynamic> extra = const {},
  }) async {
    if (_busy) return;
    final minutes = _minutes.text.trim().isEmpty
        ? null
        : int.tryParse(_minutes.text);
    if (_minutes.text.trim().isNotEmpty &&
        (minutes == null || minutes <= 0 || minutes > 1440)) {
      showStoreError(
        context,
        StoreException('Use an arrival estimate between 1 and 1440 minutes.'),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final updated = await ref.read(storeApiProvider).updateOrder(_order.id, {
        'status': ?next,
        if (_person != null) 'assigned_to': _person,
        'delivery_note': _note.text.trim(),
        if (minutes != null)
          'estimated_delivery_at': DateTime.now()
              .add(Duration(minutes: minutes))
              .toUtc()
              .toIso8601String(),
        ...extra,
      });
      if (mounted) {
        setState(() {
          _order = updated;
          _person = updated.data['assigned_to'];
          _personName = '${updated.data['assigned_to_details']?['name'] ?? ''}';
          _refreshError = null;
          _minutes.clear();
          _note.text = updated.data['delivery_note'] ?? '';
        });
      }
      ref.invalidate(adminOrdersProvider);
      ref.invalidate(adminDashboardProvider);
      ref.invalidate(deliveryTeamProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Order updated. The customer can see the latest status.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) showStoreError(context, e);
      if (mounted) await _reloadOrder();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _advance() async {
    final next = _order.nextStatus;
    if (next == 'Delivered') {
      final extra = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) => OrderActionDialog(
          kind: _order.paymentStatus == 'cod' ? 'cash' : 'delivery',
          total: _order.total,
          adminAssistance: true,
        ),
      );
      if (extra != null && mounted) await _update(next: next, extra: extra);
    } else {
      await _update(next: next);
    }
  }

  Future<void> _recordAttempt() async {
    final extra = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const OrderActionDialog(kind: 'attempt'),
    );
    if (extra != null && mounted) {
      await _update(next: 'Delivery Attempted', extra: extra);
    }
  }

  Future<void> _cancelOrder() async {
    final extra = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => OrderActionDialog(
        kind: 'cancel',
        requireReturn: _order.status != 'New',
      ),
    );
    if (extra != null && mounted) {
      await _update(next: 'Cancelled', extra: extra);
    }
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: operationsTheme(),
    child: Scaffold(
      appBar: AppBar(
        title: Text('Order ${_order.shortId}'),
        actions: [
          IconButton(
            tooltip: 'Refresh order',
            onPressed: _busy ? null : _reloadOrder,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      bottomNavigationBar:
          !_order.canFulfill || !['New', 'Preparing'].contains(_order.status)
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton.icon(
                  onPressed: _busy ? null : _advance,
                  icon: Icon(
                    _order.status == 'New'
                        ? Icons.shopping_bag_outlined
                        : Icons.inventory_2_outlined,
                    size: 18,
                  ),
                  label: Text(
                    _busy
                        ? 'Updating?'
                        : _order.status == 'New'
                        ? 'Accept & start preparing'
                        : 'Items checked ? mark packed',
                  ),
                ),
              ),
            ),
      body: AdminCanvas(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (_refreshError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _refreshError!,
                  style: const TextStyle(color: opsRed),
                ),
              ),
            OpsPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          _order.id,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(child: AdminStatusBadge(_order.status)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    opsTime(_order.data['created_at']),
                    style: const TextStyle(fontSize: 11, color: opsMuted),
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Order total',
                          style: TextStyle(color: opsMuted),
                        ),
                      ),
                      Text(
                        money(_order.total),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  AdminStatusBadge(
                    _order.paymentStatus == 'cod'
                        ? 'Cash due at delivery'
                        : _order.paymentStatus == 'collected'
                        ? 'Cash collected'
                        : _order.paymentStatus,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OpsPanel(
              color: opsMint,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NEXT ACTION',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.2,
                      color: opsForestGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _order.nextAction,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OpsPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const OpsHeading('Order journey'),
                  OrderJourney(order: _order),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OpsPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const OpsHeading('Cash on delivery'),
                  Text(
                    _order.status == 'Cancelled'
                        ? 'Cancelled · no cash due'
                        : _order.paymentStatus == 'collected'
                        ? (_order.data['cash_handover'] != null ||
                                  _order.data['cash_received_directly'] == true
                              ? 'Cash received by store'
                              : 'Cash with delivery employee · handover pending')
                        : _order.paymentStatus == 'cod'
                        ? '${money(_order.total)} to collect from customer'
                        : 'Payment status: ${_order.paymentStatus}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (_order.status == 'Cancelled')
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${_order.data['cancellation_reason'] ?? ''}\nReserved stock has been released.',
                        style: const TextStyle(color: opsMuted, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OpsPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const OpsHeading('Customer & address'),
                  Text(
                    '${_order.data['customer_name'] ?? ''}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    '${_order.data['customer_phone'] ?? ''}\n${_order.data['delivery_address'] ?? ''}',
                    style: const TextStyle(fontSize: 13, height: 1.6),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: () => openDeliveryLink(
                          context,
                          directionsForOrder(_order),
                        ),
                        icon: const Icon(Icons.directions_outlined, size: 17),
                        label: const Text('Google Maps'),
                      ),
                      TextButton.icon(
                        onPressed: () => openDeliveryLink(
                          context,
                          Uri(
                            scheme: 'tel',
                            path: '${_order.data['customer_phone']}',
                          ),
                        ),
                        icon: const Icon(Icons.call_outlined, size: 17),
                        label: const Text('Call customer'),
                      ),
                    ],
                  ),
                  if ('${_order.data['delivery_instructions'] ?? ''}'
                      .isNotEmpty)
                    Text(
                      'Instructions: ${_order.data['delivery_instructions']}',
                      style: const TextStyle(fontSize: 12, color: opsMuted),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OpsPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OpsHeading('Items (${_order.items.length})'),
                  for (final i in _order.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 46,
                            child: ProductPhoto(
                              '${i['image_url'] ?? ''}',
                              height: 46,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  productLabel(i),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '${i['unit']} × ${i['quantity']}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: opsMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            money(amount(i['total_price'])),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (_order.canFulfill) ...[
              const SizedBox(height: 12),
              OpsPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const OpsHeading('Delivery assignment'),
                    Row(
                      children: [
                        const AdminIcon(Icons.delivery_dining),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _personName.isEmpty
                                ? 'No employee assigned'
                                : _personName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _busy || _order.status == 'Out for Delivery'
                            ? null
                            : () async {
                                final employee = await showAdminEmployeePicker(
                                  context,
                                );
                                if (employee != null && mounted) {
                                  setState(() {
                                    _person = employee['id'];
                                    _personName = employee['name'];
                                  });
                                  await _update();
                                }
                              },
                        icon: const Icon(
                          Icons.person_search_outlined,
                          size: 18,
                        ),
                        label: Text(
                          _personName.isEmpty
                              ? 'Choose verified employee'
                              : 'Change assignment',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Employee picks up the packed order from their app and completes delivery with the customer code and exact cash.',
                      style: TextStyle(
                        fontSize: 11,
                        color: opsMuted,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OpsPanel(
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  maintainState: true,
                  title: const Text('Arrival & customer update'),
                  subtitle: const Text(
                    'Set an estimate or send a delivery update',
                  ),
                  children: [
                    const SizedBox(height: 12),
                    TextField(
                      controller: _minutes,
                      enabled: !_busy,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Estimated arrival · minutes (optional)',
                        helperText: '30 means about 30 minutes from saving. Customer sees this estimate in Track my order.',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _note,
                      enabled: !_busy,
                      maxLength: 255,
                      decoration: const InputDecoration(
                        labelText: 'Message to customer (optional)',
                        helperText: 'A delivery update visible to the customer, such as a delay or arrival note.',
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _busy ? null : () => _update(),
                        child: const Text('Save estimate & message'),
                      ),
                    ),
                  ],
                ),
              ),
              if ([
                'Packed',
                'Out for Delivery',
                'Delivery Attempted',
              ].contains(_order.status)) ...[
                const SizedBox(height: 12),
                OpsPanel(
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text('Admin delivery assistance'),
                    subtitle: const Text('Use when helping an employee'),
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          'An assigned, verified employee is required. Completion needs the customer delivery code and exact cash amount.',
                          style: TextStyle(fontSize: 12, color: opsMuted),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _busy || _person == null ? null : _advance,
                          child: Text(
                            _order.status == 'Out for Delivery'
                                ? 'Verify code & cash'
                                : 'Confirm pickup & dispatch',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_order.status == 'Out for Delivery') ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _recordAttempt,
                  icon: const Icon(Icons.report_outlined),
                  label: const Text('Delivery could not be completed'),
                ),
              ],
              if ([
                    'New',
                    'Preparing',
                    'Packed',
                    'Delivery Attempted',
                  ].contains(_order.status) &&
                  _order.paymentStatus == 'cod') ...[
                const SizedBox(height: 12),
                OpsPanel(
                  color: opsRedBg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cancellation',
                        style: TextStyle(
                          color: opsRed,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _busy ? null : _cancelOrder,
                        style: TextButton.styleFrom(foregroundColor: opsRed),
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Cancel order & restore stock'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
              if (_order.status == 'Out for Delivery') ...[
              const SizedBox(height: 12),
              DeliveryTrackingCard(orderId: _order.id, admin: true),
            ],
            if (_order.paymentStatus == 'pending')
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Previous incomplete online checkout. It can be cancelled; new orders use cash on delivery.',
                ),
              ),
            if (_order.paymentStatus == 'review')
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Previous online payment needs manual store review. Check original payment records before fulfillment.',
                ),
              ),
            const SizedBox(height: 16),
            OpsPanel(
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Audit timeline'),
                children: [
                  for (final event in _order.events)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const AdminIcon(
                        Icons.check_circle_outline,
                        size: 30,
                      ),
                      title: Text('${event['status']}'),
                      subtitle: Text('${event['note'] ?? ''}'),
                      trailing: Text(
                        opsTime(event['created_at']),
                        style: const TextStyle(fontSize: 9, color: opsMuted),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
