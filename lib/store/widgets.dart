import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart';
import 'loading.dart';

// =============================================================================
// AGARAM PREMIUM GROCERY DESIGN SYSTEM (MINT + CREAM + GLASSMORPHISM)
// Matches the visual reference: soft cream base, frosted glass cards,
// subtle green glow, clean typography and refined grocery palette.
// =============================================================================

// Background & Surface Colors
const storeCream = Color(0xFFFFFDF7); // Main base cream
const storeWarmWhite = Color(0xFFFFFCF6); // Warm off-white
const storePaleMint = Color(0xFFEFFAF3); // Very pale mint for ambient gradients
const storeGlassMint = Color(0xFFE9F7EE); // Translucent mint
const storeSoftSage = Color(0xFFDCEFE3); // Soft sage accent
const storeMint = Color(0xFFE8F3EC); // Chip & pill surface
const storeLightMint = Color(0xFFF2F8F4); // Soft tint surface
const storeBorder = Color(0xFFE5EBE6); // Subtle border
const storeBorderGlass = Color(0x99FFFFFF); // Frosted 60% white glass border

// Primary & Accent Grocery Greens
const storePrimaryGreen = Color(0xFF159447); // Primary brand green
const storeForestGreen = Color(0xFF0B5A3C); // Deep forest text/headers
const storeDeepGreen = Color(0xFF087532); // Deep CTA grocery green
const storeCtaGreen = Color(0xFF119B4C); // Vibrant button CTA
const storeFreshGreen = Color(0xFF39B968); // Highlight / savings green
const storeGreen = storePrimaryGreen; // Backward compatibility alias

// Text & Neutral Colors
const storeInk = Color(0xFF17201C); // Primary text
const storeGrey = Color(0xFF68736D); // Secondary text
const storeLightGrey = Color(0xFF9EABA4); // Tertiary helper text

// Accent Badges & Status Colors
const storeGold = Color(0xFFE5A93C); // Warm grocery badge / star
const storeYellow = Color(0xFFF5A623); // Highlight
const storeOrange = Color(0xFFE67E22); // Attention / out for delivery
const storeRed = Color(0xFFE53935); // Destructive / cancel / out of stock

