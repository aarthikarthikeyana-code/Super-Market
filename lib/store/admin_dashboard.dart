import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart';
import 'state.dart';
import 'widgets.dart';

import 'admin_design_system.dart';
export 'admin_design_system.dart';

class OpsPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final Border? border;
  const OpsPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.border,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color ?? Colors.white.withOpacity(0.95),
      borderRadius: BorderRadius.circular(22),
      border: border ?? Border.all(color: const Color(0xFFEEF3EF), width: 1.2),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF087532).withOpacity(0.04),
          blurRadius: 20,
          offset: const Offset(0, 6),
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
      final alerts = List<Map<String, dynamic>>.from(data['alerts'] ?? []);
      final snapshot = ref.watch(adminDashboardProvider);
      return RefreshIndicator(
        onRefresh: () =>
            ref.refresh(adminDashboardProvider.future).then((_) {}),
        child: CustomScrollView(
          key: const PageStorageKey('operations-dashboard'),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList.list(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Welcome back',
                              style: TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Store operations · ${opsDate(today['date'])}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: opsMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AdminStatusBadge(
                        snapshot.hasError
                            ? 'Refresh failed'
                            : snapshot.isLoading
                            ? 'Updating'
                            : data['generated_at'] == null
                            ? 'No data yet'
                            : 'Live data',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/admin-dashboard-banner.png',
                        width: double.infinity,
                        height: 140,
                        fit: BoxFit.contain,
                        excludeFromSemantics: true,
                        errorBuilder: (_, error, stackTrace) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  ),
                  LayoutBuilder(
                    builder: (_, c) {
                      final columns = c.maxWidth < 290
                          ? 2
                          : c.maxWidth > 650
                          ? 6
                          : 3;
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final metric
                              in <
                                (String, String, String, IconData, Color, Color)
                              >[
                                (
                                  'New orders',
                                  'new',
                                  'New',
                                  Icons.shopping_bag_outlined,
                                  opsWarning,
                                  opsWarningBg,
                                ),
                                (
                                  'Preparing',
                                  'preparing',
                                  'Preparing',
                                  Icons.kitchen_outlined,
                                  opsForestGreen,
                                  opsMint,
                                ),
                                (
                                  'Packed',
                                  'packed',
                                  'Packed',
                                  Icons.inventory_2_outlined,
                                  opsInfo,
                                  opsInfoBg,
                                ),
                                (
                                  'Out for delivery',
                                  'out_for_delivery',
                                  'Out for Delivery',
                                  Icons.local_shipping_outlined,
                                  opsInfo,
                                  Color(0xFFE7F8F5),
                                ),
                                (
                                  'Delivered today',
                                  'delivered',
                                  'Delivered',
                                  Icons.task_alt,
                                  opsForestGreen,
                                  opsGlassMint,
                                ),
                                (
                                  'Needs attention',
                                  'needs_attention',
                                  'Active',
                                  Icons.warning_amber_rounded,
                                  opsRed,
                                  opsRedBg,
                                ),
                              ])
                            SizedBox(
                              width:
                                  (c.maxWidth - (columns - 1) * 10) / columns,
                              child: AdminMetricCard(
                                label: metric.$1,
                                value: '${today[metric.$2] ?? '—'}',
                                icon: metric.$4,
                                color: metric.$5,
                                background: metric.$6,
                                onTap: () => onOrders('Today ${metric.$3}'),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  OpsPanel(
                    color: opsForestGreen,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Recorded sales',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: onReports,
                              child: const Text(
                                'Reports',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          opsMoney(data['revenue']),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'All time · paid and cash-collected orders',
                          style: TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  OpsPanel(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SmallMetric(
                                'Cash with employees',
                                opsMoney(data['cash_with_employees']),
                                color: opsWarning,
                                onTap: onCash,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Current outstanding',
                                style: TextStyle(fontSize: 10, color: opsMuted),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SmallMetric(
                                'Cash received by store',
                                opsMoney(data['cash_received_by_store']),
                                color: opsForestGreen,
                                onTap: onCash,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'All-time receipts',
                                style: TextStyle(fontSize: 10, color: opsMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const OpsHeading('Quick actions'),
                  LayoutBuilder(
                    builder: (_, c) => Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final action
                            in <(String, IconData, VoidCallback, Color, Color)>[
                              (
                                'Add product',
                                Icons.add_box_outlined,
                                onAddProduct,
                                opsInfo,
                                opsInfoBg,
                              ),
                              (
                                'Receive cash',
                                Icons.payments_outlined,
                                onCash,
                                opsWarning,
                                opsWarningBg,
                              ),
                              (
                                'Assign delivery',
                                Icons.route_outlined,
                                () => onOrders('Unassigned'),
                                opsForestGreen,
                                opsMint,
                              ),
                              (
                                'Reports',
                                Icons.bar_chart_rounded,
                                onReports,
                                opsRed,
                                opsRedBg,
                              ),
                            ])
                          SizedBox(
                            width: (c.maxWidth - 10) / 2,
                            child: AdminToolTile(
                              label: action.$1,
                              icon: action.$2,
                              onTap: action.$3,
                              color: action.$4,
                              background: action.$5,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (alerts.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const OpsHeading('Needs attention'),
                    for (final alert in alerts)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: OpsPanel(
                          color: opsWarningBg,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          child: _AttentionRow(
                            alert: alert,
                            onTap: () => _alertAction(alert['key']),
                          ),
                        ),
                      ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Updated ${opsTime(data['generated_at'])} · Pull down to refresh',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10, color: opsMuted),
                  ),
                ],
              ),
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
              AdminStatusBadge(order.status),
            ],
          ),
          if (order.items.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: ProductPhoto(
                      '${order.items.first['image_url'] ?? ''}',
                      height: 40,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    order.items
                        .map(
                          (item) =>
                              '${productLabel(item)} ? ${item['quantity']}',
                        )
                        .join(', '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: opsMuted),
                  ),
                ),
              ],
            ),
          ],
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

class CashControlPanel extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final people = List<Map<String, dynamic>>.from(
      data['cash_employees'] ?? [],
    );
    final collected = amount(data['cash_collected']);
    final received = amount(data['cash_received_by_store']);
    return OpsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _SmallMetric(
                  'With employees',
                  opsMoney(data['cash_with_employees']),
                  color: opsWarning,
                  onTap: onViewAll,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SmallMetric(
                  'Received by store',
                  opsMoney(data['cash_received_by_store']),
                  color: opsForestGreen,
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
              color: opsGreen,
              backgroundColor: opsMint,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data['pending_handover_orders'] == null
                ? 'Cash balances not available yet'
                : '${data['pending_handover_orders']} delivered orders awaiting store receipt',
            style: const TextStyle(fontSize: 11, color: opsMuted),
          ),
          if (amount(data['cash_unallocated']) > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${opsMoney(data['cash_unallocated'])} needs reconciliation',
                style: const TextStyle(color: opsRed, fontSize: 11),
              ),
            ),
          if (people.isEmpty)
            const OpsEmpty(
              'No pending collections',
              'Recorded employee cash awaiting handover will appear here.',
              icon: Icons.account_balance_wallet_outlined,
            )
          else
            for (final person in people)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Material(
                  color: opsBaseCream,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => onReceive(person),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 17,
                            backgroundColor: opsGlassMint,
                            child: Text(
                              opsInitial('${person['name']}'),
                              style: const TextStyle(
                                fontSize: 12,
                                color: opsForestGreen,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${person['name']}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${person['delivered_orders']} delivered orders',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: opsMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Flexible(
                            child: Text(
                              opsMoney(person['cash_to_handover']),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            size: 17,
                            color: opsMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          if (amount(data['cash_direct']) > 0)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'Received directly by admin: ${opsMoney(data['cash_direct'])}',
                style: const TextStyle(fontSize: 11, color: opsMuted),
              ),
            ),
        ],
      ),
    );
  }
}
