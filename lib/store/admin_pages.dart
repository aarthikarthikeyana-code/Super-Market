import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_dashboard.dart';
import 'models.dart';
import 'paged_feed.dart';
import 'state.dart';
import 'widgets.dart';

class OperationsProductCard extends StatelessWidget {
  final StoreProduct product;
  final VoidCallback onEdit, onStock, onPublication;
  const OperationsProductCard({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onStock,
    required this.onPublication,
  });
  @override
  Widget build(BuildContext context) {
    final p = product;
    final out = p.stock <= 0 || !p.inStock;
    return OpsPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 68,
                height: 84,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: opsBaseCream,
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: ProductPhoto(
                  p.imageUrl,
                  height: 76,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.tamilName.isNotEmpty ? p.tamilName : p.englishName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (p.englishName.isNotEmpty &&
                        p.englishName != p.tamilName)
                      Text(
                        p.englishName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: opsMuted),
                      ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (p.brand.isNotEmpty) p.brand,
                        p.unit,
                      ].where((s) => s.isNotEmpty).join(' · '),
                      style: const TextStyle(fontSize: 10, color: opsMuted),
                    ),
                    if (p.sku.isNotEmpty)
                      Text(
                        'SKU: ${p.sku}',
                        style: const TextStyle(fontSize: 10, color: opsMuted),
                      ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          money(p.price),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        AdminStatusBadge(p.published ? 'Published' : 'Hidden'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stock: ${p.stock % 1 == 0 ? p.stock.toInt() : p.stock}',
                      style: const TextStyle(fontSize: 11, color: opsMuted),
                    ),
                    Text(
                      out
                          ? 'Out of stock'
                          : p.stock <= 5
                          ? 'Low stock'
                          : 'In stock',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: out
                            ? opsRed
                            : p.stock <= 5
                            ? opsWarning
                            : opsForestGreen,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit product',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
              ),
              IconButton(
                tooltip: 'Update stock',
                onPressed: onStock,
                icon: const Icon(Icons.inventory_2_outlined, size: 18),
              ),
              IconButton(
                tooltip: p.published ? 'Hide product' : 'Publish product',
                onPressed: onPublication,
                icon: Icon(
                  p.published
                      ? Icons.visibility_off_outlined
                      : Icons.publish_outlined,
                  size: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class OperationsRequests extends ConsumerWidget {
  const OperationsRequests({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(storeApiProvider);
    return Column(
      children: [
        AppBar(title: const Text('Search Requests')),
        Expanded(
          child: PagedFeed<Map<String, dynamic>>(
            queryKey: ('adminRequests', api.adminToken),
            load: api.adminRequestPage,
            identity: (row) => '${row['id']}',
            emptyTitle: 'No search requests',
            emptyMessage: 'Recorded product requests will appear here.',
            itemBuilder: (_, row, _) => OpsPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const AdminIcon(
                        Icons.manage_search,
                        color: opsInfo,
                        background: opsInfoBg,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${row['item_name']}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Flexible(child: AdminStatusBadge('${row['status']}')),
                    ],
                  ),
                  const Divider(height: 20),
                  Text(
                    '${row['customer_phone']}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    opsTime(row['requested_at']),
                    style: const TextStyle(fontSize: 11, color: opsMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class OperationsMore extends StatelessWidget {
  final void Function(String) onOpen;
  const OperationsMore({super.key, required this.onOpen});
  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        sliver: SliverList.list(
          children: [
            const Text(
              'Store tools',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'People, inventory and operations in one place.',
              style: TextStyle(fontSize: 12, color: opsMuted),
            ),
            for (final group
                in <(String, Color, Color, List<(String, String, IconData)>)>[
                  (
                    'People',
                    opsInfo,
                    opsInfoBg,
                    [
                      ('Employees', 'team', Icons.badge_outlined),
                      ('Employee availability', 'team', Icons.groups_outlined),
                    ],
                  ),
                  (
                    'Inventory',
                    opsForestGreen,
                    opsMint,
                    [
                      ('Categories', 'categories', Icons.category_outlined),
                      ('Brands', 'brands', Icons.sell_outlined),
                      (
                        'Stock management',
                        'inventory',
                        Icons.inventory_2_outlined,
                      ),
                      ('Low stock', 'low', Icons.warning_amber_rounded),
                    ],
                  ),
                  (
                    'Operations',
                    opsWarning,
                    opsWarningBg,
                    [
                      ('COD cash handover', 'cash', Icons.payments_outlined),
                      ('Search requests', 'requests', Icons.manage_search),
                      ('Cancelled orders', 'cancelled', Icons.cancel_outlined),
                    ],
                  ),
                  (
                    'Insights',
                    opsInfo,
                    opsInfoBg,
                    [
                      ('Sales reports', 'reports', Icons.bar_chart),
                      ('Order reports', 'reports', Icons.receipt_long_outlined),
                      (
                        'Inventory reports',
                        'reports',
                        Icons.inventory_outlined,
                      ),
                      ('Delivery reports', 'reports', Icons.route),
                    ],
                  ),
                  (
                    'System',
                    opsForestGreen,
                    Color(0xFFE7F8F5),
                    [
                      ('Store settings', 'settings', Icons.settings_outlined),
                      ('Admin profile', 'profile', Icons.person_outline),
                      ('Logout', 'logout', Icons.logout),
                    ],
                  ),
                ]) ...[
              const SizedBox(height: 20),
              OpsHeading(group.$1),
              LayoutBuilder(
                builder: (_, c) => Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final tool in group.$4)
                      SizedBox(
                        width: (c.maxWidth - 10) / 2,
                        child: AdminToolTile(
                          label: tool.$1,
                          icon: tool.$3,
                          color: tool.$2 == 'logout' ? opsRed : group.$2,
                          background: tool.$2 == 'logout' ? opsRedBg : group.$3,
                          onTap: () => onOpen(tool.$2),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}

class OperationsDeliveryControl extends ConsumerStatefulWidget {
  final void Function(StoreOrder) onOrder;
  const OperationsDeliveryControl({super.key, required this.onOrder});
  @override
  ConsumerState<OperationsDeliveryControl> createState() =>
      _OperationsDeliveryControlState();
}

class _OperationsDeliveryControlState
    extends ConsumerState<OperationsDeliveryControl> {
  String _stage = 'Out for Delivery';
  @override
  Widget build(BuildContext context) {
    final api = ref.watch(storeApiProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: AdminWorkflowBanner(
            title: 'Delivery control',
            subtitle:
                'Follow pickups, check trips and resolve delivery issues.',
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
          child: Row(
            children: [
              for (final stage in [
                'Out for Delivery',
                'Assigned',
                'Delivery Attempted',
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      stage == 'Assigned'
                          ? 'Awaiting pickup'
                          : stage == 'Delivery Attempted'
                          ? 'Needs attention'
                          : 'In progress',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _stage == stage
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _stage == stage
                            ? Colors.white
                            : const Color(0xFF15211A),
                      ),
                    ),
                    selected: _stage == stage,
                    selectedColor: const Color(0xFF16A05D),
                    backgroundColor: Colors.white,
                    surfaceTintColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: _stage == stage
                            ? const Color(0xFF16A05D)
                            : const Color(0xFFDDE8E1),
                      ),
                    ),
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _stage = stage),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: PagedFeed<StoreOrder>(
            queryKey: ('deliveryControl', api.adminToken, _stage),
            changes: api.feedChanges,
            load: (cursor) =>
                api.orderPage(cursor: cursor, admin: true, status: _stage),
            identity: (o) => o.id,
            endContent: const OpsPanel(
              color: opsMint,
              child: OpsEmpty(
                'Queue reviewed',
                'Pull down for the latest assignments and trip updates.',
                icon: Icons.route_outlined,
              ),
            ),
            emptyTitle: _stage == 'Out for Delivery'
                ? 'No active deliveries'
                : 'No orders in this stage',
            emptyMessage: 'Packed, assigned orders and delivery progress are shown when they exist.',
            itemBuilder: (_, order, _) => _stage == 'Out for Delivery'
                ? DeliveryPreviewCard(
                    order: order,
                    onTap: () => widget.onOrder(order),
                  )
                : AdminOrderCard(
                    order: order,
                    onTap: () => widget.onOrder(order),
                  ),
          ),
        ),
      ],
    );
  }
}

class OperationsCashControl extends ConsumerWidget {
  final void Function(Map<String, dynamic>) onReceive;
  const OperationsCashControl({super.key, required this.onReceive});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(storeApiProvider);
    return PagedFeed<Map<String, dynamic>>(
      queryKey: ('pendingCashEmployees', api.adminToken),
      changes: api.feedChanges,
      load: (cursor) => api.employeePage(cursor: cursor, cashPending: true),
      identity: (p) => '${p['id']}',
      header: const Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: AdminWorkflowBanner(
          title: 'Cash handover',
          subtitle: 'Count cash, select delivered orders and confirm the exact receipt.',
        ),
      ),
      emptyTitle: 'No pending collections',
      emptyMessage:
          'No employee currently has recorded delivery cash awaiting handover.',
      itemBuilder: (_, p, _) => OpsPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: opsMint,
                  child: Text(
                    opsInitial('${p['name']}'),
                    style: const TextStyle(color: opsGreen),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextButton(
                        onPressed: () => onReceive(p),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerLeft,
                        ),
                        child: Text(
                          '${p['name']}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        '${p['employee_code'] ?? ''}',
                        style: const TextStyle(color: opsMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Text(
                  money(amount(p['cash_to_handover'])),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 19,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Expected cash · delivered orders not yet handed over',
              style: TextStyle(fontSize: 11, color: opsMuted),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => onReceive(p),
                icon: const Icon(Icons.check_circle_outline, size: 17),
                label: const Text('Confirm Cash Handover'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OperationsReports extends ConsumerWidget {
  final void Function(String) onOrders, onInventory;
  const OperationsReports({
    super.key,
    required this.onOrders,
    required this.onInventory,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) => DataView(
    value: ref.watch(adminDashboardProvider),
    onRetry: () => ref.invalidate(adminDashboardProvider),
    builder: (data) {
      final inventory = Map<String, dynamic>.from(data['inventory'] ?? {});
      final collected = amount(data['cash_collected']);
      final received = amount(data['cash_received_by_store']);
      final count = amount(data['orders_placed']);
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Reports & analytics',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'All time · updated ${opsTime(data['generated_at'])}',
            style: const TextStyle(fontSize: 11, color: opsMuted),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (_, c) => Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final metric in <(String, String, IconData, Color, Color)>[
                  (
                    'Recorded sales',
                    opsMoney(data['revenue']),
                    Icons.bar_chart,
                    opsForestGreen,
                    opsMint,
                  ),
                  (
                    'Orders received',
                    '${data['orders_placed'] ?? '—'}',
                    Icons.receipt_long_outlined,
                    opsInfo,
                    opsInfoBg,
                  ),
                  (
                    'Received by store',
                    opsMoney(data['cash_received_by_store']),
                    Icons.account_balance_outlined,
                    opsForestGreen,
                    Color(0xFFE7F8F5),
                  ),
                  (
                    'Cash with employees',
                    opsMoney(data['cash_with_employees']),
                    Icons.payments_outlined,
                    opsWarning,
                    opsWarningBg,
                  ),
                ])
                  SizedBox(
                    width: (c.maxWidth - 10) / 2,
                    child: AdminMetricCard(
                      label: metric.$1,
                      value: metric.$2,
                      icon: metric.$3,
                      color: metric.$4,
                      background: metric.$5,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          OpsPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const OpsHeading('Cash reconciliation'),
                _reportRow('Cash collected', opsMoney(data['cash_collected'])),
                _reportRow(
                  'Received by store',
                  opsMoney(data['cash_received_by_store']),
                ),
                _reportRow(
                  'Cash with employees',
                  opsMoney(data['cash_with_employees']),
                ),
                _reportRow('COD still to collect', opsMoney(data['cash_due'])),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: collected > 0
                        ? (received / collected).clamp(0, 1)
                        : 0,
                    minHeight: 8,
                    backgroundColor: opsMint,
                    color: opsGreen,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  collected > 0
                      ? '${(received / collected * 100).clamp(0, 100).toStringAsFixed(1)}% of collected cash received by store'
                      : data['cash_collected'] == null
                      ? 'Cash balances not available yet'
                      : 'No collections recorded',
                  style: const TextStyle(fontSize: 11, color: opsMuted),
                ),
                if (amount(data['cash_unallocated']) > 0)
                  Text(
                    '${opsMoney(data['cash_unallocated'])} requires reconciliation',
                    style: const TextStyle(fontSize: 11, color: opsRed),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const OpsHeading('Order breakdown'),
          OpsPanel(
            child: Column(
              children: [
                for (final row in <(String, String, String, Color)>[
                  ('New orders', 'new_orders', 'New', opsInfo),
                  ('Preparing', 'preparing', 'Preparing', opsWarning),
                  ('Packed', 'packed', 'Packed', opsInfo),
                  (
                    'On the way',
                    'active_deliveries',
                    'Out for Delivery',
                    opsForestGreen,
                  ),
                  ('Delivered', 'delivered', 'Delivered', opsGreen),
                  (
                    'Attempted',
                    'delivery_attempted',
                    'Delivery Attempted',
                    opsWarning,
                  ),
                  ('Cancelled', 'cancelled_orders', 'Cancelled', opsRed),
                ])
                  InkWell(
                    onTap: () => onOrders(row.$3),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  row.$1,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              Text(
                                '${data[row.$2] ?? '—'}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.chevron_right,
                                size: 15,
                                color: opsMuted,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: count > 0
                                ? (amount(data[row.$2]) / count).clamp(0, 1)
                                : 0,
                            minHeight: 4,
                            color: row.$4,
                            backgroundColor: opsBaseCream,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const OpsHeading('Inventory health'),
          LayoutBuilder(
            builder: (_, c) => Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final row in <(String, String, String, Color, Color)>[
                  (
                    'Published',
                    'published',
                    'published',
                    opsForestGreen,
                    opsMint,
                  ),
                  ('Hidden', 'hidden', 'hidden', opsMuted, Color(0xFFEDF1EE)),
                  ('Low stock', 'low_stock', 'low', opsWarning, opsWarningBg),
                  ('Out of stock', 'out_of_stock', 'out', opsRed, opsRedBg),
                ])
                  SizedBox(
                    width: (c.maxWidth - 10) / 2,
                    child: AdminMetricCard(
                      label: row.$1,
                      value: '${inventory[row.$2] ?? '—'}',
                      icon: Icons.inventory_2_outlined,
                      color: row.$4,
                      background: row.$5,
                      onTap: () => onInventory(row.$3),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sales include paid and cash-collected orders. Charts show recorded aggregates; no estimated trends.',
            style: TextStyle(fontSize: 11, color: opsMuted),
          ),
        ],
      );
    },
  );
  Widget _reportRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: opsMuted),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}
