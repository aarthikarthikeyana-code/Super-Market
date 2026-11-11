import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_design_system.dart';
import 'loading.dart';
import 'models.dart';
import 'state.dart';
import 'widgets.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  final String reportType;
  final void Function(String) onOrders;
  final void Function(String) onInventory;

  const AdminReportsScreen({
    super.key,
    required this.reportType,
    required this.onOrders,
    required this.onInventory,
  });

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  String _period = 'today';

  static const _periodNames = <String, String>{
    'today': 'Today',
    'week': 'Week',
    'month': 'Month',
    'all': 'All time',
  };

  @override
  Widget build(BuildContext context) => DataView<Map<String, dynamic>>(
    value: ref.watch(adminDashboardProvider),
    retainOnRefresh: true,
    onRetry: () => ref.invalidate(adminDashboardProvider),
    loading: const Padding(
      padding: EdgeInsets.all(16),
      child: AppSkeleton(kind: SkeletonKind.detail, padded: false),
    ),
    builder: (data) {
      final periodStats = Map<String, dynamic>.from(
        data['period_stats'] ?? const {},
      );
      final selected = Map<String, dynamic>.from(
        periodStats[_period] ?? const {},
      );
      final inventory = Map<String, dynamic>.from(
        data['inventory'] ?? const {},
      );
      final title = _title(widget.reportType);
      final metrics = _metrics(selected, inventory);
      final chart = _chart(data, selected);

      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _subtitle(widget.reportType),
                      style: const TextStyle(fontSize: 11, color: opsMuted),
                    ),
                  ],
                ),
              ),
              _ReportPeriodDropdown(
                value: _period,
                periods: _periodNames,
                onChanged: (period) => setState(() => _period = period),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 8.0;
              final width = (constraints.maxWidth - spacing) / 2;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (var index = 0; index < metrics.length; index++)
                    SizedBox(
                      width: width,
                      child: _ReportMetric(
                        metric: metrics[index],
                        tint: _metricTints[index % _metricTints.length],
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          _ReportChart(
            title: chart.title,
            points: chart.points,
            currency: chart.currency,
            bars: chart.bars,
            emptyMessage: chart.emptyMessage,
          ),
          if (widget.reportType == 'sales') ...[
            const SizedBox(height: 12),
            const Text(
              'Revenue uses paid and cash-collected orders. No estimates are included.',
              style: TextStyle(fontSize: 11, color: opsMuted),
            ),
          ],
          if (widget.reportType == 'inventory') ...[
            const SizedBox(height: 12),
            const Text(
              'Restock entries count recorded additions. Each quantity stays with its product pack unit.',
              style: TextStyle(fontSize: 11, color: opsMuted),
            ),
            const SizedBox(height: 18),
            _InventoryStockLists(
              receipts: List<Map<String, dynamic>>.from(
                Map<String, dynamic>.from(
                  data['inventory_stock_receipts'] ?? const {},
                )[_period] ?? const [],
              ),
              lowStock: List<Map<String, dynamic>>.from(
                data['low_stock_products'] ?? const [],
              ),
              onViewLowStock: () => widget.onInventory('low'),
            ),
          ],
        ],
      );
    },
  );

  List<_ReportMetricData> _metrics(
    Map<String, dynamic> selected,
    Map<String, dynamic> inventory,
  ) {
    switch (widget.reportType) {
      case 'orders':
        return [
          _ReportMetricData('Orders', _count(selected['orders']), Icons.receipt_long_outlined),
          _ReportMetricData('Completed', _count(selected['completed']), Icons.task_alt_rounded),
          _ReportMetricData('Attempted', _count(selected['attempted']), Icons.replay_rounded),
          _ReportMetricData('Cancelled', _count(selected['cancelled']), Icons.cancel_outlined),
        ];
      case 'inventory':
        return [
          _ReportMetricData('Published', _count(inventory['published']), Icons.inventory_2_outlined),
          _ReportMetricData('Low stock', _count(inventory['low_stock']), Icons.warning_amber_rounded),
          _ReportMetricData('Out of stock', _count(inventory['out_of_stock']), Icons.remove_shopping_cart_outlined),
          _ReportMetricData('Restock entries', _count(selected['stock_receipts']), Icons.add_box_outlined),
        ];
      case 'delivery':
        return [
          _ReportMetricData('On delivery', _count(selected['out_for_delivery']), Icons.two_wheeler_outlined),
          _ReportMetricData('Completed', _count(selected['completed']), Icons.task_alt_rounded),
          _ReportMetricData('Attempted', _count(selected['attempted']), Icons.replay_rounded),
          _ReportMetricData('Cancelled', _count(selected['cancelled']), Icons.cancel_outlined),
        ];
      default:
        final sales = amount(selected['sales']);
        final orders = amount(selected['orders']);
        return [
          _ReportMetricData('Sales', opsMoney(selected['sales']), Icons.currency_rupee_rounded),
          _ReportMetricData('Orders', _count(selected['orders']), Icons.shopping_bag_outlined),
          _ReportMetricData(
            'Average order',
            orders > 0 ? money(sales / orders) : '—',
            Icons.calculate_outlined,
          ),
        ];
    }
  }

  _ReportChartData _chart(
    Map<String, dynamic> data,
    Map<String, dynamic> selected,
  ) {
    if (widget.reportType == 'inventory') {
      final series = Map<String, dynamic>.from(
        data['inventory_stock_series'] ?? const {},
      );
      final rawPoints = series[_period] as List? ?? const [];
      return _ReportChartData(
        title: 'Stock received · entries per time bucket',
        bars: true,
        points: [
          for (final point in rawPoints)
            _ReportPoint(
              '${point['label'] ?? ''}',
              amount(point['value']),
            ),
        ],
        emptyMessage: 'No stock additions recorded for this period',
      );
    }

    if (widget.reportType == 'delivery') {
      return _ReportChartData(
        title: 'Delivery outcomes',
        bars: true,
        points: [
          _ReportPoint('On delivery', amount(selected['out_for_delivery'])),
          _ReportPoint('Completed', amount(selected['completed'])),
          _ReportPoint('Attempted', amount(selected['attempted'])),
          _ReportPoint('Cancelled', amount(selected['cancelled'])),
        ],
        emptyMessage: 'No delivery orders in this period',
      );
    }

    final key = widget.reportType == 'orders' ? 'orders_series' : 'revenue_series';
    final series = Map<String, dynamic>.from(data[key] ?? const {});
    final rawPoints = series[_period] as List? ?? const [];
    return _ReportChartData(
      title: widget.reportType == 'orders' ? 'Orders over time' : 'Revenue over time',
      currency: widget.reportType != 'orders',
      points: [
        for (final point in rawPoints)
          _ReportPoint(
            '${point['label'] ?? ''}',
            amount(point['value']),
          ),
      ],
      emptyMessage: widget.reportType == 'orders'
          ? 'No orders in this period'
          : 'No sales in this period',
    );
  }

  String _title(String type) => switch (type) {
    'orders' => 'Order reports',
    'inventory' => 'Inventory reports',
    'delivery' => 'Delivery reports',
    _ => 'Sales reports',
  };

  String _subtitle(String type) => switch (type) {
    'orders' => 'Order volume and outcomes',
    'inventory' => 'Current stock and product changes',
    'delivery' => 'Delivery activity and outcomes',
    _ => 'Recorded revenue and order value',
  };

  String _count(dynamic value) => value == null ? '—' : '${amount(value).toInt()}';
}

