import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_dashboard.dart';
import 'delivery_tracking.dart';
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(
                  product: p,
                  onEdit: onEdit,
                  onStock: onStock,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Photo with Discount Badge in corner matching Screen 2
              Stack(
                children: [
                  Container(
                    width: 76,
                    height: 88,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ProductPhoto(
                      p.imageUrl,
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    left: 4,
                    child: p.discountPercent > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${p.discountPercent}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Product Info: Tamil Name + English/Unit + Price + Stock
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.tamilName.isNotEmpty ? p.tamilName : p.englishName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (p.englishName.isNotEmpty &&
                            p.englishName != p.tamilName)
                          p.englishName,
                        if (p.brand.isNotEmpty) p.brand,
                        p.unit,
                      ].where((s) => s.isNotEmpty).join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          money(p.price),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          money(p.price * 1.12),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                            decoration: TextDecoration.lineThrough,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (!p.published) ...[
                          const SizedBox(width: 8),
                          const AdminStatusBadge('Hidden'),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          'Stock: ${p.stock % 1 == 0 ? p.stock.toInt() : p.stock} • ',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          out
                              ? 'Out of stock'
                              : p.stock <= 5
                              ? 'Low stock'
                              : 'In stock',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: out
                                ? opsRed
                                : p.stock <= 5
                                ? opsWarning
                                : const Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Right Action Buttons matching Screen 2
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Edit product',
                    visualDensity: VisualDensity.compact,
                    onPressed: onEdit,
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 19,
                      color: Color(0xFF475569),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Update stock',
                    visualDensity: VisualDensity.compact,
                    onPressed: onStock,
                    icon: const Icon(
                      Icons.inventory_2_outlined,
                      size: 19,
                      color: Color(0xFF475569),
                    ),
                  ),
                  IconButton(
                    tooltip: p.published ? 'Hide product' : 'Publish product',
                    visualDensity: VisualDensity.compact,
                    onPressed: onPublication,
                    icon: Icon(
                      p.published
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 19,
                      color: p.published
                          ? const Color(0xFF64748B)
                          : const Color(0xFF059669),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}

class ProductDetailScreen extends StatefulWidget {
  final StoreProduct product;
  final VoidCallback onEdit;
  final VoidCallback onStock;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onStock,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final p = widget.product;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: Stack(
        children: [
          // 1. Scrollable Content
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Image Section with ambient harvest background
                Container(
                  height: 340,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFEF9C3), Color(0xFFFDE68A), Color(0xFFFEF3C7)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Subtle decorative grain pattern
                      Positioned(
                        right: -30,
                        bottom: -20,
                        child: Opacity(
                          opacity: 0.15,
                          child: const Icon(
                            Icons.agriculture_rounded,
                            size: 200,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                          child: ProductPhoto(
                            p.imageUrl,
                            height: 220,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Curved Bottom Sheet Content matching Screen 3
                Transform.translate(
                  offset: const Offset(0, -28),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 20,
                          offset: Offset(0, -6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tamil Title
                        Text(
                          p.tamilName.isNotEmpty ? p.tamilName : p.englishName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // English Name / Brand
                        Text(
                          [
                            if (p.englishName.isNotEmpty && p.englishName != p.tamilName)
                              p.englishName,
                            if (p.brand.isNotEmpty) p.brand,
                          ].join(' • '),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Price Row
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            Text(
                              money(p.price),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            if (p.mrp > p.price)
                              Text(
                                money(p.mrp),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF94A3B8),
                                  decoration: TextDecoration.lineThrough,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            if (p.discountPercent > 0)
                              Text(
                                '${p.discountPercent}% off',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Selling unit: ${p.unit}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Description
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'Description',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          p.description.isNotEmpty
                              ? p.description
                              : 'No product description recorded.',
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Admin Stock & Status Row
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Inventory Stock: ${p.stock % 1 == 0 ? p.stock.toInt() : p.stock} ${p.unit}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  widget.onStock();
                                },
                                icon: const Icon(Icons.edit, size: 14),
                                label: const Text('Update Stock'),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF16A05D),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Top Floating Navigation
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A), size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Sticky Bottom Action Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: AgaramGradientButton(
                width: double.infinity,
                height: 50,
                onPressed: () {
                  Navigator.pop(context);
                  widget.onEdit();
                },
                icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                label: const Text('Edit & Configure Product'),
              ),
            ),
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
                      ('Sales reports', 'report_sales', Icons.bar_chart),
                      ('Order reports', 'report_orders', Icons.receipt_long_outlined),
                      (
                        'Inventory reports',
                        'report_inventory',
                        Icons.inventory_outlined,
                      ),
                      ('Delivery reports', 'report_delivery', Icons.route),
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
  final void Function(StoreOrder) onAssign;
  const OperationsDeliveryControl({
    super.key,
    required this.onOrder,
    required this.onAssign,
  });
  @override
  ConsumerState<OperationsDeliveryControl> createState() =>
      _OperationsDeliveryControlState();
}

class _OperationsDeliveryControlState
    extends ConsumerState<OperationsDeliveryControl> {
  String _stage = 'Ready to Assign';
  @override
  Widget build(BuildContext context) {
    final api = ref.watch(storeApiProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Delivery Management',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LiveDeliveryMonitorScreen(
                      onOrder: widget.onOrder,
                    ),
                  ),
                ),
                icon: const Icon(Icons.my_location_rounded, size: 15),
                label: const Text('Live riders'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF087A50),
                  side: const BorderSide(color: Color(0xFFD2EBDD)),
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
                  textStyle: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2EBE5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabs = [
                ('Ready to assign', 'Ready to Assign'),
                ('Assigned', 'Assigned'),
                ('On delivery', 'Out for Delivery'),
                ('Needs retry', 'Delivery Attempted'),
              ];
              const spacing = 8.0;
              final columns = constraints.maxWidth < 520 ? 2 : 4;
              final width =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final tab in tabs)
                    SizedBox(
                      width: width,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() => _stage = tab.$2),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: _stage == tab.$2
                                ? const LinearGradient(
                                    colors: [Color(0xFF10B981), Color(0xFF047857)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: _stage == tab.$2 ? null : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _stage == tab.$2
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF10B981).withOpacity(0.22),
                                      blurRadius: 7,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            tab.$1,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: _stage == tab.$2
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: _stage == tab.$2
                                  ? Colors.white
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        Expanded(
          child: PagedFeed<StoreOrder>(
            queryKey: ('deliveryControl', api.adminToken, _stage),
            changes: api.feedChanges,
            load: (cursor) =>
                api.orderPage(cursor: cursor, admin: true, status: _stage),
            identity: (o) => o.id,
            emptyTitle: switch (_stage) {
              'Ready to Assign' => 'No deliveries waiting for a rider',
              'Assigned' => 'No assigned deliveries waiting for pickup',
              'Delivery Attempted' => 'No deliveries need another attempt',
              _ => 'No active trips right now',
            },
            emptyMessage: switch (_stage) {
              'Ready to Assign' => 'Packed orders appear here when they are ready for a delivery employee.',
              'Assigned' => 'Orders assigned to an employee appear here until the trip starts.',
              'Delivery Attempted' => 'Failed delivery attempts appear here for follow-up.',
              _ => 'Orders currently out for delivery appear here with rider progress.',
            },
            itemBuilder: (_, order, _) => DeliveryPreviewCard(
              order: order,
              onTap: () => widget.onOrder(order),
              onAssign: _stage == 'Ready to Assign'
                  ? () => widget.onAssign(order)
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

class OrderPeriodDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const OrderPeriodDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const _periods = <String, String>{
    'today': 'Today',
    'week': 'Week',
    'month': 'Month',
    'six_month': '6 Months',
    'all': 'All',
  };

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    initialValue: _periods.containsKey(value) ? value : 'today',
    onSelected: onChanged,
    position: PopupMenuPosition.under,
    offset: const Offset(0, 6),
    color: Colors.white,
    surfaceTintColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: Color(0xFFE1E9E4)),
    ),
    itemBuilder: (context) => _periods.entries
        .map(
          (entry) => PopupMenuItem<String>(
            value: entry.key,
            child: Text(
              entry.value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        )
        .toList(),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F0),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFD2EBDD)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _periods[value] ?? 'Today',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF087A50),
            ),
          ),
          const SizedBox(width: 5),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 17, color: Color(0xFF087A50)),
        ],
      ),
    ),
  );
}

class OrderStageDropdown extends StatelessWidget {
  final String value;
  final Map<String, dynamic> counts;
  final ValueChanged<String> onChanged;

  const OrderStageDropdown({
    super.key,
    required this.value,
    required this.counts,
    required this.onChanged,
  });

  static const _stages = <(String, String)>[
    ('All active', 'Active'),
    ('New', 'New'),
    ('Preparing', 'Preparing'),
    ('Packed', 'Packed'),
    ('Assigned', 'Assigned'),
    ('On delivery', 'Out for Delivery'),
    ('Attempted', 'Delivery Attempted'),
    ('Delayed', 'Delayed'),
  ];

  @override
  Widget build(BuildContext context) {
    final selected = _stages.firstWhere(
      (stage) => stage.$2 == value,
      orElse: () => _stages.first,
    );
    final count = (counts[selected.$2] as num?)?.toInt();
    return PopupMenuButton<String>(
      initialValue: value,
      onSelected: onChanged,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 6),
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE1E9E4)),
      ),
      itemBuilder: (context) => _stages
          .map(
            (stage) => PopupMenuItem<String>(
              value: stage.$2,
              child: Row(
                children: [
                  Expanded(child: Text(stage.$1)),
                  Text(
                    '${(counts[stage.$2] as num?)?.toInt() ?? 0}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF75847C),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
      child: Container(
        constraints: const BoxConstraints(minHeight: 38),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: const Color(0xFFDDE7E1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tune_rounded, size: 15, color: Color(0xFF52645A)),
            const SizedBox(width: 7),
            Text(
              '${selected.$1}${count == null ? '' : ' · $count'}',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF33483B),
              ),
            ),
            const SizedBox(width: 3),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 17,
              color: Color(0xFF52645A),
            ),
          ],
        ),
      ),
    );
  }
}

class LiveDeliveryMonitorScreen extends ConsumerWidget {
  final void Function(StoreOrder) onOrder;
  const LiveDeliveryMonitorScreen({
    super.key,
    required this.onOrder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(storeApiProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Live riders')),
      body: PagedFeed<StoreOrder>(
        queryKey: ('liveDeliveryRiders', api.adminToken),
        changes: api.feedChanges,
        load: (cursor) => api.orderPage(
          cursor: cursor,
          admin: true,
          status: 'Out for Delivery',
        ),
        identity: (order) => order.id,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        header: const Padding(
          padding: EdgeInsets.fromLTRB(0, 0, 0, 8),
          child: Text(
            'Active deliveries and the employee’s latest shared GPS location.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ),
        emptyTitle: 'No riders on active deliveries',
        emptyMessage: 'Assigned employee trips will appear here while orders are out for delivery.',
        itemBuilder: (_, order, _) => Column(
          children: [
            DeliveryPreviewCard(
              order: order,
              onTap: () => onOrder(order),
            ),
            DeliveryTrackingCard(
              orderId: order.id,
              admin: true,
            ),
          ],
        ),
      ),
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
            AgaramGradientButton(
              width: double.infinity,
              height: 48,
              onPressed: () => onReceive(p),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Confirm Cash Handover'),
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
          // Header matching Screen 11
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reports & Analytics',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Operational metrics and performance',
                    style: TextStyle(fontSize: 11, color: opsMuted, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2EBE5)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF0F7645)),
                    SizedBox(width: 5),
                    Text(
                      'This Month',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F7645)),
                    ),
                    SizedBox(width: 3),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Color(0xFF0F7645)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3 Stat Cards in a row (Screen 11)
          LayoutBuilder(
            builder: (_, c) {
              final w = (c.maxWidth - 16) / 3;
              return Row(
                children: [
                  SizedBox(
                    width: w,
                    child: AgaramStatCard(
                      label: 'Total Sales',
                      value: opsMoney(data['revenue']),
                      icon: Icons.currency_rupee_rounded,
                      color: const Color(0xFF0F7645),
                      background: const Color(0xFFECFDF5),
                      border: const Color(0xFFA7F3D0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: w,
                    child: AgaramStatCard(
                      label: 'Total Orders',
                      value: '${data['orders_placed'] ?? '—'}',
                      icon: Icons.shopping_bag_outlined,
                      color: const Color(0xFF10B981),
                      background: const Color(0xFFE8F7EE),
                      border: const Color(0xFFC7EBD4),
                      onTap: () => onOrders('All'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: w,
                    child: AgaramStatCard(
                      label: 'New Customers',
                      value: '${data['total_customers'] ?? '—'}',
                      icon: Icons.person_add_alt_1_rounded,
                      color: const Color(0xFF2563EB),
                      background: const Color(0xFFEFF6FF),
                      border: const Color(0xFFBFDBFE),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),

          // Sales Trend Card (Screen 11)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE2EBE5), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Sales Trend',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F7EE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('This Month', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF0F7645))),
                          SizedBox(width: 3),
                          Icon(Icons.keyboard_arrow_down_rounded, size: 13, color: Color(0xFF0F7645)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Builder(
                  builder: (context) {
                    final series = Map<String, dynamic>.from(
                      data['revenue_series'] ?? const {},
                    );
                    final points = List<Map<String, dynamic>>.from(
                      series['month'] ?? const [],
                    );
                    final values = points
                        .map((point) => amount(point['value']))
                        .toList();
                    final maxValue = values.fold<double>(
                      0,
                      (max, value) => value > max ? value : max,
                    );
                    final stride = points.length <= 6
                        ? 1
                        : (points.length / 6).ceil();
                    final shown = [
                      for (var index = 0; index < points.length; index++)
                        if (index % stride == 0 || index == points.length - 1)
                          points[index],
                    ];
                    if (maxValue <= 0) {
                      return const SizedBox(
                        height: 110,
                        child: Center(
                          child: Text(
                            'No sales recorded this month',
                            style: TextStyle(fontSize: 11, color: opsMuted),
                          ),
                        ),
                      );
                    }
                    return SizedBox(
                      height: 110,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (final point in shown)
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    width: 20,
                                    height: 65 * amount(point['value']) / maxValue,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF34D399), Color(0xFF047857)],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${point['label'] ?? ''}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Top Categories Card (Screen 11)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE2EBE5), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Top Categories',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      'Published products',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if ((data['inventory_categories'] as List? ?? const []).isEmpty)
                  const Text(
                    'No published categories',
                    style: TextStyle(fontSize: 11, color: opsMuted),
                  )
                else
                  for (final category in List<Map<String, dynamic>>.from(
                    data['inventory_categories'],
                  ))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${category['category'] ?? 'Uncategorized'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Text(
                          '${category['products'] ?? 0}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F7645),
                          ),
                        ),
                      ],
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
