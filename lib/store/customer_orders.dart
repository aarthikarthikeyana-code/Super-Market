import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api.dart';
import 'models.dart';
import 'paged_feed.dart';
import 'state.dart';
import 'widgets.dart';

// Presentation for the customer Orders tab only. No order mutations live here.
const _emerald = Color(0xFF0D8247);
const _darkGreen = Color(0xFF075B32);
const _gold = Color(0xFFF5B400);
const _mint = Color(0xFFF4F9F5);
const _ink = Color(0xFF17211D);
const _muted = Color(0xFF6F7C76);

enum CustomerOrderFilter {
  all('All Orders', Icons.inventory_2_outlined),
  ongoing('Ongoing', Icons.local_shipping_outlined),
  delivered('Delivered', Icons.check_circle_outline),
  cancelled('Cancelled', Icons.cancel_outlined);

  final String label;
  final IconData icon;
  const CustomerOrderFilter(this.label, this.icon);

  bool matches(StoreOrder order) => switch (this) {
    all => true,
    ongoing => !['Delivered', 'Cancelled'].contains(order.status),
    delivered => order.status == 'Delivered',
    cancelled => order.status == 'Cancelled',
  };
}

class CustomerOrdersList extends ConsumerStatefulWidget {
  final Object? accountKey;
  final ValueChanged<StoreOrder> onOpen;
  const CustomerOrdersList({
    super.key,
    required this.accountKey,
    required this.onOpen,
  });
  @override
  ConsumerState<CustomerOrdersList> createState() => _CustomerOrdersListState();
}

class _CustomerOrdersListState extends ConsumerState<CustomerOrdersList> {
  CustomerOrderFilter _filter = CustomerOrderFilter.all;