class _ReportPeriodDropdown extends StatelessWidget {
  final String value;
  final Map<String, String> periods;
  final ValueChanged<String> onChanged;

  const _ReportPeriodDropdown({
    required this.value,
    required this.periods,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    initialValue: value,
    onSelected: onChanged,
    position: PopupMenuPosition.under,
    offset: const Offset(0, 6),
    color: Colors.white,
    surfaceTintColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(13),
      side: const BorderSide(color: Color(0xFFE1E9E4)),
    ),
    itemBuilder: (context) => periods.entries
        .map(
          (entry) => PopupMenuItem<String>(
            value: entry.key,
            child: Text(entry.value),
          ),
        )
        .toList(),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F0),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFD2EBDD)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF087A50)),
          const SizedBox(width: 6),
          Text(
            periods[value] ?? 'Today',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF087A50),
            ),
          ),
          const SizedBox(width: 3),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF087A50)),
        ],
      ),
    ),
  );
}

class _ReportMetricData {
  final String label;
  final String value;
  final IconData icon;
  const _ReportMetricData(this.label, this.value, this.icon);
}

class _InventoryStockLists extends StatelessWidget {
  final List<Map<String, dynamic>> receipts;
  final List<Map<String, dynamic>> lowStock;
  final VoidCallback onViewLowStock;

