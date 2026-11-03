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
    return OpsPanel(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 70,
                  height: 78,
                  child: ProductPhoto(p.imageUrl, height: 78),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.tamilName.isNotEmpty ? p.tamilName : p.englishName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (p.englishName.isNotEmpty &&
                        p.englishName != p.tamilName)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          p.englishName,
                          style: const TextStyle(fontSize: 11, color: opsMuted),
                        ),
                      ),
                    const SizedBox(height: 5),
                    Text(
                      [
                        if (p.brand.isNotEmpty) p.brand,
                        p.category,
                        p.unit,
                      ].join(' · '),
                      style: const TextStyle(fontSize: 10, color: opsMuted),
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          money(p.price),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        OpsPill(
                          p.published ? 'Published' : 'Hidden',
                          warning: !p.published,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                p.stock <= 0 ? Icons.error_outline : Icons.inventory_2_outlined,
                size: 15,
                color: p.stock <= 5 ? opsWarning : opsMuted,
              ),
              const SizedBox(width: 6),
              Text(
                'Stock ${p.stock % 1 == 0 ? p.stock.toInt() : p.stock}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: p.stock <= 5 ? opsWarning : opsMuted,
                ),
              ),
              if (!p.inStock)
                const Text(
                  ' · Unavailable',
                  style: TextStyle(fontSize: 11, color: opsRed),
                ),
            ],
          ),
          const Divider(height: 22),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 15),
                  label: const Text('Edit', style: TextStyle(fontSize: 11)),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: onStock,
                  icon: const Icon(Icons.inventory_2_outlined, size: 15),
                  label: const Text('Stock', style: TextStyle(fontSize: 11)),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: onPublication,
                  icon: Icon(
                    p.published
                        ? Icons.visibility_off_outlined
                        : Icons.publish_outlined,
                    size: 15,
                  ),
                  label: Text(
                    p.published ? 'Hide' : 'Publish',
                    style: const TextStyle(fontSize: 11),
                  ),
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
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.manage_search, color: opsGreen),
                title: Text('${row['item_name']}'),
                subtitle: Text(
                  '${row['customer_phone']}\n${opsTime(row['requested_at'])}',
                ),
                trailing: OpsPill('${row['status']}'),
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
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
    children: [
      const Text(
        'More',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 4),
      const Text(
        'Your store, organised.',
        style: TextStyle(color: opsMuted, fontSize: 12),
      ),
      for (final group in <(String, List<(String, String, IconData)>)>[
        (
          'PEOPLE',
          [
            ('Employees', 'team', Icons.badge_outlined),
            ('Employee Availability', 'team', Icons.groups_outlined),
          ],
        ),
        (
          'INVENTORY',
          [
            ('Categories', 'categories', Icons.category_outlined),
            ('Brands', 'brands', Icons.sell_outlined),
            ('Stock Management', 'inventory', Icons.inventory_2_outlined),
            ('Low Stock', 'low', Icons.warning_amber_rounded),
          ],
        ),
        (
          'OPERATIONS',
          [
            ('COD Cash Handover', 'cash', Icons.payments_outlined),
            ('Delivery Slots', 'slots', Icons.schedule),
            ('Search Requests', 'requests', Icons.manage_search),
            ('Cancelled Orders', 'cancelled', Icons.cancel_outlined),
          ],
        ),
        (
          'INSIGHTS',
          [
            ('Sales Reports', 'reports', Icons.bar_chart),
            ('Order Reports', 'reports', Icons.receipt_long_outlined),
            ('Inventory Reports', 'reports', Icons.inventory_outlined),
            ('Delivery Reports', 'reports', Icons.route),
          ],
        ),
        (
          'SYSTEM',
          [
            ('Store Settings', 'settings', Icons.settings_outlined),
            ('Admin Profile', 'profile', Icons.person_outline),
            ('Logout', 'logout', Icons.logout),
          ],
        ),
      ]) ...[
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 10),
          child: Text(
            group.$1,
            style: const TextStyle(
              fontSize: 10,
              color: opsMuted,
              letterSpacing: 1.3,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        OpsPanel(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < group.$2.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                ListTile(
                  dense: true,
                  leading: Icon(
                    group.$2[i].$3,
                    size: 20,
                    color: group.$2[i].$2 == 'logout' ? opsRed : opsGreen,
                  ),
                  title: Text(
                    group.$2[i].$1,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: opsMuted,
                  ),
                  onTap: () => onOpen(group.$2[i].$2),
                ),
              ],
            ],
          ),
        ),
      ],
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
          padding: EdgeInsets.fromLTRB(18, 12, 18, 6),
          child: Text(
            'Delivery Control',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            'Track trips, check assignments and resolve delivery issues.',
            style: TextStyle(fontSize: 12, color: opsMuted),
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
                      style: const TextStyle(fontSize: 11),
                    ),
                    selected: _stage == stage,
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
            emptyTitle: _stage == 'Out for Delivery'
                ? 'No active deliveries'
                : 'No orders in this stage',
            emptyMessage: 'Packed, assigned orders and delivery progress are shown when they exist.',
            itemBuilder: (_, order, _) => _stage == 'Out for Delivery'
                ? DeliveryPreviewCard(
                    order: order,
                    onTap: () => widget.onOrder(order),
                  )
                : OrderSummaryCard(
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
        padding: EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cash Handover',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 8),
            Text(
              'Count the cash in person. Choose the delivered orders, enter the exact amount received and confirm the store receipt.',
              style: TextStyle(color: opsMuted, fontSize: 12, height: 1.6),
            ),
          ],
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
      return ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'Operations Reports',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'Recorded totals to date · updated ${opsTime(data['generated_at'])}',
            style: const TextStyle(fontSize: 11, color: opsMuted),
          ),
          const SizedBox(height: 20),
          const OpsHeading('Sales & cash'),
          OpsPanel(
            child: Column(
              children: [
                _reportRow(
                  'Revenue from paid / collected orders',
                  money(amount(data['revenue'])),
                ),
                _reportRow(
                  'Cash collected',
                  money(amount(data['cash_collected'])),
                ),
                _reportRow(
                  'Cash received by store',
                  money(amount(data['cash_received_by_store'])),
                ),
                _reportRow(
                  'Cash with employees',
                  money(amount(data['cash_with_employees'])),
                ),
                _reportRow(
                  'COD still to collect',
                  money(amount(data['cash_due'])),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const OpsHeading('Orders & delivery'),
          OpsPanel(
            child: Column(
              children: [
                for (final row in <(String, String, String)>[
                  ('All orders received', 'orders_placed', 'All'),
                  ('Cancelled orders', 'cancelled_orders', 'Cancelled'),
                  ('New orders', 'new_orders', 'New'),
                  ('Preparing', 'preparing', 'Preparing'),
                  ('Packed', 'packed', 'Packed'),
                  ('On the way', 'active_deliveries', 'Out for Delivery'),
                  ('Delivered', 'delivered', 'Delivered'),
                  (
                    'Delivery attempted',
                    'delivery_attempted',
                    'Delivery Attempted',
                  ),
                ])
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onTap: () => onOrders(row.$3),
                    title: Text(row.$1, style: const TextStyle(fontSize: 12)),
                    trailing: Text(
                      '${data[row.$2] ?? 0}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const OpsHeading('Inventory'),
          OpsPanel(
            child: Column(
              children: [
                for (final row in <(String, String, String)>[
                  ('Published products', 'published', 'published'),
                  ('Hidden products', 'hidden', 'hidden'),
                  ('Low stock', 'low_stock', 'low'),
                  ('Out of stock', 'out_of_stock', 'out'),
                ])
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onTap: () => onInventory(row.$3),
                    title: Text(row.$1, style: const TextStyle(fontSize: 12)),
                    trailing: Text(
                      '${inventory[row.$2] ?? 0}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
              ],
            ),
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
