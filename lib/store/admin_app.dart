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
import 'paged_feed.dart';
import 'employee_picker.dart';

class AdminConsoleScreen extends ConsumerStatefulWidget {
  const AdminConsoleScreen({super.key});
  @override
  ConsumerState<AdminConsoleScreen> createState() => _AdminConsoleState();
}

class _AdminConsoleState extends ConsumerState<AdminConsoleScreen> {
  bool _signedIn = false;
  int _tab = 0;
  String _orderFilter = 'All';
  Timer? _poll;
  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_signedIn) {
        ref.read(storeApiProvider).feedChanges.value++;
        ref.invalidate(adminOrdersProvider);
        ref.invalidate(adminDashboardProvider);
        if (_tab == 3) ref.invalidate(deliveryTeamProvider);
      }
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _logout() async {
    try {
      await ref.read(storeApiProvider).logout();
    } catch (e) {
      if (mounted) showStoreError(context, e);
    }
    if (!mounted) return;
    refreshCommerce(ref);
    context.go('/');
  }

  void _loginSuccess() {
    refreshCommerce(ref);
    setState(() => _signedIn = true);
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: storeTheme(),
    child: !_signedIn
        ? AdminSignInScreen(onSuccess: _loginSuccess)
        : Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Agaram Workspace',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 21),
                  ),
                  Text(
                    [
                      'Store overview',
                      'Product catalog',
                      'Order management',
                      'Delivery team',
                    ][_tab],
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: () => refreshCommerce(ref),
                  icon: const Icon(Icons.refresh),
                ),
                IconButton(
                  tooltip: 'Logout',
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                ),
              ],
            ),
            body: switch (_tab) {
              0 => _overview(),
              1 => _products(),
              2 => _orders(),
              _ => _team(),
            },
            floatingActionButton: _tab == 1
                ? FloatingActionButton.extended(
                    onPressed: () => _editProduct(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add product'),
                  )
                : _tab == 3
                ? FloatingActionButton.extended(
                    onPressed: () => _editPerson(),
                    icon: const Icon(Icons.person_add_outlined),
                    label: const Text('Add delivery person'),
                  )
                : null,
            bottomNavigationBar: NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (i) => setState(() => _tab = i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.space_dashboard_outlined),
                  label: 'Overview',
                ),
                NavigationDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  label: 'Products',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  label: 'Orders',
                ),
                NavigationDestination(
                  icon: Icon(Icons.delivery_dining),
                  label: 'Delivery',
                ),
              ],
            ),
          ),
  );
  Widget _overview() => DataView(
    value: ref.watch(adminDashboardProvider),
    onRetry: () => ref.invalidate(adminDashboardProvider),
    builder: (data) => RefreshIndicator(
      onRefresh: () async {
        await ref.refresh(adminDashboardProvider.future).then((_) {});
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: storeGreen,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your store, at a glance.',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Cash collected at delivery',
                  style: TextStyle(color: Color(0xFFD2E7D9)),
                ),
                const SizedBox(height: 6),
                Text(
                  money(amount(data['cash_collected'])),
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Received by store: ${money(amount(data['cash_received_by_store']))}\nWith employees: ${money(amount(data['cash_with_employees']))}',
                  style: const TextStyle(color: Colors.white70, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (ctx, c) => Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _stat(
                  'Published products',
                  data['total_products'],
                  Icons.inventory_2_outlined,
                  (c.maxWidth - 12) / 2,
                ),
                _stat(
                  'New orders',
                  data['new_orders'],
                  Icons.shopping_bag_outlined,
                  (c.maxWidth - 12) / 2,
                ),
                _stat(
                  'Out for delivery',
                  data['active_deliveries'],
                  Icons.delivery_dining,
                  (c.maxWidth - 12) / 2,
                ),
                _stat(
                  'Low stock',
                  data['low_stock'],
                  Icons.warning_amber_rounded,
                  (c.maxWidth - 12) / 2,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            '${money(amount(data['cash_due']))} cash to collect Â· ${data['delivered']} delivered',
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 24),
          const Text(
            'Recent orders',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          if ((data['recent_orders'] as List).isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('New customer orders will appear here.'),
              ),
            ),
          for (final j in data['recent_orders'])
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OrderSummaryCard(
                order: StoreOrder(Map<String, dynamic>.from(j)),
                onTap: () =>
                    _openOrder(StoreOrder(Map<String, dynamic>.from(j))),
              ),
            ),
        ],
      ),
    ),
  );
  Widget _stat(String label, dynamic value, IconData icon, double width) =>
      SizedBox(
        width: width,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: storeGreen),
                const SizedBox(height: 12),
                Text(
                  '$value',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 5),
                Text(label, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        ),
      );
  Future<void> _editProduct([StoreProduct? product]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ProductEditorScreen(product: product)),
    );
    if (result == true) refreshCommerce(ref);
  }

  Widget _products() {
    final api = ref.watch(storeApiProvider);
    return PagedFeed<StoreProduct>(
      queryKey: ('adminProducts', api.adminToken),
      changes: api.feedChanges,
      load: (cursor) => api.productPage(cursor: cursor, admin: true),
      identity: (p) => p.id,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      emptyTitle: 'Build your product catalog',
      emptyMessage:
          'Publish real products with prices, stock and product photos.',
      emptyAction: 'Add your first product',
      onEmptyAction: () => _editProduct(),
      itemBuilder: (ctx, p, _) {
        return Card(
          child: InkWell(
            onTap: () => _editProduct(p),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  SizedBox(
                    width: 72,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ProductPhoto(p.imageUrl, height: 72),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${p.category} / ${p.unit}',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${money(p.price)} / Stock: ${p.stock.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: storeGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (action) async {
                      if (action == 'edit') {
                        _editProduct(p);
                        return;
                      }
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Remove product?'),
                          content: Text(
                            '${p.name} will no longer appear in the customer store. Existing order records are preserved.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Remove'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        try {
                          await ref.read(storeApiProvider).deleteProduct(p.id);
                          refreshCommerce(ref);
                        } catch (e) {
                          if (mounted) showStoreError(context, e);
                        }
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit product')),
                      PopupMenuItem(
                        value: 'remove',
                        child: Text('Remove product'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _orders() {
    final api = ref.watch(storeApiProvider);
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              for (final status in [
                'All',
                'New',
                'Preparing',
                'Packed',
                'Out for Delivery',
                'Delivery Attempted',
                'Delivered',
                'Cancelled',
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(status),
                    selected: _orderFilter == status,
                    onSelected: (_) => setState(() => _orderFilter = status),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: PagedFeed<StoreOrder>(
            queryKey: ('adminOrders', api.adminToken, _orderFilter),
            changes: api.feedChanges,
            load: (cursor) => api.orderPage(
              cursor: cursor,
              admin: true,
              status: _orderFilter,
            ),
            identity: (o) => o.id,
            emptyTitle: 'No orders in this stage',
            emptyMessage: 'Choose another stage or pull down to refresh.',
            itemBuilder: (_, order, _) =>
                OrderSummaryCard(order: order, onTap: () => _openOrder(order)),
          ),
        ),
      ],
    );
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
      queryKey: ('adminTeam', api.adminToken),
      changes: api.feedChanges,
      load: (cursor) => api.employeePage(cursor: cursor),
      identity: (p) => '${p['id']}',
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      emptyTitle: 'Set up your delivery team',
      emptyMessage:
          'Create real delivery employee accounts and assign their work.',
      emptyAction: 'Create employee',
      onEmptyAction: () => _editPerson(),
      itemBuilder: (_, p, _) {
        return Card(
          child: ListTile(
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
        );
      },
    );
  }

  Future<void> _editPerson([Map<String, dynamic>? person]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EmployeeEditorScreen(person: person)),
    );
    ref.invalidate(deliveryTeamProvider);
  }
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
  bool _busy = false, _uploading = false, _available = true;
  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _tamil = TextEditingController(text: p?.tamilName ?? '');
    _brand = TextEditingController(text: p?.brand ?? '');
    _category = TextEditingController(text: p?.category ?? '');
    _price = TextEditingController(text: p?.price.toStringAsFixed(2) ?? '');
    _stock = TextEditingController(text: p?.stock.toStringAsFixed(0) ?? '');
    _unit = TextEditingController(text: p?.unit ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _sku = TextEditingController(text: p?.sku ?? '');
    _imageId = p?.imageId ?? '';
    _imageUrl = p?.imageUrl ?? '';
    _available = p?.inStock ?? true;
  }

  @override
  void dispose() {
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
    if (_busy || _uploading || !_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(storeApiProvider).saveProduct({
        'english_name': _name.text.trim(),
        'tamil_name': _tamil.text.trim(),
        'brand': _brand.text.trim(),
        'category': _category.text.trim(),
        'price': double.parse(_price.text).toStringAsFixed(2),
        'stock_kg': int.parse(_stock.text),
        'unit': _unit.text.trim(),
        'description': _description.text.trim(),
        'sku': _sku.text.trim(),
        'image': _imageId.isEmpty ? null : _imageId,
        'is_in_stock': _available,
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
      data: storeTheme(),
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
              const SizedBox(height: 22),
              _field(_name, 'Product name', required: true),
              _field(_tamil, 'Tamil name (optional)'),
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
                        final v = int.tryParse(s ?? '');
                        return v == null || v < 0 ? 'Use a whole number' : null;
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
              const SizedBox(height: 22),
              FilledButton(
                onPressed: _busy || _uploading ? null : _save,
                child: Text(
                  _busy
                      ? 'Saving product...'
                      : widget.product == null
                      ? 'Publish product'
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
      controller: controller,
      enabled: !_busy,
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
  final _note = TextEditingController(), _minutes = TextEditingController();
  @override
  void initState() {
    super.initState();
    _order = widget.initialOrder;
    _person = _order.data['assigned_to'];
    _personName = '${_order.data['assigned_to_details']?['name'] ?? ''}';
    _note.text = _order.data['delivery_note'] ?? '';
  }

  @override
  void dispose() {
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
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _advance() async {
    final next = _order.nextStatus;
    if (next == 'Delivered' && _order.paymentStatus == 'cod') {
      final extra = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) => OrderActionDialog(kind: 'cash', total: _order.total),
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
    data: storeTheme(),
    child: Scaffold(
      appBar: AppBar(title: const Text('Manage order')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            _order.id,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusChip(_order.status),
              StatusChip(_order.paymentStatus),
            ],
          ),
          const SizedBox(height: 22),
          CodPaymentCard(order: _order),
          const SizedBox(height: 16),
          OrderJourney(order: _order),
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
              title: Text('${i['english_name']}'),
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
              'Delivery management',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _busy
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
                      }
                    },
              icon: const Icon(Icons.person_search_outlined),
              label: Text(
                _personName.isEmpty
                    ? 'Assign a verified delivery employee'
                    : 'Assigned: $_personName',
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
            if (_order.nextStatus != null)
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
                      : 'Mark ${_order.nextStatus}',
                ),
              ),
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
