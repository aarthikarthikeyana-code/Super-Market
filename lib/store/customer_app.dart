import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'api.dart';
import 'customer_account.dart';
import 'models.dart';
import 'state.dart';
import 'widgets.dart';
import 'paged_feed.dart';
import 'loading.dart';

class StorefrontScreen extends ConsumerStatefulWidget {
  const StorefrontScreen({super.key});
  @override
  ConsumerState<StorefrontScreen> createState() => _StorefrontState();
}

class _StorefrontState extends ConsumerState<StorefrontScreen> {
  int _tab = 0;
  String _search = '', _category = 'All';
  Timer? _poll, _searchDebounce;
  final _searchInput = TextEditingController();
  List<String> _categories = ['All'];
  bool _accountActionBusy = false;
  final Set<String> _savingWishlist = {};

  Future<bool> _addToCart(StoreProduct product) async {
    if (_accountActionBusy) return false;
    _accountActionBusy = true;
    try {
      if (!await ensureCustomerAccount(context, ref) || !mounted) return false;
      ref.read(storeCartProvider.notifier).add(product);
      return true;
    } finally {
      _accountActionBusy = false;
    }
  }

  Future<void> _toggleWishlist(StoreProduct product) async {
    if (_savingWishlist.contains(product.id) || _accountActionBusy) return;
    _accountActionBusy = true;
    setState(() => _savingWishlist.add(product.id));
    try {
      if (!await ensureCustomerAccount(context, ref) || !mounted) return;
      final saved = await ref.read(wishlistIdsProvider.future);
      final exists = saved.contains(product.id);
      await ref.read(storeApiProvider).setWishlist(product.id, !exists);
      ref.invalidate(wishlistProvider);
      ref.invalidate(wishlistIdsProvider);
    } catch (e) {
      if (mounted) showStoreError(context, e);
    } finally {
      _accountActionBusy = false;
      if (mounted) setState(() => _savingWishlist.remove(product.id));
    }
  }

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_tab == 2) {
        ref.invalidate(myOrdersProvider);
        ref.read(storeApiProvider).feedChanges.value++;
      }
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _searchDebounce?.cancel();
    _searchInput.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(storeCartProvider);
    final count = cart.fold(0, (sum, l) => sum + l.quantity);
    return Theme(
      data: storeTheme(),
      child: Scaffold(
        appBar: AppBar(
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AGARAM',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  fontSize: 22,
                ),
              ),
              Text(
                'SUPERMARKET',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 3,
                  color: storeGreen,
                ),
              ),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              tooltip: 'Staff sign in',
              onSelected: (role) async {
                await context.push(role == 'delivery' ? '/delivery' : '/admin');
                ref.invalidate(catalogProvider);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'admin', child: Text('Admin login')),
                PopupMenuItem(
                  value: 'delivery',
                  child: Text('Delivery employee login'),
                ),
              ],
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.badge_outlined, size: 19),
                    SizedBox(width: 6),
                    Text('Staff login'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: switch (_tab) {
          0 => _shop(),
          1 => DataView(
            retainOnRefresh: false,
            value: ref.watch(customerAccountProvider),
            onRetry: () => ref.invalidate(customerAccountProvider),
            builder: (account) => account == null
                ? EmptyPanel(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Sign in to your cart',
                    message: 'Use your mobile number to add products and place an order.',
                    action: 'Sign in',
                    onAction: () => ensureCustomerAccount(context, ref),
                  )
                : ref.watch(cartLoadingProvider)
                ? const SingleChildScrollView(child: AppSkeleton())
                : cart.isEmpty &&
                      ref.read(storeCartProvider.notifier).restoreError != null
                ? EmptyPanel(
                    icon: Icons.wifi_off_outlined,
                    title: 'Could not restore your cart',
                    message: ref.read(storeCartProvider.notifier).restoreError!,
                    action: 'Retry',
                    onAction: () => ref.invalidate(storeCartProvider),
                  )
                : _cart(cart),
          ),
          2 => _orders(),
          _ => const CustomerAccountScreen(),
        },
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) {
            setState(() => _tab = i);
            if (i == 2) ref.invalidate(myOrdersProvider);
          },
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront),
              label: 'Shop',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: count > 0,
                label: Text('$count'),
                child: const Icon(Icons.shopping_bag_outlined),
              ),
              label: 'Cart',
            ),
            const NavigationDestination(
              icon: Icon(Icons.local_shipping_outlined),
              label: 'My orders',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }

  Widget _shop() => LayoutBuilder(
    builder: (context, constraints) {
      final api = ref.watch(storeApiProvider);
      return PagedFeed<StoreProduct>(
        beforeRefresh: api.clearPublicCache,
        queryKey: (_search, _category),
        changes: api.feedChanges,
        load: (cursor) => api.productPage(
          cursor: cursor,
          search: _search,
          category: _category,
        ),
        identity: (p) => p.id,
        onMetadata: (data) {
          if (!mounted) return;
          setState(() {
            _categories = [
              'All',
              ...(data['categories'] as List? ?? [])
                  .map((c) => '$c')
                  .where((c) => c.isNotEmpty && c != 'All'),
            ];
            if (!_categories.contains(_category)) _category = 'All';
          });
        },
        header: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StoreHero(),
              const SizedBox(height: 10),
              const StoreServiceStrip(),
              const SizedBox(height: 16),
              TextField(
                controller: _searchInput,
                maxLength: 100,
                decoration: const InputDecoration(
                  hintText: 'Search products or brands',
                  prefixIcon: Icon(Icons.search),
                  counterText: '',
                ),
                onChanged: (text) {
                  _searchDebounce?.cancel();
                  _searchDebounce = Timer(
                    const Duration(milliseconds: 350),
                    () {
                      if (mounted) setState(() => _search = text.trim());
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final category in _categories)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: _category == category,
                          onSelected: (_) =>
                              setState(() => _category = category),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Shop the essentials',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: constraints.maxWidth > 700 ? 4 : 2,
          mainAxisExtent: 320,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (_, product, _) => _productCard(product),
        emptyTitle: _search.isEmpty && _category == 'All'
            ? 'Our shelves are getting ready'
            : 'No matching products',
        emptyMessage:
            'Try another search or category, or pull down to refresh.',
        endContent: const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: DeliveryStoryCard(),
        ),
      );
    },
  );
  Widget _productCard(StoreProduct p) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            InkWell(
              onTap: () => _showProduct(p),
              child: ProductPhoto(p.imageUrl, height: 142),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton.filledTonal(
                tooltip: 'Save to wishlist',
                onPressed: _savingWishlist.contains(p.id)
                    ? null
                    : () => _toggleWishlist(p),
                icon: Icon(
                  (ref.watch(wishlistIdsProvider).asData?.value ?? []).contains(
                        p.id,
                      )
                      ? Icons.favorite
                      : Icons.favorite_border,
                  size: 21,
                ),
              ),
            ),
          ],
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.brand.isEmpty ? p.category : p.brand,
                  style: const TextStyle(
                    color: storeGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  p.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Text(
                  p.unit,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        money(p.price),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: p.available ? 'Add ${p.name}' : 'Out of stock',
                      onPressed: p.available ? () => _addToCart(p) : null,
                      icon: Icon(
                        p.available
                            ? Icons.add
                            : Icons.remove_shopping_cart_outlined,
                        size: 20,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      padding: const EdgeInsets.all(6),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
  void _showProduct(StoreProduct p) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: ProductPhoto(p.imageUrl, height: 240),
            ),
            const SizedBox(height: 20),
            Text(
              p.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            if (p.tamilName.isNotEmpty) Text(p.tamilName),
            const SizedBox(height: 8),
            Text(
              '${money(p.price)} / ${p.unit}',
              style: const TextStyle(
                fontSize: 20,
                color: storeGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            if (p.description.isNotEmpty)
              Text(p.description, style: const TextStyle(height: 1.6)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: p.available
                    ? () async {
                        final added = await _addToCart(p);
                        if (added && ctx.mounted) Navigator.pop(ctx);
                      }
                    : null,
                icon: const Icon(Icons.add_shopping_cart),
                label: Text(p.available ? 'Add to cart' : 'Out of stock'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  Widget _cart(List<CartLine> lines) {
    if (lines.isEmpty) {
      return EmptyPanel(
        icon: Icons.shopping_bag_outlined,
        title: 'Your cart is empty',
        message: 'Add your essentials and we will take it from there.',
        action: 'Start shopping',
        onAction: () => setState(() => _tab = 0),
      );
    }
    final total = lines.fold(0.0, (sum, l) => sum + l.total);
    final config = ref.watch(storeConfigProvider);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Your shopping bag',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 26),
              ),
              const SizedBox(height: 6),
              const Text(
                'Final prices and availability are checked at checkout.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),
              for (final l in lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 65,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: ProductPhoto(
                                l.product.imageUrl,
                                height: 65,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l.product.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${l.product.unit}  /  ${money(l.product.price)}',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () => ref
                                          .read(storeCartProvider.notifier)
                                          .change(l.product.id, -1),
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                      ),
                                    ),
                                    Text('${l.quantity}'),
                                    IconButton(
                                      onPressed: () => ref
                                          .read(storeCartProvider.notifier)
                                          .add(l.product),
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      money(l.total),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Remove',
                            onPressed: () => ref
                                .read(storeCartProvider.notifier)
                                .remove(l.product.id),
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Items total',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    Text(
                      money(total),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  config.hasValue
                      ? 'Delivery: ${money(amount(config.value!['delivery_charge']))}'
                      : 'Delivery charge confirmed at checkout',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      if (!await ensureCustomerAccount(context, ref)) return;
                      if (!mounted) return;
                      try {
                        final products = await ref
                            .read(storeApiProvider)
                            .productsByIds(
                              ref
                                  .read(storeCartProvider)
                                  .map((line) => line.product.id)
                                  .toList(),
                            );
                        if (!mounted) return;
                        ref
                            .read(storeCartProvider.notifier)
                            .reconcile(products);
                      } catch (e) {
                        if (mounted) showStoreError(context, e);
                        return;
                      }
                      if (!mounted || ref.read(storeCartProvider).isEmpty) {
                        return;
                      }
                      final placed = await Navigator.push<StoreOrder>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CheckoutScreen(),
                        ),
                      );
                      if (placed != null && mounted) {
                        setState(() => _tab = 2);
                        final browse = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderPlacedScreen(order: placed),
                          ),
                        );
                        if (browse == true && mounted) setState(() => _tab = 0);
                      }
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Continue to checkout'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _orders() => DataView(
    retainOnRefresh: false,
    value: ref.watch(customerAccountProvider),
    onRetry: () => ref.invalidate(customerAccountProvider),
    builder: (account) => account == null
        ? EmptyPanel(
            icon: Icons.receipt_long_outlined,
            title: 'Your orders, in one place',
            message: 'Enter your mobile number to see your account and orders.',
            action: 'Enter mobile number',
            onAction: () => ensureCustomerAccount(context, ref),
          )
        : _signedInOrders(),
  );

  Widget _signedInOrders() {
    final api = ref.watch(storeApiProvider);
    final phone = ref.watch(customerAccountProvider).asData?.value?['phone'];
    return PagedFeed<StoreOrder>(
      queryKey: ('customer', phone),
      changes: api.feedChanges,
      load: (cursor) => api.orderPage(cursor: cursor),
      identity: (o) => o.id,
      emptyTitle: 'Your orders will appear here',
      emptyMessage: 'Once you place an order, follow its progress right here.',
      itemBuilder: (_, order, _) => OrderSummaryCard(
        order: order,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderTrackingScreen(orderId: order.id),
          ),
        ),
      ),
    );
  }
}

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutState();
}

class _CheckoutState extends ConsumerState<CheckoutScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _phone = TextEditingController(),
      _address = TextEditingController(),
      _notes = TextEditingController();
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _restoreAddress();
  }

  bool _loadingProfile = true;
  String? _profileError;
  Future<void> _restoreAddress() async {
    setState(() {
      _loadingProfile = true;
      _profileError = null;
    });
    try {
      final profile = await ref.read(storeApiProvider).customerProfile();
      if (!mounted) return;
      if (_name.text.isEmpty) _name.text = profile['name'] ?? '';
      _phone.text = profile['phone'] ?? '';
      if (_address.text.isEmpty) _address.text = profile['address'] ?? '';
      if (_notes.text.isEmpty) {
        _notes.text = profile['delivery_instructions'] ?? '';
      }
    } catch (e) {
      if (mounted) setState(() => _profileError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _place() async {
    if (_busy ||
        _loadingProfile ||
        _profileError != null ||
        !(_form.currentState?.validate() ?? false)) {
      return;
    }
    final lines = ref.read(storeCartProvider);
    if (lines.isEmpty) return;
    setState(() => _busy = true);
    final api = ref.read(storeApiProvider);
    try {
      await api.saveCustomerProfile({
        'name': _name.text.trim(),
        'address': _address.text.trim(),
        'delivery_instructions': _notes.text.trim(),
      });
      if (!mounted) return;
      ref.invalidate(customerProfileProvider);
      ref.invalidate(customerAccountProvider);
      final response = await api.checkout({
        'customer_name': _name.text.trim(),
        'customer_phone': _phone.text.trim(),
        'delivery_address': _address.text.trim(),
        'delivery_instructions': _notes.text.trim(),
        'payment_method': 'cod',
        'expected_total':
            (lines.fold(0.0, (sum, line) => sum + line.total) +
                    amount(
                      ref.read(storeConfigProvider).value!['delivery_charge'],
                    ))
                .toStringAsFixed(2),
        'items': [
          for (final l in lines)
            {'product_id': l.product.id, 'quantity': l.quantity},
        ],
      });
      final order = StoreOrder(Map<String, dynamic>.from(response['order']));
      if (!['paid', 'cod'].contains(order.paymentStatus)) {
        throw StoreException(
          'This order needs attention. Open My orders for its latest status.',
        );
      }
      await api.finishCheckout();
      ref.read(storeCartProvider.notifier).clear();
      refreshCommerce(ref);
      if (mounted) {
        Navigator.pop(context, order);
      }
    } catch (e) {
      if (mounted) showStoreError(context, e);
      ref.invalidate(myOrdersProvider);
      ref.invalidate(catalogProvider);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lines = ref.watch(storeCartProvider);
    final subtotal = lines.fold(0.0, (sum, l) => sum + l.total);
    return PopScope(
      canPop: !_busy,
      child: Theme(
        data: storeTheme(),
        child: Scaffold(
          appBar: AppBar(title: const Text('Checkout')),
          body: DataView(
            value: ref.watch(storeConfigProvider),
            onRetry: () => ref.invalidate(storeConfigProvider),
            builder: (config) => Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (_loadingProfile)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: LinearProgressIndicator(),
                    ),
                  if (_profileError != null) ...[
                    Text(
                      _profileError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    TextButton(
                      onPressed: _restoreAddress,
                      child: const Text('Reload saved address'),
                    ),
                  ],
                  const Text(
                    'Where should we deliver?',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your store will prepare your order and assign a delivery person. Track every update in My orders.',
                    style: TextStyle(color: Colors.black54, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _name,
                    enabled: !_busy,
                    decoration: const InputDecoration(labelText: 'Full name'),
                    textCapitalization: TextCapitalization.words,
                    validator: (s) =>
                        (s?.trim().length ?? 0) < 2 ? 'Enter your name' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phone,
                    readOnly: true,
                    enabled: !_busy,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Mobile number',
                    ),
                    validator: (s) =>
                        !RegExp(r'^\+?[0-9]{10,15}$').hasMatch(s?.trim() ?? '')
                        ? 'Enter a valid mobile number'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _address,
                    enabled: !_busy,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Full address, landmark and pincode',
                    ),
                    validator: (s) => (s?.trim().length ?? 0) < 12
                        ? 'Enter your complete delivery address'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _notes,
                    enabled: !_busy,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      labelText: 'Delivery instructions (optional)',
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Payment',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  const CodPaymentCard(),
                  const SizedBox(height: 22),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          for (final l in lines)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${l.product.name} \u00d7 ${l.quantity}',
                                    ),
                                  ),
                                  Text(money(l.total)),
                                ],
                              ),
                            ),
                          const Divider(),
                          Row(
                            children: [
                              const Expanded(child: Text('Delivery')),
                              Text(money(amount(config['delivery_charge']))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Total',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                              Text(
                                money(
                                  subtotal + amount(config['delivery_charge']),
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 24,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed:
                        _busy ||
                            _loadingProfile ||
                            _profileError != null ||
                            lines.isEmpty
                        ? null
                        : _place,
                    child: _busy
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('Place COD order'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OrderPlacedScreen extends StatelessWidget {
  final StoreOrder order;
  const OrderPlacedScreen({super.key, required this.order});
  @override
  Widget build(BuildContext context) => Theme(
    data: storeTheme(),
    child: Scaffold(
      appBar: AppBar(title: const Text('Order confirmed')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Image.asset(
              'assets/images/delivery-handover.png',
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 24),
          const Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(0xFFE4EEDF),
                child: Icon(Icons.check, color: storeGreen),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your order is placed.',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    color: storeGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Your store will prepare your groceries and assign a delivery person. We will keep you updated as your order moves.',
            style: TextStyle(height: 1.6, color: Colors.black54),
          ),
          const SizedBox(height: 18),
          Text(
            order.id,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          CodPaymentCard(order: order),
          const SizedBox(height: 20),
          const Text(
            'Delivering to',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
          ),
          const SizedBox(height: 8),
          Text(
            '${order.data['customer_name']}\n${order.data['delivery_address']}',
            style: const TextStyle(height: 1.6),
          ),
          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                onPressed: () => Navigator.pushReplacement<bool, bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderTrackingScreen(orderId: order.id),
                  ),
                ),
                icon: const Icon(Icons.local_shipping_outlined),
                label: const Text('Track my order'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Continue shopping'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});
  @override
  ConsumerState<OrderTrackingScreen> createState() => _TrackingState();
}

class _TrackingState extends ConsumerState<OrderTrackingScreen> {
  late Future<Map<String, dynamic>> _future;
  Timer? _poll;
  bool _paying = false;
  @override
  void initState() {
    super.initState();
    _future = _fetch();
    _poll = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!_paying) _reload();
    });
  }

  Future<Map<String, dynamic>> _fetch() =>
      ref.read(storeApiProvider).order(widget.orderId);
  void _reload() {
    if (mounted) {
      setState(() {
        _future = _fetch();
      });
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _cancelCheckout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this order?'),
        content: const Text(
          'Your order will be cancelled and no payment is due. You can place a new order whenever you are ready.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep order'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _paying = true);
    try {
      await ref.read(storeApiProvider).cancelCheckout(widget.orderId);
      refreshCommerce(ref);
    } catch (e) {
      if (mounted) showStoreError(context, e);
    } finally {
      if (mounted) {
        setState(() => _paying = false);
        _reload();
      }
    }
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: storeTheme(),
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Track your order'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return EmptyPanel(
              icon: Icons.wifi_off,
              title: 'Could not refresh order',
              message: snapshot.error.toString(),
              action: 'Retry',
              onAction: _reload,
            );
          }
          if (!snapshot.hasData) {
            return const SingleChildScrollView(
              child: AppSkeleton(kind: SkeletonKind.detail),
            );
          }
          final order = StoreOrder(
            Map<String, dynamic>.from(snapshot.data!['order']),
          );
          final person = order.data['assigned_to_details'] as Map?;
          final eta = DateTime.tryParse(
            '${order.data['estimated_delivery_at']}',
          )?.toLocal();
          return RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _future;
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  order.id,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusChip(order.status),
                    StatusChip(order.paymentStatus),
                  ],
                ),
                const SizedBox(height: 20),
                OrderJourney(order: order),
                const SizedBox(height: 16),
                CodPaymentCard(order: order),
                const SizedBox(height: 16),
                if (order.canCancel)
                  OutlinedButton.icon(
                    onPressed: _paying ? null : _cancelCheckout,
                    icon: const Icon(Icons.close),
                    label: const Text('Cancel order before preparation'),
                  ),
                if (order.status == 'Delivery Attempted')
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Your delivery needs attention. Your store will contact you to arrange another attempt.',
                    ),
                  ),
                if (order.status == 'Cancelled')
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Reason: ${order.data['cancellation_reason'] ?? 'Order cancelled'}',
                    ),
                  ),
                if (person != null)
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.delivery_dining,
                        color: storeGreen,
                      ),
                      title: Text('${person['name']}'),
                      subtitle: Text('Delivery contact: ${person['phone']}'),
                    ),
                  ),
                if (eta != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Estimated arrival: ${eta.day}/${eta.month}, ${eta.hour.toString().padLeft(2, '0')}:${eta.minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                if ('${order.data['delivery_note'] ?? ''}'.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      order.data['delivery_note'],
                      style: const TextStyle(color: storeGreen),
                    ),
                  ),
                const SizedBox(height: 20),
                const Text(
                  'Delivery progress',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                for (final event in order.events)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.check_circle_outline,
                      color: storeGreen,
                    ),
                    title: Text('${event['status']}'),
                    subtitle: Text(
                      '${event['note']}\n${DateTime.tryParse('${event['created_at']}')?.toLocal().toString().split('.').first ?? ''}',
                    ),
                  ),
                const Divider(height: 32),
                const Text(
                  'Order details',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                ),
                for (final item in order.items)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${item['english_name']}'),
                    subtitle: Text(
                      '${item['unit']} \u00d7 ${item['quantity']}',
                    ),
                    trailing: Text(money(amount(item['total_price']))),
                  ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Total'),
                  trailing: Text(
                    money(order.total),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  '${order.data['customer_name']}\n${order.data['customer_phone']}\n${order.data['delivery_address']}',
                  style: const TextStyle(height: 1.6),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Status updates refresh automatically every 15 seconds.',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}