  Future<StorePage<StoreOrder>> _load(
    StoreApi api,
    String? cursor,
    CustomerOrderFilter filter,
  ) async {
    // Customer orders API intentionally stays unchanged. Scan real API pages
    // until this UI filter has a match or the actual history has ended.
    final seen = <String>{if (cursor != null) cursor};
    while (true) {
      final page = await api.orderPage(cursor: cursor);
      final matching = page.items.where(filter.matches).toList();
      if (matching.isNotEmpty || page.nextCursor == null) {
        return StorePage(items: matching, nextCursor: page.nextCursor);
      }
      if (!seen.add(page.nextCursor!)) {
        throw StoreException('Order history changed. Pull down to refresh.');
      }
      cursor = page.nextCursor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = ref.watch(storeApiProvider);
    final selected = _filter;
    return ColoredBox(
      color: _mint,
      child: PagedFeed<StoreOrder>(
        queryKey: ('customer_orders_tab', widget.accountKey, selected),
        changes: api.feedChanges,
        load: (cursor) => _load(api, cursor, selected),
        identity: (order) => order.id,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        header: Column(
          children: [
            const OrdersHero(),
            OrderFilterTabs(
              selected: selected,
              onSelected: (filter) => setState(() => _filter = filter),
            ),
          ],
        ),
        emptyContent: OrdersEmptyState(
          title: selected == CustomerOrderFilter.all
              ? 'No orders yet'
              : 'No ${selected.label.toLowerCase()} orders',
          message: selected == CustomerOrderFilter.all
              ? 'Your grocery orders will appear here after checkout.'
              : 'Orders with this status will appear here.',
        ),
        endContent: const _OrdersCaughtUp(),
        itemBuilder: (_, order, _) =>
            CustomerOrderCard(order: order, onTap: () => widget.onOpen(order)),
      ),
    );
  }
}

class OrdersHero extends StatelessWidget {
  const OrdersHero({super.key});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 8, 16, 18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      gradient: const LinearGradient(
        colors: [Color(0xFFE0F4E7), Color(0xFFF9FCF6)],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: CustomPaint(
      painter: const _OrderWaves(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 8, 18),
        child: LayoutBuilder(
          builder: (context, constraints) => Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.shopping_bag_outlined,
                      size: 25,
                      color: _emerald,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'My Orders',
                      style: TextStyle(
                        fontSize: 28,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.8,
                        color: _darkGreen,
                      ),
                    ),
                    Container(
                      width: 52,
                      height: 3,
                      margin: const EdgeInsets.only(top: 9, bottom: 9),
                      decoration: BoxDecoration(
                        color: _gold,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Text(
                      'Track and manage your grocery orders',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class OrderFilterTabs extends StatelessWidget {
  final CustomerOrderFilter selected;
  final ValueChanged<CustomerOrderFilter> onSelected;
  const OrderFilterTabs({
    super.key,
    required this.selected,
    required this.onSelected,
  });
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
    child: Row(
      children: [
        for (final filter in CustomerOrderFilter.values)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Semantics(
              selected: selected == filter,
              button: true,
              child: Material(
                color: selected == filter ? _emerald : Colors.white,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  key: ValueKey('orders-filter-${filter.name}'),
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => onSelected(filter),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected == filter
                            ? _emerald
                            : const Color(0xFFDCEAE0),
                      ),
                      boxShadow: selected == filter
                          ? [
                              BoxShadow(
                                color: _emerald.withValues(alpha: .12),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          filter.icon,
                          size: 19,
                          color: selected == filter ? Colors.white : _emerald,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          filter.label,
                          style: TextStyle(
                            color: selected == filter ? Colors.white : _ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

({Color color, IconData icon}) _orderStatusStyle(String status) =>
    switch (status) {
      'New' || 'Payment Pending' => (
        color: const Color(0xFF328BC1),
        icon: Icons.receipt_long_outlined,
      ),
      'Preparing' => (
        color: const Color(0xFF9C7200),
        icon: Icons.inventory_2_outlined,
      ),
      'Packed' => (color: _emerald, icon: Icons.inventory_2_outlined),
      'Out for Delivery' || 'Delivery Attempted' => (
        color: const Color(0xFFF28C28),
        icon: Icons.local_shipping_outlined,
      ),
      'Delivered' => (color: _emerald, icon: Icons.check_circle_outline),
      'Cancelled' => (
        color: const Color(0xFFC65353),
        icon: Icons.cancel_outlined,
      ),
      _ => (color: _muted, icon: Icons.receipt_long_outlined),
    };

class CustomerOrderStatusBadge extends StatelessWidget {
  final String status;
  const CustomerOrderStatusBadge({super.key, required this.status});
  @override
  Widget build(BuildContext context) {
    final style = _orderStatusStyle(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, color: style.color, size: 15),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              status,
              style: TextStyle(
                color: style.color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomerOrderCard extends StatelessWidget {
  final StoreOrder order;
  final VoidCallback onTap;
  const CustomerOrderCard({
    super.key,
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = order.items;
    final date = DateTime.tryParse('${order.data['created_at']}')?.toLocal();
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
    final dateLabel = date == null
        ? null
        : '${date.day} ${months[date.month - 1]} ${date.year}';
    final style = _orderStatusStyle(order.status);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _darkGreen.withValues(alpha: .065),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFE0EEE3)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('customer-order-${order.id}'),
          onTap: onTap,
          child: CustomPaint(
            painter: const _OrderWaves(subtle: true),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 43,
                        height: 46,
                        decoration: BoxDecoration(
                          color: style.color.withValues(alpha: .09),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          Icons.shopping_bag_outlined,
                          color: style.color,
                          size: 25,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order #${order.id}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.3,
                                fontWeight: FontWeight.w800,
                                color: _darkGreen,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 3,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (dateLabel != null) ...[
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 12,
                                    color: _muted,
                                  ),
                                  Text(
                                    dateLabel,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: _muted,
                                    ),
                                  ),
                                  const Text(
                                    '·',
                                    style: TextStyle(color: _muted),
                                  ),
                                ],
                                Text(
                                  '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: _muted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 22,
                        color: _emerald,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: CustomerOrderStatusBadge(status: order.status),
                  ),
                  if (items.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    OrderProductPreview(items: items),
                  ],
                  const SizedBox(height: 14),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 16,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        money(order.total),
                        style: const TextStyle(
                          color: _darkGreen,
                          fontWeight: FontWeight.w900,
                          fontSize: 23,
                          letterSpacing: -.5,
                        ),
                      ),
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View details',
                            style: TextStyle(
                              color: _emerald,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                          SizedBox(width: 3),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: _emerald,
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (!['Delivered', 'Cancelled'].contains(order.status))
                    CustomerOrderProgress(order: order),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OrderProductPreview extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const OrderProductPreview({super.key, required this.items});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const gap = 7.0;
      final slots = ((constraints.maxWidth + gap) / 57).floor().clamp(2, 5);
      final needsMore = items.length > slots;
      final visible = needsMore ? slots - 1 : items.length.clamp(0, 4);
      final remaining = items.length - visible;
      final count = visible + (remaining > 0 ? 1 : 0);
      final size = ((constraints.maxWidth - gap * (count - 1)) / count).clamp(
        32.0,
        58.0,
      );
      return Row(
        children: [
          for (var index = 0; index < visible; index++) ...[
            if (index > 0) const SizedBox(width: gap),
            Semantics(
              label: productLabel(items[index]),
              image: true,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Container(
                  width: size,
                  height: size,
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Color(0xFFF1F7F2)),
                  child: ProductPhoto(
                    '${items[index]['image_url'] ?? ''}',
                    height: size - 8,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
          if (remaining > 0) ...[
            const SizedBox(width: gap),
            Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFE4F3E8),
                borderRadius: BorderRadius.circular(13),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '+$remaining',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _darkGreen,
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    },
  );
}

class CustomerOrderProgress extends StatelessWidget {
  final StoreOrder order;
  const CustomerOrderProgress({super.key, required this.order});
  @override
  Widget build(BuildContext context) {
    // These are the existing backend stages. Attempts/payment exceptions show
    // their actual status badge instead of a fabricated successful journey.
    const stages = [
      'New',
      'Preparing',
      'Packed',
      'Out for Delivery',
      'Delivered',
    ];
    const labels = ['Placed', 'Preparing', 'Packed', 'On the way', 'Delivered'];
    final current = stages.indexOf(order.status);
    if (current < 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 17),
      child: Column(
        children: [
          Row(
            children: [
              for (var index = 0; index < stages.length; index++) ...[
                if (index > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index <= current
                          ? _emerald
                          : const Color(0xFFE3EBE5),
                    ),
                  ),
                Container(
                  width: 19,
                  height: 19,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < current
                        ? _emerald
                        : index == current
                        ? _gold
                        : const Color(0xFFE7EEE8),
                  ),
                  child: Icon(
                    index < current
                        ? Icons.check
                        : index == current
                        ? Icons.circle
                        : Icons.circle_outlined,
                    size: index == current ? 7 : 11,
                    color: index < current
                        ? Colors.white
                        : index == current
                        ? _darkGreen
                        : const Color(0xFFA7B8AC),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 7),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < labels.length; index++)
                Expanded(
                  child: Text(
                    labels[index],
                    textAlign: index == 0
                        ? TextAlign.left
                        : index == labels.length - 1
                        ? TextAlign.right
                        : TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      height: 1.3,
                      color: index == current ? _darkGreen : _muted,
                      fontWeight: index == current
                          ? FontWeight.w800
                          : FontWeight.w500,
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

class OrdersEmptyState extends StatelessWidget {
  final String title, message;
  final Widget? action;
  const OrdersEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.action,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: _darkGreen,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, height: 1.6, color: _muted),
        ),
        if (action != null) ...[const SizedBox(height: 18), action!],
      ],
    ),
  );
}

class _OrdersCaughtUp extends StatelessWidget {
  const _OrdersCaughtUp();
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 4, 16, 24),
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(
        colors: [Color(0xFFE1F2E6), Color(0xFFF6FAF2)],
      ),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle_rounded, color: _gold, size: 23),
              const SizedBox(height: 5),
              const Text(
                'You’re all caught up!',
                style: TextStyle(
                  color: _darkGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'No more orders to show',
                style: TextStyle(color: _muted, fontSize: 11, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _OrderWaves extends CustomPainter {
  final bool subtle;
  const _OrderWaves({this.subtle = false});
  @override
  void paint(Canvas canvas, Size size) {
    final wave = Path()
      ..moveTo(0, size.height * .88)
      ..cubicTo(
        size.width * .30,
        size.height * .65,
        size.width * .57,
        size.height * 1.10,
        size.width,
        size.height * .74,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      wave,
      Paint()..color = _emerald.withValues(alpha: subtle ? .035 : .065),
    );
    if (!subtle) {
      canvas.drawCircle(
        Offset(size.width * .92, size.height * .15),
        35,
        Paint()..color = const Color(0xFFFFD65A).withValues(alpha: .08),
      );
    }
  }

  @override
  bool shouldRepaint(_OrderWaves oldDelegate) => subtle != oldDelegate.subtle;
}
