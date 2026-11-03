import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart';
import 'state.dart';
import 'widgets.dart';

const opsGreen = Color(0xFF075E46);
const opsMint = Color(0xFFEAF7F0);
const opsMuted = Color(0xFF6D756F);
const opsWarning = Color(0xFF9B650C);
const opsRed = Color(0xFFD94A4A);

ThemeData operationsTheme() => storeTheme().copyWith(
  scaffoldBackgroundColor: const Color(0xFFFAFAF7),
  colorScheme: ColorScheme.fromSeed(
    seedColor: opsGreen,
    primary: opsGreen,
    surface: Colors.white,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFFAFAF7),
    foregroundColor: storeInk,
    centerTitle: false,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: Color(0xFFE3EAE6)),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: opsGreen,
      foregroundColor: Colors.white,
      minimumSize: const Size(48, 44),
      textStyle: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    height: 70,
    backgroundColor: Colors.white,
    indicatorColor: opsMint,
    labelTextStyle: WidgetStateProperty.resolveWith(
      (s) => TextStyle(
        fontSize: 10,
        fontWeight: s.contains(WidgetState.selected)
            ? FontWeight.w800
            : FontWeight.w500,
        color: s.contains(WidgetState.selected) ? opsGreen : opsMuted,
      ),
    ),
  ),
);

class OpsPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const OpsPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE3EAE6)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x04000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Material(type: MaterialType.transparency, child: child),
  );
}

class OpsHeading extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const OpsHeading(this.title, {super.key, this.action, this.onAction});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: storeInk,
            ),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            child: Text(action!, style: const TextStyle(fontSize: 12)),
          ),
      ],
    ),
  );
}

