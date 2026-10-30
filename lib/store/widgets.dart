import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart';

const storeGreen = Color(0xFF075E40);
const storeInk = Color(0xFF172C26);
const storeCream = Color(0xFFF6F8F5);
ThemeData storeTheme() => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: storeCream,
  colorScheme: ColorScheme.fromSeed(
    seedColor: storeGreen,
    primary: storeGreen,
    surface: Colors.white,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: storeCream,
    foregroundColor: storeInk,
    centerTitle: false,
    elevation: 0,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFDBE5DE)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFDBE5DE)),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(48, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: Colors.white,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: Color(0xFFE1E8E2)),
    ),
  ),
);

void showStoreError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(error.toString()),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class DataView<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T) builder;
  final VoidCallback onRetry;
  const DataView({
    super.key,
    required this.value,
    required this.builder,
    required this.onRetry,
  });
  @override
  Widget build(BuildContext context) => value.when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (error, stack) => EmptyPanel(
      icon: Icons.wifi_off_rounded,
      title: 'Could not load this page',
      message: error.toString(),
      action: 'Try again',
      onAction: onRetry,
    ),
    data: builder,
  );
}

class EmptyPanel extends StatelessWidget {
  final IconData icon;
  final String title, message;
  final String? action;
  final VoidCallback? onAction;
  const EmptyPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.onAction,
  });
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(
              color: Color(0xFFE5F1E9),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 38, color: storeGreen),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, height: 1.5),
          ),
          if (action != null) ...[
            const SizedBox(height: 20),
            FilledButton(onPressed: onAction, child: Text(action!)),
          ],
        ],
      ),
    ),
  );
}

class ProductPhoto extends StatelessWidget {
  final String url;
  final double height;
  const ProductPhoto(this.url, {super.key, this.height = 130});
  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      height: height,
      color: const Color(0xFFF0F4EF),
      alignment: Alignment.center,
      child: const Icon(
        Icons.shopping_basket_outlined,
        size: 36,
        color: Color(0xFF8CA496),
      ),
    );
    if (url.isEmpty) return placeholder;
    return Image.network(
      url,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, error, stack) => placeholder,
      loadingBuilder: (context, child, event) =>
          event == null ? child : placeholder,
    );
  }
}

class StatusChip extends StatelessWidget {
  final String label;
  const StatusChip(this.label, {super.key});
  @override
  Widget build(BuildContext context) {
    final warning = [
      'Payment Pending',
      'pending',
      'review',
      'expired',
      'Cancelled',
    ].contains(label);
    final color = warning ? const Color(0xFF9B5B13) : storeGreen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class OrderSummaryCard extends StatelessWidget {
  final StoreOrder order;
  final VoidCallback onTap;
  const OrderSummaryCard({super.key, required this.order, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long_outlined, color: storeGreen),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    order.id,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.black38),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                StatusChip(order.status),
                StatusChip(order.paymentStatus),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              order.items
                  .map((i) => '${i['english_name']} × ${i['quantity']}')
                  .join(', '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.data['customer_name'] ?? '',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
                Text(
                  money(order.total),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