  const _InventoryStockLists({
    required this.receipts,
    required this.lowStock,
    required this.onViewLowStock,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _InventoryListHeading(title: 'Stock received', count: receipts.length),
      if (receipts.isEmpty)
        const _InventoryEmptyRow('No stock additions in this period')
      else
        for (final receipt in receipts.take(8)) ...[
          _StockReceiptRow(receipt: receipt),
          if (receipt != receipts.take(8).last)
            const Divider(height: 1, color: Color(0xFFE9EFEB)),
        ],
      const SizedBox(height: 22),
      Row(
        children: [
          Expanded(
            child: _InventoryListHeading(
              title: 'Low stock',
              count: lowStock.length,
            ),
          ),
          TextButton(
            onPressed: onViewLowStock,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('View all'),
          ),
        ],
      ),
      if (lowStock.isEmpty)
        const _InventoryEmptyRow('No products are currently low on stock')
      else
        for (final product in lowStock.take(8)) ...[
          _LowStockRow(product: product),
          if (product != lowStock.take(8).last)
            const Divider(height: 1, color: Color(0xFFE9EFEB)),
        ],
    ],
  );
}

class _InventoryListHeading extends StatelessWidget {
  final String title;
  final int count;
  const _InventoryListHeading({required this.title, required this.count});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 7),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: opsMuted,
          ),
        ),
      ],
    ),
  );
}

class _StockReceiptRow extends StatelessWidget {
  final Map<String, dynamic> receipt;
  const _StockReceiptRow({required this.receipt});

  @override
  Widget build(BuildContext context) {
    final product = '${receipt['product__tamil_name'] ?? ''}'.trim();
    final english = '${receipt['product__english_name'] ?? ''}'.trim();
    final category = '${receipt['product__category'] ?? 'Uncategorized'}';
    final unit = '${receipt['unit'] ?? ''}'.trim();
    final date = DateTime.tryParse('${receipt['created_at'] ?? ''}')?.toLocal();
    final count = amount(receipt['delta']);
    final quantity = count == count.truncateToDouble()
        ? count.toInt().toString()
        : count.toStringAsFixed(2);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.add_box_outlined,
              size: 17,
              color: Color(0xFF087A50),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.isNotEmpty ? product : english,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '$category · ${date == null ? 'Date not recorded' : '${date.day}/${date.month}/${date.year}'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: opsMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '+$quantity${unit.isEmpty ? '' : ' × $unit'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF087A50),
            ),
          ),
        ],
      ),
    );
  }
}

class _LowStockRow extends StatelessWidget {
  final Map<String, dynamic> product;
  const _LowStockRow({required this.product});

