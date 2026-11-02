import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart';
import 'loading.dart';

const storeGreen = Color(0xFF0D634B);
const storeInk = Color(0xFF17382D);
const storeCream = Color(0xFFF7F8F2);
const storeGold = Color(0xFFE6B85C);
ThemeData storeTheme() => ThemeData(
  useMaterial3: true,
  fontFamilyFallback: const ['NotoSansTamil'],
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
  navigationBarTheme: NavigationBarThemeData(
    height: 72,
    backgroundColor: Colors.white,
    indicatorColor: const Color(0xFFE1F0D3),
    labelTextStyle: WidgetStateProperty.resolveWith(
      (states) => TextStyle(
        fontSize: 11,
        fontWeight: states.contains(WidgetState.selected)
            ? FontWeight.w800
            : FontWeight.w500,
        color: states.contains(WidgetState.selected)
            ? storeGreen
            : const Color(0xFF6E7D74),
      ),
    ),
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
  final bool retainOnRefresh;
  final Widget? loading;
  const DataView({
    super.key,
    required this.value,
    required this.builder,
    required this.onRetry,
    this.retainOnRefresh = true,
    this.loading,
  });
  @override
  Widget build(BuildContext context) => value.when(
    skipLoadingOnRefresh: retainOnRefresh,
    loading: () =>
        loading ??
        const SingleChildScrollView(
          child: AppSkeleton(kind: SkeletonKind.detail),
        ),
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

class StoreHero extends StatelessWidget {
  const StoreHero({super.key});
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(26),
    child: SizedBox(
      height:
          216 +
          (MediaQuery.textScalerOf(context).scale(1) - 1).clamp(0.0, 1.5) * 300,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/storefront-harvest.png',
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFA0C3E2E),
                  Color(0xB50C3E2E),
                  Color(0x180C3E2E),
                ],
                stops: [0, .55, 1],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'THE EVERYDAY GROCERY STORE',
                  style: TextStyle(
                    color: storeGold,
                    fontSize: 10,
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Good food.\nMade simple.',
                  style: TextStyle(
                    fontSize: 31,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: storeGold,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.payments_outlined, size: 16, color: storeInk),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Shop now. Pay at your door.',
                          style: TextStyle(
                            color: storeInk,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class StoreServiceStrip extends StatelessWidget {
  const StoreServiceStrip({super.key});
  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Expanded(
        child: _ServiceItem(Icons.payments_outlined, 'Cash on delivery'),
      ),
      Expanded(
        child: _ServiceItem(Icons.storefront_outlined, 'Your local store'),
      ),
      Expanded(
        child: _ServiceItem(Icons.local_shipping_outlined, 'Order updates'),
      ),
    ],
  );
}

class _ServiceItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ServiceItem(this.icon, this.label);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
    child: Column(
      children: [
        Icon(icon, size: 23, color: storeGreen),
        const SizedBox(height: 7),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: storeInk,
          ),
        ),
      ],
    ),
  );
}

class DeliveryStoryCard extends StatelessWidget {
  const DeliveryStoryCard({super.key});
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Row(
      children: [
        const Expanded(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'From our store\nto your doorstep.',
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: storeGreen,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'We prepare. We deliver.\nYou pay when it arrives.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: 118,
          height: 168,
          child: Image.asset(
            'assets/images/delivery-handover.png',
            fit: BoxFit.cover,
            alignment: const Alignment(-.2, 0),
          ),
        ),
      ],
    ),
  );
}

