import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'customer_account.dart';
import 'loading.dart';
import 'models.dart';
import 'paged_feed.dart';
import 'state.dart';
import 'widgets.dart';

// =============================================================================
// SEARCH SCREEN (Full dedicated search experience)
// =============================================================================
class SearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;
  final String? initialCategory;
  final String? initialBrand;
  final double? maxPrice;
  final String? initialCollection;

  const SearchScreen({
    super.key,
    this.initialQuery,
    this.initialCategory,
    this.initialBrand,
    this.maxPrice,
    this.initialCollection,
  });

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with CatalogActions<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  bool _submitted = false;
  String _currentQuery = '';
  List<String> _recentSearches = [];
  List<StoreProduct> _suggestions = [];
  bool _loadingSuggestions = false;

  // Filter and Sort states
  String _activeQuickChip = 'All';
  String? _collection;
  String? _suggestionError;
  int _queryGeneration = 0;
  List<String> _matchingCategories = [], _matchingBrands = [];
  String? _selectedCategory;
  String? _selectedBrand;
  double? _minPrice;
  double? _maxPrice;
  bool _inStockOnly = false;
  String _sortBy = 'recommended'; // Product-name order unless an explicit price sort is selected.

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _selectedCategory = widget.initialCategory;
    _selectedBrand = widget.initialBrand;
    _maxPrice = widget.maxPrice;
    _collection = widget.initialCollection;
    _controller.text = widget.initialQuery ?? '';
    _currentQuery = _controller.text.trim();
    _submitted =
        _currentQuery.isNotEmpty ||
        _selectedCategory != null ||
        _selectedBrand != null ||
        _maxPrice != null ||
        _collection != null;
    if (_collection != null || _maxPrice != null) _activeQuickChip = 'Custom';
    // Auto-focus keyboard if not pre-submitted
    if (!_submitted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _queryGeneration++;
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    try {
      final saved = await ref
          .read(storeApiProvider)
          .storage
          .read(key: 'agaram_recent_searches');
      if (saved != null) {
        final decoded = jsonDecode(saved);
        if (mounted && decoded is List) {
          setState(() {
            _recentSearches = decoded.map((e) => e.toString()).toList();
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _saveRecentSearch(String query) async {
    final clean = query.trim();
    if (!mounted || clean.isEmpty) return;
    final updated = [
      clean,
      ..._recentSearches.where((s) => s.toLowerCase() != clean.toLowerCase()),
    ].take(10).toList();
    setState(() => _recentSearches = updated);
    try {
      await ref
          .read(storeApiProvider)
          .storage
          .write(key: 'agaram_recent_searches', value: jsonEncode(updated));
    } catch (_) {}
  }

  Future<void> _clearRecentSearches() async {
    setState(() => _recentSearches = []);
    try {
      await ref
          .read(storeApiProvider)
          .storage
          .delete(key: 'agaram_recent_searches');
    } catch (_) {}
  }

  void _onQueryChanged(String query) {
    final clean = query.trim();
    _debounce?.cancel();
    final generation = ++_queryGeneration;
    setState(() {
      _currentQuery = clean;
      _suggestions = [];
      _suggestionError = null;
      _matchingCategories = [];
      _matchingBrands = [];
      _loadingSuggestions = clean.isNotEmpty;
      _submitted = false;
    });
    if (clean.isEmpty) return;
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final page = await ref
            .read(storeApiProvider)
            .productPage(
              search: clean,
              category: _selectedCategory ?? 'All',
              brand: _selectedBrand,
            );
        if (!mounted || generation != _queryGeneration || _submitted) return;
        final categories = List<String>.from(page.metadata['categories'] ?? []);
        final brands = List<String>.from(page.metadata['brands'] ?? []);
        setState(() {
          _suggestions = page.items.take(8).toList();
          _matchingCategories = categories
              .where((v) => v.toLowerCase().contains(clean.toLowerCase()))
              .toList();
          _matchingBrands = brands
              .where((v) => v.toLowerCase().contains(clean.toLowerCase()))
              .toList();
          _loadingSuggestions = false;
        });
      } catch (e) {
        if (mounted && generation == _queryGeneration && !_submitted) {
          setState(() {
            _suggestionError = e.toString();
            _loadingSuggestions = false;
          });
        }
      }
    });
  }

  void _submitSearch(String query) {
    final clean = query.trim();
    _debounce?.cancel();
    _queryGeneration++;
    _controller.text = clean;
    _saveRecentSearch(clean);
    _focusNode.unfocus();
    setState(() {
      _currentQuery = clean;
      _submitted = true;
      _suggestions = [];
      _loadingSuggestions = false;
      _suggestionError = null;
    });
  }

  void _applyQuickChip(String chip) {
    setState(() {
      _activeQuickChip = chip;
      _minPrice = null;
      _maxPrice = null;
      _inStockOnly = false;
      _collection = null;
      if (chip == 'Under ₹100') _maxPrice = 99.99;
      if (chip == 'Under ₹200') _maxPrice = 199.99;
      if (chip == 'In Stock') _inStockOnly = true;
    });
  }

  void _openFilterSheet(BuildContext context) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ProductFilterSheet(
        currentCategory: _selectedCategory,
        currentBrand: _selectedBrand,
        currentMinPrice: _minPrice,
        currentMaxPrice: _maxPrice,
        inStockOnly: _inStockOnly,
        currentSortBy: _sortBy,
      ),
    );

    if (mounted && result != null) {
      setState(() {
        _activeQuickChip = 'Custom';
        if (result['clear_collection'] == true) _collection = null;
        _selectedCategory = result['category'];
        _selectedBrand = result['brand'];
        _minPrice = result['min_price'];
        _maxPrice = result['max_price'];
        _inStockOnly = result['in_stock_only'] ?? false;
        _sortBy = result['sort_by'] ?? 'recommended';
      });
    }
  }

  void _openSortDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sort Products By',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: storeInk,
                ),
              ),
              const SizedBox(height: 12),
              _sortTile('Product name', 'recommended'),
              _sortTile('Price: Low to High', 'price_asc'),
              _sortTile('Price: High to Low', 'price_desc'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sortTile(String title, String value) {
    final selected = _sortBy == value;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          color: selected ? storeForestGreen : storeInk,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded, color: storeForestGreen)
          : null,
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: storeCream,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar with large input
            _buildSearchHeader(),

            // Content Area
            Expanded(
              child: _submitted
                  ? _buildSearchResults()
                  : _currentQuery.isNotEmpty
                  ? _buildSuggestionsList()
                  : _buildRecentAndPopularSearches(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: storeInk,
              size: 22,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFF6F8F6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: storeBorder),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: _onQueryChanged,
                onSubmitted: _submitSearch,
                textInputAction: TextInputAction.search,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: storeInk,
                ),
                decoration: InputDecoration(
                  hintText: 'Search groceries, brands or essentials',
                  hintStyle: const TextStyle(color: storeGrey, fontSize: 13.5),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: storeForestGreen,
                    size: 22,
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_controller.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(
                            Icons.clear_rounded,
                            color: storeGrey,
                            size: 20,
                          ),
                          onPressed: () {
                            _controller.clear();
                            _onQueryChanged('');
                          },
                        ),
                    ],
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAndPopularSearches() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        // Recent searches
        if (_recentSearches.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Searches',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: storeInk,
                ),
              ),
              TextButton(
                onPressed: _clearRecentSearches,
                child: const Text(
                  'Clear All',
                  style: TextStyle(color: storeGrey, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recentSearches.map((s) {
              return ActionChip(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: storeBorder),
                ),
                avatar: const Icon(
                  Icons.history_rounded,
                  size: 16,
                  color: storeGrey,
                ),
                label: Text(
                  s,
                  style: const TextStyle(fontSize: 12.5, color: storeInk),
                ),
                onPressed: () => _submitSearch(s),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],

        const Text(
          'Explore groceries',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: storeInk,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Search product names, brands or categories in our live catalog.',
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BrowseGroceriesScreen()),
          ),
          icon: const Icon(Icons.grid_view_rounded),
          label: const Text('Browse groceries'),
        ),
      ],
    );
  }

  Widget _buildSuggestionsList() {
    if (_loadingSuggestions) {
      return const SingleChildScrollView(child: AppSkeleton(count: 5));
    }

    if (_suggestionError != null) {
      return EmptyPanel(
        icon: Icons.cloud_off_outlined,
        title: 'Could not search groceries',
        message: _suggestionError!,
        action: 'Retry',
        onAction: () => _onQueryChanged(_controller.text),
      );
    }
    if (_suggestions.isEmpty &&
        _matchingCategories.isEmpty &&
        _matchingBrands.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded, size: 48, color: storeGrey),
              const SizedBox(height: 12),
              Text(
                'Search for "$_currentQuery"',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => _submitSearch(_currentQuery),
                child: const Text('Search Now'),
              ),
            ],
          ),
        ),
      );
    }

    final categories = {
      ..._matchingCategories,
      ..._suggestions.map((p) => p.category).where((c) => c.isNotEmpty),
    }.toList();
    final brands = {
      ..._matchingBrands,
      ..._suggestions.map((p) => p.brand).where((b) => b.isNotEmpty),
    }.toList();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Exact Search Row
        ListTile(
          leading: const Icon(Icons.search_rounded, color: storeForestGreen),
          title: Text(
            'Search for "$_currentQuery"',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: storeForestGreen,
            ),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: storeForestGreen,
          ),
          onTap: () => _submitSearch(_currentQuery),
        ),
        const Divider(color: storeBorder, height: 1),

        // Products group
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            'PRODUCTS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: storeGrey,
              letterSpacing: 1.1,
            ),
          ),
        ),
        for (final p in _suggestions.take(5))
          ListTile(
            leading: SizedBox(
              width: 38,
              height: 38,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ProductPhoto(
                  p.imageUrl,
                  height: 38,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            title: Text(
              p.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
            subtitle: Text(
              '₹${p.price.toStringAsFixed(2)} · ${p.unit}',
              style: const TextStyle(color: storeGrey, fontSize: 11),
            ),
            trailing: const Icon(
              Icons.north_west_rounded,
              size: 14,
              color: storeGrey,
            ),
            onTap: () => _submitSearch(p.name),
          ),

        // Categories group
        if (categories.isNotEmpty) ...[
          const Divider(color: storeBorder, height: 1),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'CATEGORIES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: storeGrey,
                letterSpacing: 1.1,
              ),
            ),
          ),
          for (final cat in categories.take(3))
            ListTile(
              leading: const Icon(
                Icons.grid_view_rounded,
                color: storeForestGreen,
                size: 20,
              ),
              title: Text(
                cat,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: storeGrey,
              ),
              onTap: () {
                setState(() {
                  _selectedCategory = cat;
                  _submitSearch('');
                });
              },
            ),
        ],

        // Brands group
        if (brands.isNotEmpty) ...[
          const Divider(color: storeBorder, height: 1),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'BRANDS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: storeGrey,
                letterSpacing: 1.1,
              ),
            ),
          ),
          for (final b in brands.take(3))
            ListTile(
              leading: const Icon(
                Icons.branding_watermark_outlined,
                color: storeForestGreen,
                size: 20,
              ),
              title: Text(
                b,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: storeGrey,
              ),
              onTap: () {
                setState(() {
                  _selectedBrand = b;
                  _submitSearch('');
                });
              },
            ),
        ],
      ],
    );
  }

  Widget _buildSearchResults() {
    final api = ref.watch(storeApiProvider);
    final cart = ref.watch(storeCartProvider);
    final cartQuantityMap = {for (final l in cart) l.product.id: l.quantity};
    final wishlistIds =
        ref.watch(wishlistIdsProvider).asData?.value ?? <String>[];

    final catalog =
        ref.watch(catalogBrowseProvider).asData?.value ?? <String, dynamic>{};
    final collectionLabel =
        catalogEntries(catalog, 'collections')
                .where((entry) => entry['key'] == _collection)
                .firstOrNull?['label']
            as String?;
    String? backendOrdering;
    if (_sortBy == 'price_asc') backendOrdering = 'price';
    if (_sortBy == 'price_desc') backendOrdering = '-price';

    return Column(
      children: [
        // Sort & Filter Toolbar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _currentQuery.isNotEmpty
                      ? '"$_currentQuery"'
                      : (collectionLabel ??
                            _selectedBrand ??
                            _selectedCategory ??
                            'Products'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: storeInk,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: storeBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                ),
                icon: const Icon(
                  Icons.swap_vert_rounded,
                  size: 18,
                  color: storeForestGreen,
                ),
                label: const Text(
                  'Sort',
                  style: TextStyle(color: storeInk, fontSize: 12),
                ),
                onPressed: _openSortDialog,
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: storeMint,
                  foregroundColor: storeForestGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
                icon: const Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: storeForestGreen,
                ),
                label: const Text(
                  'Filter',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
                onPressed: () => _openFilterSheet(context),
              ),
            ],
          ),
        ),

        // Quick Filter Chips
        Container(
          height: 44,
          color: Colors.white,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children: [
              for (final chip in [
                'All',
                'Under ₹100',
                'Under ₹200',
                'In Stock',
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    showCheckmark: false,
                    label: Text(chip),
                    labelStyle: TextStyle(
                      fontSize: 11.5,
                      fontWeight: _activeQuickChip == chip
                          ? FontWeight.w800
                          : FontWeight.w500,
                      color: _activeQuickChip == chip ? Colors.white : storeInk,
                    ),
                    selected: _activeQuickChip == chip,
                    selectedColor: storeForestGreen,
                    backgroundColor: const Color(0xFFF2F4F2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: _activeQuickChip == chip
                            ? storeForestGreen
                            : storeBorder,
                      ),
                    ),
                    onSelected: (_) => _applyQuickChip(chip),
                  ),
                ),
            ],
          ),
        ),
        const Divider(color: storeBorder, height: 1),

        // Product Results Grid
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return PagedFeed<StoreProduct>(
                queryKey: (
                  _currentQuery,
                  _selectedCategory,
                  _selectedBrand,
                  _minPrice,
                  _maxPrice,
                  _inStockOnly,
                  backendOrdering,
                  _collection,
                ),
                changes: api.feedChanges,
                load: (cursor) => api.productPage(
                  cursor: cursor,
                  search: _currentQuery,
                  category: _selectedCategory ?? 'All',
                  brand: _selectedBrand,
                  minPrice: _minPrice,
                  maxPrice: _maxPrice,
                  inStock: _inStockOnly,
                  ordering: backendOrdering,
                  collection: _collection,
                ),
                identity: (p) => p.id,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: constraints.maxWidth > 700 ? 4 : 2,
                  mainAxisExtent: 278,
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
                    onAddToCart: () => _addProduct(product),
                    onIncrement: () => _addProduct(product),
                    onDecrement: () => ref
                        .read(storeCartProvider.notifier)
                        .change(product.id, -1),
                    onToggleWishlist: () => _toggleProduct(product),
                  );
                },
                emptyTitle: 'No products found',
                emptyMessage: 'Try another product name, brand or explore our grocery categories.',
              );
            },
          ),
        ),
      ],
    );
  }
}

