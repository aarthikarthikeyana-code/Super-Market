import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/sample_data.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_widgets.dart';
import '../widgets/veg_illustrations.dart';

class Screen03HomeDiscover extends StatelessWidget {
  final Function(Product) onProductSelected;
  final VoidCallback onOpenCategories;
  final Function(String)? onCategorySelected;
  final VoidCallback onOpenCart;
  final VoidCallback onSearchTriggered;
  final Function(Product) onAddToCart;
  final int cartCount;

  const Screen03HomeDiscover({
    super.key,
    required this.onProductSelected,
    required this.onOpenCategories,
    this.onCategorySelected,
    required this.onOpenCart,
    required this.onSearchTriggered,
    required this.onAddToCart,
    required this.cartCount,
  });

  @override
  Widget build(BuildContext context) {
    final categories = SampleData.categories;
    final pulses = SampleData.products.where((p) => p.category == 'Pulses & Dals').toList();
    final freshVegs = SampleData.products.where((p) => p.category == 'Vegetables').toList();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar Greeting
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.surfaceLight,
                          child: const Icon(Icons.person, color: AppColors.primaryGreen, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Good Morning!',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Fresh Groceries • Direct Farm Harvest',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.surfaceBorder, width: 1),
                          ),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Hero Banner: Pulses & Dals
                    GestureDetector(
                      onTap: () {
                        onCategorySelected?.call('Pulses & Dals');
                        onOpenCategories();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: AppColors.heroCardGradient,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.surfaceBorderLight, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.badgeBg,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '100% PURE & UNPOLISHED',
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.badgeText,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Pulses & Dals',
                                    style: GoogleFonts.outfit(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Ideal for Sambar, Idli, Vada & Sundal',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ProductImageView(
                              imageUrl: pulses.isNotEmpty ? pulses.first.imageUrl : null,
                              iconKey: 'beans',
                              width: 80,
                              height: 80,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Search Bar
                    GestureDetector(
                      onTap: onSearchTriggered,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.surfaceBorder, width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search_rounded,
                              color: AppColors.primaryGreen,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Search for groceries... (e.g. Toor Dal, Tomato)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Categories Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Categories',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            onCategorySelected?.call('Pulses & Dals');
                            onOpenCategories();
                          },
                          child: Text(
                            'See All',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGreenLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Categories Carousel
                    SizedBox(
                      height: 92,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          final cat = categories[index];
                          final isFirst = index == 0;

                          return GestureDetector(
                            onTap: () {
                              onCategorySelected?.call(cat['name'] as String);
                              onOpenCategories();
                            },
                            child: Column(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isFirst
                                        ? AppColors.primaryGreen.withOpacity(0.2)
                                        : AppColors.surface,
                                    border: Border.all(
                                      color: isFirst
                                          ? AppColors.primaryGreen
                                          : AppColors.surfaceBorder,
                                      width: isFirst ? 2 : 1,
                                    ),
                                    boxShadow: isFirst
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primaryGreen.withOpacity(0.25),
                                              blurRadius: 8,
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: Icon(
                                    cat['icon'] as IconData,
                                    color: AppColors.primaryGreenLight,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  cat['name'] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: isFirst ? FontWeight.bold : FontWeight.w500,
                                    color: isFirst ? Colors.white : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Pulses & Dals Spotlight Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 18,
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Pulses & Dals',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            onCategorySelected?.call('Pulses & Dals');
                            onOpenCategories();
                          },
                          child: Text(
                            'View All (12)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGreenLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 2 Dal Cards (Product name strictly in Tamil)
                    if (pulses.length >= 2)
                      Row(
                        children: [
                          Expanded(
                            child: _ProductCard(
                              product: pulses[0], // துவரம் பருப்பு
                              onTap: () => onProductSelected(pulses[0]),
                              onAdd: () => onAddToCart(pulses[0]),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ProductCard(
                              product: pulses[1], // பாசிப் பருப்பு
                              onTap: () => onProductSelected(pulses[1]),
                              onAdd: () => onAddToCart(pulses[1]),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),

                    // Vegetables Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 18,
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Fresh Vegetables',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Farm Fresh',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.textGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 2 Vegetable Cards (Product name strictly in Tamil)
                    if (freshVegs.length >= 2)
                      Row(
                        children: [
                          Expanded(
                            child: _ProductCard(
                              product: freshVegs[0], // தக்காளி
                              onTap: () => onProductSelected(freshVegs[0]),
                              onAdd: () => onAddToCart(freshVegs[0]),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ProductCard(
                              product: freshVegs[1], // வெங்காயம்
                              onTap: () => onProductSelected(freshVegs[1]),
                              onAdd: () => onAddToCart(freshVegs[1]),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Bottom Navigation Bar (English)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF0D1C13),
                border: Border(
                  top: BorderSide(color: AppColors.surfaceBorder, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavButton(
                    icon: Icons.home_filled,
                    label: 'Home',
                    isActive: true,
                    onTap: () {},
                  ),
                  _NavButton(
                    icon: Icons.grid_view_rounded,
                    label: 'Categories',
                    isActive: false,
                    onTap: () {
                      onCategorySelected?.call('Pulses & Dals');
                      onOpenCategories();
                    },
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _NavButton(
                        icon: Icons.shopping_cart_outlined,
                        label: 'Cart',
                        isActive: false,
                        onTap: onOpenCart,
                      ),
                      if (cartCount > 0)
                        Positioned(
                          top: -2,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.accentCoral,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              '$cartCount',
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
                  _NavButton(
                    icon: Icons.receipt_long_rounded,
                    label: 'Orders',
                    isActive: false,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const StepFooterBadge(
              number: '03',
              title: 'Home / Discover Browse Categories',
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ProductImageView(
                imageUrl: product.imageUrl,
                iconKey: product.iconKey,
                width: 78,
                height: 78,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(height: 10),
            // Product Name STRICTLY IN TAMIL
            Text(
              product.tamilName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            // Subtitle English Descriptor
            Text(
              product.englishName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${product.price.toInt()} / ${product.unit}',
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryGreenLight,
                  ),
                ),
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.accentCoral,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? AppColors.primaryGreen : AppColors.textMuted,
            size: 22,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? AppColors.primaryGreen : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