class CodPaymentCard extends StatelessWidget {
  final StoreOrder? order;
  const CodPaymentCard({super.key, this.order});
  @override
  Widget build(BuildContext context) {
    final collected = order?.paymentStatus == 'collected';
    final cancelled = order?.status == 'Cancelled';
    final paid = order?.paymentStatus == 'paid';
    final previousOnline =
        order != null && order!.data['payment_method'] != 'cod' && !paid;
    final recordedAt = DateTime.tryParse('${order?.data['cash_collected_at']}')
        ?.toLocal();
    final title = cancelled
        ? 'Order cancelled'
        : collected
        ? 'Cash received'
        : paid
        ? 'Payment recorded'
        : previousOnline
        ? 'Previous payment needs review'
        : 'Cash on delivery';
    final subtitle = cancelled
        ? 'No cash is due for this cancelled order.'
        : collected
        ? '${money(amount(order!.data['cash_collected_amount']))} collected at delivery.'
        : paid
        ? 'Payment for this previous order is already recorded.'
        : previousOnline
        ? 'Contact the store with your order ID. This previous checkout is not a cash-on-delivery order.'
        : order == null
        ? 'Pay in cash when your groceries arrive. No online payment needed.'
        : '${money(order!.total)} to pay when your groceries arrive.';
    return Card(
      color: const Color(0xFFEDF3E9),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                collected || paid ? Icons.task_alt : Icons.payments_outlined,
                color: storeGreen,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: storeGreen,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(height: 1.5, fontSize: 13),
                  ),
                  if (collected && recordedAt != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Received ${recordedAt.day}/${recordedAt.month}/${recordedAt.year}, ${recordedAt.hour.toString().padLeft(2, '0')}:${recordedAt.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderJourney extends StatelessWidget {
  final StoreOrder order;
  const OrderJourney({super.key, required this.order});
  @override
  Widget build(BuildContext context) {
    if (order.status == 'Cancelled') return const SizedBox.shrink();
    const steps = [
      'New',
      'Preparing',
      'Packed',
      'Out for Delivery',
      'Delivered',
    ];
    const labels = ['Placed', 'Preparing', 'Packed', 'On the way', 'Delivered'];
    const icons = [
      Icons.receipt_long_outlined,
      Icons.shopping_basket_outlined,
      Icons.inventory_2_outlined,
      Icons.local_shipping_outlined,
      Icons.home_outlined,
    ];
    final current = order.status == 'Delivery Attempted'
        ? 3
        : steps.indexOf(order.status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < steps.length; i++)
              Expanded(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: i <= current
                          ? storeGreen
                          : const Color(0xFFEDF0E8),
                      child: Icon(
                        icons[i],
                        size: 17,
                        color: i <= current ? Colors.white : Colors.black38,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      labels[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: i == current
                            ? FontWeight.w800
                            : FontWeight.w500,
                        color: i <= current ? storeGreen : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ProductPhoto extends StatelessWidget {
  final String url;
  final double height;
  final BoxFit fit;
  const ProductPhoto(
    this.url, {
    super.key,
    this.height = 130,
    this.fit = BoxFit.cover,
  });
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
      fit: fit,
      errorBuilder: (_, error, stack) => placeholder,
      loadingBuilder: (context, child, event) => event == null
          ? child
          : AppSkeleton(
              kind: SkeletonKind.image,
              height: height,
              padded: false,
            ),
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
      'Delivery Attempted',
      'cod',
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
        {
              'cod': 'Cash due at delivery',
              'collected': 'Cash collected',
              'paid': 'Paid',
              'cancelled': 'Cancelled',
              'pending': 'Pending',
              'expired': 'Expired',
              'review': 'Needs review',
            }[label] ??
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
                  .map((i) => '${productLabel(i)} × ${i['quantity']}')
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

class OrderActionDialog extends StatefulWidget {
  final String kind;
  final double total;
  final bool requireReturn;
  const OrderActionDialog({
    super.key,
    required this.kind,
    this.total = 0,
    this.requireReturn = false,
  });
  @override
  State<OrderActionDialog> createState() => OrderActionDialogState();
}

class OrderActionDialogState extends State<OrderActionDialog> {
  final _form = GlobalKey<FormState>();
  final _value = TextEditingController();
  bool _confirmed = false;
  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final handover = widget.kind == 'handover';
    final cash = widget.kind == 'cash' || handover;
    final cancel = widget.kind == 'cancel';
    final needsConfirm = cash || widget.requireReturn;
    return AlertDialog(
      title: Text(
        handover
            ? 'Confirm cash handover'
            : cash
            ? 'Confirm cash collection'
            : cancel
            ? 'Cancel this order?'
            : 'Record delivery attempt',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                handover
                    ? 'Count and receive ${money(widget.total)} from the employee before confirming this handover.'
                    : cash
                    ? 'Collect ${money(widget.total)} from the customer before completing delivery.'
                    : cancel
                    ? 'The reason is visible to the customer. Stock will be restored once this cancellation is confirmed.'
                    : 'Tell the customer why delivery could not be completed. You can arrange another attempt from this order.',
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _value,
                keyboardType: cash
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.multiline,
                maxLines: cash ? 1 : 3,
                maxLength: cash ? 12 : 255,
                decoration: InputDecoration(
                  labelText: handover
                      ? 'Cash received (INR)'
                      : cash
                      ? 'Cash collected (INR)'
                      : 'Reason',
                  hintText: cash ? widget.total.toStringAsFixed(2) : null,
                ),
                validator: (value) {
                  if (cash) {
                    if (!RegExp(r'^\d+(\.\d{1,2})?$')
                            .hasMatch(value?.trim() ?? '') ||
                        double.tryParse(value!.trim()) != widget.total) {
                      return 'Enter exactly ${money(widget.total)}';
                    }
                  } else if ((value?.trim().length ?? 0) < 3) {
                    return 'Enter a clear reason';
                  }
                  return null;
                },
              ),
              if (needsConfirm)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _confirmed,
                  onChanged: (v) => setState(() => _confirmed = v ?? false),
                  title: Text(
                    handover
                        ? 'I have counted and received this cash from the employee.'
                        : cash
                        ? 'Cash has been received from the customer.'
                        : 'Undelivered items are back in store and available for stock.',
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Go back'),
        ),
        FilledButton(
          onPressed: needsConfirm && !_confirmed
              ? null
              : () {
                  if (!_form.currentState!.validate()) return;
                  Navigator.pop(context, <String, dynamic>{
                    if (cash) ...{
                      'cash_collected': true,
                      'cash_collected_amount': _value.text.trim(),
                    },
                    if (cancel) ...{
                      'cancellation_reason': _value.text.trim(),
                      'stock_returned': _confirmed,
                    },
                    if (!cash && !cancel) 'delivery_note': _value.text.trim(),
                  });
                },
          child: Text(
            handover
                ? 'Confirm store receipt'
                : cash
                ? 'Complete delivery'
                : cancel
                ? 'Cancel order'
                : 'Save attempt',
          ),
        ),
      ],
    );
  }
}
