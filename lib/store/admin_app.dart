import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'api.dart';
import 'models.dart';
import 'state.dart';
import 'widgets.dart';

class AdminConsoleScreen extends ConsumerStatefulWidget {
  const AdminConsoleScreen({super.key});
  @override
  ConsumerState<AdminConsoleScreen> createState() => _AdminConsoleState();
}

class _AdminConsoleState extends ConsumerState<AdminConsoleScreen> {
  bool _signedIn = false;
  int _tab = 0;
  Timer? _poll;
  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_signedIn) {
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
  Widget build(BuildContext context) {
    final activeRole = ref.watch(activeRoleProvider);
    final activeEmployee = ref.watch(activeEmployeeProvider);

    if (activeRole == 'employee') {
      return Theme(
        data: storeTheme(),
        child: EmployeeConsoleScreen(
          employee: activeEmployee,
          onSwitchToAdmin: () {
            ref.read(activeRoleProvider.notifier).setRole('admin');
          },
        ),
      );
    }

    return Theme(
      data: storeTheme(),
      child: !_signedIn
          ? AdminSignInScreen(onSuccess: _loginSuccess)
          : Scaffold(
              appBar: AppBar(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Agaram Workspace',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE4F0E7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF006B3C), width: 1),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.admin_panel_settings, size: 13, color: Color(0xFF006B3C)),
                              SizedBox(width: 3),
                              Text(
                                'Role: Admin',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF006B3C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      [
                        'Store overview',
                        'Product catalog',
                        'Order management',
                        'Staff & Employees',
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
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: const Text('Create Employee'),
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
                    icon: Icon(Icons.badge_outlined),
                    label: 'Employees',
                  ),
                ],
              ),
            ),
    );
  }
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
                  'Captured online payments',
                  style: TextStyle(color: Color(0xFFD2E7D9)),
                ),
                const SizedBox(height: 6),
                Text(
                  money(amount(data['revenue'])),
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
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
            '${data['awaiting_payment']} awaiting payment / ${data['delivered']} delivered',
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

  Widget _products() => DataView(
    value: ref.watch(catalogProvider),
    onRetry: () => ref.invalidate(catalogProvider),
    builder: (products) {
      if (products.isEmpty) {
        return EmptyPanel(
          icon: Icons.inventory_2_outlined,
          title: 'Build your product catalog',
          message: 'Upload a product photo, set your price and stock, and publish it to the customer store.',
          action: 'Add your first product',
          onAction: () => _editProduct(),
        );
      }
      return RefreshIndicator(
        onRefresh: () async {
          await ref.refresh(catalogProvider.future).then((_) {});
        },
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          itemCount: products.length,
          separatorBuilder: (_, i) => const SizedBox(height: 12),
          itemBuilder: (ctx, i) {
            final p = products[i];
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
                              await ref
                                  .read(storeApiProvider)
                                  .deleteProduct(p.id);
                              refreshCommerce(ref);
                            } catch (e) {
                              if (mounted) showStoreError(context, e);
                            }
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit product'),
                          ),
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
        ),
      );
    },
  );
  Widget _orders() => DataView(
    value: ref.watch(adminOrdersProvider),
    onRetry: () => ref.invalidate(adminOrdersProvider),
    builder: (orders) {
      if (orders.isEmpty) {
        return const EmptyPanel(
          icon: Icons.receipt_long_outlined,
          title: 'Ready for your first order',
          message: 'Customer orders will arrive here with verified prices and payment status.',
        );
      }
      return RefreshIndicator(
        onRefresh: () async {
          await ref.refresh(adminOrdersProvider.future).then((_) {});
        },
        child: ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: orders.length,
          separatorBuilder: (_, i) => const SizedBox(height: 14),
          itemBuilder: (_, i) => OrderSummaryCard(
            order: orders[i],
            onTap: () => _openOrder(orders[i]),
          ),
        ),
      );
    },
  );
  Future<void> _openOrder(StoreOrder order) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdminOrderScreen(initialOrder: order)),
    );
    if (mounted) refreshCommerce(ref);
  }

  Widget _team() => DataView(
    value: ref.watch(deliveryTeamProvider),
    onRetry: () => ref.invalidate(deliveryTeamProvider),
    builder: (team) {
      if (team.isEmpty) {
        return EmptyPanel(
          icon: Icons.badge_outlined,
          title: 'Register store employees',
          message: 'Add store executives, order packers, cashiers and delivery staff. You can switch into any employee role with one tap.',
          action: 'Create Employee',
          onAction: () => _editPerson(),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        itemCount: team.length,
        separatorBuilder: (_, i) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final p = team[i];
          final roleName = p['role'] ?? 'Store Executive';
          return Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFFE4F0E7),
                        child: Text(
                          '${p['name']}'.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF006B3C),
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${p['name']}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE4F0E7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                roleName,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF006B3C),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${p['phone']}',
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      StatusChip(
                        p['is_active'] == true ? '${p['status'] ?? 'Active'}' : 'Inactive',
                      ),
                    ],
                  ),
                  const Divider(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${p['active_orders'] ?? 0} active tasks',
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            tooltip: 'Edit details',
                            onPressed: () => _editPerson(p),
                          ),
                          const SizedBox(width: 4),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF006B3C),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.visibility_rounded, size: 16),
                            label: const Text('View Employee'),
                            onPressed: () {
                              // AUTOMATICALLY CHANGE ROLE AS EMPLOYEE
                              ref.read(activeRoleProvider.notifier).setRole('employee');
                              ref.read(activeEmployeeProvider.notifier).setEmployee(p);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  Future<void> _editPerson([Map<String, dynamic>? person]) async {
    final name = TextEditingController(text: person?['name'] ?? ''),
        phone = TextEditingController(text: person?['phone'] ?? '');
    String role = person?['role'] ?? 'Store Executive';
    final form = GlobalKey<FormState>();
    bool active = person?['is_active'] ?? true, busy = false;
    Map<String, dynamic>? savedPersonPayload;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            person == null ? 'Create Employee' : 'Edit Employee',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: form,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(
                      labelText: 'Employee Name *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (s) =>
                        (s?.trim().length ?? 0) < 2 ? 'Enter a valid name' : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: role,
                    decoration: const InputDecoration(
                      labelText: 'Employee Role *',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Store Executive', child: Text('Store Executive')),
                      DropdownMenuItem(value: 'Order Packer & Verification', child: Text('Order Packer & Verification')),
                      DropdownMenuItem(value: 'Billing Cashier', child: Text('Billing Cashier')),
                      DropdownMenuItem(value: 'Delivery Executive', child: Text('Delivery Executive')),
                      DropdownMenuItem(value: 'Inventory Staff', child: Text('Inventory Staff')),
                    ],
                    onChanged: (v) {
                      if (v != null) setDialog(() => role = v);
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Mobile number *',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (s) =>
                        !RegExp(r'^\+?[0-9]{10,15}$').hasMatch(s?.trim() ?? '')
                        ? 'Enter a valid mobile number'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active Staff Status'),
                    value: active,
                    onChanged: busy ? null : (v) => setDialog(() => active = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (!form.currentState!.validate()) return;
                      setDialog(() => busy = true);
                      try {
                        final payload = {
                          'name': name.text.trim(),
                          'role': role,
                          'phone': phone.text.trim(),
                          'is_active': active,
                        };
                        final res = await ref.read(storeApiProvider).savePerson(payload, id: person?['id']);
                        savedPersonPayload = {
                          ...payload,
                          ...res,
                        };
                        ref.invalidate(deliveryTeamProvider);
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        if (ctx.mounted) {
                          showStoreError(ctx, e);
                          setDialog(() => busy = false);
                        }
                      }
                    },
              child: Text(busy ? 'Saving...' : 'Save Employee'),
            ),
          ],
        ),
      ),
    );

    // Prompt user to View the Employee and automatically change role
    if (savedPersonPayload != null && mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(22),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4F0E7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF006B3C),
                  size: 42,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Employee Saved Successfully!',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              const SizedBox(height: 8),
              Text(
                '${savedPersonPayload!['name']} ($role) has been registered in the store system.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FBF9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE4F0E7)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.badge_outlined, color: Color(0xFF006B3C)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${savedPersonPayload!['name']}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                          Text(
                            'Role: $role • ${savedPersonPayload!['phone']}',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF006B3C)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF006B3C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.visibility_rounded, size: 18),
                  label: const Text(
                    'View the Employee',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    // AUTOMATICALLY CHANGE ROLE TO EMPLOYEE!
                    ref.read(activeRoleProvider.notifier).setRole('employee');
                    ref.read(activeEmployeeProvider.notifier).setEmployee(savedPersonPayload);
                  },
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Continue as Admin'),
              ),
            ],
          ),
        ),
      );
    }

    await Future<void>.delayed(const Duration(milliseconds: 300));
    name.dispose();
    phone.dispose();
  }
}