List<Map<String, dynamic>> catalogEntries(
  Map<String, dynamic> data,
  String key,
) => List<Map<String, dynamic>>.from(data[key] ?? const []);

mixin CatalogActions<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool _accountBusy = false;
  Future<void> _addProduct(StoreProduct product) async {
    if (_accountBusy) return;
    _accountBusy = true;
    try {
      if (await ensureCustomerAccount(context, ref) && mounted) {
        ref.read(storeCartProvider.notifier).add(product);
      }
    } catch (e) {
      if (mounted) showStoreError(context, e);
    } finally {
      _accountBusy = false;
    }
  }

  Future<void> _toggleProduct(StoreProduct product) async {
    if (_accountBusy) return;
    _accountBusy = true;
    try {
      if (!await ensureCustomerAccount(context, ref) || !mounted) return;
      final saved = await ref.read(wishlistIdsProvider.future);
      await ref
          .read(storeApiProvider)
          .setWishlist(product.id, !saved.contains(product.id));
      ref.invalidate(wishlistIdsProvider);
      ref.invalidate(wishlistProvider);
    } catch (e) {
      if (mounted) showStoreError(context, e);
    } finally {
      _accountBusy = false;
    }
  }

  void _showProduct(StoreProduct product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ProductPhoto(product.imageUrl, height: 210, fit: BoxFit.contain),
              const SizedBox(height: 16),
              Text(
                product.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (product.brand.isNotEmpty) Text(product.brand),
              Text(
                '${money(product.price)} · ${product.unit}',
                style: const TextStyle(fontSize: 18, color: storeForestGreen),
              ),
              const SizedBox(height: 12),
              if (product.description.isNotEmpty) Text(product.description),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: product.available
                    ? () => _addProduct(product)
                    : null,
                child: Text(product.available ? 'Add to cart' : 'Out of stock'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Existing green/cream two-panel browse, populated entirely by catalog facets.
class BrowseGroceriesScreen extends ConsumerStatefulWidget {
  const BrowseGroceriesScreen({super.key});
  @override
  ConsumerState<BrowseGroceriesScreen> createState() => _BrowseGroceriesState();
}

class _BrowseGroceriesState extends ConsumerState<BrowseGroceriesScreen>
    with CatalogActions<BrowseGroceriesScreen> {
  String? _selectedCategory;
  void _open({String? category, String? brand, String? collection}) =>
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SearchScreen(
            initialCategory: category,
            initialBrand: brand,
            initialCollection: collection,
          ),
        ),
      );
  void _refresh() {
    ref.read(storeApiProvider).clearPublicCache();
    ref.invalidate(catalogBrowseProvider);
    ref.read(storeApiProvider).feedChanges.value++;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: storeCream,
    appBar: AppBar(
      title: const Text(
        'Browse Groceries',
        style: TextStyle(
          color: storeForestGreen,
          fontWeight: FontWeight.w900,
          fontSize: 18,
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Refresh catalog',
          onPressed: _refresh,
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          tooltip: 'Search groceries',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SearchScreen()),
          ),
          icon: const Icon(Icons.search_rounded),
        ),
      ],
    ),
    body: DataView(
      value: ref.watch(catalogBrowseProvider),
      onRetry: _refresh,
      builder: (data) {
        final categories = catalogEntries(data, 'categories');
        final brands = catalogEntries(data, 'brands');
        final collections = catalogEntries(data, 'collections');
        if (categories.isEmpty) {
          return EmptyPanel(
            icon: Icons.shopping_basket_outlined,
            title: 'Groceries are on their way',
            message: 'Published groceries will appear here when the store adds them.',
            action: 'Refresh',
            onAction: _refresh,
          );
        }
        return Column(
          children: [
            if (collections.isNotEmpty)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: collections.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => ActionChip(
                      avatar: const Icon(
                        Icons.shopping_bag_outlined,
                        size: 17,
                        color: storeForestGreen,
                      ),
                      backgroundColor: storeMint,
                      label: Text('${collections[i]['label']}'),
                      onPressed: () => _open(collection: collections[i]['key']),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: MediaQuery.sizeOf(context).width < 350 ? 88 : 104,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(right: BorderSide(color: storeBorder)),
                    ),
                    child: ListView(
                      children: [
                        _rail('All groceries', null),
                        for (final category in categories)
                          _rail('${category['name']}', '${category['name']}'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _selectedCategory == null
                        ? ListView(
                            padding: const EdgeInsets.all(12),
                            children: [
                              const Text(
                                'Shop by category',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: storeInk,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _facetGrid(categories, false),
                              if (brands.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                const Text(
                                  'Shop by brand',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _facetGrid(brands, true),
                              ],
                            ],
                          )
                        : _categoryProducts(),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _rail(String label, String? category) => InkWell(
    onTap: () => setState(() => _selectedCategory = category),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
      decoration: BoxDecoration(
        color: _selectedCategory == category ? storeMint : Colors.white,
        border: Border(
          left: BorderSide(
            width: 4,
            color: _selectedCategory == category
                ? storeForestGreen
                : Colors.transparent,
          ),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.shopping_basket_outlined,
            color: storeForestGreen,
            size: 22,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );

  Widget _facetGrid(List<Map<String, dynamic>> entries, bool brand) =>
      LayoutBuilder(
        builder: (context, constraints) => GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: entries.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: constraints.maxWidth < 180 ? 1 : 2,
            mainAxisExtent:
                160 + 44 * (MediaQuery.textScalerOf(context).scale(1) - 1),
            crossAxisSpacing: 8,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (_, i) {
            final entry = entries[i];
            return Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _open(
                  category: brand ? null : entry['name'],
                  brand: brand ? entry['name'] : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Expanded(
                        child: '${entry['image_url'] ?? ''}'.isEmpty
                            ? const Icon(
                                Icons.shopping_basket_outlined,
                                size: 36,
                                color: storeForestGreen,
                              )
                            : ProductPhoto(
                                '${entry['image_url']}',
                                height: 84,
                                fit: BoxFit.contain,
                              ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${entry['name']}',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${entry['count']} products',
                        style: const TextStyle(fontSize: 10, color: storeGrey),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );

  Widget _categoryProducts() {
    final api = ref.watch(storeApiProvider);
    final cart = ref.watch(storeCartProvider);
    final saved = ref.watch(wishlistIdsProvider).asData?.value ?? <String>[];
    return PagedFeed<StoreProduct>(
      queryKey: ('browseCategory', _selectedCategory),
      changes: api.feedChanges,
      beforeRefresh: api.clearPublicCache,
      load: (cursor) =>
          api.productPage(cursor: cursor, category: _selectedCategory!),
      identity: (p) => p.id,
      header: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          _selectedCategory!,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      padding: const EdgeInsets.all(10),
      itemBuilder: (_, product, _) => SizedBox(
        height: 290,
        child: ProductCard(
          product: product,
          cartQuantity: cart
              .where((l) => l.product.id == product.id)
              .fold(0, (sum, l) => sum + l.quantity),
          isWishlisted: saved.contains(product.id),
          onTap: () => _showProduct(product),
          onAddToCart: () => _addProduct(product),
          onIncrement: () => _addProduct(product),
          onDecrement: () =>
              ref.read(storeCartProvider.notifier).change(product.id, -1),
          onToggleWishlist: () => _toggleProduct(product),
        ),
      ),
      emptyTitle: 'No groceries available',
      emptyMessage: 'Refresh or choose another category.',
    );
  }
}

class ProductFilterSheet extends ConsumerStatefulWidget {
  final String? currentCategory;
  final String? currentBrand;
  final double? currentMinPrice;
  final double? currentMaxPrice;
  final bool inStockOnly;
  final String currentSortBy;

  const ProductFilterSheet({
    super.key,
    this.currentCategory,
    this.currentBrand,
    this.currentMinPrice,
    this.currentMaxPrice,
    this.inStockOnly = false,
    this.currentSortBy = 'recommended',
  });

  @override
  ConsumerState<ProductFilterSheet> createState() => _ProductFilterSheetState();
}

class _ProductFilterSheetState extends ConsumerState<ProductFilterSheet> {
  bool _clearCollection = false;
  late String? _category;
  late String? _brand;
  late double? _minPrice;
  late double? _maxPrice;
  late bool _inStock;
  late String _sortBy;

  @override
  void initState() {
    super.initState();
    _category = widget.currentCategory;
    _brand = widget.currentBrand;
    _minPrice = widget.currentMinPrice;
    _maxPrice = widget.currentMaxPrice;
    _inStock = widget.inStockOnly;
    _sortBy = widget.currentSortBy;
  }

  void _clearAll() {
    setState(() {
      _clearCollection = true;
      _category = null;
      _brand = null;
      _minPrice = null;
      _maxPrice = null;
      _inStock = false;
      _sortBy = 'recommended';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter Products',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: storeInk,
                  ),
                ),
                TextButton(
                  onPressed: _clearAll,
                  child: const Text('Reset', style: TextStyle(color: storeRed)),
                ),
              ],
            ),
          ),
          const Divider(color: storeBorder, height: 1),

          // Filter Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Price Range Section
                const Text('PRICE RANGE', style: _sectionHeadingStyle),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _priceChip('All Prices', null, null),
                    _priceChip('Under ₹50', null, 49.99),
                    _priceChip('₹50 – ₹100', 50, 100),
                    _priceChip('₹100 – ₹200', 100, 200),
                    _priceChip('₹200 – ₹500', 200, 500),
                    _priceChip('Above ₹500', 500.01, null),
                  ],
                ),
                const SizedBox(height: 24),

                // Availability
                DataView(
                  value: ref.watch(catalogBrowseProvider),
                  onRetry: () => ref.invalidate(catalogBrowseProvider),
                  builder: (catalog) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CATEGORY', style: _sectionHeadingStyle),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('All categories'),
                            selected: _category == null,
                            onSelected: (_) => setState(() => _category = null),
                          ),
                          for (final item in catalogEntries(
                            catalog,
                            'categories',
                          ))
                            ChoiceChip(
                              label: Text('${item['name']}'),
                              selected: _category == item['name'],
                              onSelected: (_) =>
                                  setState(() => _category = item['name']),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (catalogEntries(catalog, 'brands').isNotEmpty) ...[
                        const Text('BRAND', style: _sectionHeadingStyle),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('All brands'),
                              selected: _brand == null,
                              onSelected: (_) => setState(() => _brand = null),
                            ),
                            for (final item in catalogEntries(
                              catalog,
                              'brands',
                            ))
                              ChoiceChip(
                                label: Text('${item['name']}'),
                                selected: _brand == item['name'],
                                onSelected: (_) =>
                                    setState(() => _brand = item['name']),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
                const Text('AVAILABILITY', style: _sectionHeadingStyle),
                const SizedBox(height: 10),
                Material(
                  color: Colors.white,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: storeForestGreen,
                    title: const Text(
                      'In Stock Only',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    value: _inStock,
                    onChanged: (v) => setState(() => _inStock = v),
                  ),
                ),
              ],
            ),
          ),

          // Sticky Bottom Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: storeBorder)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearAll,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: storeBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Clear All',
                      style: TextStyle(
                        color: storeInk,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context, <String, dynamic>{
                        'category': _category,
                        'brand': _brand,
                        'min_price': _minPrice,
                        'max_price': _maxPrice,
                        'in_stock_only': _inStock,
                        'sort_by': _sortBy,
                        'clear_collection': _clearCollection,
                      });
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: storeForestGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
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

  static const _sectionHeadingStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    color: storeGrey,
    letterSpacing: 1.1,
  );

  Widget _priceChip(String label, double? min, double? max) {
    final selected = _minPrice == min && _maxPrice == max;
    return ChoiceChip(
      showCheckmark: false,
      label: Text(label),
      selected: selected,
      selectedColor: storeForestGreen,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        color: selected ? Colors.white : storeInk,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? storeForestGreen : storeBorder),
      ),
      onSelected: (_) {
        setState(() {
          _minPrice = min;
          _maxPrice = max;
        });
      },
    );
  }
}
