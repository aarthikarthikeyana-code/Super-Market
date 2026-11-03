import 'dart:async';

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
  bool _batchBusy = false;
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
    if (mounted) setState(() => _signedIn = _api.adminToken != null);
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
                body: switch (_tab) {
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
                floatingActionButton: _tab == 2
                    ? FloatingActionButton.extended(
                        onPressed: () => _editProduct(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add product'),
                      )
                    : _tab == 5
                    ? FloatingActionButton.extended(
                        onPressed: () => _editPerson(),
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        label: const Text('Create Employee'),
                      )
                    : null,
                bottomNavigationBar: NavigationBar(
                  selectedIndex: _tab <= 4 ? _tab : 4,
                  onDestinationSelected: (i) => setState(() => _tab = i),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.space_dashboard_outlined),
                      label: 'Dashboard',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.receipt_long_outlined),
                      label: 'Orders',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.inventory_2_outlined),
                      label: 'Products',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.route_outlined),
                      label: 'Delivery',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.grid_view_outlined),
                      label: 'More',
                    ),
                  ],
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
    final live = data != null && !snapshot.hasError && !snapshot.isLoading;
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 70,
      titleSpacing: 18,
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Agaram',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _tab == 0
                      ? 'Store Operations'
                      : const [
                          'Store Operations',
                          'Orders',
                          'Products',
                          'Delivery Control',
                          'More',
                          'Delivery Team',
                          'Cash Handover',
                          'Reports',
                        ][_tab],
                  style: const TextStyle(fontSize: 10, color: opsMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
            decoration: BoxDecoration(
              color: live ? opsMint : const Color(0xFFEEEFEA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 5, color: live ? opsGreen : opsMuted),
                const SizedBox(width: 4),
                Text(
                  snapshot.hasError
                      ? 'Retry'
                      : live
                      ? 'Live data'
                      : 'Syncing',
                  style: TextStyle(
                    fontSize: 9,
                    color: live ? opsGreen : opsMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Search orders',
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 34),
          onPressed: () {
            setState(() => _tab = 1);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _orderSearchFocus.requestFocus();
            });
          },
          icon: const Icon(Icons.search, size: 21),
        ),
        IconButton(
          tooltip: 'Operational alerts',
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 34),
          onPressed: _showAlerts,
          icon: Badge(
            isLabelVisible: alerts.isNotEmpty,
            label: Text('${alerts.length}'),
            child: const Icon(Icons.notifications_none, size: 21),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: IconButton(
            tooltip: 'Admin profile',
            visualDensity: VisualDensity.compact,
            onPressed: _showProfile,
            icon: CircleAvatar(
              radius: 15,
              backgroundColor: opsMint,
              child: Text(
                profile['name'] == null
                    ? 'AD'
                    : opsInitial('${profile['name']}'),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: opsGreen,
                ),
              ),
            ),
          ),
        ),
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

  Future<void> _receiveCash(Map<String, dynamic> person) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EmployeeCashScreen(person: person)),
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
        showDragHandle: true,
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Admin Profile',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: opsMint,
                    child: Icon(
                      Icons.admin_panel_settings_outlined,
                      color: opsGreen,
                    ),
                  ),
                  title: Text('${profile['name'] ?? 'Admin'}'),
                  subtitle: Text('${profile['email'] ?? ''}'),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.sync),
                  title: const Text('Refresh store data'),
                  onTap: () {
                    Navigator.pop(ctx);
                    refreshCommerce(ref);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout, color: opsRed),
                  title: const Text('Logout'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _logout();
                  },
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
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(value),
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
                    title: const Text('Store'),
                    subtitle: Text('${store['name'] ?? 'No data yet'}'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Payment'),
                    subtitle: Text(
                      store['cash_on_delivery'] == true
                          ? 'Cash on delivery'
                          : 'No payment configuration available',
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
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
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Products',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _productSearchInput,
            decoration: const InputDecoration(
              hintText: 'Search Tamil name, reference or brand',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              _productDebounce?.cancel();
              _productDebounce = Timer(const Duration(milliseconds: 350), () {
                if (mounted) setState(() => _productSearch = value.trim());
              });
            },
          ),
          const SizedBox(height: 10),
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
                    padding: const EdgeInsets.only(right: 7),
                    child: ChoiceChip(
                      label: Text(
                        filter.$1,
                        style: const TextStyle(fontSize: 11),
                      ),
                      selected: _productFilter == filter.$2,
                      onSelected: (_) =>
                          setState(() => _productFilter = filter.$2),
                    ),
                  ),
              ],
            ),
          ),
          if (_productCategory != null || _productBrand != null)
            InputChip(
              label: Text(_productCategory ?? _productBrand!),
              onDeleted: () => setState(() {
                _productCategory = null;
                _productBrand = null;
              }),
            ),
          const SizedBox(height: 16),
        ],
      ),
      emptyTitle: 'No products in this view',
      emptyMessage: 'Add real products or choose a different filter.',
      emptyAction: 'Add product',
      onEmptyAction: () => _editProduct(),
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
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 8, 18, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Orders',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
          ),
        ),
        if (_assignmentEmployee != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: InputChip(
              label: Text('Assign to ${_assignmentEmployee!['name']}'),
              onDeleted: () => setState(() => _assignmentEmployee = null),
            ),
          ),
        if ([
          'Delivered Today',
          'Today Attention',
          'Delayed',
          'Cash Handover Complete',
          'Pending Handover',
          'Cash Review',
        ].contains(_orderFilter))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Align(
              alignment: Alignment.centerLeft,
              child: InputChip(
                label: Text(_orderFilter),
                onDeleted: () => _showOrders('Active'),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: TextField(
            controller: _orderSearchInput,
            focusNode: _orderSearchFocus,
            decoration: const InputDecoration(
              hintText: 'Search order, customer, phone or address',
              prefixIcon: Icon(Icons.search),
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
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              FilterChip(
                label: const Text('Needs employee'),
                selected: _unassignedOnly,
                onSelected: (v) => setState(() {
                  _unassignedOnly = v;
                  _orderFilter = 'Active';
                  _selectedOrders.clear();
                }),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Today'),
                selected: _todayOnly,
                onSelected: (v) => setState(() {
                  _todayOnly = v;
                  _selectedOrders.clear();
                }),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              for (final status in [
                'Active',
                'All',
                'New',
                'Preparing',
                'Packed',
                'Assigned',
                'Out for Delivery',
                'Delivery Attempted',
                'Delivered',
                'Cancelled',
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      _stageCounts.containsKey(status)
                          ? '$status (${_stageCounts[status]})'
                          : status,
                    ),
                    selected: _orderFilter == status,
                    onSelected: (_) => setState(() {
                      _orderFilter = status;
                      _selectedOrders.clear();
                    }),
                  ),
                ),
            ],
          ),
        ),
        if (_selectedOrders.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _batchBusy ? null : _assignSelected,
                    icon: const Icon(Icons.group_add_outlined),
                    label: Text(
                      _batchBusy
                          ? 'Assigning...'
                          : 'Assign ${_selectedOrders.length} packed orders',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _batchBusy
                      ? null
                      : () => setState(_selectedOrders.clear),
                  tooltip: 'Clear selection',
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
        Expanded(
          child: PagedFeed<StoreOrder>(
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
            header: const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Prepare > Pack > Assign. Select packed orders to assign a batch. Employees handle pickup, delivery and cash.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
            ),
            identity: (o) => o.id,
            emptyTitle: 'No orders in this stage',
            emptyMessage: 'Choose another stage or pull down to refresh.',
            itemBuilder: (_, order, _) => order.status == 'Packed'
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
                                  if (value == true &&
                                      _selectedOrders.length >= 50) {
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
                        child: OrderSummaryCard(
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
                : OrderSummaryCard(
                    order: order,
                    onTap: () => _openOrder(order),
                    actionLabel: _orderActionLabel(order),
                    onAction: _quickOrderId == null
                        ? () => _quickOrder(order)
                        : null,
                  ),
          ),
        ),
      ],
    );
  }

  String _orderActionLabel(StoreOrder order) => switch (order.status) {
    'New' => 'Start Preparing',
    'Preparing' => 'Mark Packed',
    'Packed' =>
      order.data['assigned_to'] == null
          ? 'Assign Employee'
          : 'View employee pickup',
    'Out for Delivery' => 'Track delivery',
    'Delivered' =>
      order.paymentStatus == 'collected' &&
              order.data['cash_handover'] == null &&
              order.data['cash_received_directly'] != true
          ? 'Verify Cash'
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
          _assignmentEmployee ??
          await Navigator.push<Map<String, dynamic>>(
            context,
            MaterialPageRoute(builder: (_) => const EmployeePickerScreen()),
          );
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
    if (_orderActionLabel(order) == 'Verify Cash' &&
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
        _assignmentEmployee ??
        await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute(builder: (_) => const EmployeePickerScreen()),
        );
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
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your delivery team',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final metric in <(String, String)>[
                ('Available', 'available'),
                ('On delivery', 'on_delivery'),
                ('Inactive', 'inactive'),
              ])
                OpsPill(
                  '${metric.$1} ${ref.watch(adminDashboardProvider).asData?.value['team']?[metric.$2] ?? 0}',
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '1. Create login & contact details\n2. Check identity and activate\n3. Open a packed order and assign an employee',
            style: TextStyle(height: 1.7, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _teamSearchInput,
            decoration: const InputDecoration(
              hintText: 'Search employee, ID or mobile',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (s) {
              _teamDebounce?.cancel();
              _teamDebounce = Timer(const Duration(milliseconds: 350), () {
                if (mounted) setState(() => _teamSearch = s.trim());
              });
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
      identity: (p) => '${p['id']}',
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      emptyTitle: 'Set up your delivery team',
      emptyMessage:
          'Create real delivery employee accounts and assign their work.',
      emptyAction: 'Create employee',
      onEmptyAction: () => _editPerson(),
      itemBuilder: (_, p, _) {
        return Card(
          child: Column(
            children: [
              ListTile(
                onTap: () => _editPerson(p),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFE4F0E7),
                  child: Text('${p['name']}'.substring(0, 1).toUpperCase()),
                ),
                title: Text(
                  '${p['name']}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${p['employee_code'] ?? 'Complete onboarding'} | ${p['phone']}\n${p['active_orders']} orders | ${money(amount(p['cash_to_handover']))} cash due',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                isThreeLine: true,
                trailing: StatusChip(
                  p['is_active'] == true
                      ? p['ready_for_deliveries'] == true
                            ? '${p['status']}'
                            : 'Onboarding'
                      : 'Inactive',
                ),
              ),
              Wrap(
                spacing: 4,
                children: [
                  TextButton(
                    onPressed: () => _editPerson(p),
                    child: const Text(
                      'View Profile',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                  TextButton(
                    onPressed: p['ready_for_deliveries'] == true
                        ? () => _showOrders('Unassigned', employee: p)
                        : null,
                    child: const Text(
                      'Assign Order',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                  TextButton(
                    onPressed: amount(p['cash_to_handover']) > 0
                        ? () => _receiveCash(p)
                        : null,
                    child: const Text(
                      'Receive Cash',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
    appBar: AppBar(
      leading: BackButton(
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        },
      ),
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: storeGreen,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.storefront,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Welcome back.',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to your Agaram store workspace.',
                  style: TextStyle(color: Colors.black54, fontSize: 16),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _email,
                  enabled: !_busy,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.username],
                  decoration: const InputDecoration(
                    labelText: 'Admin email',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (s) => (s?.trim().isEmpty ?? true)
                      ? 'Enter your admin email'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  enabled: !_busy,
                  obscureText: _hidden,
                  autofillHints: const [AutofillHints.password],
                  onFieldSubmitted: (_) => _login(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _hidden = !_hidden),
                      icon: Icon(
                        _hidden
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (s) =>
                      (s?.isEmpty ?? true) ? 'Enter your password' : null,
                ),
                const SizedBox(height: 20),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy ? null : _login,
                    child: Text(_busy ? 'Signing in...' : 'Sign in'),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'For authorised store staff. Customers can browse and shop without an admin account.',
                  style: TextStyle(color: Colors.black54, height: 1.5),
                ),
              ],
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
      _sku;
  String _imageId = '', _imageUrl = '';
  bool _busy = false, _uploading = false, _available = true, _published = true;
  Timer? _nameDebounce;
  int _nameGeneration = 0;
  bool _suggestingName = false, _applyingName = false;
  String
  _autoTamil = '',
  _nameHint =
      'Type an English or Tanglish grocery name (e.g. Rice or Arisi) for a Tamil suggestion.';
  bool get _namePending =>
      _suggestingName || (_nameDebounce?.isActive ?? false);
  bool get _mayFillTamil =>
      _tamil.text.trim().isEmpty || _tamil.text == _autoTamil;
  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.englishName ?? '');
    _tamil = TextEditingController(text: p?.tamilName ?? '');
    _brand = TextEditingController(text: p?.brand ?? '');
    _category = TextEditingController(text: p?.category ?? 'Groceries');
    _price = TextEditingController(text: p?.price.toStringAsFixed(2) ?? '');
    _stock = TextEditingController(text: p?.stock.toStringAsFixed(2) ?? '');
    _unit = TextEditingController(text: p?.unit ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _sku = TextEditingController(text: p?.sku ?? '');
    _imageId = p?.imageId ?? '';
    _imageUrl = p?.imageUrl ?? '';
    _available = p?.inStock ?? true;
    _published = p?.published ?? true;
    _name.addListener(_queueTamilName);
    _tamil.addListener(_tamilEdited);
  }

  void _tamilEdited() {
    if (_applyingName) return;
    _nameGeneration++;
    _nameDebounce?.cancel();
    setState(() {
      _suggestingName = false;
      _autoTamil = '';
      _nameHint =
          'Your Tamil name will be used. You can edit it before publishing.';
    });
  }

  void _queueTamilName() {
    _nameGeneration++;
    _nameDebounce?.cancel();
    if (!_mayFillTamil) {
      setState(() {
        _suggestingName = false;
        _nameHint =
            'Your edited Tamil name is kept. Tap Suggest Tamil to replace it.';
      });
      return;
    }
    _applyingName = true;
    _tamil.clear();
    _applyingName = false;
    _autoTamil = '';
    setState(() {
      _suggestingName = false;
      _nameHint =
          'Tamil suggestions appear as you type. Please review the name.';
    });
    if (_name.text.trim().isNotEmpty) {
      _nameDebounce = Timer(
        const Duration(milliseconds: 450),
        () => _suggestTamilName(),
      );
    }
  }

  Future<void> _suggestTamilName({bool replace = false}) async {
    _nameDebounce?.cancel();
    final english = _name.text.trim();
    if (english.isEmpty || (!replace && !_mayFillTamil)) return;
    final generation = ++_nameGeneration;
    setState(() {
      _suggestingName = true;
      _nameHint = 'Finding a Tamil name…';
    });
    try {
      final tamil = await ref.read(storeApiProvider).suggestTamilName(english);
      if (!mounted ||
          generation != _nameGeneration ||
          _name.text.trim() != english) {
        return;
      }
      setState(() {
        if (tamil != null && tamil.isNotEmpty) {
          _applyingName = true;
          _tamil.text = tamil;
          _applyingName = false;
          _autoTamil = tamil;
          _nameHint =
              'Tamil suggestion added. Please check it before publishing.';
        } else {
          _nameHint = 'Enter the Tamil name for this product; an automatic suggestion is not available.';
        }
      });
    } catch (_) {
      if (mounted && generation == _nameGeneration) {
        setState(
          () => _nameHint =
              'Could not suggest a name. You can enter Tamil directly.',
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
      _sku,
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
    setState(() => _busy = true);
    try {
      await ref.read(storeApiProvider).saveProduct({
        'english_name': _name.text.trim(),
        'tamil_name': _tamil.text.trim(),
        'brand': _brand.text.trim(),
        'category': _category.text.trim(),
        'price': double.parse(_price.text).toStringAsFixed(2),
        'stock_kg': double.parse(_stock.text).toStringAsFixed(2),
        'unit': _unit.text.trim(),
        'description': _description.text.trim(),
        'sku': _sku.text.trim(),
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
          title: Text(widget.product == null ? 'Add product' : 'Edit product'),
        ),
        body: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              InkWell(
                onTap: _photo,
                borderRadius: BorderRadius.circular(20),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      if (_imageUrl.isNotEmpty)
                        ProductPhoto(_imageUrl, height: 210)
                      else
                        const SizedBox(
                          height: 150,
                          child: Center(
                            child: Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 48,
                              color: storeGreen,
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _uploading
                              ? 'Uploading photo...'
                              : _imageId.isEmpty
                              ? 'Add product photo (optional)'
                              : 'Change product photo',
                          style: const TextStyle(
                            color: storeGreen,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (_uploading) const LinearProgressIndicator(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Square photo · 1000 × 1000 recommended · JPG, PNG or WebP · Max 8 MB',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Product details',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: storeInk,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tamil name is shown first. Enter the actual price, selling unit and stock.',
                style: TextStyle(color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 20),
              _field(_tamil, 'Tamil product name', required: true),
              _field(_name, 'English / Tanglish reference (optional)'),
              if (_suggestingName) const LinearProgressIndicator(minHeight: 2),
              Row(
                children: [
                  const Icon(Icons.translate, size: 18, color: storeGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _nameHint,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _busy || _uploading || _suggestingName
                      ? null
                      : () => _suggestTamilName(replace: true),
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('Suggest Tamil'),
                ),
              ),
              _field(_brand, 'Brand (optional)'),
              _field(_category, 'Category', required: true),
              _field(
                _unit,
                'Selling unit (e.g. 1 kg, 500 g, 1 pack)',
                required: true,
              ),
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
                        return v == null || v <= 0 || v > 99999999
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
              _field(_sku, 'SKU (optional)'),
              _field(_description, 'Product description', lines: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Available for purchase'),
                subtitle: const Text(
                  'Stock is checked automatically at checkout.',
                ),
                value: _available,
                onChanged: _busy ? null : (v) => setState(() => _available = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _published,
                title: const Text('Publish in customer store'),
                subtitle: const Text(
                  'Hidden products stay in your inventory and existing order history.',
                ),
                onChanged: _busy ? null : (v) => setState(() => _published = v),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: _busy || _uploading || _namePending ? null : _save,
                child: Text(
                  _busy
                      ? 'Saving product...'
                      : widget.product == null
                      ? (_published ? 'Publish product' : 'Save hidden product')
                      : 'Save changes',
                ),
              ),
              const SizedBox(height: 30),
            ],
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
            onPressed: _busy ? null : _reloadOrder,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_refreshError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _refreshError!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Card(
            color: storeGreen,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NEXT ACTION',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _order.nextAction,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SelectableText(
            _order.id,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusChip(_order.status),
              if (_order.status != 'Cancelled')
                StatusChip(_order.paymentStatus),
            ],
          ),
          const SizedBox(height: 22),
          CodPaymentCard(order: _order),
          const SizedBox(height: 16),
          OrderJourney(order: _order),
          if (_order.status == 'Cancelled')
            Card(
              color: const Color(0xFFFFF0E2),
              child: ListTile(
                leading: const Icon(Icons.cancel_outlined),
                title: const Text('Cancelled · no cash due'),
                subtitle: Text(
                  '${_order.data['cancellation_reason']}\nReserved stock has been released.',
                ),
              ),
            ),
          if ([
            'Out for Delivery',
            'Delivery Attempted',
            'Delivered',
          ].contains(_order.status))
            DeliveryTrackingCard(orderId: _order.id, admin: true),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_order.data['customer_name']}',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SelectableText(
                    '${_order.data['customer_phone']}\n${_order.data['delivery_address']}',
                    style: const TextStyle(height: 1.6),
                  ),
                  Wrap(
                    spacing: 12,
                    children: [
                      TextButton.icon(
                        onPressed: () => openDeliveryLink(
                          context,
                          directionsTo('${_order.data['delivery_address']}'),
                        ),
                        icon: const Icon(Icons.directions_outlined),
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
                        icon: const Icon(Icons.call_outlined),
                        label: const Text('Call customer'),
                      ),
                    ],
                  ),
                  if ('${_order.data['delivery_instructions'] ?? ''}'
                      .isNotEmpty)
                    Text(
                      'Instructions: ${_order.data['delivery_instructions']}',
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          for (final i in _order.items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(productLabel(i)),
              subtitle: Text('${i['unit']} \u00d7 ${i['quantity']}'),
              trailing: Text(money(amount(i['total_price']))),
            ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Order total'),
            trailing: Text(
              money(_order.total),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
          ),
          if (_order.canFulfill) ...[
            const SizedBox(height: 22),
            const Text(
              'Assign delivery employee',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _busy || _order.status == 'Out for Delivery'
                  ? null
                  : () async {
                      final employee =
                          await Navigator.push<Map<String, dynamic>>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EmployeePickerScreen(),
                            ),
                          );
                      if (employee != null && mounted) {
                        setState(() {
                          _person = employee['id'];
                          _personName = employee['name'];
                        });
                        await _update();
                      }
                    },
              icon: const Icon(Icons.person_search_outlined),
              label: Text(
                _personName.isEmpty
                    ? 'Choose employee & save assignment'
                    : '$_personName · change assignment',
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Choose a verified employee. Their assigned order appears automatically in the employee app. They collect the items after packing.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: Colors.black54,
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _minutes,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Estimated arrival in minutes (optional)',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _note,
              enabled: !_busy,
              maxLength: 255,
              decoration: const InputDecoration(
                labelText: 'Customer delivery update (optional)',
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: _busy ? null : () => _update(),
              child: const Text('Save delivery details'),
            ),
            const SizedBox(height: 12),
            if (['New', 'Preparing'].contains(_order.status))
              FilledButton(
                onPressed: _busy ? null : _advance,
                child: Text(
                  _busy
                      ? 'Updating...'
                      : _order.nextStatus == 'Delivered' &&
                            _order.paymentStatus == 'cod'
                      ? 'Confirm cash & complete delivery'
                      : _order.status == 'Delivery Attempted'
                      ? 'Retry delivery'
                      : _order.status == 'New'
                      ? 'Accept order & start preparation'
                      : 'Items checked · mark packed',
                ),
              ),
            if ([
              'Packed',
              'Out for Delivery',
              'Delivery Attempted',
            ].contains(_order.status)) ...[
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.delivery_dining, color: storeGreen),
                  title: Text(
                    _personName.isEmpty
                        ? 'Choose an employee to continue'
                        : _personName,
                  ),
                  subtitle: Text(
                    _order.status == 'Packed'
                        ? 'Employee picks up from their app. Customer receives a delivery code when the trip starts.'
                        : 'Employee handles navigation, cash collection and customer code verification.',
                  ),
                ),
              ),
              ExpansionTile(
                title: const Text('Admin delivery assistance'),
                subtitle: const Text('Use only when helping an employee'),
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'An assigned, verified employee is still required. Completion requires the customer’s delivery code and exact cash amount.',
                    ),
                  ),
                  FilledButton(
                    onPressed: _busy || _person == null ? null : _advance,
                    child: Text(
                      _order.status == 'Out for Delivery'
                          ? 'Verify customer code & cash'
                          : 'Confirm employee pickup & dispatch',
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
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
              TextButton.icon(
                onPressed: _busy ? null : _cancelOrder,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel order & restore stock'),
              ),
            ],
          ],
          if (_order.paymentStatus == 'pending')
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'This is a previous incomplete online checkout. It can be cancelled; new orders use cash on delivery.',
              ),
            ),
          if (_order.paymentStatus == 'review')
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'A previous online payment needs manual store review. Check the original payment records before fulfillment.',
              ),
            ),
          const SizedBox(height: 24),
          const Text(
            'Activity',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          for (final event in _order.events)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.check_circle_outline,
                color: storeGreen,
              ),
              title: Text('${event['status']}'),
              subtitle: Text('${event['note']}'),
            ),
        ],
      ),
    ),
  );
}