/// Full Employee Console View / Portal Screen
class EmployeeConsoleScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? employee;
  final VoidCallback onSwitchToAdmin;

  const EmployeeConsoleScreen({
    super.key,
    required this.employee,
    required this.onSwitchToAdmin,
  });

  @override
  ConsumerState<EmployeeConsoleScreen> createState() => _EmployeeConsoleScreenState();
}

class _EmployeeConsoleScreenState extends ConsumerState<EmployeeConsoleScreen> {
  final Map<String, bool> _packedItems = {
    'item_1': true,
    'item_2': true,
    'item_3': false,
  };

  void _confirmReturnToAdmin() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Switch to Admin Role?'),
        content: const Text(
          'You are currently logged in as Employee. Do you want to return to the Admin Dashboard?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Stay as Employee'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF006B3C)),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onSwitchToAdmin();
            },
            child: const Text('Switch to Admin'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final emp = widget.employee;
    final empName = emp?['name'] ?? 'Store Staff';
    final empRole = emp?['role'] ?? 'Store Executive';
    final empPhone = emp?['phone'] ?? '+91 98765 43210';
    final ordersAsync = ref.watch(adminOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Employee Portal',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4F0E7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF006B3C)),
                  ),
                  child: const Text(
                    'Role: Employee',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006B3C),
                    ),
                  ),
                ),
              ],
            ),
            Text(
              'Active Employee: $empName',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                backgroundColor: const Color(0xFFE4F0E7),
                foregroundColor: const Color(0xFF006B3C),
              ),
              icon: const Icon(Icons.admin_panel_settings, size: 16),
              label: const Text('Admin View'),
              onPressed: _confirmReturnToAdmin,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Employee Identity Profile Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF006B3C), Color(0xFF07894F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF006B3C).withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white,
                        child: Text(
                          empName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF006B3C),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              empName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              empRole,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFEAF7EE),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              empPhone,
                              style: const TextStyle(fontSize: 11, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '● On Duty',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Employee Duty Quick Metrics
            Row(
              children: [
                _buildMetricCard('Assigned Tasks', '6', Icons.checklist_rounded, const Color(0xFF006B3C)),
                const SizedBox(width: 10),
                _buildMetricCard('To Pack', '3', Icons.inventory_2_outlined, Colors.orange.shade800),
                const SizedBox(width: 10),
                _buildMetricCard('Verified', '12', Icons.verified_outlined, Colors.blue.shade700),
              ],
            ),
            const SizedBox(height: 22),

            // Section 1: Order Packing & Verification Duty
            const Text(
              'Order Fulfillment & Packing (Assigned Order)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Check off packed items before dispatching order #NK20251022',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 10),

            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _buildCheckItem('item_1', 'துவரம் பருப்பு (Toor Dal 1 kg)', '₹275'),
                    const Divider(height: 16),
                    _buildCheckItem('item_2', 'அரிசி (Ponni Boiled Rice 5 kg)', '₹325'),
                    const Divider(height: 16),
                    _buildCheckItem('item_3', 'சமையல் எண்ணெய் (Refined Oil 1 L)', '₹165'),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF006B3C),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Mark Order Packed & Ready'),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Order items verified and marked as Packed!'),
                              backgroundColor: Color(0xFF006B3C),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),

            // Section 2: Store Live Orders Overview
            const Text(
              'Active Customer Orders Queue',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ordersAsync.when(
              data: (orders) {
                if (orders.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No active orders right now.'),
                    ),
                  );
                }
                return Column(
                  children: orders.take(3).map((o) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF006B3C)),
                        title: Text(o.id, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${o.items.length} items • ${money(o.total)}'),
                        trailing: StatusChip(o.status),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Unable to load queue'),
            ),

            const SizedBox(height: 22),

            // Role Banner Notice
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade900),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You are working in Employee Role ($empName). Administrative controls and settings are restricted.',
                      style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Big Switch Back Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF006B3C),
                  side: const BorderSide(color: Color(0xFF006B3C), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text(
                  'Switch Back to Admin Role',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: _confirmReturnToAdmin,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckItem(String keyId, String title, String price) {
    final checked = _packedItems[keyId] ?? false;
    return InkWell(
      onTap: () => setState(() => _packedItems[keyId] = !checked),
      child: Row(
        children: [
          Checkbox(
            value: checked,
            activeColor: const Color(0xFF006B3C),
            onChanged: (v) => setState(() => _packedItems[keyId] = v ?? false),
          ),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                decoration: checked ? TextDecoration.lineThrough : null,
                color: checked ? Colors.black45 : Colors.black87,
              ),
            ),
          ),
          Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
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
  bool _busy = false;
  final _note = TextEditingController(), _minutes = TextEditingController();
  @override
  void initState() {
    super.initState();
    _order = widget.initialOrder;
    _person = _order.data['assigned_to'];
    _note.text = _order.data['delivery_note'] ?? '';
  }

  @override
  void dispose() {
    _note.dispose();
    _minutes.dispose();
    super.dispose();
  }

  Future<void> _update({String? next}) async {
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
      await ref.read(storeApiProvider).updateOrder(_order.id, {
        'status': ?next,
        if (_person != null) 'assigned_to': _person,
        'delivery_note': _note.text.trim(),
        if (minutes != null)
          'estimated_delivery_at': DateTime.now()
              .add(Duration(minutes: minutes))
              .toUtc()
              .toIso8601String(),
      });
      final orders = await ref.refresh(adminOrdersProvider.future).then((_) {});
      final updated = orders.where((o) => o.id == _order.id).firstOrNull;
      if (updated != null && mounted) setState(() => _order = updated);
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
            DataView(
              value: ref.watch(deliveryTeamProvider),
              onRetry: () => ref.invalidate(deliveryTeamProvider),
              builder: (team) {
                final people = team
                    .where((p) => p['is_active'] == true)
                    .toList();
                return DropdownButtonFormField<int>(
                  initialValue: people.any((p) => p['id'] == _person)
                      ? _person
                      : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Assign delivery person',
                  ),
                  items: [
                    for (final p in people)
                      DropdownMenuItem(
                        value: p['id'] as int,
                        child: Text(
                          '${p['name']} (${p['active_orders']} active)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: _busy ? null : (v) => setState(() => _person = v),
                );
              },
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
                onPressed: _busy
                    ? null
                    : () => _update(next: _order.nextStatus),
                child: Text(
                  _busy ? 'Updating...' : 'Mark ${_order.nextStatus}',
                ),
              ),
          ],
          if (_order.paymentStatus == 'pending')
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Awaiting customer payment. Fulfillment becomes available only after payment is verified.',
              ),
            ),
          if (_order.paymentStatus == 'review')
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'A late payment needs review. Stock was released. Resolve fulfillment or refund in Razorpay before proceeding.',
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
