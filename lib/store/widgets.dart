import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart';
import 'loading.dart';

const storeForestGreen = Color(0xFF0B5A3C);
const storeDeepGreen = Color(0xFF06452F);
const storeFreshGreen = Color(0xFF138B5A);
const storeMint = Color(0xFFE8F3EC);
const storeLightMint = Color(0xFFF2F8F4);
const storeCream = Color(0xFFFFFDF7);
const storeInk = Color(0xFF17201C);
const storeGrey = Color(0xFF69716D);
const storeGold = Color(0xFFE5A93C);
const storeYellow = Color(0xFFF5A623);
const storeOrange = Color(0xFFE67E22);
const storeBorder = Color(0xFFE5EBE6);
const storeRed = Color(0xFFE53935);

// Backward compatibility alias
const storeGreen = storeForestGreen;

ThemeData storeTheme() => ThemeData(
  useMaterial3: true,
  fontFamilyFallback: const ['NotoSansTamil'],
  scaffoldBackgroundColor: storeCream,
  colorScheme: ColorScheme.fromSeed(
    seedColor: storeForestGreen,
    primary: storeForestGreen,
    surface: Colors.white,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: storeCream,
    foregroundColor: storeInk,
    centerTitle: true,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
  ),
  navigationBarTheme: NavigationBarThemeData(
    height: 72,
    backgroundColor: Colors.white,
    indicatorColor: storeMint,
    labelTextStyle: WidgetStateProperty.resolveWith(
      (states) => TextStyle(
        fontSize: 11,
        fontWeight: states.contains(WidgetState.selected)
            ? FontWeight.w800
            : FontWeight.w500,
        color: states.contains(WidgetState.selected)
            ? storeForestGreen
            : storeGrey,
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: const BorderSide(color: storeBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: const BorderSide(color: storeBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: const BorderSide(color: storeForestGreen, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: storeForestGreen,
      foregroundColor: Colors.white,
      minimumSize: const Size(48, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: Colors.white,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: storeBorder),
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

// =============================================================================
// AGARAM SUPERMARKET – NEW CUSTOMER COMPONENT SUITE
// =============================================================================

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
      color: storeCream,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 4,
        left: 8,
        right: 8,
        bottom: 6,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: showBackButton ? 'Back' : 'Open menu',
            icon: Icon(
              showBackButton
                  ? Icons.arrow_back_ios_new_rounded
                  : Icons.menu_rounded,
              color: storeInk,
              size: 24,
            ),
            onPressed: showBackButton ? onBackPressed : onMenuPressed,
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'AGARAM',
                  style: TextStyle(
                    color: storeForestGreen,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.2,
                    fontSize: 17,
                  ),
                ),
                Text(
                  'SUPERMARKET',
                  style: TextStyle(
                    color: storeFreshGreen,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.6,
                    fontSize: 8.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'My shopping cart',
            onPressed: onCartPressed,
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text(
                '$cartCount',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: Colors.white,
                ),
              ),
              backgroundColor: storeOrange,
              child: const Icon(
                Icons.shopping_cart_outlined,
                color: storeInk,
                size: 24,
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

  const AgaramBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final items = const [
      (Icons.home_outlined, Icons.home_rounded, 'Home'),
      (Icons.grid_view_outlined, Icons.grid_view_rounded, 'Categories'),
      (Icons.local_offer_outlined, Icons.local_offer_rounded, 'Offers'),
      (Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'Orders'),
      (Icons.person_outline_rounded, Icons.person_rounded, 'Account'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: storeBorder, width: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: 6,
        bottom: MediaQuery.of(context).padding.bottom + 6,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final isSelected = selectedIndex == index;
          final item = items[index];
          return InkWell(
            onTap: () => onItemSelected(index),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 14 : 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isSelected ? storeMint : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected ? item.$2 : item.$1,
                    size: 22,
                    color: isSelected ? storeForestGreen : storeGrey,
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 6),
                    Text(
                      item.$3,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: storeForestGreen,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
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
            // Top curved header
            Container(
              margin: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  colors: [storeDeepGreen, storeForestGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: storeDeepGreen.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.22,
                        child: Image.asset(
                          'assets/images/drawer_grocery_pantry.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox(),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
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
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2.2,
                                      fontSize: 19,
                                    ),
                                  ),
                                  Text(
                                    'SUPERMARKET',
                                    style: TextStyle(
                                      color: storeGold,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 2.6,
                                      fontSize: 9,
                                    ),
                                  ),
                                ],
                              ),
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.white24,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // First prominent action button
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
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 20,
                                      backgroundColor: storeMint,
                                      child: Icon(
                                        Icons.person_rounded,
                                        color: storeForestGreen,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: const [
                                          Text(
                                            'Login / Sign In',
                                            style: TextStyle(
                                              color: storeForestGreen,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 15.5,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            'Access orders, wishlist & addresses',
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
                                      size: 16,
                                      color: storeForestGreen,
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
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 22,
                                      backgroundColor: Colors.white,
                                      child: Icon(
                                        Icons.person_rounded,
                                        color: storeForestGreen,
                                        size: 26,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            displayName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          if (phone.isNotEmpty)
                                            Text(
                                              phone,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                          const SizedBox(height: 2),
                                          const Text(
                                            'View Profile →',
                                            style: TextStyle(
                                              color: storeGold,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 11,
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
                  ],
                ),
              ),
            ),

            // Navigation Menu List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                children: [
                  _drawerRow(
                    icon: Icons.admin_panel_settings_outlined,
                    label: 'Admin login',
                    onTap: () {
                      Navigator.pop(context);
                      onAdminLogin();
                    },
                  ),
                  _drawerRow(
                    icon: Icons.delivery_dining,
                    label: 'Delivery employee login',
                    onTap: () {
                      Navigator.pop(context);
                      onDeliveryLogin();
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: storeBorder, height: 1),
                  ),
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
                    label: 'Help',
                    onTap: () {
                      Navigator.pop(context);
                      onSelectHelp();
                    },
                  ),
                  _drawerRow(
                    icon: Icons.phone_outlined,
                    label: 'Contact',
                    onTap: () {
                      Navigator.pop(context);
                      onSelectContact();
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
    Color iconColor = storeForestGreen,
    Color textColor = storeInk,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(icon, color: iconColor, size: 21),
        title: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 14.5,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: storeGrey,
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 195,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [storeDeepGreen, storeForestGreen],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 200,
              child: imageUrl.isEmpty
                  ? const Icon(
                      Icons.shopping_basket_outlined,
                      color: storeMint,
                      size: 100,
                    )
                  : ProductPhoto(imageUrl, height: 195, fit: BoxFit.contain),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      storeDeepGreen.withOpacity(0.96),
                      storeDeepGreen.withOpacity(0.85),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your One-Stop\nGrocery Store',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Groceries from our store\nPay cash on delivery',
                    style: TextStyle(
                      color: storeLightMint,
                      fontSize: 11,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      InkWell(
                        onTap: onShopNow,
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: storeGold,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
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
                                  color: storeInk,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.5,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 16,
                                color: storeInk,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Carousel Indicator dots
                      Row(
                        children: [
                          Container(
                            width: 16,
                            height: 5,
                            decoration: BoxDecoration(
                              color: storeMint,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Colors.white54,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Colors.white54,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ],
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
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: storeBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.search_rounded, color: storeForestGreen, size: 24),
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
                        fontWeight: FontWeight.w600,
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
                color: storeForestGreen,
                size: 23,
              ),
              onPressed: onVoiceTap,
            ),
          if (onFilterTap != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InkWell(
                onTap: onFilterTap,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: storeMint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.tune_rounded,
                      color: storeForestGreen,
                      size: 20,
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
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: imageUrl.isEmpty
                    ? Icon(icon, color: storeForestGreen, size: 28)
                    : ProductPhoto(imageUrl, height: 58, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 6),
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
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: storeInk,
            ),
          ),
        ),
        if (onAction != null)
          InkWell(
            onTap: onAction,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Text(
                action,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: storeForestGreen,
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
      height: 98,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final item = items[i];
          return InkWell(
            onTap: () => onSelectCategory('${item['name']}'),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 82,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: storeBorder),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: storeMint,
                    child: '${item['image_url'] ?? ''}'.isEmpty
                        ? const Icon(
                            Icons.shopping_basket_outlined,
                            color: storeForestGreen,
                            size: 20,
                          )
                        : ClipOval(
                            child: ProductPhoto(
                              '${item['image_url']}',
                              height: 40,
                              fit: BoxFit.contain,
                            ),
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
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: storeBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image Container with Wishlist button
            Stack(
              children: [
                Container(
                  height: 118,
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFAFCFA),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: ProductPhoto(
                    product.imageUrl,
                    height: 102,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: onToggleWishlist,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        isWishlisted
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isWishlisted ? storeRed : storeGrey,
                        size: 17,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Product Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: storeInk,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      product.unit,
                      style: const TextStyle(
                        fontSize: 11,
                        color: storeGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    // Price row: Selling Price + MRP + Discount %
                    Row(
                      children: [
                        Text(
                          '₹${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: storeInk,
                          ),
                        ),
                        const SizedBox(width: 5),
                        if (product.discountPercent > 0)
                          Text(
                            '₹${product.mrp.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: storeGrey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        const Spacer(),
                        if (product.discountPercent > 0)
                          Text(
                            '${product.discountPercent}% OFF',
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: storeFreshGreen,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Add Button or Quantity Selector
                    if (cartQuantity > 0)
                      QuantitySelector(
                        quantity: cartQuantity,
                        onIncrement: onIncrement ?? onAddToCart,
                        onDecrement: onDecrement ?? () {},
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 32,
                        child: OutlinedButton(
                          onPressed: product.available ? onAddToCart : null,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: storeForestGreen,
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: Text(
                            product.available ? '+ ADD' : 'Out of Stock',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: product.available
                                  ? storeForestGreen
                                  : storeGrey,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuantitySelector extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const QuantitySelector({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: storeMint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: storeForestGreen, width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 15, color: storeForestGreen),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28),
            onPressed: onDecrement,
          ),
          Text(
            '$quantity',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: storeForestGreen,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 15, color: storeForestGreen),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28),
            onPressed: onIncrement,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: storeMint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: const [
          Icon(
            Icons.local_shipping_outlined,
            color: storeForestGreen,
            size: 19,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Free delivery',
              style: TextStyle(
                color: storeForestGreen,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: storeForestGreen, size: 18),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: storeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Price Details',
            style: TextStyle(
              fontSize: 15,
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
              valueColor: storeFreshGreen,
            ),
          ],
          const SizedBox(height: 8),
          _row(
            'Delivery Fee',
            finalDelivery == 0
                ? 'FREE'
                : '₹${finalDelivery.toStringAsFixed(2)}',
            valueColor: finalDelivery == 0 ? storeFreshGreen : storeInk,
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
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: storeBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Product thumbnail preview
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: storeMint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: storeForestGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.id}',
                      style: const TextStyle(
                        fontSize: 13.5,
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
                      style: const TextStyle(fontSize: 11, color: storeGrey),
                    ),
                  ],
                ),
              ),
              // Status Pill
              _statusPill(status),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: storeGrey,
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
        bg = const Color(0xFFE8F8F0);
        fg = storeFreshGreen;
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
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
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
            SizedBox(
              height: 150,
              child: Image.asset(
                'assets/images/empty_cart_grocery.jpg',
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.shopping_bag_outlined,
                  size: 64,
                  color: storeForestGreen,
                ),
              ),
            ),
            const SizedBox(height: 20),
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
              'Add your essentials and they will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: storeGrey, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onStartShopping,
              style: FilledButton.styleFrom(
                backgroundColor: storeForestGreen,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
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
