import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'api.dart';
import 'customer_account.dart';
import 'login_screen.dart';
import 'models.dart';
import 'search_browse.dart';
import 'state.dart';
import 'widgets.dart';
import 'paged_feed.dart';
import 'loading.dart';
import 'delivery_tracking.dart';
import 'order_invoice.dart';
import 'customer_orders.dart';

class StorefrontScreen extends ConsumerStatefulWidget {
  const StorefrontScreen({super.key});
  @override
  ConsumerState<StorefrontScreen> createState() => _StorefrontState();
}

class _StorefrontState extends ConsumerState<StorefrontScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _tab = 0;
  bool _showCart = false;
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
      if (_tab == 3) {
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
    final profile = ref.watch(customerProfileProvider).asData?.value;

    return Theme(
      data: storeTheme(),
      child: Scaffold(
        key: _scaffoldKey,
        appBar: _showCart || _tab != 0
            ? AgaramAppBar(
                showBackButton: _showCart,
                onBackPressed: () => setState(() => _showCart = false),
                onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
                onCartPressed: () => setState(() => _showCart = !_showCart),
                cartCount: count,
              )
            : HomeTopHeader(
                onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
                onCartPressed: () => setState(() => _showCart = !_showCart),
                cartCount: count,
              ),
        drawer: AgaramDrawer(
          customerProfile: profile,
          onLoginPressed: () async {
            // Close drawer first, then push login screen
            _scaffoldKey.currentState?.closeDrawer();
            await Future.delayed(const Duration(milliseconds: 250));
            if (!context.mounted) return;
            final loggedIn = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const CustomerLoginScreen()),
            );
            if (loggedIn == true && mounted) {
              ref.invalidate(customerProfileProvider);
              ref.invalidate(customerAccountProvider);
            }
          },
          onSelectCategories: () => setState(() {
            _showCart = false;
            _tab = 1;
          }),
          onSelectOffers: () => setState(() {
            _showCart = false;
            _tab = 2;
          }),
          onSelectWishlist: () {
            setState(() => _showCart = false);
            _showWishlistModal();
          },
          onSelectOrders: () => setState(() {
            _showCart = false;
            _tab = 3;
            ref.invalidate(myOrdersProvider);
          }),
          onSelectAccount: () => setState(() {
            _showCart = false;
            _tab = 4;
          }),
          onSelectHelp: _showHelpModal,
          onSelectContact: _showContactModal,
          onAdminLogin: () => context.push('/admin'),
          onDeliveryLogin: () => context.push('/delivery'),
          onLogout: () async {
            final cartNotifier = ref.read(storeCartProvider.notifier);
            cartNotifier.clear();
            await cartNotifier.flush();
            await ref.read(storeApiProvider).logoutCustomer();
            ref.invalidate(customerAccountProvider);
            ref.invalidate(customerProfileProvider);
            ref.invalidate(myOrdersProvider);
            ref.invalidate(wishlistProvider);
            ref.invalidate(wishlistIdsProvider);
            ref.invalidate(storeCartProvider);
          },
        ),
        body: _showCart
            ? _cartView(cart)
            : switch (_tab) {
                0 => _homeView(),
                1 => _categoriesView(),
                2 => _offersView(),
                3 => _ordersView(),
                _ => _accountView(),
              },
        bottomNavigationBar: _showCart
            ? null
            : CustomerFloatingBottomNav(
                selectedIndex: _tab,
                cartCount: cart.fold(0, (s, l) => s + l.quantity),
                onCartPressed: () => setState(() => _showCart = true),
                onItemSelected: (i) {
                  setState(() {
                    _tab = i;
                    _showCart = false;
                  });
                  if (i == 3) ref.invalidate(myOrdersProvider);
                },
              ),
      ),
    );
  }

  // SCREEN 1: HOME VIEW (Completely redesigned to match reference landing page)
  // ===========================================================================
  Widget _homeView() => LayoutBuilder(
    builder: (context, constraints) {
      final api = ref.watch(storeApiProvider);
      final cart = ref.watch(storeCartProvider);
      final cartQuantityMap = {for (final l in cart) l.product.id: l.quantity};
      final browse =
          ref.watch(catalogBrowseProvider).asData?.value ?? <String, dynamic>{};
      final browseCategories = catalogEntries(browse, 'categories');
      final collections = catalogEntries(browse, 'collections');
      final wishlistIds =
          ref.watch(wishlistIdsProvider).asData?.value ?? <String>[];

      final isFiltered = _search.isNotEmpty || _category != 'All';
      final curated = ref.watch(homeCuratedSectionsProvider).asData?.value;
      final rawTopSales = (browse['top_sales'] as List? ?? []);
      final rawNewLaunch = (browse['new_launch'] as List? ?? []);

      final topSales = curated?['top_sales'] ?? [
        for (final j in rawTopSales)
          StoreProduct.fromJson(Map<String, dynamic>.from(j))
      ];
      final newLaunch = curated?['new_launch'] ?? [
        for (final j in rawNewLaunch)
          StoreProduct.fromJson(Map<String, dynamic>.from(j))
      ];

      return Container(
        color: const Color(0xFFF4F9F5),
        child: Stack(
          children: [
            if (!isFiltered)
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(14, 8, 14, cart.isEmpty ? 24 : 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Search Bar
                    HomeSearchBar(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SearchScreen(),
                          ),
                        );
                      },
                      onFilterTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BrowseGroceriesScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    // 2. Hero 3-Banner Carousel
                    HomeHeroCarousel(
                      onShopNow: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const SearchScreen(initialCategory: 'All'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 3. Arched Category Grid
                    HomeCategoryGrid(
                      categories: browseCategories,
                      onSelectCategory: (name) => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SearchScreen(initialCategory: name),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 4. Promo Offer Banners
                    CollectionChipRow(
                      collections: collections,
                      onSelectCollection: (key) => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SearchScreen(initialCollection: key),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // 5. TOP SALES SECTION (Strictly up to 10 products, no numbers in UI)
                    HomeSectionHeader(
                      title: 'Top Sales',
                      subtitle: 'அதிகம் விற்பனையானவை',
                      action: 'See All >',
                      onAction: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SearchScreen(
                            initialCollection: 'top_sales',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCuratedGrid(
                      topSales,
                      constraints,
                      cartQuantityMap,
                      wishlistIds,
                    ),
                    const SizedBox(height: 24),

                    // 6. NEW LAUNCH SECTION (Strictly up to 10 products, no numbers in UI)
                    HomeSectionHeader(
                      title: 'New Launch',
                      subtitle: 'புதிய வரவுகள்',
                      action: 'See All >',
                      onAction: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SearchScreen(
                            initialCollection: 'new_launch',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCuratedGrid(
                      newLaunch,
                      constraints,
                      cartQuantityMap,
                      wishlistIds,
                    ),
                    const SizedBox(height: 26),

                    // 7. Trust Strip
                    const HomeTrustStrip(),
                  ],
                ),
              )
            else
              PagedFeed<StoreProduct>(
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
                    if (!_categories.contains(_category) &&
                        !homeGroceryCategories.any(
                          (item) => item['query'] == _category,
                        )) {
                      _category = 'All';
                    }
                  });
                },
                header: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HomeSearchBar(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SearchScreen(),
                            ),
                          );
                        },
                        onFilterTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BrowseGroceriesScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      HomeSectionHeader(
                        title: _category == 'All' ? 'Search results' : _category,
                        action: 'Clear',
                        onAction: () => setState(() {
                          _search = '';
                          _category = 'All';
                          _searchInput.clear();
                        }),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
                padding: EdgeInsets.fromLTRB(14, 0, 14, cart.isEmpty ? 24 : 96),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: constraints.maxWidth > 700 ? 4 : 2,
                  mainAxisExtent: groceryProductCardExtent(
                    context,
                    (constraints.maxWidth -
                            28 -
                            (constraints.maxWidth > 700 ? 3 : 1) * 10) /
                        (constraints.maxWidth > 700 ? 4 : 2),
                  ),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (_, product, _) {
                  final quantity = cartQuantityMap[product.id] ?? 0;
                  final wishlisted = wishlistIds.contains(product.id);
                  return PremiumProductCard(
                    product: product,
                    cartQuantity: quantity,
                    isWishlisted: wishlisted,
                    onTap: () => _showProduct(product),
                    onAddToCart: () => _addToCart(product),
                    onIncrement: () =>
                        ref.read(storeCartProvider.notifier).add(product),
                    onDecrement: () => ref
                        .read(storeCartProvider.notifier)
                        .change(product.id, -1),
                    onToggleWishlist: () => _toggleWishlist(product),
                  );
                },
                emptyTitle: 'No matching products',
                emptyMessage:
                    'Try searching another grocery name or select another category.',
              ),

            // Floating View Cart Bar if cart has items
            if (cart.isNotEmpty)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: _floatingCartBar(cart),
              ),
          ],
        ),
      );
    },
  );

  Widget _buildCuratedGrid(
    List<StoreProduct> list,
    BoxConstraints constraints,
    Map<String, int> cartQuantityMap,
    List<String> wishlistIds,
  ) {
    if (list.isEmpty) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: storePrimaryGreen,
          ),
        ),
      );
    }
    final crossAxisCount = constraints.maxWidth > 700 ? 4 : 2;
    final cardWidth = (constraints.maxWidth -
            28 -
            (crossAxisCount - 1) * 10) /
        crossAxisCount;
    final extent = groceryProductCardExtent(context, cardWidth);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: list.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisExtent: extent,
        crossAxisSpacing: 10,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (_, index) {
        final product = list[index];
        final quantity = cartQuantityMap[product.id] ?? 0;
        final wishlisted = wishlistIds.contains(product.id);
        return PremiumProductCard(
          product: product,
          cartQuantity: quantity,
          isWishlisted: wishlisted,
          onTap: () => _showProduct(product),
          onAddToCart: () => _addToCart(product),
          onIncrement: () =>
              ref.read(storeCartProvider.notifier).add(product),
          onDecrement: () => ref
              .read(storeCartProvider.notifier)
              .change(product.id, -1),
          onToggleWishlist: () => _toggleWishlist(product),
        );
      },
    );
  }

  Widget _floatingCartBar(List<StoreCartLine> cart) => InkWell(
    onTap: () => setState(() => _showCart = true),
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
              '${cart.fold(0, (s, l) => s + l.quantity)} items · ${money(cart.fold<double>(0, (s, l) => s + l.total))}',
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

  Widget _categoriesView() {
    final browse =
        ref.watch(catalogBrowseProvider).asData?.value ?? <String, dynamic>{};
    final allCats = [
      ('All', Icons.grid_view_rounded, storeMint),
      for (final entry in homeGroceryCategories)
        (
          groceryCategoryQuery(entry, catalogEntries(browse, 'categories')),
          Icons.shopping_basket_outlined,
          storeMint,
        ),
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SearchBarWidget(
            controller: _searchInput,
            onChanged: (text) {
              _searchDebounce?.cancel();
              _searchDebounce = Timer(const Duration(milliseconds: 350), () {
                if (mounted) setState(() => _search = text.trim());
              });
            },
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: allCats.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final cat = allCats[i];
              final isSelected = _category == cat.$1;
              return ChoiceChip(
                showCheckmark: false,
                avatar: i == 0
                    ? Icon(
                        cat.$2,
                        size: 16,
                        color: isSelected ? Colors.white : storePrimaryGreen,
                      )
                    : ClipOval(
                        child: Image.asset(
                          homeGroceryCategories[i - 1]['asset']!,
                          width: 24,
                          height: 24,
                          fit: BoxFit.cover,
                        ),
                      ),
                label: Text(
                  i == 0
                      ? 'All Groceries'
                      : homeGroceryCategories[i - 1]['tamil']!,
                ),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : storeInk,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 12.5,
                ),
                selectedColor: storeCtaGreen,
                backgroundColor: isSelected
                    ? storeCtaGreen
                    : Colors.white.withOpacity(0.85),
                selected: isSelected,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? storeCtaGreen : Colors.white,
                    width: 1.2,
                  ),
                ),
                onSelected: (_) => setState(() => _category = cat.$1),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final api = ref.watch(storeApiProvider);
              final cart = ref.watch(storeCartProvider);
              final cartQuantityMap = {
                for (final l in cart) l.product.id: l.quantity,
              };
              final wishlistIds =
                  ref.watch(wishlistIdsProvider).asData?.value ?? <String>[];

              return PagedFeed<StoreProduct>(
                queryKey: ('category_view', _search, _category),
                changes: api.feedChanges,
                load: (cursor) => api.productPage(
                  cursor: cursor,
                  search: _search,
                  category: _category,
                ),
                identity: (p) => p.id,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: constraints.maxWidth > 700 ? 4 : 2,
                  mainAxisExtent: groceryProductCardExtent(
                    context,
                    (constraints.maxWidth -
                            32 -
                            (constraints.maxWidth > 700 ? 3 : 1) * 12) /
                        (constraints.maxWidth > 700 ? 4 : 2),
                  ),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (_, product, _) {
                  final quantity = cartQuantityMap[product.id] ?? 0;
                  final wishlisted = wishlistIds.contains(product.id);
                  return ProductCard(
                    product: product,
                    cartQuantity: quantity,
                    isWishlisted: wishlisted,
                    onTap: () => _showProduct(product),
                    onAddToCart: () => _addToCart(product),
                    onIncrement: () =>
                        ref.read(storeCartProvider.notifier).add(product),
                    onDecrement: () => ref
                        .read(storeCartProvider.notifier)
                        .change(product.id, -1),
                    onToggleWishlist: () => _toggleWishlist(product),
                  );
                },
                emptyTitle: 'No items in this category',
                emptyMessage: 'Select another category to view products.',
              );
            },
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // SCREEN 3: OFFERS VIEW
  // ===========================================================================
  Widget _offersView() => LayoutBuilder(
    builder: (context, constraints) {
      final api = ref.watch(storeApiProvider);
      final cart = ref.watch(storeCartProvider);
      final quantities = {
        for (final line in cart) line.product.id: line.quantity,
      };
      final saved = ref.watch(wishlistIdsProvider).asData?.value ?? <String>[];
      final columns = constraints.maxWidth > 700 ? 4 : 2;
      return PagedFeed<StoreProduct>(
        queryKey: 'customer-offers',
        changes: api.feedChanges,
        beforeRefresh: api.clearPublicCache,
        load: (cursor) => api.productPage(cursor: cursor, collection: 'offers'),
        identity: (product) => product.id,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisExtent: groceryProductCardExtent(
            context,
            (constraints.maxWidth - 32 - (columns - 1) * 12) / columns,
          ),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (_, product, _) => ProductCard(
          product: product,
          cartQuantity: quantities[product.id] ?? 0,
          isWishlisted: saved.contains(product.id),
          onTap: () => _showProduct(product),
          onAddToCart: () => _addToCart(product),
          onIncrement: () => ref.read(storeCartProvider.notifier).add(product),
          onDecrement: () =>
              ref.read(storeCartProvider.notifier).change(product.id, -1),
          onToggleWishlist: () => _toggleWishlist(product),
        ),
        emptyTitle: 'No active offers right now',
        emptyMessage: 'Products with store offers will appear here.',
      );
    },
  );

  // ===========================================================================
  // SCREEN 4: MY ORDERS VIEW
  // ===========================================================================
  Widget _ordersView() => DataView(
    retainOnRefresh: false,
    value: ref.watch(customerAccountProvider),
    onRetry: () => ref.invalidate(customerAccountProvider),
    builder: (account) => account == null
        ? EmptyPanel(
            icon: Icons.receipt_long_outlined,
            title: 'Your orders, in one place',
            message: 'Enter your mobile number to see your order history and track deliveries.',
            action: 'Sign in to Orders',
            onAction: () => ensureCustomerAccount(context, ref),
          )
        : _signedInOrdersList(),
  );

  Widget _signedInOrdersList() {
    final phone = ref.watch(customerAccountProvider).asData?.value?['phone'];

    return CustomerOrdersList(
      key: ValueKey(('customer-orders', phone)),
      accountKey: phone,
      onOpen: (order) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(orderId: order.id),
        ),
      ),
    );
  }

  // ===========================================================================
  // SCREEN 5: ACCOUNT VIEW (Matching Reference Screen 4)
  // ===========================================================================
  Widget _accountView() => DataView(
    retainOnRefresh: false,
    value: ref.watch(customerAccountProvider),
    onRetry: () => ref.invalidate(customerAccountProvider),
    builder: (account) {
      if (account == null) {
        return EmptyPanel(
          icon: Icons.person_outline_rounded,
          title: 'Welcome to Agaram',
          message: 'Sign in with your mobile number to view saved addresses, wishlist and recent orders.',
          action: 'Sign in / Register',
          onAction: () => ensureCustomerAccount(context, ref),
        );
      }

      final profile =
          ref.watch(customerProfileProvider).asData?.value ??
          <String, dynamic>{};
      final name = (profile['name'] as String? ?? '').trim();
      final phone = (profile['phone'] as String? ?? account['phone'] ?? '')
          .trim();
      final wishlistCount =
          (ref.watch(wishlistIdsProvider).asData?.value ?? []).length;

      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          // 1. Profile Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF087532).withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    color: storeGlassMint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: storePrimaryGreen,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isNotEmpty ? name : 'My Account',
                        style: const TextStyle(
                          color: storeInk,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        phone,
                        style: const TextStyle(
                          color: storeGrey,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: _editProfileModal,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: storeGlassMint,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: storePrimaryGreen,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Edit Profile',
                          style: TextStyle(
                            color: storeDeepGreen,
                            fontWeight: FontWeight.w800,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 2. Four Shortcut Cards (2x2 Grid)
          Row(
            children: [
              Expanded(
                child: _shortcutCard(
                  icon: Icons.location_on_rounded,
                  iconColor: storeForestGreen,
                  title: 'Saved Addresses',
                  onTap: _showSavedAddressesModal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _shortcutCard(
                  icon: Icons.favorite_rounded,
                  iconColor: storeRed,
                  title: 'Wishlist ($wishlistCount)',
                  onTap: _showWishlistModal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _shortcutCard(
                  icon: Icons.percent_rounded,
                  iconColor: storeOrange,
                  title: 'My Offers (5)',
                  onTap: () => setState(() => _tab = 2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _shortcutCard(
                  icon: Icons.settings_outlined,
                  iconColor: storeForestGreen,
                  title: 'Settings',
                  onTap: _showSettingsModal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 3. My Recent Orders Section
          SectionHeader(
            title: 'My Recent Orders',
            action: 'View All Orders >',
            onAction: () => setState(() => _tab = 3),
          ),
          const SizedBox(height: 12),
          _recentOrdersPreview(),
          const SizedBox(height: 22),

          // 4. Need Help? Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: storeBorder),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: storeMint,
                  child: const Icon(
                    Icons.support_agent_rounded,
                    color: storeForestGreen,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Need Help?',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: storeInk,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Get support for your orders, payments and more.',
                        style: TextStyle(fontSize: 11.5, color: storeGrey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _showContactModal,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: storeForestGreen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                  child: const Text(
                    'Contact Us >',
                    style: TextStyle(
                      color: storeForestGreen,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );

  Widget _shortcutCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: storeBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: iconColor.withOpacity(0.12),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: storeInk,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recentOrdersPreview() {
    final ordersAsync = ref.watch(myOrdersProvider);
    return ordersAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: LinearProgressIndicator(),
      ),
      error: (_, _) => const Text('Could not load recent orders'),
      data: (orders) {
        if (orders.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: storeBorder),
            ),
            child: const Center(
              child: Text(
                'No orders placed yet.',
                style: TextStyle(color: storeGrey, fontSize: 13),
              ),
            ),
          );
        }
        final displayList = orders.take(3).toList();
        return Column(
          children: [
            for (final o in displayList)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OrderCard(
                  order: o,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderTrackingScreen(orderId: o.id),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // SCREEN 6: MY CART VIEW (Matching Reference Screen 3)
  // ===========================================================================
  Widget _cartView(List<CartLine> lines) {
    if (lines.isEmpty) {
      return EmptyCartWidget(
        onStartShopping: () => setState(() {
          _showCart = false;
          _tab = 0;
        }),
      );
    }

    final total = lines.fold(0.0, (sum, l) => sum + l.total);
    final count = lines.fold(0, (sum, l) => sum + l.quantity);
    final config = ref.watch(storeConfigProvider);
    final deliveryCharge = config.hasValue
        ? amount(config.value!['delivery_charge'])
        : null;
    final discount = lines.fold(
      0.0,
      (sum, l) => sum + (l.product.mrp - l.product.price) * l.quantity,
    );

    return Column(
      children: [
        // Cart content
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              Text(
                'My Cart ($count items)',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: storeInk,
                ),
              ),
              const SizedBox(height: 12),

              // Item rows
              for (final l in lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Product photo container
                        Container(
                          width: 68,
                          height: 68,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FDFB),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: ProductPhoto(
                            l.product.imageUrl,
                            height: 56,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Title & pricing
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.product.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  color: storeInk,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l.product.unit,
                                style: const TextStyle(
                                  color: storeGrey,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '₹${l.product.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14.5,
                                      color: storeInk,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  if (l.product.discountPercent > 0)
                                    Text(
                                      '₹${l.product.mrp.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        color: storeGrey,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Quantity Selector & Delete icon
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            GestureDetector(
                              onTap: () => ref
                                  .read(storeCartProvider.notifier)
                                  .remove(l.product.id),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.delete_outline_rounded,
                                  size: 19,
                                  color: storeLightGrey,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            QuantitySelector(
                              quantity: l.quantity,
                              onIncrement: () => ref
                                  .read(storeCartProvider.notifier)
                                  .add(l.product),
                              onDecrement: () => ref
                                  .read(storeCartProvider.notifier)
                                  .change(l.product.id, -1),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 10),

              // Free delivery banner
              if (deliveryCharge == 0) const FreeDeliveryBanner(),
              const SizedBox(height: 12),

              DataView(
                value: config,
                onRetry: () => ref.invalidate(storeConfigProvider),
                builder: (data) => PriceDetailsCard(
                  subtotal: total,
                  deliveryCharge: amount(data['delivery_charge']),
                  discount: discount,
                  itemsCount: count,
                ),
              ),
              const SizedBox(height: 20),

              // You May Also Like Section
              _youMayAlsoLikeSection(),
              const SizedBox(height: 20),
            ],
          ),
        ),

        // Proceed to Checkout CTA Bar
        Container(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            MediaQuery.of(context).padding.bottom + 12,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(top: BorderSide(color: storeBorder)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
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
                  ref.read(storeCartProvider.notifier).reconcile(products);
                } catch (e) {
                  if (mounted) showStoreError(context, e);
                  return;
                }
                if (!mounted || ref.read(storeCartProvider).isEmpty) return;

                final placed = await Navigator.push<StoreOrder>(
                  context,
                  MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                );
                if (placed != null && mounted) {
                  setState(() {
                    _showCart = false;
                    _tab = 3;
                  });
                  final browse = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderPlacedScreen(order: placed),
                    ),
                  );
                  if (browse == true && mounted) {
                    setState(() {
                      _showCart = false;
                      _tab = 0;
                    });
                  }
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: storeCtaGreen,
                elevation: 3,
                shadowColor: storePrimaryGreen.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Proceed to Checkout',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _youMayAlsoLikeSection() {
    final catalogAsync = ref.watch(catalogProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'You May Also Like',
          action: 'See All >',
          onAction: () => setState(() {
            _showCart = false;
            _tab = 0;
          }),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 130,
          child: catalogAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const SizedBox(),
            data: (products) {
              final recommendations = products.take(6).toList();
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recommendations.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final p = recommendations[i];
                  return Container(
                    width: 108,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: storeBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Center(
                            child: ProductPhoto(
                              p.imageUrl,
                              height: 60,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: storeInk,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₹${p.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: storeInk,
                              ),
                            ),
                            InkWell(
                              onTap: () => _addToCart(p),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: storeMint,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  size: 16,
                                  color: storeForestGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // MODALS & DIALOGS
  // ===========================================================================
  void _showWishlistModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: storeCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'My Wishlist',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: storeInk,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Consumer(
                  builder: (context, ref, _) {
                    final wishlistAsync = ref.watch(wishlistProvider);
                    return wishlistAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(child: Text(err.toString())),
                      data: (products) {
                        if (products.isEmpty) {
                          return const Center(
                            child: Text(
                              'Your wishlist is empty.',
                              style: TextStyle(color: storeGrey),
                            ),
                          );
                        }
                        return GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisExtent: groceryProductCardExtent(
                                  context,
                                  (MediaQuery.sizeOf(context).width - 44) / 2,
                                ),
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                          itemCount: products.length,
                          itemBuilder: (_, i) {
                            final p = products[i];
                            return ProductCard(
                              product: p,
                              isWishlisted: true,
                              onTap: () {
                                Navigator.pop(ctx);
                                _showProduct(p);
                              },
                              onAddToCart: () => _addToCart(p),
                              onToggleWishlist: () => _toggleWishlist(p),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSavedAddressesModal() {
    final profile =
        ref.read(customerProfileProvider).asData?.value ?? <String, dynamic>{};
    final address = (profile['address'] as String? ?? '').trim();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Saved Addresses',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: storeInk,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: storeBorder),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.home_outlined,
                    color: storeForestGreen,
                    size: 24,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      address.isNotEmpty
                          ? address
                          : 'No delivery address saved yet.',
                      style: const TextStyle(height: 1.4, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _editProfileModal();
                },
                child: const Text('Update Delivery Address'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editProfileModal() {
    final profile =
        ref.read(customerProfileProvider).asData?.value ?? <String, dynamic>{};
    final nameCtrl = TextEditingController(
      text: profile['name'] as String? ?? '',
    );
    final addrCtrl = TextEditingController(
      text: profile['address'] as String? ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: storeInk,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Customer Name'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: addrCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Delivery Address'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  await ref.read(storeApiProvider).saveCustomerProfile({
                    'name': nameCtrl.text.trim(),
                    'address': addrCtrl.text.trim(),
                  });
                  ref.invalidate(customerProfileProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Save Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Agaram Help & Support'),
        content: const Text(
          'Need assistance with your grocery order or delivery?\n\n'
          '• Orders arrive directly from Agaram Supermarket.\n'
          '• Payment is collected via Cash on Delivery (COD).\n'
          '• For changes or cancellations, visit the My Orders tab.',
          style: TextStyle(height: 1.5, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showContactModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Contact Store'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Agaram Supermarket',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text('Customer Helpline: +91 63852 57541'),
            Text('Timings: 7:00 AM – 9:30 PM'),
            Text('Location: Chennai, Tamil Nadu'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.language_rounded,
                color: storeForestGreen,
              ),
              title: const Text('Language / மொழி'),
              subtitle: const Text('English & தமிழ்'),
            ),
            ListTile(
              leading: const Icon(
                Icons.notifications_outlined,
                color: storeForestGreen,
              ),
              title: const Text('Notifications'),
              subtitle: const Text('Order updates & offers enabled'),
            ),
            ListTile(
              leading: const Icon(
                Icons.info_outline_rounded,
                color: storeForestGreen,
              ),
              title: const Text('App Version'),
              subtitle: const Text('Agaram Supermarket 1.0 (Production)'),
            ),
          ],
        ),
      ),
    );
  }

  void _showProduct(StoreProduct p) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product photo in rounded container
            Container(
              height: 220,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FDFB),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: ProductPhoto(p.imageUrl, height: 200, fit: BoxFit.contain),
            ),
            const SizedBox(height: 18),
            if (p.brand.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: storeGlassMint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  p.brand,
                  style: const TextStyle(
                    color: storePrimaryGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                  ),
                ),
              ),
            Text(
              p.name,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: storeInk,
              ),
            ),
            if (p.tamilName.isNotEmpty && p.tamilName != p.name)
              Text(
                p.tamilName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: storeGrey,
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '₹${p.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: storeInk,
                  ),
                ),
                const SizedBox(width: 8),
                if (p.discountPercent > 0)
                  Text(
                    '₹${p.mrp.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: storeGrey,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                const SizedBox(width: 8),
                if (p.discountPercent > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: storeGlassMint,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${p.discountPercent}% OFF',
                      style: const TextStyle(
                        fontSize: 11,
                        color: storePrimaryGreen,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: storeBorder),
                  ),
                  child: Text(
                    p.unit,
                    style: const TextStyle(
                      color: storeInk,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (p.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(color: storeBorder),
              const SizedBox(height: 8),
              const Text(
                'About this product',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                  color: storeInk,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                p.description,
                style: const TextStyle(
                  height: 1.5,
                  fontSize: 13,
                  color: storeGrey,
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: p.available
                      ? storeCtaGreen
                      : const Color(0xFFE0E5E2),
                  elevation: p.available ? 2 : 0,
                  shadowColor: storePrimaryGreen.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: p.available
                    ? () async {
                        final added = await _addToCart(p);
                        if (added && ctx.mounted) Navigator.pop(ctx);
                      }
                    : null,
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
                label: Text(
                  p.available ? 'Add to Cart' : 'Out of stock',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
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
      _notes = TextEditingController();
  final _deliveryAddress = DeliveryAddressData();
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
      _deliveryAddress.restore(profile);
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
    _deliveryAddress.dispose();
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
        'address': _deliveryAddress.formatted,
        'address_details': _deliveryAddress.value,
        'delivery_instructions': _notes.text.trim(),
      });
      if (!mounted) return;
      ref.invalidate(customerProfileProvider);
      ref.invalidate(customerAccountProvider);
      final response = await api.checkout({
        'customer_name': _name.text.trim(),
        'customer_phone': _phone.text.trim(),
        'delivery_address': _deliveryAddress.formatted,
        'address_details': _deliveryAddress.value,
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
                    'Delivery address',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Confirm your address and delivery pin before placing the order.',
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
                  StructuredAddressFields(
                    address: _deliveryAddress,
                    enabled: !_busy && !_loadingProfile,
                  ),
                  TextFormField(
                    controller: _notes,
                    enabled: !_busy,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      labelText: 'Note for delivery employee (optional)',
                      helperText: 'Gate access, floor, or a request to call on arrival. Leave blank if not needed.',
                      helperMaxLines: 3,
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
      backgroundColor: storeCream,
      appBar: AppBar(
        title: const Text(
          'Order Placed',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 12),
          // Success check circle with soft glow
          Center(
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: storeGlassMint,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: storePrimaryGreen.withOpacity(0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: storePrimaryGreen,
                size: 52,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'Order Placed\nSuccessfully!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: storeInk,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'Your grocery order has been placed.\nWe will deliver it fresh to your doorstep.',
              textAlign: TextAlign.center,
              style: TextStyle(color: storeGrey, fontSize: 13.5, height: 1.4),
            ),
          ),
          const SizedBox(height: 28),

          // Order details card (matching reference screen 15)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF087532).withOpacity(0.04),
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
                      'Order ID',
                      style: TextStyle(
                        fontSize: 13,
                        color: storeGrey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      order.id,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: storeInk,
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: storeBorder, height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Payment Mode',
                      style: TextStyle(
                        fontSize: 13,
                        color: storeGrey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Cash on Delivery (COD)',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: storeDeepGreen,
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: storeBorder, height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: 14,
                        color: storeInk,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      money(order.total),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: storePrimaryGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Delivery Address Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 1.2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: storeGlassMint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: storePrimaryGreen,
                    size: 20,
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
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: storeInk,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${order.data['delivery_address'] ?? ''}',
                        style: const TextStyle(
                          color: storeGrey,
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
                style: FilledButton.styleFrom(
                  backgroundColor: storeCtaGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                icon: const Icon(Icons.local_shipping_outlined, size: 20),
                label: const Text(
                  'View / Track Order',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.pop(context, true),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: storeBorder, width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                child: const Text(
                  'Continue Shopping',
                  style: TextStyle(
                    color: storeInk,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
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

  Future<void> _refreshCode() async {
    if (_paying) return;
    setState(() => _paying = true);
    try {
      await ref.read(storeApiProvider).refreshDeliveryCode(widget.orderId);
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
        title: const Text('Track my order'),
        actions: [
          IconButton(
            onPressed: _reload,
            tooltip: 'Refresh order',
            icon: const Icon(Icons.refresh),
          ),
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
          final confirmation = Map<String, dynamic>.from(
            snapshot.data!['delivery_confirmation'] ?? {},
          );
          final person = order.data['assigned_to_details'] as Map?;
          final eta = DateTime.tryParse(
            '${order.data['estimated_delivery_at']}',
          )?.toLocal();
          final closed = ['Delivered', 'Cancelled'].contains(order.status);
          final headline =
              <String, String>{
                'New': 'Your order is placed',
                'Preparing': 'We are preparing your groceries',
                'Packed': 'Your groceries are packed',
                'Out for Delivery': 'Your delivery is on the way',
                'Delivery Attempted': 'We need to arrange another attempt',
                'Delivered': 'Your groceries are delivered',
                'Cancelled': 'This order was cancelled',
              }[order.status] ??
              order.status;
          final message =
              <String, String>{
                'New':
                    'The store will accept your order and start preparing it.',
                'Preparing': 'Your items are being checked and packed.',
                'Packed': person == null
                    ? 'The store is assigning a delivery employee.'
                    : 'Your employee will pick up the packed items.',
                'Out for Delivery': 'Keep your phone available. Share your delivery code only after receiving your items.',
                'Delivery Attempted':
                    '${order.data['delivery_note'] ?? 'The store will contact you about the next attempt.'}',
                'Delivered':
                    'Thank you. Your delivery and payment record are below.',
                'Cancelled':
                    '${order.data['cancellation_reason'] ?? 'Contact the store if you need help.'}',
              }[order.status] ??
              'Pull down for the latest update.';
          return RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _future;
            },
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        order.shortId,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    StatusChip(order.status),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  headline,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),
                OrderJourney(order: order),
                const SizedBox(height: 14),
                if (!closed)
                  Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(14),
                      leading: const Icon(Icons.schedule, color: storeGreen),
                      title: Text(
                        eta == null
                            ? 'Arrival time not set yet'
                            : eta.isBefore(DateTime.now())
                            ? 'Your delivery is taking longer'
                            : 'Expected arrival',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        eta == null
                            ? 'Your store will update the estimated time here.'
                            : '${eta.day}/${eta.month}, ${eta.hour.toString().padLeft(2, '0')}:${eta.minute.toString().padLeft(2, '0')}${eta.isBefore(DateTime.now()) ? ' was the last estimate. Check the latest update below.' : ' (estimated)'}',
                        style: const TextStyle(height: 1.6),
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                if (!closed)
                  Card(
                    color: const Color(0xFFEAF7F0),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.verified_user_outlined,
                                color: storeGreen,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Your delivery code',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (confirmation['code'] != null)
                            SelectableText(
                              '${confirmation['code']}',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 8,
                                color: storeGreen,
                              ),
                            )
                          else
                            FilledButton(
                              onPressed: _paying ? null : _refreshCode,
                              child: const Text('Get delivery code'),
                            ),
                          const SizedBox(height: 10),
                          Text(
                            order.paymentStatus == 'cod'
                                ? 'Receive your groceries and pay ${money(order.total)} in cash. Then tell this code to the delivery employee.'
                                : 'Tell this code to the employee after receiving all items. This order is already paid.',
                            style: const TextStyle(fontSize: 13, height: 1.6),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Keep it private until the handover. Your employee cannot see it in their app.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(14),
                    leading: const Icon(
                      Icons.payments_outlined,
                      color: storeGreen,
                    ),
                    title: Text(
                      order.status == 'Cancelled'
                          ? 'No payment due'
                          : order.paymentStatus == 'collected'
                          ? 'Cash paid to your delivery employee'
                          : order.paymentStatus == 'cod'
                          ? 'Cash to pay at delivery'
                          : 'Payment recorded',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    trailing: Text(
                      order.status == 'Cancelled'
                          ? money(0)
                          : money(order.total),
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (person != null && order.status != 'Cancelled')
                  Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFEAF7F0),
                        child: Icon(Icons.delivery_dining, color: storeGreen),
                      ),
                      title: Text(
                        '${person['name']}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: const Text('Your assigned delivery employee'),
                      trailing: IconButton(
                        tooltip: 'Call delivery employee',
                        onPressed: () => openDeliveryLink(
                          context,
                          Uri(scheme: 'tel', path: '${person['phone']}'),
                        ),
                        icon: const Icon(
                          Icons.call_outlined,
                          color: storeGreen,
                        ),
                      ),
                    ),
                  ),
                if (order.status == 'Out for Delivery') ...[
                  const SizedBox(height: 14),
                  DeliveryTrackingCard(orderId: order.id),
                ],
                if ('${order.data['delivery_note'] ?? ''}'.trim().isNotEmpty &&
                    order.status != 'Delivery Attempted')
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.chat_bubble_outline,
                          color: storeGreen,
                        ),
                        title: const Text('Update from your store'),
                        subtitle: Text(
                          '${order.data['delivery_note']}',
                          style: const TextStyle(height: 1.6),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                Card(
                  child: ExpansionTile(
                    title: const Text(
                      'Delivery address',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    leading: const Icon(
                      Icons.location_on_outlined,
                      color: storeGreen,
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SelectableText(
                          '${order.data['customer_name']}\n${order.data['delivery_address']}',
                          style: const TextStyle(height: 1.7),
                        ),
                      ),
                      if ('${order.data['delivery_instructions'] ?? ''}'
                          .isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Your note: ${order.data['delivery_instructions']}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ),
                      TextButton.icon(
                        onPressed: () => openDeliveryLink(
                          context,
                          directionsForOrder(order),
                        ),
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('View delivery location'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ExpansionTile(
                    title: Text(
                      'Items & bill (${order.items.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    leading: const Icon(
                      Icons.shopping_bag_outlined,
                      color: storeGreen,
                    ),
                    childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      for (final item in order.items)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            productLabel(item),
                            style: const TextStyle(fontSize: 13),
                          ),
                          subtitle: Text(
                            '${item['unit']} x ${item['quantity']}',
                          ),
                          trailing: Text(money(amount(item['total_price']))),
                        ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Delivery charge'),
                        trailing: Text(
                          money(amount(order.data['delivery_charge'])),
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Order total',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        trailing: Text(
                          money(order.total),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFF16A05D),
                              width: 1.5,
                            ),
                            backgroundColor: const Color(0xFFE9F8EF),
                            foregroundColor: const Color(0xFF0D6F47),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(
                            Icons.receipt_long_rounded,
                            size: 20,
                          ),
                          label: const Text(
                            'View & Download Bill Receipt',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                            ),
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderInvoiceScreen(order: order),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ExpansionTile(
                    title: const Text(
                      'Order updates',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    leading: const Icon(Icons.history, color: storeGreen),
                    children: [
                      for (final event in order.events)
                        ListTile(
                          leading: const Icon(
                            Icons.check_circle_outline,
                            size: 18,
                            color: storeGreen,
                          ),
                          title: Text(
                            '${event['status']}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          subtitle: Text(
                            '${event['note']}\n${DateTime.tryParse('${event['created_at']}')?.toLocal().toString().split('.').first ?? ''}',
                            style: const TextStyle(fontSize: 12, height: 1.5),
                          ),
                        ),
                    ],
                  ),
                ),
                if (order.canCancel)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: OutlinedButton.icon(
                      onPressed: _paying ? null : _cancelCheckout,
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancel before preparation'),
                    ),
                  ),
                const SizedBox(height: 20),
                const Text(
                  'Updates refresh every 15 seconds.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}
