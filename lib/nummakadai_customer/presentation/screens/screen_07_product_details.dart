import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/customer_theme.dart';
import '../providers/customer_providers.dart';
import '../widgets/customer_common_widgets.dart';

class Customer07ProductSelectionScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback onAddToCartSuccess;

  const Customer07ProductSelectionScreen({
    super.key,
    this.onBack,
    required this.onAddToCartSuccess,
  });

  @override
  ConsumerState<Customer07ProductSelectionScreen> createState() => _Customer07ProductSelectionScreenState();
}

class _Customer07ProductSelectionScreenState extends ConsumerState<Customer07ProductSelectionScreen> {
  int _selectedSizeIndex = 0;
  int _quantity = 1;
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final product = ref.watch(selectedProductProvider);
    final selectedOption = product.sizes[_selectedSizeIndex];

    return Scaffold(
      backgroundColor: NummaCustomerColors.creamBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header: Back, Heart, Share
            CustomerAppBar(
              title: product.brand,
              onBack: widget.onBack,
              actions: [
                IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border_rounded,
                    color: _isFavorite ? NummaCustomerColors.errorRed : NummaCustomerColors.darkGreen,
                  ),
                  onPressed: () => setState(() => _isFavorite = !_isFavorite),
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: NummaCustomerColors.darkGreen),
                  onPressed: () {},
                ),
              ],
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Large Product Image
                    Container(
                      width: double.infinity,
                      height: 220,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: NummaCustomerColors.border),
                        boxShadow: NummaCustomerColors.lightShadow,
                      ),
                      alignment: Alignment.center,
                      child: CustomerProductImage(
                        imageUrl: product.imageUrl,
                        size: 160,
                        radius: BorderRadius.circular(16),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Tamil Title & English Subtitle
                    Text(
                      product.nameTamil,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: NummaCustomerColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.brand} • ${product.nameEnglish}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: NummaCustomerColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Rating & Reviews Count
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: NummaCustomerColors.lightGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 16, color: NummaCustomerColors.yellowAccent),
                              const SizedBox(width: 4),
                              Text(
                                '${product.rating}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: NummaCustomerColors.darkGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${product.reviewsCount} reviews)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: NummaCustomerColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Pricing & Discount
                    Row(
                      children: [
                        Text(
                          '₹${selectedOption.price.toStringAsFixed(0)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: NummaCustomerColors.darkGreen,
                          ),
                        ),
                        if (selectedOption.oldPrice != null) ...[
                          const SizedBox(width: 10),
                          Text(
                            '₹${selectedOption.oldPrice!.toStringAsFixed(0)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              decoration: TextDecoration.lineThrough,
                              color: NummaCustomerColors.secondaryText,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: NummaCustomerColors.warmCream,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              product.discount,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: NummaCustomerColors.orangeAccent,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),

                    // SELECT SIZE SECTION
                    Text(
                      'Select Size',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: NummaCustomerColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Three Selectable Size Cards
                    Row(
                      children: List.generate(product.sizes.length, (index) {
                        final sizeOpt = product.sizes[index];
                        final isSelected = _selectedSizeIndex == index;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedSizeIndex = index),
                            child: Container(
                              margin: EdgeInsets.only(right: index < product.sizes.length - 1 ? 8 : 0),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? NummaCustomerColors.lightGreen : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? NummaCustomerColors.darkGreen : NummaCustomerColors.border,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    sizeOpt.size,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: NummaCustomerColors.darkText,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${sizeOpt.price.toStringAsFixed(0)}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: NummaCustomerColors.darkGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),

                    // QUANTITY STEPPER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Quantity',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: NummaCustomerColors.darkText,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: NummaCustomerColors.border),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 18),
                                onPressed: () {
                                  if (_quantity > 1) setState(() => _quantity--);
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  '$_quantity',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 18, color: NummaCustomerColors.darkGreen),
                                onPressed: () => setState(() => _quantity++),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom Add to Cart CTA
            Padding(
              padding: const EdgeInsets.all(16),
              child: CustomerPrimaryButton(
                icon: Icons.shopping_cart_outlined,
                text: 'Add to Cart  •  ₹${(selectedOption.price * _quantity).toStringAsFixed(0)}',
                onPressed: () {
                  ref.read(customerCartProvider.notifier).addToCart(
                        product,
                        selectedOption,
                        _quantity,
                      );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added ${product.nameTamil} ($_quantity item) to cart'),
                      backgroundColor: NummaCustomerColors.darkGreen,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                  widget.onAddToCartSuccess();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
