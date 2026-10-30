import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/sample_data.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_widgets.dart';
import '../widgets/veg_illustrations.dart';

class Screen04CategoryListing extends StatefulWidget {
  final String selectedCategory;
  final String selectedSubcategory;
  final Function(String) onSelectCategory;
  final Function(String) onSelectSubcategory;
  final Function(Product) onProductTap;
  final Function(Product, {String? unit, double? price, int qty}) onAddToCart;
  final Function(Product, {String? unit, double? price, int qty}) onBuyNow;
  final VoidCallback onBack;
  final VoidCallback onOpenCart;
  final int cartCount;

  const Screen04CategoryListing({
    super.key,
    required this.selectedCategory,
    required this.selectedSubcategory,
    required this.onSelectCategory,
    required this.onSelectSubcategory,
    required this.onProductTap,
    required this.onAddToCart,
    required this.onBuyNow,
    required this.onBack,
    required this.onOpenCart,
    this.cartCount = 0,
  });

  @override
  State<Screen04CategoryListing> createState() => _Screen04CategoryListingState();
}

class _Screen04CategoryListingState extends State<Screen04CategoryListing> {
  // Map of productId to selected weight in list view
  final Map<String, String> _selectedWeights = {};

  String _getEffectiveWeight(Product p) {
    return _selectedWeights[p.id] ??
        (p.availableWeights.isNotEmpty
            ? p.availableWeights.firstWhere((w) => w == '1 Kg', orElse: () => p.availableWeights.first)
            : p.unit);
  }

  @override
  Widget build(BuildContext context) {
    final currentCatMeta = SampleData.categories.firstWhere(
      (c) => c['name'] == widget.selectedCategory,
      orElse: () => SampleData.categories.first,
    );
    final List<String> subcategories = List<String>.from(currentCatMeta['subcategories'] ?? ['All']);

    final filteredProducts = SampleData.products.where((p) {
      if (p.category != widget.selectedCategory) return false;
      if (widget.selectedSubcategory != 'All' && p.subcategory != null) {
        return p.subcategory == widget.selectedSubcategory;
      }
      return true;
    }).toList();

    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            // Dark App Bar with Back Button & Cart Icon
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFF0C1910),
                border: Border(bottom: BorderSide(color: AppColors.surfaceBorder, width: 1)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: widget.onBack,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surfaceBorder, width: 1),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.selectedCategory,
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          currentCatMeta['englishName'] ?? 'Farm Fresh Quality',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        onTap: widget.onOpenCart,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.surfaceBorder, width: 1),
                          ),
                          child: const Icon(Icons.shopping_cart_outlined, size: 18, color: Colors.white),
                        ),
                      ),
                      if (widget.cartCount > 0)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.accentCoral,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              '${widget.cartCount}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Top Category Tabs (English)
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: const Color(0xFF08120C),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: SampleData.categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = SampleData.categories[index];
                  final isSelected = cat['name'] == widget.selectedCategory;
                  return GestureDetector(
                    onTap: () {
                      widget.onSelectCategory(cat['name'] as String);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF163824) : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryGreen : AppColors.surfaceBorder,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            cat['icon'] as IconData,
                            size: 13,
                            color: isSelected ? AppColors.primaryGreenLight : AppColors.textMuted,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            cat['name'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Subcategories Horizontal Chips (English)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF0E1E14),
                border: Border(bottom: BorderSide(color: AppColors.surfaceBorder, width: 1)),
              ),
              child: SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: subcategories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final subcat = subcategories[index];
                    final isSelected = subcat == widget.selectedSubcategory;
                    return GestureDetector(
                      onTap: () => widget.onSelectSubcategory(subcat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryGreenDark : AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.primaryGreenLight : AppColors.surfaceBorder,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            subcat,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Products Count & Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${widget.selectedSubcategory} (${filteredProducts.length} items)',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textGreen,
                    ),
                  ),
                  Text(
                    '100% Unpolished & Pure',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            // Products Listing
            Expanded(
              child: filteredProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.grain_rounded, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 10),
                          Text(
                            'No items available in this category',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      itemCount: filteredProducts.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final p = filteredProducts[index];
                        final selectedWeight = _getEffectiveWeight(p);
                        final currentPrice = p.getPriceForWeight(selectedWeight);

                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.surfaceBorder, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Main Row: Image + Product Name in TAMIL + Price
                              GestureDetector(
                                onTap: () => widget.onProductTap(p),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Product Image
                                      ProductImageView(
                                        imageUrl: p.imageUrl,
                                        iconKey: p.iconKey,
                                        width: 72,
                                        height: 72,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      const SizedBox(width: 12),
                                      // Titles & Price
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    p.tamilName, // STRICTLY IN TAMIL
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  '₹${currentPrice.toInt()}',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.primaryGreenLight,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              p.englishName,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            if (p.badges.isNotEmpty)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF10B981).withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  p.badges.first,
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.primaryGreenLight,
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

                              // Kilogram / Weight Options Selection Chips
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Select Weight (Kg):',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    SizedBox(
                                      height: 28,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: p.availableWeights.length,
                                        separatorBuilder: (_, _) => const SizedBox(width: 6),
                                        itemBuilder: (context, wIdx) {
                                          final weightOption = p.availableWeights[wIdx];
                                          final isWeightActive = weightOption == selectedWeight;
                                          final optPrice = p.getPriceForWeight(weightOption);

                                          return GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _selectedWeights[p.id] = weightOption;
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: isWeightActive
                                                    ? AppColors.primaryGreenDark
                                                    : AppColors.surfaceLight,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: isWeightActive
                                                      ? AppColors.primaryGreenLight
                                                      : AppColors.surfaceBorderLight,
                                                  width: isWeightActive ? 1.5 : 1,
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '$weightOption • ₹${optPrice.toInt()}',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 10.5,
                                                    fontWeight: isWeightActive ? FontWeight.bold : FontWeight.w500,
                                                    color: isWeightActive ? Colors.white : AppColors.textSecondary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 10),

                              // Bottom Actions: Add to Cart & Buy Now (English)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0F2016),
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(17),
                                    bottomRight: Radius.circular(17),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Add to Cart
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          widget.onAddToCart(
                                            p,
                                            unit: selectedWeight,
                                            price: currentPrice,
                                            qty: 1,
                                          );
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Added ${p.tamilName} ($selectedWeight) to Cart'),
                                              backgroundColor: AppColors.primaryGreenDark,
                                              duration: const Duration(milliseconds: 1200),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          decoration: BoxDecoration(
                                            color: AppColors.surface,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: AppColors.primaryGreen.withOpacity(0.5)),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.add_shopping_cart_rounded, size: 14, color: AppColors.primaryGreenLight),
                                              const SizedBox(width: 5),
                                              Text(
                                                'Add to Cart',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Buy Now
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          widget.onBuyNow(
                                            p,
                                            unit: selectedWeight,
                                            price: currentPrice,
                                            qty: 1,
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          decoration: BoxDecoration(
                                            gradient: AppColors.coralButtonGradient,
                                            borderRadius: BorderRadius.circular(10),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.accentCoral.withOpacity(0.3),
                                                blurRadius: 6,
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.bolt_rounded, size: 15, color: Colors.white),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Buy Now',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
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
                      },
                    ),
            ),

            const StepFooterBadge(
              number: '04',
              title: 'Category Listing (All Subcategories & Kg Selection)',
            ),
          ],
        ),
      ),
    );
  }
}