class OpsEmpty extends StatelessWidget {
  final String title, message;
  final IconData icon;
  const OpsEmpty(
    this.title,
    this.message, {
    super.key,
    this.icon = Icons.inbox_outlined,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: opsMint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: opsGreen),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                style: const TextStyle(
                  color: opsMuted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

String opsTime(dynamic value) {
  final date = DateTime.tryParse('$value')?.toLocal();
  if (date == null) return 'Time not recorded';
  return '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

String opsDate(dynamic value) {
  final date = DateTime.tryParse('$value');
  if (date == null) return '';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]}';
}

String opsInitial(String name) =>
    name.trim().isEmpty ? '•' : name.trim().substring(0, 1).toUpperCase();

class OperationsDashboard extends ConsumerWidget {
  final void Function(String) onOrders, onInventory;
  final VoidCallback onAddProduct,
      onCreateEmployee,
      onTeam,
      onCash,
      onDelivery,
      onReports;
  final void Function(StoreOrder) onOrder;
  final void Function(StoreProduct) onProduct;
  final void Function(Map<String, dynamic>) onReceiveCash;
  const OperationsDashboard({
    super.key,
    required this.onOrders,
    required this.onInventory,
    required this.onAddProduct,
    required this.onCreateEmployee,
    required this.onTeam,
    required this.onCash,
    required this.onDelivery,
    required this.onReports,
    required this.onOrder,
    required this.onProduct,
    required this.onReceiveCash,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) => DataView(
    value: ref.watch(adminDashboardProvider),
    retainOnRefresh: true,
    onRetry: () => ref.invalidate(adminDashboardProvider),
    builder: (data) {
      final today = Map<String, dynamic>.from(data['today'] ?? {});
      final inventory = Map<String, dynamic>.from(data['inventory'] ?? {});
      final team = Map<String, dynamic>.from(data['team'] ?? {});
      final alerts = List<Map<String, dynamic>>.from(data['alerts'] ?? []);
      final deliveries = List<Map<String, dynamic>>.from(
        data['active_delivery_preview'] ?? [],
      );
      final products = List<Map<String, dynamic>>.from(
        data['recent_products'] ?? [],
      );
      final people = List<Map<String, dynamic>>.from(
        data['team_preview'] ?? [],
      );
      final events = List<Map<String, dynamic>>.from(
        data['recent_activity'] ?? [],
      );
      return RefreshIndicator(
        onRefresh: () =>
            ref.refresh(adminDashboardProvider.future).then((_) {}),
        child: ListView(
          key: const PageStorageKey('operations-dashboard'),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.6,
                    ),
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 30),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => ref.invalidate(adminDashboardProvider),
                  icon: const Icon(Icons.sync, size: 15),
                  label: const Text('Refresh', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OpsPanel(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: opsMint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.insights_outlined,
                          color: opsGreen,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Today’s Operations',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        opsDate(today['date']),
                        style: const TextStyle(fontSize: 10, color: opsMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (_, c) => Wrap(
                      spacing: 8,
                      runSpacing: 12,
                      children: [
                        for (final metric in <(String, String, String, Color)>[
                          ('New Orders', 'new', 'New', opsGreen),
                          ('Preparing', 'preparing', 'Preparing', storeInk),
                          ('Packed', 'packed', 'Packed', storeInk),
                          (
                            'On the way',
                            'out_for_delivery',
                            'Out for Delivery',
                            opsGreen,
                          ),
                          ('Delivered', 'delivered', 'Delivered', storeInk),
                          (
                            'Needs attention',
                            'needs_attention',
                            'Active',
                            opsWarning,
                          ),
                        ])
                          SizedBox(
                            width: (c.maxWidth - 16) / 3,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => onOrders('Today ${metric.$3}'),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${today[metric.$2] ?? 0}',
                                    style: TextStyle(
                                      fontSize: 22,
                                      height: 1.1,
                                      fontWeight: FontWeight.w800,
                                      color: metric.$4,
                                      letterSpacing: -.5,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    metric.$1,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: opsMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Today’s queue · deliveries completed today',
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.4,
                      color: opsMuted,
                    ),
                  ),
                  const Divider(height: 20),
                  _CollectionSummary(data: data),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => onOrders('Active'),
                      icon: const Icon(Icons.arrow_forward, size: 17),
                      label: const Text('View Orders'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const OpsHeading('Needs your attention'),
            if (alerts.isEmpty)
              const OpsPanel(
                child: OpsEmpty(
                  'All caught up',
                  'No action is currently required.',
                  icon: Icons.task_alt,
                ),
              )
            else
              OpsPanel(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < alerts.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      _AttentionRow(
                        alert: alerts[i],
                        onTap: () => _alertAction(alerts[i]['key']),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 22),
            OpsHeading(
              'Order Pipeline',
              action: 'All orders',
              onAction: () => onOrders('All'),
            ),
            OpsPanel(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  for (final stage in <(String, String, IconData, String)>[
                    (
                      'New',
                      'new_orders',
                      Icons.receipt_long_outlined,
                      'Start preparing',
                    ),
                    (
                      'Preparing',
                      'preparing',
                      Icons.shopping_basket_outlined,
                      'Check & pack items',
                    ),
                    (
                      'Packed',
                      'packed_unassigned',
                      Icons.inventory_2_outlined,
                      'Assign Delivery Employee',
                    ),
                    (
                      'Assigned',
                      'assigned',
                      Icons.person_pin_circle_outlined,
                      'Waiting for employee pickup',
                    ),
                    (
                      'Out for Delivery',
                      'active_deliveries',
                      Icons.route_outlined,
                      'Track active delivery',
                    ),
                    (
                      'Delivered',
                      'delivered',
                      Icons.task_alt,
                      'Review completed deliveries',
                    ),
                    (
                      'Cash Handover Complete',
                      'cash_received_orders',
                      Icons.account_balance_outlined,
                      'Cash received by store',
                    ),
                  ])
                    ListTile(
                      dense: true,
                      visualDensity: const VisualDensity(vertical: -1),
                      onTap: () => onOrders(
                        stage.$1 == 'Packed' ? 'Unassigned' : stage.$1,
                      ),
                      leading: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color:
                              stage.$1 == 'Packed' && amount(data[stage.$2]) > 0
                              ? const Color(0xFFFFF4DE)
                              : opsMint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          stage.$3,
                          size: 18,
                          color: stage.$1 == 'Packed' ? opsWarning : opsGreen,
                        ),
                      ),
                      title: Text(
                        stage.$1,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        stage.$4,
                        style: TextStyle(
                          fontSize: 10,
                          color: stage.$1 == 'Packed' ? opsWarning : opsMuted,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${data[stage.$2] ?? 0}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right,
                            size: 17,
                            color: opsMuted,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            OpsHeading(
              'Active Deliveries',
              action: 'Delivery control',
              onAction: onDelivery,
            ),
            if (deliveries.isEmpty)
              const OpsPanel(
                child: OpsEmpty(
                  'No active deliveries',
                  'No deliveries currently in progress.',
                  icon: Icons.local_shipping_outlined,
                ),
              )
            else
              for (final row in deliveries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: DeliveryPreviewCard(
                    order: StoreOrder(row),
                    onTap: () => onOrder(StoreOrder(row)),
                  ),
                ),
            const SizedBox(height: 22),
            OpsHeading(
              'Orders & sales',
              action: 'Reports',
              onAction: onReports,
            ),
            OpsPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _SmallMetric(
                          'Orders received',
                          '${data['orders_placed'] ?? 0}',
                          onTap: () => onOrders('All'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SmallMetric(
                          'Recorded sales',
                          money(amount(data['revenue'])),
                          color: opsGreen,
                          onTap: onReports,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${data['delivered'] ?? 0} delivered · ${data['cancelled_orders'] ?? 0} cancelled',
                    style: const TextStyle(fontSize: 12, color: opsMuted),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'All-time orders. Sales include paid or cash-collected orders.',
                    style: TextStyle(fontSize: 10, color: opsMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            OpsHeading(
              'COD Cash Control',
              action: 'View all',
              onAction: onCash,
            ),
            CashControlPanel(
              data: data,
              onReceive: onReceiveCash,
              onViewAll: onCash,
            ),
            const SizedBox(height: 22),
            const OpsHeading('Quick Actions'),
            LayoutBuilder(
              builder: (_, c) => Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final action in <(String, IconData, VoidCallback)>[
                    ('Add Product', Icons.add_box_outlined, onAddProduct),
                    (
                      'Manage Inventory',
                      Icons.inventory_2_outlined,
                      () => onInventory('all'),
                    ),
                    (
                      'New Orders',
                      Icons.receipt_long_outlined,
                      () => onOrders('New'),
                    ),
                    (
                      'Assign Delivery',
                      Icons.person_add_alt,
                      () => onOrders('Unassigned'),
                    ),
                    ('Create Employee', Icons.badge_outlined, onCreateEmployee),
                    ('Cash Handover', Icons.payments_outlined, onCash),
                    (
                      'Low Stock',
                      Icons.warning_amber_rounded,
                      () => onInventory('low'),
                    ),
                    ('Reports', Icons.bar_chart_outlined, onReports),
                  ])
                    SizedBox(
                      width: (c.maxWidth - 10) / 2,
                      child: Material(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color(0xFFE3EAE6)),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: action.$3,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Icon(action.$2, size: 21, color: opsGreen),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    action.$1,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            OpsHeading(
              'Inventory',
              action: 'Manage products',
              onAction: () => onInventory('all'),
            ),
            OpsPanel(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _SmallMetric(
                          'Published',
                          '${inventory['published'] ?? 0}',
                          onTap: () => onInventory('published'),
                        ),
                      ),
                      Expanded(
                        child: _SmallMetric(
                          'Low stock',
                          '${inventory['low_stock'] ?? 0}',
                          color: opsWarning,
                          onTap: () => onInventory('low'),
                        ),
                      ),
                      Expanded(
                        child: _SmallMetric(
                          'Out of stock',
                          '${inventory['out_of_stock'] ?? 0}',
                          color: opsRed,
                          onTap: () => onInventory('out'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${inventory['recently_updated'] ?? 0} products updated today',
                      style: const TextStyle(fontSize: 11, color: opsMuted),
                    ),
                  ),
                  if (products.isEmpty)
                    const OpsEmpty(
                      'No data yet',
                      'Add a real product to start managing inventory.',
                      icon: Icons.inventory_2_outlined,
                    )
                  else ...[
                    const Divider(height: 24),
                    for (final row in products)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        onTap: () => onProduct(StoreProduct.fromJson(row)),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: SizedBox(
                            width: 42,
                            height: 42,
                            child: ProductPhoto(
                              '${row['image_url'] ?? ''}',
                              height: 42,
                            ),
                          ),
                        ),
                        title: Text(
                          '${row['tamil_name']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          '${row['unit']} · Stock ${row['stock_kg']}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: Text(
                          money(amount(row['price'])),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 22),
            OpsHeading(
              'Delivery Team',
              action: 'Manage team',
              onAction: onTeam,
            ),
            OpsPanel(
              child: Column(
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OpsPill('Available ${team['available'] ?? 0}'),
                      OpsPill('On delivery ${team['on_delivery'] ?? 0}'),
                      OpsPill(
                        'Inactive ${team['inactive'] ?? 0}',
                        warning: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Online/offline presence is not recorded.',
                      style: TextStyle(color: opsMuted, fontSize: 10),
                    ),
                  ),
                  if (people.isEmpty)
                    const OpsEmpty(
                      'No employees yet',
                      'Create an employee, verify their details and activate their account.',
                      icon: Icons.groups_outlined,
                    )
                  else
                    for (final person in people)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        onTap: onTeam,
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: opsMint,
                          child: Text(
                            opsInitial('${person['name']}'),
                            style: const TextStyle(
                              color: opsGreen,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(
                          '${person['name']}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          '${person['employee_code'] ?? ''} · ${person['active_orders']} assigned',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: Icon(
                          person['ready_for_deliveries'] == true
                              ? Icons.verified_outlined
                              : Icons.pending_outlined,
                          size: 19,
                          color: person['ready_for_deliveries'] == true
                              ? opsGreen
                              : opsWarning,
                        ),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const OpsHeading('Recent Activity'),
            OpsPanel(
              child: events.isEmpty
                  ? const OpsEmpty(
                      'No recent activity.',
                      'Recorded order updates and cash receipts will appear here.',
                      icon: Icons.history,
                    )
                  : Column(
                      children: [
                        for (final event in events)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            onTap: event['type'] == 'product'
                                ? () => onInventory('all')
                                : event['order_id'] == null
                                ? onCash
                                : () => onOrders('All'),
                            leading: Icon(
                              event['type'] == 'product'
                                  ? Icons.inventory_2_outlined
                                  : event['type'] == 'cash'
                                  ? Icons.account_balance_wallet_outlined
                                  : Icons.check_circle_outline,
                              color: opsGreen,
                              size: 19,
                            ),
                            title: Text(
                              '${event['title']}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              '${event['detail'] ?? ''}${event['amount'] == null ? '' : ' · ${money(amount(event['amount']))}'}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: Text(
                              opsTime(event['at']),
                              style: const TextStyle(
                                fontSize: 9,
                                color: opsMuted,
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              'Updated ${opsTime(data['generated_at'])} · Pull down to refresh',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: opsMuted),
            ),
          ],
        ),
      );
    },
  );

  void _alertAction(dynamic key) {
    switch (key) {
      case 'cash':
        onCash();
      case 'cash_review':
        onOrders('Cash Review');
      case 'stock':
        onInventory('low');
      case 'team':
        onTeam();
      case 'assignment':
        onOrders('Unassigned');
      case 'delayed':
        onOrders('Delayed');
      case 'attempted':
        onOrders('Delivery Attempted');
      default:
        onOrders('New');
    }
  }
}

class OpsPill extends StatelessWidget {
  final String text;
  final bool warning;
  const OpsPill(this.text, {super.key, this.warning = false});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: warning ? const Color(0xFFFFF4DE) : opsMint,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: warning ? opsWarning : opsGreen,
      ),
    ),
  );
}

class _SmallMetric extends StatelessWidget {
  final String title, value;
  final Color color;
  final VoidCallback? onTap;
  const _SmallMetric(
    this.title,
    this.value, {
    this.color = storeInk,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 10, color: opsMuted)),
      ],
    ),
  );
}

class _CollectionSummary extends StatelessWidget {
  final Map<String, dynamic> data;
  const _CollectionSummary({required this.data});
  @override
  Widget build(BuildContext context) {
    final collected = amount(data['cash_collected']),
        received = amount(data['cash_received_by_store']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 16,
              color: opsGreen,
            ),
            SizedBox(width: 7),
            Text(
              'COD Collection',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _SmallMetric(
                'With delivery team',
                money(amount(data['cash_with_employees'])),
                color: opsWarning,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SmallMetric(
                'Received by store',
                money(received),
                color: opsGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: collected > 0 ? (received / collected).clamp(0, 1) : 0,
            minHeight: 6,
            backgroundColor: const Color(0xFFF0F2EE),
            color: const Color(0xFF18A66A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          collected == 0
              ? 'No collections recorded'
              : '${data['pending_handover_orders'] ?? 0} orders pending handover · balances to date',
          style: const TextStyle(fontSize: 10, color: opsMuted),
        ),
        if (amount(data['cash_unallocated']) > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${money(amount(data['cash_unallocated']))} collected cash needs reconciliation.',
              style: const TextStyle(fontSize: 10, color: opsRed),
            ),
          ),
      ],
    );
  }
}

class _AttentionRow extends StatelessWidget {
  final Map<String, dynamic> alert;
  final VoidCallback onTap;
  const _AttentionRow({required this.alert, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final icon = switch (alert['key']) {
      'cash' => Icons.payments_outlined,
      'stock' => Icons.inventory_2_outlined,
      'team' => Icons.person_off_outlined,
      'assignment' => Icons.person_add_alt,
      'delayed' => Icons.schedule,
      'attempted' => Icons.report_outlined,
      _ => Icons.receipt_long_outlined,
    };
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4DE),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: opsWarning, size: 19),
      ),
      title: Text(
        '${alert['title']}',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${alert['detail']}',
        style: const TextStyle(fontSize: 10, color: opsMuted),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${alert['count']}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 16, color: opsMuted),
        ],
      ),
    );
  }
}

class DeliveryPreviewCard extends StatelessWidget {
  final StoreOrder order;
  final VoidCallback onTap;
  const DeliveryPreviewCard({
    super.key,
    required this.order,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final person = order.data['assigned_to_details'] as Map?;
    final name = '${person?['name'] ?? ''}';
    final eta = DateTime.tryParse('${order.data['estimated_delivery_at']}');
    final started = DateTime.tryParse('${order.data['dispatched_at']}');
    return OpsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.shortId,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              const OpsPill('On the way'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: opsMint,
                child: Text(
                  opsInitial(name),
                  style: const TextStyle(
                    color: opsGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'No employee assigned' : name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${order.data['delivery_address'] ?? ''}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: opsMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  eta != null
                      ? 'Expected ${opsTime(eta.toIso8601String())}'
                      : started != null
                      ? '${DateTime.now().difference(started).inMinutes.clamp(0, 100000)} min since dispatch'
                      : 'Arrival estimate not set',
                  style: const TextStyle(fontSize: 11, color: opsMuted),
                ),
              ),
              Text(
                order.paymentStatus == 'cod'
                    ? '${money(order.total)} COD'
                    : 'Paid',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.route, size: 17),
              label: const Text('Track delivery'),
            ),
          ),
        ],
      ),
    );
  }
}

class CashControlPanel extends StatefulWidget {
  final Map<String, dynamic> data;
  final void Function(Map<String, dynamic>) onReceive;
  final VoidCallback onViewAll;
  const CashControlPanel({
    super.key,
    required this.data,
    required this.onReceive,
    required this.onViewAll,
  });
  @override
  State<CashControlPanel> createState() => _CashControlPanelState();
}

class _CashControlPanelState extends State<CashControlPanel> {
  int _segment = 0;
  @override
  Widget build(BuildContext context) {
    final people = List<Map<String, dynamic>>.from(
      widget.data['cash_employees'] ?? [],
    );
    final receipts = List<Map<String, dynamic>>.from(
      widget.data['cash_receipts'] ?? [],
    );
    return OpsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(
                        [
                          'With Employees',
                          'Pending Confirmation',
                          'Received',
                        ][i],
                        style: const TextStyle(fontSize: 10),
                      ),
                      selected: _segment == i,
                      onSelected: (_) => setState(() => _segment = i),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_segment == 0) ...[
            Text(
              money(amount(widget.data['cash_with_employees'])),
              style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w900,
                color: opsGreen,
              ),
            ),
            Text(
              '${widget.data['pending_handover_orders'] ?? 0} delivered orders awaiting store receipt',
              style: const TextStyle(fontSize: 11, color: opsMuted),
            ),
            if (people.isEmpty)
              const OpsEmpty(
                'No pending collections',
                'Delivery cash held by employees will appear here.',
                icon: Icons.task_alt,
              )
            else
              for (final person in people)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: opsMint,
                            child: Text(
                              opsInitial('${person['name']}'),
                              style: const TextStyle(
                                fontSize: 12,
                                color: opsGreen,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextButton(
                              onPressed: () => widget.onReceive(person),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                alignment: Alignment.centerLeft,
                              ),
                              child: Text(
                                '${person['name']}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            money(amount(person['cash_to_handover'])),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${person['delivered_orders']} delivered orders · Submitted / difference: not recorded',
                        style: const TextStyle(fontSize: 10, color: opsMuted),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => widget.onReceive(person),
                          icon: const Icon(
                            Icons.check_circle_outline,
                            size: 16,
                          ),
                          label: const Text(
                            'Confirm Cash Handover',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ] else if (_segment == 1)
            const OpsEmpty(
              'No submission data yet',
              'Employee-submitted amounts are not recorded. Count cash received in person, then confirm it under With Employees.',
              icon: Icons.pending_actions,
            )
          else ...[
            Text(
              money(amount(widget.data['cash_received_by_store'])),
              style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w900,
                color: opsGreen,
              ),
            ),
            const Text(
              'Cash confirmed by store · all time',
              style: TextStyle(fontSize: 11, color: opsMuted),
            ),
            if (amount(widget.data['cash_direct']) > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Received directly by admin: ${money(amount(widget.data['cash_direct']))}',
                  style: const TextStyle(fontSize: 11, color: opsMuted),
                ),
              ),
            const SizedBox(height: 12),
            const Text(
              'Recent employee handovers',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            if (receipts.isEmpty)
              const OpsEmpty(
                'No handover receipts yet',
                'Confirmed employee handovers will appear here.',
                icon: Icons.receipt_long_outlined,
              )
            else
              for (final receipt in receipts)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.task_alt,
                    color: opsGreen,
                    size: 18,
                  ),
                  title: Text(
                    '${receipt['employee']}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  subtitle: Text(
                    opsTime(receipt['at']),
                    style: const TextStyle(fontSize: 10),
                  ),
                  trailing: Text(
                    money(amount(receipt['amount'])),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}
