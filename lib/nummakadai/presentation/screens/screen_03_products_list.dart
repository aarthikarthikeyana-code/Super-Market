import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/numma_theme.dart';
import '../../data/models/numma_models.dart';
import '../providers/numma_providers.dart';
import '../widgets/numma_common_widgets.dart';

class Numma03ProductsListScreen extends ConsumerStatefulWidget {
  final VoidCallback onAddProduct;
  final Function(NummaProduct) onSelectProduct;

  const Numma03ProductsListScreen({
    super.key,
    required this.onAddProduct,
    required this.onSelectProduct,
  });

  @override
  ConsumerState<Numma03ProductsListScreen> createState() => _Numma03ProductsListScreenState();
}

class _Numma03ProductsListScreenState extends ConsumerState<Numma03ProductsListScreen> {
  String _searchQuery = '';
  int _selectedFilterIndex = 0; // 0: All, 1: In Stock, 2: Low Stock, 3: Out of Stock

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(nummaProductsProvider);

    final filteredProducts = products.where((p) {
      // Search
      final matchesQuery = p.nameTamil.contains(_searchQuery) ||
          p.nameEnglish.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.sku.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesQuery) return false;

      // Filter
      if (_selectedFilterIndex == 1) return p.stockStatus == StockStatus.inStock;
      if (_selectedFilterIndex == 2) return p.stockStatus == StockStatus.lowStock;
      if (_selectedFilterIndex == 3) return p.stockStatus == StockStatus.outOfStock;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: NummaColors.creamBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Products',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: NummaColors.textMain,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: widget.onAddProduct,
                    icon: const Icon(Icons.add, size: 16, color: Colors.white),
                    label: Text(
                      'Add Product',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NummaColors.primaryGreen,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),

            // Search Box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: NummaSearchField(
                hint: 'Search products by name, category...',
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),

            // Filter Chips Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All (432)',
                    isSelected: _selectedFilterIndex == 0,
                    onTap: () => setState(() => _selectedFilterIndex = 0),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'In Stock (320)',
                    isSelected: _selectedFilterIndex == 1,
                    onTap: () => setState(() => _selectedFilterIndex = 1),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Low Stock (90)',
                    isSelected: _selectedFilterIndex == 2,
                    onTap: () => setState(() => _selectedFilterIndex = 2),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Out of Stock (22)',
                    isSelected: _selectedFilterIndex == 3,
                    onTap: () => setState(() => _selectedFilterIndex = 3),
                  ),
                ],
              ),
            ),

            // Products List
            Expanded(
              child: filteredProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 48, color: NummaColors.textMuted),
                          const SizedBox(height: 8),
                          Text(
                            'No products found',
                            style: GoogleFonts.plusJakartaSans(color: NummaColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: filteredProducts.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final p = filteredProducts[index];
                        return _ProductCardTile(
                          product: p,
                          onTap: () => widget.onSelectProduct(p),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? NummaColors.primaryGreen : NummaColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? NummaColors.primaryGreen : NummaColors.border,
            width: 1,
          ),
          boxShadow: isSelected ? NummaColors.cardShadow : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : NummaColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ProductCardTile extends StatelessWidget {
  final NummaProduct product;
  final VoidCallback onTap;

  const _ProductCardTile({
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: NummaColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: NummaColors.border, width: 1),
          boxShadow: NummaColors.cardShadow,
        ),
        child: Row(
          children: [
            // Product Image (real grocery produce)
            NummaProductImage(
              imageUrl: product.imageUrl,
              size: 54,
              radius: BorderRadius.circular(12),
            ),
            const SizedBox(width: 12),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Tamil Name prominently displayed
                      Text(
                        product.nameTamil,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: NummaColors.textMain,
                        ),
                      ),
                      Text(
                        'Stock: ${product.stockQuantity}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: NummaColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${product.weight} | SKU: ${product.sku}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: NummaColors.textMuted,
                        ),
                      ),
                      NummaStatusBadge.stock(product.stockStatus),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${product.price.toInt()}',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: NummaColors.primaryGreen,
                        ),
                      ),
                      const Icon(Icons.more_vert_rounded, size: 18, color: NummaColors.textMuted),
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
