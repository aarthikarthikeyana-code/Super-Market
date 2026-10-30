import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/customer_theme.dart';
import '../../data/models/customer_models.dart';
import '../providers/customer_providers.dart';
import '../widgets/customer_common_widgets.dart';

class Customer04HomeScreen extends ConsumerWidget {
  final VoidCallback onOpenDrawer;
  final VoidCallback onOpenCategories;
  final VoidCallback onOpenOffers;
  final void Function(CustomerProduct product) onSelectProduct;

  const Customer04HomeScreen({
    super.key,
    required this.onOpenDrawer,
    required this.onOpenCategories,
    required this.onOpenOffers,
    required this.onSelectProduct,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(customerRepoProvider);
    final products = repo.products;
    final categories = repo.categories;

    return Scaffold(
      backgroundColor: NummaCustomerColors.creamBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Hamburger, Logo, Location, Notification
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu_rounded, color: NummaCustomerColors.darkGreen, size: 26),
                        onPressed: onOpenDrawer,
                      ),
                      const SizedBox(width: 4),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'AGARAM',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: NummaCustomerColors.darkGreen,
                                ),
                              ),
                              Text(
                                ' Supermarket',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: NummaCustomerColors.orangeAccent,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 12, color: NummaCustomerColors.secondaryGreen),
                              const SizedBox(width: 2),
                              Text(
                                'Anna Nagar, Chennai',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: NummaCustomerColors.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: NummaCustomerColors.border),
                    ),
                    child: const Icon(Icons.notifications_none_rounded, size: 20, color: NummaCustomerColors.darkGreen),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Search Bar
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: NummaCustomerColors.border),
                  boxShadow: NummaCustomerColors.lightShadow,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: NummaCustomerColors.secondaryText, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Search for products, brands and more...',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: NummaCustomerColors.secondaryText,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.mic_none_rounded, color: NummaCustomerColors.darkGreen, size: 18),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Hero Banner: Everyday Essentials at Your Doorstep
              Container(
                height: 130,
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [
                      NummaCustomerColors.darkGreen,
                      NummaCustomerColors.secondaryGreen,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: NummaCustomerColors.cardShadow,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Everyday Essentials\nat Your Doorstep',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: onOpenCategories,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: NummaCustomerColors.yellowAccent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Shop Now →',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: NummaCustomerColors.darkText,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/splash_harvest_basket.jpg',
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.shopping_basket, size: 50, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Quick Actions: Offers, Fresh Arrivals, Reorder, Categories
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildQuickAction(Icons.local_offer_outlined, 'Offers', onOpenOffers),
                  _buildQuickAction(Icons.eco_outlined, 'Fresh Arrivals', onOpenCategories),
                  _buildQuickAction(Icons.repeat_rounded, 'Reorder', () {}),
                  _buildQuickAction(Icons.grid_view_rounded, 'Categories', onOpenCategories),
                ],
              ),
              const SizedBox(height: 20),

              // Shop by Category Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Shop by Category',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: NummaCustomerColors.darkText,
                    ),
                  ),
                  GestureDetector(
                    onTap: onOpenCategories,
                    child: Text(
                      'View All',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: NummaCustomerColors.darkGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Horizontal Category Cards
              SizedBox(
                height: 95,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    return GestureDetector(
                      onTap: onOpenCategories,
                      child: Container(
                        width: 82,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: NummaCustomerColors.border),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomerProductImage(
                              imageUrl: cat.imageUrl,
                              size: 44,
                              radius: BorderRadius.circular(10),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              cat.nameTamil,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: NummaCustomerColors.darkText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Product List Section
              Text(
                'Featured Essentials',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: NummaCustomerColors.darkText,
                ),
              ),
              const SizedBox(height: 12),

              // Product Cards Grid/List
              ...products.map((product) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: NummaCustomerColors.border),
                    boxShadow: NummaCustomerColors.lightShadow,
                  ),
                  child: InkWell(
                    onTap: () {
                      ref.read(selectedProductProvider.notifier).setProduct(product);
                      onSelectProduct(product);
                    },
                    child: Row(
                      children: [
                        CustomerProductImage(
                          imageUrl: product.imageUrl,
                          size: 68,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.nameTamil,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: NummaCustomerColors.darkText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${product.brand} • ${product.sizes.first.size}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: NummaCustomerColors.secondaryText,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    '₹${product.price.toStringAsFixed(0)}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: NummaCustomerColors.darkGreen,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '₹${product.oldPrice.toStringAsFixed(0)}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      decoration: TextDecoration.lineThrough,
                                      color: NummaCustomerColors.secondaryText,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: NummaCustomerColors.warmCream,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      product.discount,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: NummaCustomerColors.orangeAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: NummaCustomerColors.lightGreen,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: NummaCustomerColors.darkGreen.withOpacity(0.3)),
                          ),
                          child: Text(
                            'Add',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: NummaCustomerColors.darkGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: NummaCustomerColors.lightGreen,
              shape: BoxShape.circle,
              border: Border.all(color: NummaCustomerColors.darkGreen.withOpacity(0.2)),
            ),
            child: Icon(icon, color: NummaCustomerColors.darkGreen, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: NummaCustomerColors.darkText,
            ),
          ),
        ],
      ),
    );
  }
}