  @override
  Widget build(BuildContext context) {
    final tamil = '${product['tamil_name'] ?? ''}'.trim();
    final english = '${product['english_name'] ?? ''}'.trim();
    final unit = '${product['unit'] ?? ''}'.trim();
    final stock = amount(product['stock_kg']);
    final count = stock == stock.truncateToDouble()
        ? stock.toInt().toString()
        : stock.toStringAsFixed(2);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFD97706)),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tamil.isNotEmpty ? tamil : english,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${product['category'] ?? 'Uncategorized'} · ${unit.isEmpty ? 'Unit not set' : '$unit pack'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: opsMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count left',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFFB45309),
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryEmptyRow extends StatelessWidget {
  final String text;
  const _InventoryEmptyRow(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(text, style: const TextStyle(fontSize: 11, color: opsMuted)),
  );
}

const _metricTints = <(Color, Color)>[
  (Color(0xFF0F7645), Color(0xFFEAF7F0)),
  (Color(0xFF2563EB), Color(0xFFEFF6FF)),
  (Color(0xFFD97706), Color(0xFFFFF7E8)),
  (Color(0xFF7C3AED), Color(0xFFF3F0FF)),
];

class _ReportMetric extends StatelessWidget {
  final _ReportMetricData metric;
  final (Color, Color) tint;
  const _ReportMetric({required this.metric, required this.tint});

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 82),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE5ECE8)),
    ),
    child: Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: tint.$2, borderRadius: BorderRadius.circular(10)),
          child: Icon(metric.icon, size: 18, color: tint.$1),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                metric.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10.5, color: opsMuted),
              ),
              const SizedBox(height: 4),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  metric.value,
                  key: ValueKey(metric.value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ReportChartData {
  final String title;
  final List<_ReportPoint> points;
  final bool currency;
  final bool bars;
  final String emptyMessage;
  const _ReportChartData({
    required this.title,
    required this.points,
    required this.emptyMessage,
    this.currency = false,
    this.bars = false,
  });
}

class _ReportPoint {
  final String label;
  final double value;
  const _ReportPoint(this.label, this.value);
}

class _ReportChart extends StatelessWidget {
  final String title;
  final List<_ReportPoint> points;
  final bool currency;
  final bool bars;
  final String emptyMessage;

  const _ReportChart({
    required this.title,
    required this.points,
    required this.emptyMessage,
    this.currency = false,
    this.bars = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasValues = points.any((point) => point.value > 0);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5ECE8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF163B29).withOpacity(0.035),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 190,
            width: double.infinity,
            child: Stack(
              children: [
                Positioned.fill(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 650),
                    curve: Curves.easeInOutCubic,
                    builder: (context, progress, child) => CustomPaint(
                      painter: _ReportChartPainter(
                        points: points,
                        currency: currency,
                        bars: bars,
                        progress: progress,
                      ),
                    ),
                  ),
                ),
                if (!hasValues)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 38, bottom: 20),
                      child: Text(
                        emptyMessage,
                        style: const TextStyle(fontSize: 11, color: opsMuted),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportChartPainter extends CustomPainter {
  final List<_ReportPoint> points;
  final bool currency;
  final bool bars;
  final double progress;

  const _ReportChartPainter({
    required this.points,
    required this.currency,
    required this.bars,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const left = 42.0;
    const right = 6.0;
    const top = 8.0;
    const bottom = 26.0;
    final plot = Rect.fromLTRB(left, top, size.width - right, size.height - bottom);
    final maxValue = points.fold<double>(
      0,
      (current, point) => point.value > current ? point.value : current,
    );
    final maxAxis = maxValue <= 0 ? 0.0 : _niceMaximum(maxValue);
    final grid = Paint()
      ..color = const Color(0xFFE9EFEB)
      ..strokeWidth = 1;
    for (var index = 0; index <= 3; index++) {
      final y = plot.bottom - plot.height * index / 3;
      _drawDashed(canvas, Offset(plot.left, y), Offset(plot.right, y), grid);
      if (maxAxis > 0) {
        final value = maxAxis * index / 3;
        final tick = TextPainter(
          text: TextSpan(
            text: _formatValue(value),
            style: const TextStyle(fontSize: 8.5, color: Color(0xFF84928A)),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: left - 5);
        tick.paint(canvas, Offset(0, y - tick.height / 2));
      }
    }
    if (points.isEmpty) return;

    final values = points.map((point) => point.value).toList();
    final offsets = <Offset>[];
    for (var index = 0; index < points.length; index++) {
      final x = points.length == 1
          ? plot.center.dx
          : plot.left + plot.width * index / (points.length - 1);
      final y = maxAxis > 0
          ? plot.bottom - plot.height * values[index] / maxAxis * progress
          : plot.bottom;
      offsets.add(Offset(x, y));
    }
    _drawLabels(canvas, size, plot);
    if (maxAxis <= 0) return;

    if (bars) {
      final barWidth = math.min(28.0, plot.width / (points.length * 1.8));
      for (var index = 0; index < offsets.length; index++) {
        final point = offsets[index];
        final rect = Rect.fromLTRB(
          point.dx - barWidth / 2,
          point.dy,
          point.dx + barWidth / 2,
          plot.bottom,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(5)),
          Paint()
            ..shader = const LinearGradient(
              colors: [Color(0xFF34D399), Color(0xFF047857)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(rect),
        );
      }
      return;
    }

    final line = _path(offsets);
    final fill = Path.from(line)
      ..lineTo(offsets.last.dx, plot.bottom)
      ..lineTo(offsets.first.dx, plot.bottom)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x3322B981), Color(0x0022B981)],
        ).createShader(plot),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = const Color(0xFF078653)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _drawLabels(Canvas canvas, Size size, Rect plot) {
    if (points.isEmpty) return;
    final stride = points.length <= 6 ? 1 : (points.length / 5).ceil();
    for (var index = 0; index < points.length; index++) {
      if (index % stride != 0 && index != points.length - 1) continue;
      final point = points[index];
      final x = points.length == 1
          ? plot.center.dx
          : plot.left + plot.width * index / (points.length - 1);
      final text = TextPainter(
        text: TextSpan(
          text: point.label,
          style: const TextStyle(fontSize: 8.5, color: Color(0xFF66766D)),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 58);
      text.paint(
        canvas,
        Offset(
          (x - text.width / 2).clamp(0.0, size.width - text.width),
          plot.bottom + 7,
        ),
      );
    }
  }

  Path _path(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var index = 1; index < points.length; index++) {
      final previous = points[index - 1];
      final current = points[index];
      final beforePrevious = points[index > 1 ? index - 2 : index - 1];
      final afterCurrent = points[index + 1 < points.length ? index + 1 : index];
      final control1 = previous + (current - beforePrevious) / 6;
      final control2 = current - (afterCurrent - previous) / 6;
      path.cubicTo(
        control1.dx,
        control1.dy,
        control2.dx,
        control2.dy,
        current.dx,
        current.dy,
      );
    }
    return path;
  }

  void _drawDashed(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dash = 3.0;
    const gap = 4.0;
    var x = start.dx;
    while (x < end.dx) {
      final next = (x + dash).clamp(start.dx, end.dx);
      canvas.drawLine(Offset(x, start.dy), Offset(next, end.dy), paint);
      x = next + gap;
    }
  }

  double _niceMaximum(double value) {
    final rawStep = value / 3;
    final magnitude = math.pow(10, (math.log(rawStep) / math.ln10).floor()).toDouble();
    final fraction = rawStep / magnitude;
    final step = fraction <= 1
        ? 1.0
        : fraction <= 2
        ? 2.0
        : fraction <= 2.5
        ? 2.5
        : fraction <= 5
        ? 5.0
        : 10.0;
    return step * magnitude * 3;
  }

  String _formatValue(double value) {
    if (currency) {
      if (value >= 1000000) return '₹${(value / 1000000).toStringAsFixed(1)}M';
      if (value >= 1000) return '₹${(value / 1000).toStringAsFixed(1)}k';
      return '₹${value.toStringAsFixed(0)}';
    }
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.round().toString();
  }

  @override
  bool shouldRepaint(covariant _ReportChartPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.currency != currency ||
      oldDelegate.bars != bars ||
      oldDelegate.progress != progress;
}