ThemeData storeTheme() => ThemeData(
  useMaterial3: true,
  fontFamilyFallback: const ['NotoSansTamil'],
  scaffoldBackgroundColor: storeCream,
  colorScheme: ColorScheme.fromSeed(
    seedColor: storePrimaryGreen,
    primary: storePrimaryGreen,
    surface: storeCream,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: storeInk,
    centerTitle: true,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
  ),
  navigationBarTheme: NavigationBarThemeData(
    height: 72,
    backgroundColor: Colors.white.withOpacity(0.85),
    indicatorColor: storeGlassMint,
    labelTextStyle: WidgetStateProperty.resolveWith(
      (states) => TextStyle(
        fontSize: 11,
        fontWeight: states.contains(WidgetState.selected)
            ? FontWeight.w800
            : FontWeight.w600,
        color: states.contains(WidgetState.selected)
            ? storeDeepGreen
            : storeGrey,
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white.withOpacity(0.85),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.9), width: 1.2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: storeBorder, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: storePrimaryGreen, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: storeCtaGreen,
      foregroundColor: Colors.white,
      minimumSize: const Size(48, 48),
      elevation: 2,
      shadowColor: storePrimaryGreen.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: Colors.white.withOpacity(0.88),
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: storeBorderGlass, width: 1),
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
  final VoidCallback? onAction;
  final String? actionLabel;
  const OrderSummaryCard({
    super.key,
    required this.order,
    required this.onTap,
    this.onAction,
    this.actionLabel,
  });
  @override
  Widget build(BuildContext context) {
    final cancelled = order.status == 'Cancelled';
    final completed = order.status == 'Delivered';
    final attention = ['New', 'Delivery Attempted'].contains(order.status);
    final person = order.data['assigned_to_details'] as Map?;
    final date = DateTime.tryParse('${order.data['created_at']}')?.toLocal();
    final units = order.items.fold<int>(
      0,
      (sum, item) => sum + (item['quantity'] as num).toInt(),
    );
    final photo = order.items.isEmpty
        ? ''
        : '${order.items.first['image_url'] ?? ''}';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                        fontSize: 17,
                      ),
                    ),
                  ),
                  if (date != null)
                    Text(
                      '${date.day}/${date.month} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: Colors.black38),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  StatusChip(order.status),
                  if (!cancelled) StatusChip(order.paymentStatus),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: ProductPhoto(photo, height: 56),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${order.data['customer_name'] ?? 'Customer'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          order.items
                              .map(
                                (i) => '${productLabel(i)} × ${i['quantity']}',
                              )
                              .join(', '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${order.data['delivery_address'] ?? ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
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
                      '$units items · ${person?['name'] ?? (cancelled ? 'Closed' : 'Unassigned')}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        money(order.total),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        cancelled
                            ? 'No cash due'
                            : completed
                            ? (order.paymentStatus == 'collected'
                                  ? 'Cash collected'
                                  : 'Paid online')
                            : order.paymentStatus == 'cod'
                            ? 'Collect on delivery'
                            : 'Paid online',
                        style: TextStyle(
                          fontSize: 11,
                          color: cancelled ? Colors.black54 : storeGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (actionLabel != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: onAction,
                    child: Text(
                      actionLabel!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
              const Divider(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    cancelled
                        ? Icons.cancel_outlined
                        : attention
                        ? Icons.bolt
                        : completed
                        ? Icons.task_alt
                        : Icons.arrow_circle_right_outlined,
                    size: 17,
                    color: attention ? const Color(0xFF9B5B13) : storeGreen,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      order.nextAction,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: attention ? const Color(0xFF9B5B13) : storeGreen,
                      ),
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
}

class OrderActionDialog extends StatefulWidget {
  final String kind;
  final double total;
  final bool requireReturn;
  final bool adminAssistance;
  const OrderActionDialog({
    super.key,
    required this.kind,
    this.total = 0,
    this.requireReturn = false,
    this.adminAssistance = false,
  });
  @override
  State<OrderActionDialog> createState() => OrderActionDialogState();
}

class OrderActionDialogState extends State<OrderActionDialog> {
  final _form = GlobalKey<FormState>();
  final _value = TextEditingController();
  final _deliveryCode = TextEditingController();
  bool _confirmed = false;
  bool _storeReceived = false;
  @override
  void dispose() {
    _value.dispose();
    _deliveryCode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final handover = widget.kind == 'handover';
    final cash = widget.kind == 'cash' || handover;
    final cancel = widget.kind == 'cancel';
    final codeOnly = widget.kind == 'delivery';
    final needsConfirm = cash || widget.requireReturn;
    return AlertDialog(
      title: Text(
        handover
            ? 'Confirm cash handover'
            : cash
            ? 'Confirm cash collection'
            : cancel
            ? 'Cancel this order?'
            : codeOnly
            ? 'Verify delivery code'
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
                    : codeOnly
                    ? 'This order is already paid. Hand over all items and ask the customer for the delivery code shown in their order screen.'
                    : 'Tell the customer why delivery could not be completed. You can arrange another attempt from this order.',
              ),
              const SizedBox(height: 18),
              if (widget.kind == 'cash' || codeOnly) ...[
                const Text(
                  'Ask the customer to open Orders → this order. Enter their delivery code only after handing over all items.',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _deliveryCode,
                  keyboardType: TextInputType.number,
                  maxLength: 5,
                  decoration: const InputDecoration(
                    labelText: 'Delivery code',
                    hintText: '5 digits',
                    prefixIcon: Icon(Icons.verified_user_outlined),
                  ),
                  validator: (s) => RegExp(r'^\d{5}$').hasMatch(s?.trim() ?? '')
                      ? null
                      : 'Enter the customer’s 5-digit delivery code',
                ),
                const SizedBox(height: 12),
              ],
              if (!codeOnly)
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
              if (widget.kind == 'cash' && widget.adminAssistance)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _storeReceived,
                  onChanged: (v) => setState(() => _storeReceived = v ?? false),
                  title: const Text(
                    'I delivered and the cash is already with the store.',
                  ),
                  subtitle: const Text(
                    'Leave unchecked when recording cash still held by the assigned employee.',
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
                    if (widget.kind == 'cash' || codeOnly)
                      'delivery_code': _deliveryCode.text.trim(),
                    if (widget.kind == 'cash' && widget.adminAssistance)
                      'cash_received_by_store': _storeReceived,
                    if (cancel) ...{
                      'cancellation_reason': _value.text.trim(),
                      'stock_returned': _confirmed,
                    },
                    if (!cash && !cancel && !codeOnly)
                      'delivery_note': _value.text.trim(),
                  });
                },
          child: Text(
            handover
                ? 'Confirm store receipt'
                : cash
                ? 'Complete delivery'
                : codeOnly
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

// =============================================================================
// AGARAM SUPERMARKET – NEW CUSTOMER COMPONENT SUITE
// Redesigned to visually match the uploaded reference: soft frosted cream
// background, glassmorphism pills, ambient shadows, refined typography.
// =============================================================================

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final double blur;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 22,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.border,
    this.boxShadow,
    this.blur = 12,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color ?? Colors.white.withOpacity(0.82),
            borderRadius: BorderRadius.circular(borderRadius),
            border:
                border ??
                Border.all(color: Colors.white.withOpacity(0.85), width: 1.2),
            boxShadow:
                boxShadow ??
                [
                  BoxShadow(
                    color: const Color(0xFF087532).withOpacity(0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class AgaramAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onMenuPressed;
  final VoidCallback onCartPressed;
  final int cartCount;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const AgaramAppBar({
    super.key,
    required this.onMenuPressed,
    required this.onCartPressed,
    this.cartCount = 0,
    this.showBackButton = false,
    this.onBackPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(66);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: storeCream.withOpacity(0.92),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.8), width: 1),
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 4,
        left: 12,
        right: 12,
        bottom: 8,
      ),
      child: Row(
        children: [
          InkWell(
            onTap: showBackButton ? onBackPressed : onMenuPressed,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF087532).withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                showBackButton
                    ? Icons.arrow_back_ios_new_rounded
                    : Icons.menu_rounded,
                color: storeInk,
                size: 20,
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: storeGlassMint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shopping_basket_rounded,
                        color: storePrimaryGreen,
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'AGARAM',
                      style: TextStyle(
                        color: storeDeepGreen,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.8,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
                const Text(
                  'SUPERMARKET',
                  style: TextStyle(
                    color: storePrimaryGreen,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.4,
                    fontSize: 8.5,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onCartPressed,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF087532).withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    color: storeInk,
                    size: 20,
                  ),
                  if (cartCount > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: storeRed,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$cartCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AgaramBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final int cartCount;
  final VoidCallback? onCartPressed;

  const AgaramBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.cartCount = 0,
    this.onCartPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.of(context).padding.bottom + 8,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF087532).withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(
            icon: Icons.home_rounded,
            outlineIcon: Icons.home_outlined,
            label: 'Home',
            isSelected: selectedIndex == 0,
            onTap: () => onItemSelected(0),
          ),
          _navItem(
            icon: Icons.grid_view_rounded,
            outlineIcon: Icons.grid_view_outlined,
            label: 'Categories',
            isSelected: selectedIndex == 1,
            onTap: () => onItemSelected(1),
          ),
          // Center Shopping Cart icon with red badge
          InkWell(
            onTap: onCartPressed ?? () => onItemSelected(2),
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Badge(
                isLabelVisible: cartCount > 0,
                label: Text(
                  '$cartCount',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: storeRed,
                offset: const Offset(6, -4),
                child: const Icon(
                  Icons.shopping_cart_outlined,
                  color: storeInk,
                  size: 24,
                ),
              ),
            ),
          ),
          _navItem(
            icon: Icons.inventory_2_rounded,
            outlineIcon: Icons.inventory_2_outlined,
            label: 'Orders',
            isSelected: selectedIndex == 3,
            onTap: () => onItemSelected(3),
          ),
          _navItem(
            icon: Icons.person_rounded,
            outlineIcon: Icons.person_outline_rounded,
            label: 'Account',
            isSelected: selectedIndex == 4,
            onTap: () => onItemSelected(4),
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required IconData outlineIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? icon : outlineIcon,
              size: 22,
              color: isSelected ? storePrimaryGreen : storeGrey,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? storePrimaryGreen : storeGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AgaramDrawer extends StatelessWidget {
  final Map<String, dynamic>? customerProfile;
  final VoidCallback onLoginPressed;
  final VoidCallback onSelectCategories;
  final VoidCallback onSelectOffers;
  final VoidCallback onSelectWishlist;
  final VoidCallback onSelectOrders;
  final VoidCallback onSelectAccount;
  final VoidCallback onSelectHelp;
  final VoidCallback onSelectContact;
  final VoidCallback onAdminLogin;
  final VoidCallback onDeliveryLogin;
  final VoidCallback? onLogout;

  const AgaramDrawer({
    super.key,
    this.customerProfile,
    required this.onLoginPressed,
    required this.onSelectCategories,
    required this.onSelectOffers,
    required this.onSelectWishlist,
    required this.onSelectOrders,
    required this.onSelectAccount,
    required this.onSelectHelp,
    required this.onSelectContact,
    required this.onAdminLogin,
    required this.onDeliveryLogin,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = customerProfile != null;
    final name = (customerProfile?['name'] as String? ?? '').trim();
    final phone = (customerProfile?['phone'] as String? ?? '').trim();
    final displayName = name.isNotEmpty ? name : 'Agaram Customer';

    return Drawer(
      backgroundColor: storeCream,
      child: SafeArea(
        child: Column(
          children: [
            // Top Frosted Glass Brand Header
            Container(
              margin: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Color(0xFFEFFAF3), Color(0xFFE2F3E7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: storeDeepGreen.withOpacity(0.08),
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'AGARAM',
                            style: TextStyle(
                              color: storeDeepGreen,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.2,
                              fontSize: 20,
                            ),
                          ),
                          Text(
                            'SUPERMARKET',
                            style: TextStyle(
                              color: storePrimaryGreen,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.6,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: storeInk,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (!isLoggedIn)
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        onLoginPressed();
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: storeDeepGreen.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                color: storeGlassMint,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: storePrimaryGreen,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Login / Sign In',
                                    style: TextStyle(
                                      color: storeDeepGreen,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Access orders & wishlist',
                                    style: TextStyle(
                                      color: storeGrey,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: storePrimaryGreen,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        onSelectAccount();
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white, width: 1.2),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: const BoxDecoration(
                                color: storeGlassMint,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: storePrimaryGreen,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: const TextStyle(
                                      color: storeInk,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                  if (phone.isNotEmpty)
                                    Text(
                                      phone,
                                      style: const TextStyle(
                                        color: storeGrey,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: storeGrey,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Navigation Menu List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                children: [
                  _drawerRow(
                    icon: Icons.grid_view_outlined,
                    label: 'Categories',
                    onTap: () {
                      Navigator.pop(context);
                      onSelectCategories();
                    },
                  ),
                  _drawerRow(
                    icon: Icons.local_offer_outlined,
                    label: 'Offers',
                    onTap: () {
                      Navigator.pop(context);
                      onSelectOffers();
                    },
                  ),
                  _drawerRow(
                    icon: Icons.favorite_outline_rounded,
                    label: 'Wishlist',
                    onTap: () {
                      Navigator.pop(context);
                      onSelectWishlist();
                    },
                  ),
                  _drawerRow(
                    icon: Icons.inventory_2_outlined,
                    label: 'My Orders',
                    onTap: () {
                      Navigator.pop(context);
                      onSelectOrders();
                    },
                  ),
                  _drawerRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Account',
                    onTap: () {
                      Navigator.pop(context);
                      onSelectAccount();
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: storeBorder, height: 1),
                  ),
                  _drawerRow(
                    icon: Icons.help_outline_rounded,
                    label: 'Help & FAQ',
                    onTap: () {
                      Navigator.pop(context);
                      onSelectHelp();
                    },
                  ),
                  _drawerRow(
                    icon: Icons.phone_outlined,
                    label: 'Contact Store',
                    onTap: () {
                      Navigator.pop(context);
                      onSelectContact();
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: storeBorder, height: 1),
                  ),
                  // Staff logins softened
                  _drawerRow(
                    icon: Icons.admin_panel_settings_outlined,
                    label: 'Admin Portal',
                    iconColor: storeGrey,
                    textColor: storeGrey,
                    onTap: () {
                      Navigator.pop(context);
                      onAdminLogin();
                    },
                  ),
                  _drawerRow(
                    icon: Icons.delivery_dining,
                    label: 'Delivery Portal',
                    iconColor: storeGrey,
                    textColor: storeGrey,
                    onTap: () {
                      Navigator.pop(context);
                      onDeliveryLogin();
                    },
                  ),
                  if (isLoggedIn && onLogout != null) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(color: storeBorder, height: 1),
                    ),
                    _drawerRow(
                      icon: Icons.logout_rounded,
                      label: 'Logout',
                      iconColor: storeRed,
                      textColor: storeRed,
                      onTap: () {
                        Navigator.pop(context);
                        onLogout!();
                      },
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

  static Widget _drawerRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color iconColor = storePrimaryGreen,
    Color textColor = storeInk,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: storeLightGrey,
          size: 19,
        ),
        onTap: onTap,
      ),
    );
  }
}

class HeroBanner extends StatelessWidget {
  final VoidCallback onShopNow;
  final String imageUrl;

  const HeroBanner({super.key, required this.onShopNow, this.imageUrl = ''});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF6E5), Color(0xFFFFFCF5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF5A623).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Right-aligned grocery illustration with proper rounded framing
            Positioned(
              right: 10,
              top: 10,
              bottom: 10,
              width: 140,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  'assets/images/hero_grocery_banner.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    decoration: const BoxDecoration(
                      color: storeGlassMint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_basket_rounded,
                      color: storeGold,
                      size: 60,
                    ),
                  ),
                ),
              ),
            ),
            // Subtle frosted gradient for clean title readability
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 230,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFF6E5),
                      const Color(0xFFFFF6E5).withOpacity(0.95),
                      const Color(0xFFFFF6E5).withOpacity(0.0),
                    ],
                    stops: const [0.0, 0.75, 1.0],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: storeGold.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'MONTHLY GROCERY DEALS',
                      style: TextStyle(
                        color: Color(0xFF996B00),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Essential Groceries\nFor Your Home',
                    style: TextStyle(
                      color: storeInk,
                      fontSize: 16.5,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: onShopNow,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: storeCtaGreen,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: storeCtaGreen.withOpacity(0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Shop Now',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 11.5,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                        ],
                      ),
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

class SearchBarWidget extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final VoidCallback? onVoiceTap;
  final VoidCallback? onFilterTap;
  final bool readOnly;
  final String placeholder;

  const SearchBarWidget({
    super.key,
    this.controller,
    this.onChanged,
    this.onTap,
    this.onVoiceTap,
    this.onFilterTap,
    this.readOnly = false,
    this.placeholder = 'Search groceries, brands or essentials',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF087532).withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.search_rounded, color: storePrimaryGreen, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: readOnly
                  ? Text(
                      placeholder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: storeGrey,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  : TextField(
                      controller: controller,
                      onChanged: onChanged,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: storeInk,
                      ),
                      decoration: InputDecoration(
                        hintText: placeholder,
                        hintStyle: const TextStyle(
                          color: storeGrey,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
            ),
          ),
          if (onVoiceTap != null)
            IconButton(
              tooltip: 'Voice search',
              icon: const Icon(
                Icons.mic_none_rounded,
                color: storePrimaryGreen,
                size: 21,
              ),
              onPressed: onVoiceTap,
            ),
          if (onFilterTap != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InkWell(
                onTap: onFilterTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: storeGlassMint,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.tune_rounded,
                      color: storeDeepGreen,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class CategoryTile extends StatelessWidget {
  final String title;
  final String imageUrl;
  final String subtitle;
  final IconData icon;
  final Color bgColor;
  final VoidCallback onTap;

  const CategoryTile({
    super.key,
    required this.title,
    this.subtitle = '',
    this.imageUrl = '',
    required this.icon,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF087532).withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: imageUrl.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: storeGlassMint,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: storePrimaryGreen, size: 24),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: ProductPhoto(
                          imageUrl,
                          height: 58,
                          fit: BoxFit.contain,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: storeInk,
              ),
            ),
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 8.5, color: storeGrey),
              ),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.action = 'See All >',
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: storeInk,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (onAction != null)
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
              child: Text(
                action,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: storePrimaryGreen,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class FeaturedEssentialsRow extends StatelessWidget {
  final ValueChanged<String> onSelectCategory;
  final List<Map<String, dynamic>> categories;

  const FeaturedEssentialsRow({
    super.key,
    required this.onSelectCategory,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final items = categories;
    if (items.isEmpty) return const SizedBox();

    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final item = items[i];
          final hasImage = '${item['image_url'] ?? ''}'.isNotEmpty;
          return InkWell(
            onTap: () => onSelectCategory('${item['name']}'),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 84,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF087532).withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: storeGlassMint,
                      shape: BoxShape.circle,
                    ),
                    child: hasImage
                        ? ClipOval(
                            child: ProductPhoto(
                              '${item['image_url']}',
                              height: 46,
                              fit: BoxFit.contain,
                            ),
                          )
                        : const Icon(
                            Icons.shopping_basket_rounded,
                            color: storePrimaryGreen,
                            size: 22,
                          ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${item['name']}',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: storeInk,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final StoreProduct product;
  final int cartQuantity;
  final bool isWishlisted;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final VoidCallback onToggleWishlist;

  const ProductCard({
    super.key,
    required this.product,
    this.cartQuantity = 0,
    this.isWishlisted = false,
    required this.onTap,
    required this.onAddToCart,
    this.onIncrement,
    this.onDecrement,
    required this.onToggleWishlist,
  });

  @override
  Widget build(BuildContext context) => PremiumProductCard(
    product: product,
    cartQuantity: cartQuantity,
    isWishlisted: isWishlisted,
    onTap: onTap,
    onAddToCart: onAddToCart,
    onIncrement: onIncrement,
    onDecrement: onDecrement,
    onToggleWishlist: onToggleWishlist,
  );
}

class QuantitySelector extends StatelessWidget {
  final int quantity;
  final double height;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const QuantitySelector({
    super.key,
    this.height = 34,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = height < 30;
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 2 : 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0A5C36),
        borderRadius: BorderRadius.circular(isCompact ? 8 : 14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A5C36).withOpacity(0.25),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: onDecrement,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: EdgeInsets.all(isCompact ? 2 : 4),
              child: Icon(
                Icons.remove,
                size: isCompact ? 13 : 15,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 4 : 6),
            child: Text(
              '$quantity',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: isCompact ? 11 : 13,
                color: Colors.white,
              ),
            ),
          ),
          InkWell(
            onTap: onIncrement,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: EdgeInsets.all(isCompact ? 2 : 4),
              child: Icon(
                Icons.add,
                size: isCompact ? 13 : 15,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FreeDeliveryBanner extends StatelessWidget {
  const FreeDeliveryBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: storeGlassMint,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white, width: 1.2),
      ),
      child: Row(
        children: const [
          Icon(
            Icons.local_shipping_outlined,
            color: storePrimaryGreen,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Free delivery on all grocery orders',
              style: TextStyle(
                color: storeDeepGreen,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: storePrimaryGreen, size: 18),
        ],
      ),
    );
  }
}

class PriceDetailsCard extends StatelessWidget {
  final double subtotal;
  final double deliveryCharge;
  final double discount;
  final int itemsCount;

  const PriceDetailsCard({
    super.key,
    required this.subtotal,
    required this.deliveryCharge,
    this.discount = 0.0,
    required this.itemsCount,
  });

  @override
  Widget build(BuildContext context) {
    final finalDelivery = deliveryCharge;
    final total = subtotal + finalDelivery;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF087532).withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Price Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: storeInk,
            ),
          ),
          const SizedBox(height: 14),
          _row(
            'Item Total ($itemsCount items)',
            '₹${subtotal.toStringAsFixed(2)}',
          ),
          if (discount > 0) ...[
            const SizedBox(height: 8),
            _row(
              'You save',
              '-₹${discount.toStringAsFixed(2)}',
              valueColor: storePrimaryGreen,
            ),
          ],
          const SizedBox(height: 8),
          _row(
            'Delivery Fee',
            finalDelivery == 0
                ? 'FREE'
                : '₹${finalDelivery.toStringAsFixed(2)}',
            valueColor: finalDelivery == 0 ? storePrimaryGreen : storeInk,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: storeBorder, height: 1),
          ),
          _row(
            'Total Payable',
            '₹${total.toStringAsFixed(2)}',
            isBold: true,
            fontSize: 16,
          ),
        ],
      ),
    );
  }

  static Widget _row(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 13,
    Color valueColor = storeInk,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            color: isBold ? storeInk : storeGrey,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            color: valueColor,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class OrderCard extends StatelessWidget {
  final StoreOrder order;
  final VoidCallback onTap;

  const OrderCard({super.key, required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = order.status;
    final total = money(order.total);
    final count = order.items.length;
    final date = order.data['created_at'] != null
        ? DateTime.tryParse('${order.data['created_at']}')?.toLocal()
        : null;
    final dateStr = date != null
        ? '${date.day} ${_month(date.month)} ${date.year}'
        : 'Recent Order';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF087532).withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: storeGlassMint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: storePrimaryGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.id}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: storeInk,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$total • $count items',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: storeGrey,
                      ),
                    ),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 11,
                        color: storeLightGrey,
                      ),
                    ),
                  ],
                ),
              ),
              _statusPill(status),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: storeLightGrey,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _statusPill(String status) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status) {
      case 'Delivered':
        bg = const Color(0xFFE9F7EE);
        fg = storePrimaryGreen;
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'Out for Delivery':
        bg = const Color(0xFFFEF5E7);
        fg = storeOrange;
        icon = Icons.delivery_dining_rounded;
        break;
      case 'Cancelled':
        bg = const Color(0xFFFDEDEC);
        fg = storeRed;
        icon = Icons.cancel_outlined;
        break;
      default:
        bg = const Color(0xFFEBF5FB);
        fg = const Color(0xFF2980B9);
        icon = Icons.sync_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  static String _month(int m) {
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
    return m >= 1 && m <= 12 ? months[m - 1] : '';
  }
}

class EmptyCartWidget extends StatelessWidget {
  final VoidCallback onStartShopping;

  const EmptyCartWidget({super.key, required this.onStartShopping});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 130,
              height: 130,
              decoration: const BoxDecoration(
                color: storeGlassMint,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/empty_cart_grocery.jpg',
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.shopping_bag_outlined,
                    size: 56,
                    color: storePrimaryGreen,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: storeInk,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your daily essentials and they will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: storeGrey, fontSize: 13.5, height: 1.4),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onStartShopping,
              style: FilledButton.styleFrom(
                backgroundColor: storeCtaGreen,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Start Shopping'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// CUSTOMER HOME REDESIGNED WIDGETS
// =============================================================================

/// Colors for Agaram Customer Home design system matching reference image
const homeBackgroundMint = Color(0xFFF4F9F5);
const homeSurfaceCream = Color(0xFFFFFDF8);
const homeCardWhite = Colors.white;
const homePrimaryGreen = Color(0xFF12A05B);
const homeDeepGreen = Color(0xFF087247);
const homeForestTitle = Color(0xFF0B5A3C);
const homeTextDark = Color(0xFF172019);
const homeTextMuted = Color(0xFF6C7771);
const homeBorderMint = Color(0xFFDFE9E2);
const homePillMint = Color(0xFFE8F5EC);
const homeGold = Color(0xFFF39C12);

/// 1. Compact Header matching reference:
/// Left: Menu drawer icon
/// Center: Agaram Supermarket typography with logo and side flourish lines
/// Right: Cart icon with real count badge
class HomeTopHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onMenuPressed;
  final VoidCallback onCartPressed;
  final int cartCount;

  const HomeTopHeader({
    super.key,
    required this.onMenuPressed,
    required this.onCartPressed,
    this.cartCount = 0,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 4,
        left: 14,
        right: 14,
        bottom: 4,
      ),
      child: Row(
        children: [
          // Left: Menu button with rounded white tile
          InkWell(
            onTap: onMenuPressed,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: homeCardWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: homeBorderMint.withOpacity(0.8),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: homeDeepGreen.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.menu_rounded,
                color: homeTextDark,
                size: 22,
              ),
            ),
          ),

          // Center: Agaram Supermarket branding
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shopping_basket_rounded,
                      color: Color(0xFF0D6838),
                      size: 22,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'AGARAM',
                      style: TextStyle(
                        color: Color(0xFF0D6838),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.8,
                        fontSize: 19,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 18,
                      height: 1.5,
                      color: homePrimaryGreen.withOpacity(0.55),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        'SUPERMARKET',
                        style: TextStyle(
                          color: Color(0xFF0D6838),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.4,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    Container(
                      width: 18,
                      height: 1.5,
                      color: homePrimaryGreen.withOpacity(0.55),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Right: Cart icon button with real badge
          InkWell(
            onTap: onCartPressed,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: homeCardWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: homeBorderMint.withOpacity(0.8),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: homeDeepGreen.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    color: homeTextDark,
                    size: 21,
                  ),
                  if (cartCount > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE53935),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$cartCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 2. Delivery Location Bar:
/// Left: Location pin in circle
/// Text: "Deliver to" small + dynamic address bold
/// Right: COD badge (soft mint background, deep green text)
class DeliveryLocationBar extends StatelessWidget {
  final String locationText;
  final VoidCallback? onTap;

  const DeliveryLocationBar({
    super.key,
    required this.locationText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: homeCardWhite,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: homeBorderMint.withOpacity(0.7),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: homeDeepGreen.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: homePillMint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: homePrimaryGreen,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Deliver to',
                    style: TextStyle(
                      color: homeTextMuted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    locationText.isNotEmpty
                        ? locationText
                        : 'Agaram Supermarket · Express Store',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: homeTextDark,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: homePillMint,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: homeBorderMint.withOpacity(0.7),
                  width: 1,
                ),
              ),
              child: const Text(
                'COD',
                style: TextStyle(
                  color: homeDeepGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 3. Modern Pill Search Bar
class HomeSearchBar extends StatelessWidget {
  final VoidCallback onTap;
  final VoidCallback onFilterTap;

  const HomeSearchBar({
    super.key,
    required this.onTap,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: homeCardWhite,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: homeBorderMint.withOpacity(0.8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: homeDeepGreen.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.search_rounded, color: Color(0xFF0D6838), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: const Text(
                'Search groceries, brands or essentials',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: homeTextMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              onTap: onFilterTap,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: homePillMint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Icon(
                    Icons.tune_rounded,
                    color: homeDeepGreen,
                    size: 19,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 4. Hero Banner 3-Image Carousel
/// Prepared for:
/// - assets/images/customer_home/banner_01.png
/// - assets/images/customer_home/banner_02.png
/// - assets/images/customer_home/banner_03.png
/// Includes 3-second automatic rotation, manual swipe, smooth curve animation,
/// 3 indicator dots, lifecycle safety, and clean neutral fallback placeholder.
class HomeHeroCarousel extends StatefulWidget {
  final VoidCallback onShopNow;

  const HomeHeroCarousel({super.key, required this.onShopNow});

  @override
  State<HomeHeroCarousel> createState() => _HomeHeroCarouselState();
}

class _HomeHeroCarouselState extends State<HomeHeroCarousel> {
  static const int _basePages = 3;
  late final PageController _pageController;
  Timer? _timer;
  int _virtualIndex = 0;

  static const List<String> _bannerAssets = [
    'assets/images/customer_home/banner_01.png',
    'assets/images/customer_home/banner_02.png',
    'assets/images/customer_home/banner_03.png',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startTimer();
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients) return;
      if (!_pageController.position.hasContentDimensions) return;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeRealDot = _virtualIndex % _basePages;

    return AspectRatio(
      aspectRatio: 2.15,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: homeDeepGreen.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Infinite smooth looping PageView: 1 -> 2 -> 3 -> 1 -> 2 ...
              PageView.builder(
                controller: _pageController,
                onPageChanged: (vIndex) {
                  setState(() => _virtualIndex = vIndex);
                  _startTimer(); // Reset 3s cycle cleanly after manual swipe
                },
                itemBuilder: (context, vIndex) {
                  final realIndex = vIndex % _basePages;
                  final assetPath = _bannerAssets[realIndex];
                  return Image.asset(
                    assetPath,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) =>
                        _buildPlaceholder(realIndex),
                  );
                },
              ),

              // Bottom Center: 3 Dot Indicators (1, 2, 3)
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_basePages, (idx) {
                    final isActive = activeRealDot == idx;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isActive ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isActive
                            ? homePrimaryGreen
                            : Colors.white.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(int index) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE8F5EC), Color(0xFFFFF9EE), Color(0xFFE4F3EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Everyday Groceries,',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: homeForestTitle,
                    ),
                  ),
                ),
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Delivered Better',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: homeForestTitle,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Shop essentials from your trusted store',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: homeTextMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: widget.onShopNow,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF087247),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: homeDeepGreen.withOpacity(0.28),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Shop Now',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 10.5,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 11,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/images/hero_grocery_banner.jpg',
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.shopping_basket_rounded,
                    size: 54,
                    color: Color(0xFF8CA496),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 5. Category Model & Grid Mapping
/// Arched/oval decorative tiles matching reference visual style
const List<Map<String, String>> homeGroceryCategories = [
  {
    'query': 'Rice & Grains',
    'tamil': 'அரிசி & தானியங்கள்',
    'asset': 'assets/images/customer_home/cat_rice_grains.png',
  },
  {
    'query': 'Cooking Oil & Ghee',
    'tamil': 'எண்ணெய் & நெய்',
    'asset': 'assets/images/customer_home/cat_oil_ghee.png',
  },
  {
    'query': 'Dals & Pulses',
    'tamil': 'பருப்பு வகைகள்',
    'asset': 'assets/images/customer_home/cat_dals_pulses.png',
  },
  {
    'query': 'Atta & Flours',
    'tamil': 'மாவு வகைகள்',
    'asset': 'assets/images/customer_home/cat_atta_flours.png',
  },
  {
    'query': 'Biscuits & Cookies',
    'tamil': 'பிஸ்கட் & குக்கீஸ்',
    'asset': 'assets/images/customer_home/cat_biscuits_cookies.png',
  },
  {
    'query': 'Snacks',
    'tamil': 'ஸ்நாக்ஸ்',
    'asset': 'assets/images/customer_home/cat_snacks.png',
  },
  {
    'query': 'Chocolates',
    'tamil': 'சாக்லேட்ஸ்',
    'asset': 'assets/images/customer_home/cat_chocolates.png',
  },
  {
    'query': 'Spices & Masalas',
    'tamil': 'மசாலா பொருட்கள்',
    'asset': 'assets/images/customer_home/cat_spices_masalas.png',
  },
  {
    'query': 'Tea & Coffee',
    'tamil': 'தேநீர் & காபி',
    'asset': 'assets/images/customer_home/cat_tea_coffee.png',
  },
  {
    'query': 'Sugar & Salt',
    'tamil': 'சர்க்கரை & உப்பு',
    'asset': 'assets/images/customer_home/cat_sugar_salt.png',
  },
  {
    'query': 'Dairy Products',
    'tamil': 'பால் பொருட்கள்',
    'asset': 'assets/images/customer_home/cat_dairy.png',
  },
];

/// Resolve existing admin category labels without inventing product membership.
String groceryCategoryQuery(
  Map<String, String> category,
  List<Map<String, dynamic>> available,
) {
  return category['query']!;
}

class HomeCategoryGrid extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final ValueChanged<String> onSelectCategory;

  const HomeCategoryGrid({
    super.key,
    required this.categories,
    required this.onSelectCategory,
  });

  @override
  State<HomeCategoryGrid> createState() => _HomeCategoryGridState();
}

class _HomeCategoryGridState extends State<HomeCategoryGrid> {
  late final ScrollController _scrollController;
  Timer? _autoScrollTimer;
  bool _isUserTouching = false;

  static const int _multiplier = 200;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startAutoScroll();
    });
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (!mounted || _isUserTouching) return;
      if (!_scrollController.hasClients) return;
      if (!_scrollController.position.hasContentDimensions) return;

      final oneCycleWidth =
          homeGroceryCategories.length * 86.0; // 11 * 86 = 946.0 px
      final current = _scrollController.offset;
      double next = current + 1.1;

      // 11 mudinjavudan seamlessly 1 start aagum (zero jump jerk)
      if (next >= oneCycleWidth * 10) {
        next -= oneCycleWidth * 5;
        _scrollController.jumpTo(next);
      } else {
        _scrollController.jumpTo(next);
      }
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        _isUserTouching = true;
        _stopAutoScroll();
      },
      onPointerUp: (_) {
        _isUserTouching = false;
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted && !_isUserTouching) _startAutoScroll();
        });
      },
      onPointerCancel: (_) {
        _isUserTouching = false;
        _startAutoScroll();
      },
      child: SizedBox(
        height: 114,
        child: ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          clipBehavior: Clip.none,
          itemCount: homeGroceryCategories.length * _multiplier,
          itemBuilder: (context, index) {
            final cat =
                homeGroceryCategories[index % homeGroceryCategories.length];
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: InkWell(
                onTap: () => widget.onSelectCategory(
                  groceryCategoryQuery(cat, widget.categories),
                ),
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  width: 74,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Arched / Oval container with soft warm-cream background
                      Container(
                        width: 66,
                        height: 66,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBF4E6),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(33),
                            bottom: Radius.circular(20),
                          ),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8B6C38).withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(33),
                            bottom: Radius.circular(20),
                          ),
                          child: Image.asset(
                            cat['asset']!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Center(
                              child: Icon(
                                Icons.shopping_basket_rounded,
                                color: homePrimaryGreen,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Tamil Title Only
                      Text(
                        cat['tamil']!,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'NotoSansTamil',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: homeTextDark,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 6. JioMart-style High Conversion Promo Offer Cards
/// Collection content comes from the backend; styling never invents an offer.
/// 6. High Conversion 3D Animated Promo Offer Carousel (5-sec auto-glide 1 -> 2 -> 3 -> 1)
class CollectionChipRow extends StatefulWidget {
  final List<Map<String, dynamic>> collections;
  final String? activeCollectionKey;
  final ValueChanged<String> onSelectCollection;

  const CollectionChipRow({
    super.key,
    required this.collections,
    this.activeCollectionKey,
    required this.onSelectCollection,
  });

  @override
  State<CollectionChipRow> createState() => _CollectionChipRowState();
}

class _CollectionChipRowState extends State<CollectionChipRow> {
  static const List<Map<String, dynamic>> _dealBanners = [
    {
      'key': 'best_sellers',
      'title': 'Best Selling',
      'asset': 'assets/images/customer_home/deal_best_selling.png',
      'glow': Color(0xFF0D8247),
    },
    {
      'key': 'most_bought',
      'title': 'Most Bought',
      'asset': 'assets/images/customer_home/deal_most_bought.png',
      'glow': Color(0xFFE65100),
    },
    {
      'key': 'under_100',
      'title': '100 Below',
      'asset': 'assets/images/customer_home/deal_under_100.png',
      'glow': Color(0xFF5E35B1),
    },
  ];

  List<Map<String, dynamic>> get _availableBanners => [
    for (final definition in _dealBanners)
      for (final actual in widget.collections)
        if (actual['key'] == definition['key'] &&
            (int.tryParse('${actual['count']}') ?? 0) > 0)
          {
            ...definition,
            'count': actual['count'],
            'image_url': actual['image_url'] ?? '',
          },
  ];

  @override
  void didUpdateWidget(covariant CollectionChipRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.collections != widget.collections) _startTimer();
  }

  late final PageController _pageController;
  Timer? _timer;
  int _currentIndex = 0;
  bool _isInteracting = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.86);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startTimer();
    });
  }

  void _startTimer() {
    _timer?.cancel();
    if (_availableBanners.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _isInteracting) return;
      if (!_pageController.hasClients ||
          !_pageController.position.hasContentDimensions) {
        return;
      }
      final current = _pageController.page?.round() ?? _currentIndex;
      _pageController.animateToPage(
        current + 1,
        duration: const Duration(milliseconds: 750),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banners = _availableBanners;
    if (banners.isEmpty) return const SizedBox();
    final total = banners.length;
    final activeReal = _currentIndex % total;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 148,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                _isInteracting = true;
                _timer?.cancel();
              } else if (notification is ScrollEndNotification) {
                _isInteracting = false;
                _startTimer();
              }
              return false;
            },
            child: PageView.builder(
              controller: _pageController,
              clipBehavior: Clip.none,
              onPageChanged: (idx) {
                if (mounted) {
                  setState(() => _currentIndex = idx);
                }
              },
              itemBuilder: (context, vIndex) {
                final realIndex = vIndex % total;
                final deal = banners[realIndex];

                return AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    double page = vIndex.toDouble();
                    if (_pageController.hasClients &&
                        _pageController.position.hasContentDimensions) {
                      page = _pageController.page ?? _currentIndex.toDouble();
                    }
                    final diff = (page - vIndex).abs().clamp(0.0, 1.0);
                    // 3D Depth Zoom: Center card scales 1.0, side cards scale 0.90
                    final scale = 1.0 - (diff * 0.10);
                    // Side card opacity fades smoothly
                    final opacity = 1.0 - (diff * 0.22);

                    return Transform.scale(
                      scale: scale,
                      child: Opacity(opacity: opacity, child: child),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white, width: 1.8),
                      boxShadow: [
                        BoxShadow(
                          color: (deal['glow'] as Color).withOpacity(0.28),
                          blurRadius: 16,
                          offset: const Offset(0, 5),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () =>
                              widget.onSelectCollection(deal['key'] as String),
                          child: '${deal['asset']}'.isNotEmpty
                              ? Image.asset(
                                  deal['asset'] as String,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                )
                              : Container(
                                  color: storeMint,
                                  padding: const EdgeInsets.all(18),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${deal['title']}',
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w900,
                                                color: storeForestGreen,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '${deal['count']} products',
                                              style: const TextStyle(
                                                color: storeGrey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        width: 80,
                                        height: 90,
                                        child: '${deal['image_url']}'.isEmpty
                                            ? const Icon(
                                                Icons.shopping_bag_outlined,
                                                color: storeForestGreen,
                                                size: 42,
                                              )
                                            : ProductPhoto(
                                                '${deal['image_url']}',
                                                height: 90,
                                                fit: BoxFit.contain,
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Animated Indicators (1, 2, 3)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(total, (i) {
            final isActive = activeReal == i;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 22 : 6,
              height: 5.5,
              decoration: BoxDecoration(
                color: isActive
                    ? (banners[i]['glow'] as Color)
                    : const Color(0xFFC7D4CD),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class HomeSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String action;
  final VoidCallback? onAction;

  const HomeSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action = 'See All >',
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: homeTextDark,
                  letterSpacing: -0.3,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontFamily: 'NotoSansTamil',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: homePrimaryGreen,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (onAction != null)
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text(
                action,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: homePrimaryGreen,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 8. Premium Product Card:
/// Language Rule: Tamil title ONLY (using product.tamilName with fallback).
/// Image: Real Cloudinary product image only with BoxFit.contain.
/// Price, Unit, MRP, Discount, Add / Quantity selector.
/// The same proportions are used wherever a grocery card is displayed.
String groceryUnitLabel(String value) => value.trim().replaceAllMapped(
  RegExp(
    r'கிலோகிராம்|கிலோ கிராம்|கிலோ|கிராம்|லிட்டர்|மில்லிலிட்டர்|(?<![A-Za-z])(?:kilograms?|grams?|litres?|liters?|kgs?|ml|l|g)(?![A-Za-z])',
    caseSensitive: false,
  ),
  (match) {
    final unit = match[0]!.toLowerCase();
    if (unit.startsWith('கிலோ') || unit.startsWith('k')) return 'Kg';
    if (unit.startsWith('லிட்டர்') || unit == 'l' || unit.startsWith('liter') || unit.startsWith('litre')) return 'L';
    if (unit.startsWith('மில்லி') || unit == 'ml') return 'ML';
    return 'g';
  },
);

String formatGroceryUnit(String raw) {
  return groceryUnitLabel(raw);
}

double groceryProductCardExtent(
  BuildContext context,
  double cardWidth, {
  bool compact = false,
}) {
  final imageHeight = compact
      ? (cardWidth - 12).clamp(55.0, 95.0)
      : (cardWidth - 14).clamp(60.0, 105.0);
  final scale = MediaQuery.textScalerOf(context).scale(1);
  final baseline = imageHeight + 50 + (32 * scale);
  return baseline + 18;
}

class PremiumProductCard extends StatelessWidget {
  final StoreProduct product;
  final int cartQuantity;
  final bool isWishlisted;
  final bool compact;
  final VoidCallback onTap, onAddToCart, onToggleWishlist;
  final VoidCallback? onIncrement, onDecrement;

  const PremiumProductCard({
    super.key,
    required this.product,
    this.cartQuantity = 0,
    this.isWishlisted = false,
    this.compact = false,
    required this.onTap,
    required this.onAddToCart,
    this.onIncrement,
    this.onDecrement,
    required this.onToggleWishlist,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(1);
      final imageHeight = compact
          ? (constraints.maxWidth - 12).clamp(55.0, 95.0)
          : (constraints.maxWidth - 14).clamp(60.0, 105.0);
      final title = product.tamilName.trim().isNotEmpty
          ? product.tamilName.trim()
          : product.name;
      final unitLabel = formatGroceryUnit(product.unit);

      final sellingPrice = product.price;
      // Comparison prices must come from backend data, never a price multiplier.
      final effectiveMrp = product.mrp;
      final effectiveDiscount = product.discountPercent;
      final savings = effectiveMrp - sellingPrice;

      final priceText = sellingPrice == sellingPrice.truncateToDouble()
          ? '₹${sellingPrice.toStringAsFixed(0)}'
          : money(sellingPrice);

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: homeDeepGreen.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Material(
          color: Colors.white,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: cartQuantity > 0
                  ? homePrimaryGreen.withOpacity(0.55)
                  : const Color(0xFFE8ECE9),
              width: cartQuantity > 0 ? 1.4 : 0.8,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.all(compact ? 6 : 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image with Gradient Backing and floating tags
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: imageHeight,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            border: Border.all(
                              color: const Color(0xFFF1F5F9),
                              width: 0.8,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: ProductPhoto(
                            product.imageUrl,
                            height: imageHeight - 8,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      // Discount Tag top-left
                      if (effectiveDiscount > 0)
                        Positioned(
                          left: 4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0D8648), Color(0xFF065E32)],
                              ),
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0D8648).withOpacity(0.25),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Text(
                              '% OFF',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),

                      // Wishlist Button top-right
                      Positioned(
                        right: 4,
                        top: 4,
                        child: GestureDetector(
                          onTap: onToggleWishlist,
                          child: Container(
                            width: compact ? 26 : 28,
                            height: compact ? 26 : 28,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Icon(
                              isWishlisted
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: isWishlisted
                                  ? const Color(0xFFE53935)
                                  : const Color(0xFF94A3B8),
                              size: compact ? 15 : 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Unit Badge Pill & Delivery Hint (JioMart compact style)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (unitLabel.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            unitLabel,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475569),
                            ),
                          ),
                        )
                      else
                        const SizedBox.shrink(),

                      // Compact ADD button in top or action area (JioMart outline style)
                      if (cartQuantity == 0)
                        InkWell(
                          onTap: product.available ? onAddToCart : null,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: product.available
                                  ? Colors.white
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: product.available
                                    ? const Color(0xFF0F7645)
                                    : const Color(0xFFCBD5E1),
                                width: 1.1,
                              ),
                            ),
                            child: Text(
                              product.available ? 'ADD' : 'Out',
                              style: TextStyle(
                                color: product.available
                                    ? const Color(0xFF0F7645)
                                    : const Color(0xFF94A3B8),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        )
                      else
                        QuantitySelector(
                          height: 24,
                          quantity: cartQuantity,
                          onIncrement: onIncrement ?? onAddToCart,
                          onDecrement: onDecrement ?? () {},
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),

                  // Price Row: Selling Price + Strikethrough MRP
                  SizedBox(
                    height: 16 * scale,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            priceText,
                            style: const TextStyle(
                              fontSize: 13.5,
                              height: 1.1,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (effectiveMrp > sellingPrice) ...[
                            const SizedBox(width: 4),
                            Text(
                              money(effectiveMrp),
                              style: const TextStyle(
                                fontSize: 9.5,
                                color: Color(0xFF94A3B8),
                                decoration: TextDecoration.lineThrough,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Tamil/English Product Title (Clean 1 line with ellipsis)
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'NotoSansTamil',
                      fontSize: compact ? 9.5 : 10.2,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Delivery speed / brand footnote (JioMart style)
                  Row(
                    children: [
                      const Icon(
                        Icons.bolt_rounded,
                        size: 10,
                        color: Color(0xFF0F7645),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          product.brand.isNotEmpty
                              ? product.brand
                              : '15 Mins',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F7645),
                          ),
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
    },
  );
}

class HomeTrustStrip extends StatelessWidget {
  const HomeTrustStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: homeCardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: homeBorderMint.withOpacity(0.8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: homeDeepGreen.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _trustItem(Icons.local_shipping_outlined, 'On-Demand\nDelivery'),
          Container(width: 1, height: 32, color: homeBorderMint),
          _trustItem(Icons.payments_outlined, 'Cash on\nDelivery'),
          Container(width: 1, height: 32, color: homeBorderMint),
          _trustItem(Icons.verified_outlined, 'Quality\nGroceries'),
        ],
      ),
    );
  }

  Widget _trustItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: homePillMint,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: homePrimaryGreen, size: 17),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: homeForestTitle,
            height: 1.15,
          ),
        ),
      ],
    );
  }
}

/// 10. Floating Rounded Customer Bottom Navigation
/// Preserving all tabs: Home (0), Categories (1), Offers (2), Orders (3), Account (4)
class CustomerFloatingBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final int cartCount;
  final VoidCallback? onCartPressed;

  const CustomerFloatingBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.cartCount = 0,
    this.onCartPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.of(context).padding.bottom + 8,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: homeDeepGreen.withOpacity(0.08),
            blurRadius: 22,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(
            icon: Icons.home_rounded,
            outlineIcon: Icons.home_outlined,
            label: 'Home',
            isSelected: selectedIndex == 0,
            onTap: () => onItemSelected(0),
          ),
          _navItem(
            icon: Icons.grid_view_rounded,
            outlineIcon: Icons.grid_view_outlined,
            label: 'Categories',
            isSelected: selectedIndex == 1,
            onTap: () => onItemSelected(1),
          ),
          _navItem(
            icon: Icons.local_offer_rounded,
            outlineIcon: Icons.local_offer_outlined,
            label: 'Offers',
            isSelected: selectedIndex == 2,
            onTap: () => onItemSelected(2),
          ),
          _navItem(
            icon: Icons.inventory_2_rounded,
            outlineIcon: Icons.inventory_2_outlined,
            label: 'Orders',
            isSelected: selectedIndex == 3,
            onTap: () => onItemSelected(3),
          ),
          _navItem(
            icon: Icons.person_rounded,
            outlineIcon: Icons.person_outline_rounded,
            label: 'Account',
            isSelected: selectedIndex == 4,
            onTap: () => onItemSelected(4),
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required IconData outlineIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 6)
            : const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? homePillMint : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? icon : outlineIcon,
              size: 22,
              color: isSelected ? const Color(0xFF0D6838) : homeTextMuted,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? const Color(0xFF0D6838) : homeTextMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating View Cart Bar shown whenever the cart has items
class FloatingCartBar extends StatelessWidget {
  final List<CartLine> cart;
  final VoidCallback onTap;

  const FloatingCartBar({
    super.key,
    required this.cart,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (cart.isEmpty) return const SizedBox.shrink();
    final count = cart.fold(0, (s, l) => s + l.quantity);
    final total = cart.fold<double>(0, (s, l) => s + l.total);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF087247),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.4),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF087247).withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$count items · ${money(total)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                ),
              ),
            ),
            const Text(
              'View Cart',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

