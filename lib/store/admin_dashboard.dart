import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'loading.dart';
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

class OperationsDashboard extends ConsumerStatefulWidget {
  final void Function(String) onOrders, onInventory;
  final void Function(String category)? onCategory;
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
    this.onCategory,
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
  ConsumerState<OperationsDashboard> createState() =>
      _OperationsDashboardState();
}

class _OperationsDashboardState extends ConsumerState<OperationsDashboard> {
  String _summaryPeriod = 'today';
  String _chartPeriod = 'today';

  void Function(String) get onOrders => widget.onOrders;
  void Function(String) get onInventory => widget.onInventory;
  void Function(String)? get onCategory => widget.onCategory;
  VoidCallback get onAddProduct => widget.onAddProduct;
  VoidCallback get onCreateEmployee => widget.onCreateEmployee;
  VoidCallback get onTeam => widget.onTeam;
  VoidCallback get onCash => widget.onCash;
  VoidCallback get onDelivery => widget.onDelivery;
  VoidCallback get onReports => widget.onReports;
  void Function(StoreOrder) get onOrder => widget.onOrder;
  void Function(StoreProduct) get onProduct => widget.onProduct;
  void Function(Map<String, dynamic>) get onReceiveCash => widget.onReceiveCash;

  @override
  Widget build(BuildContext context) => DataView(
    value: ref.watch(adminDashboardProvider),
    retainOnRefresh: true,
    onRetry: () => ref.invalidate(adminDashboardProvider),
    loading: const SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            AppSkeleton(kind: SkeletonKind.summary, padded: false),
            SizedBox(height: 12),
            AppSkeleton(kind: SkeletonKind.grid, padded: false),
            SizedBox(height: 12),
            AppSkeleton(kind: SkeletonKind.detail, padded: false),
            SizedBox(height: 12),
            AppSkeleton(kind: SkeletonKind.list, count: 2, padded: false),
          ],
        ),
      ),
    ),
    builder: (data) {
      final today = Map<String, dynamic>.from(data['today'] ?? {});
      final adminProfile = Map<String, dynamic>.from(
        data['admin_profile'] ?? {},
      );
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
                  // 1. Agaram Welcome Banner (Reference Theme)
                  Builder(
                    builder: (context) {
                      final adminName = '${adminProfile['name'] ?? ''}'.trim();
                      final now = DateTime.now();
                      const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
                      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                      final dateFormatted = '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';

                      return AgaramWelcomeBanner(
                        adminName: adminName,
                        dateText: dateFormatted,
                        statusBeacon: LivePulseBeacon(
                          color: snapshot.hasError
                              ? const Color(0xFFE11D48)
                              : snapshot.isLoading
                              ? const Color(0xFFD97706)
                              : const Color(0xFF10B981),
                          label: snapshot.hasError
                              ? 'Sync Retry'
                              : snapshot.isLoading
                              ? 'Updating...'
                              : 'Live Store',
                          backgroundColor: snapshot.hasError
                              ? const Color(0xFFFFE4E6)
                              : snapshot.isLoading
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFFE8F7EE),
                          borderColor: snapshot.hasError
                              ? const Color(0xFFFECDD3)
                              : snapshot.isLoading
                              ? const Color(0xFFFDE68A)
                              : const Color(0xFFC7EBD4),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),

                  // 2. Agaram 4 Key Stats 2x2 Grid (Reference Screen 2)
                  LayoutBuilder(
                    builder: (_, c) {
                      final itemW = (c.maxWidth - 10) / 2;
                      final inventory = Map<String, dynamic>.from(data['inventory'] ?? {});
                      final periods = Map<String, dynamic>.from(
                        data['period_stats'] ?? {},
                      );
                      final selected = Map<String, dynamic>.from(
                        periods[_summaryPeriod] ?? {},
                      );
                      final totalOrdersVal = '${selected['orders'] ?? 0}';
                      final totalCustomersVal = '${data['total_customers'] ?? 0}';
                      final totalProductsVal = '${inventory['published'] ?? 0}';
                      final totalSalesVal = opsMoney(selected['sales'] ?? 0);

                      return Column(
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: AdminPeriodDropdown(
                              value: _summaryPeriod,
                              onChanged: (period) => setState(
                                () => _summaryPeriod = period,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                          SizedBox(
                            width: itemW,
                            child: AgaramStatCard(
                              label: 'Total Orders',
                              value: totalOrdersVal,
                              icon: Icons.shopping_bag_rounded,
                              color: const Color(0xFF10B981),
                              background: const Color(0xFFE8F7EE),
                              border: const Color(0xFFC7EBD4),
                              onTap: () => onOrders('All'),
                            ),
                          ),
                          SizedBox(
                            width: itemW,
                            child: AgaramStatCard(
                              label: 'Total Customers',
                              value: totalCustomersVal,
                              icon: Icons.people_alt_rounded,
                              color: const Color(0xFF2563EB),
                              background: const Color(0xFFEFF6FF),
                              border: const Color(0xFFBFDBFE),
                              onTap: onTeam,
                            ),
                          ),
                          SizedBox(
                            width: itemW,
                            child: AgaramStatCard(
                              label: 'Total Products',
                              value: '$totalProductsVal Items',
                              icon: Icons.apple_rounded,
                              color: const Color(0xFFEA580C),
                              background: const Color(0xFFFFF7ED),
                              border: const Color(0xFFFED7AA),
                              onTap: () => onInventory('all'),
                            ),
                          ),
                          SizedBox(
                            width: itemW,
                            child: AgaramStatCard(
                              label: 'Total Sales',
                              value: totalSalesVal,
                              icon: Icons.emoji_events_rounded,
                              color: const Color(0xFF0F7645),
                              background: const Color(0xFFECFDF5),
                              border: const Color(0xFFA7F3D0),
                              onTap: onReports,
                            ),
                          ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // 3. Agaram Sales Overview Weekly Bar Chart (Reference Screen 2)
                  AgaramOrdersChart(
                    data: data,
                    period: _chartPeriod,
                    onPeriodChanged: (period) => setState(
                      () => _chartPeriod = period,
                    ),
                  ),
                  const SizedBox(height: 22),

                  // 3. Section: Live Orders Pipeline Radar (6 Stages)
                  const OpsHeading('Live Orders Pipeline'),
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
                                  const Color(0xFFD97706),
                                  const Color(0xFFFEF3C7),
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
                                  const Color(0xFF0284C7),
                                  const Color(0xFFE0F2FE),
                                ),
                                (
                                  'Out for delivery',
                                  'out_for_delivery',
                                  'Out for Delivery',
                                  Icons.local_shipping_outlined,
                                  const Color(0xFF7C3AED),
                                  const Color(0xFFEDE9FE),
                                ),
                                (
                                  'Delivered today',
                                  'delivered',
                                  'Delivered',
                                  Icons.task_alt,
                                  const Color(0xFF059669),
                                  const Color(0xFFD1FAE5),
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
                                value: '${today[metric.$2] ?? '0'}',
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
                  const SizedBox(height: 22),

                  // 4. Quick Actions Command Dock
                  const OpsHeading('Operations Command Hub'),
                  LayoutBuilder(
                    builder: (_, c) => Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final action
                            in <(String, IconData, VoidCallback, Color, Color, String)>[
                              (
                                'Add Product',
                                Icons.add_box_rounded,
                                onAddProduct,
                                const Color(0xFF0284C7),
                                const Color(0xFFE0F2FE),
                                'Scan barcode or publish item',
                              ),
                              (
                                'Collect Cash',
                                Icons.payments_rounded,
                                onCash,
                                const Color(0xFFD97706),
                                const Color(0xFFFEF3C7),
                                'Staff cash reconciliation',
                              ),
                              (
                                'Assign Delivery',
                                Icons.route_rounded,
                                () => onOrders('Unassigned'),
                                opsForestGreen,
                                opsMint,
                                'Route pending shipments',
                              ),
                              (
                                'Reports & Tax',
                                Icons.bar_chart_rounded,
                                onReports,
                                const Color(0xFFE11D48),
                                const Color(0xFFFFE4E6),
                                'Profit, loss & GST reports',
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
                              detail: action.$6,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // 5. Store Categories Hub (Quick Category Filtering)
                  const SizedBox(height: 22),
                  OpsHeading(
                    'Product Categories · வகைகள்',
                    action: 'All 140 Products',
                    onAction: () => onInventory('all'),
                  ),
                  LayoutBuilder(
                    builder: (ctx, c) {
                      final itemWidth = (c.maxWidth - 10) / 2;
                      final categories = [
                        (
                          id: 'Groceries',
                          tamil: 'அரிசி & தானியங்கள்',
                          english: 'Rice & Grains',
                          count: '20 Items',
                          icon: Icons.grain_rounded,
                          color: const Color(0xFF0F7645),
                          bgColor: const Color(0xFFE8F7EE),
                          borderColor: const Color(0xFFC7EBD4),
                        ),
                        (
                          id: 'பருப்பு வகைகள்',
                          tamil: 'பருப்பு வகைகள்',
                          english: 'Dals & Pulses',
                          count: '20 Items',
                          icon: Icons.spa_rounded,
                          color: const Color(0xFFD97706),
                          bgColor: const Color(0xFFFEF3C7),
                          borderColor: const Color(0xFFFDE68A),
                        ),
                        (
                          id: 'மாவு வகைகள்',
                          tamil: 'மாவு வகைகள்',
                          english: 'Flours & Rava',
                          count: '20 Items',
                          icon: Icons.bakery_dining_rounded,
                          color: const Color(0xFFB45309),
                          bgColor: const Color(0xFFFFFBEB),
                          borderColor: const Color(0xFFFED7AA),
                        ),
                        (
                          id: 'எண்ணெய் வகைகள்',
                          tamil: 'எண்ணெய் வகைகள்',
                          english: 'Oils & Pure Ghee',
                          count: '20 Items',
                          icon: Icons.opacity_rounded,
                          color: const Color(0xFFEA580C),
                          bgColor: const Color(0xFFFFEDD5),
                          borderColor: const Color(0xFFFDBA74),
                        ),
                        (
                          id: 'மசாலா வகைகள்',
                          tamil: 'மசாலா வகைகள்',
                          english: 'Spices & Masalas',
                          count: '20 Items',
                          icon: Icons.local_fire_department_rounded,
                          color: const Color(0xFFDC2626),
                          bgColor: const Color(0xFFFEE2E2),
                          borderColor: const Color(0xFFFECACA),
                        ),
                        (
                          id: 'பானங்கள்',
                          tamil: 'பானங்கள்',
                          english: 'Tea & Coffee',
                          count: '20 Items',
                          icon: Icons.coffee_rounded,
                          color: const Color(0xFF7C3AED),
                          bgColor: const Color(0xFFEDE9FE),
                          borderColor: const Color(0xFFDDD6FE),
                        ),
                        (
                          id: 'மளிகைப் பொருட்கள்',
                          tamil: 'மளிகைப் பொருட்கள்',
                          english: 'Pantry Staples',
                          count: '20 Items',
                          icon: Icons.shopping_basket_rounded,
                          color: const Color(0xFF0D9488),
                          bgColor: const Color(0xFFCCFBF1),
                          borderColor: const Color(0xFF99F6E4),
                        ),
                      ];

                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final cat in categories)
                            SizedBox(
                              width: itemWidth,
                              child: BouncingTap(
                                onTap: () => onCategory?.call(cat.id),
                                child: Material(
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  side: BorderSide(
                                    color: cat.borderColor,
                                    width: 1.2,
                                  ),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () => onCategory?.call(cat.id),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: cat.bgColor,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                cat.icon,
                                                size: 18,
                                                color: cat.color,
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 7,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: cat.bgColor,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                cat.count,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                  color: cat.color,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          cat.tamil,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF15211A),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                cat.english,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: opsMuted,
                                                ),
                                              ),
                                            ),
                                            Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              size: 11,
                                              color: cat.color,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                  // 6. Critical Attention Alerts Radar (if any)
                  if (alerts.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    const OpsHeading('Critical Attention Radar'),
                    for (final alert in alerts)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: const Color(0xFFFFFBEB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(
                              color: const Color(0xFFF59E0B).withOpacity(0.35),
                              width: 1.2,
                            ),
                          ),
                          child: InkWell(
                            onTap: () => _alertAction(alert['key']),
                            borderRadius: BorderRadius.circular(18),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFF59E0B).withOpacity(0.4),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.warning_amber_rounded,
                                      color: Color(0xFFD97706),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${alert['title']}',
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w800,
                                            color: storeInk,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${alert['detail']}',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: opsMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD97706),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${alert['count']}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
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

                  const SizedBox(height: 20),
                  Text(
                    'Last synchronized ${opsTime(data['generated_at'])} · Pull down to refresh live console',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: opsMuted,
                    ),
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
    final date = DateTime.tryParse('${order.data['delivered_at'] ?? ''}');
    final estimate = DateTime.tryParse(
      '${order.data['estimated_delivery_at'] ?? ''}',
    );
    final address = '${order.data['delivery_address'] ?? ''}'.trim();
    final deliveryNote = '${order.data['delivery_note'] ?? ''}'.trim();
    final isDelivered = order.status == 'Delivered';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2EBE5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F3B25).withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: #ID + Status Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '#${order.shortId.toUpperCase()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    AdminStatusBadge(order.status),
                  ],
                ),
                const SizedBox(height: 4),

                // Subtitle: Delivered on ... OR Expected by ...
                Text(
                  isDelivered
                      ? (date != null
                          ? 'Delivered on ${date.day}/${date.month}/${date.year} • ${TimeOfDay.fromDateTime(date).format(context)}'
                      : 'Delivery time not recorded')
                    : estimate != null
                    ? 'Estimated ${estimate.day}/${estimate.month} • ${TimeOfDay.fromDateTime(estimate).format(context)}'
                    : 'Arrival estimate not recorded',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 14),

                if (isDelivered) ...[
                  // 4-Step Horizontal Tracker Line (Screen 4 Card 1)
                  AdminOrderProgressTracker(order: order),
                ] else ...[
                  // 4 Product Thumbnails Row (Screen 4 Card 2)
                  if (order.items.isNotEmpty) ...[
                    Row(
                      children: [
                        for (final item in order.items.take(4))
                          Container(
                            width: 52,
                            height: 56,
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: ProductPhoto(
                              '${item['image_url'] ?? ''}',
                              height: 48,
                              fit: BoxFit.contain,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Delivery employee and recorded delivery details.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF0FDF4), Color(0xFFECFDF5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFC7EBD4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF16A05D),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.two_wheeler_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name.isNotEmpty
                                        ? name
                                        : 'Delivery employee not recorded',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  if (address.isNotEmpty)
                                    Text(
                                      address,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (deliveryNote.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            deliveryNote,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
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
