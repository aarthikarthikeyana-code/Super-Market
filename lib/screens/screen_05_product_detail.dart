import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_widgets.dart';
import '../widgets/veg_illustrations.dart';

class Screen05ProductDetail extends StatefulWidget {
  final Product product;
  final VoidCallback onBack;
  final Function(Product, int qty, String weight, double price) onAddToCart;
  final Function(Product, int qty, String weight, double price) onBuyNow;

  const Screen05ProductDetail({
    super.key,
    required this.product,
    required this.onBack,
    required this.onAddToCart,
    required this.onBuyNow,
  });

  @override
  State<Screen05ProductDetail> createState() => _Screen05ProductDetailState();
}

class _Screen05ProductDetailState extends State<Screen05ProductDetail> {
  int _quantity = 1;
  late String _selectedWeight;
  bool _isFavorite = true;

  @override
  void initState() {
    super.initState();
    _selectedWeight = widget.product.availableWeights.contains('1 Kg')
        ? '1 Kg'
        : (widget.product.availableWeights.isNotEmpty
            ? widget.product.availableWeights.first
            : widget.product.unit);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final unitPrice = p.getPriceForWeight(_selectedWeight);
    final totalPrice = unitPrice * _quantity;

    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            // App Bar
            DarkAppBar(
              title: p.tamilName, // STRICTLY IN TAMIL
              onBack: widget.onBack,
              actions: [
                IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: _isFavorite ? AppColors.accentCoral : Colors.white,
                    size: 22,
                  ),
                  onPressed: () {
                    setState(() {
                      _isFavorite = !_isFavorite;
                    });
                  },
                ),
              ],
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Image Card
                    Container(
                      width: double.infinity,
                      height: 220,
                      decoration: BoxDecoration(
                        color: const Color(0xFF102117),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.surfaceBorder, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ProductImageView(
                            imageUrl: p.imageUrl,
                            iconKey: p.iconKey,
                            width: double.infinity,
                            height: 220,
                            borderRadius: BorderRadius.zero,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.5),
                                ],
                              ),
                            ),
                          ),
                          if (p.subcategory != null)
                            Positioned(
                              top: 14,
                              left: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.primaryGreenLight.withOpacity(0.5)),
                                ),
                                child: Text(
                                  p.subcategory!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGreenLight,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Tamil Title (TAMIL ONLY) & English Subtitle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.tamilName, // Product name STRICTLY IN TAMIL
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                p.englishName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Price Tag
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${unitPrice.toInt()}',
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGreenLight,
                              ),
                            ),
                            Text(
                              'per $_selectedWeight',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Product Description (English)
                    Text(
                      p.description,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Kilogram / Weight Selector (English)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.surfaceBorder, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.scale_rounded, size: 16, color: AppColors.primaryGreenLight),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Choose Weight (Kg)',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Selected: $_selectedWeight',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryGreenLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: p.availableWeights.map((w) {
                              final isSelected = w == _selectedWeight;
                              final wPrice = p.getPriceForWeight(w);
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedWeight = w;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primaryGreenDark : AppColors.surfaceLight,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primaryGreenLight : AppColors.surfaceBorderLight,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primaryGreen.withOpacity(0.3),
                                              blurRadius: 8,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        w,
                                        style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? Colors.white : AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '₹${wPrice.toInt()}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected ? Colors.white : AppColors.primaryGreenLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Quantity Stepper & Total (English)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Amount',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              '₹${totalPrice.toInt()}',
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: AppColors.surfaceBorder, width: 1.2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (_quantity > 1) {
                                    setState(() => _quantity--);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceLight,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.remove, color: Colors.white, size: 16),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  '$_quantity',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() => _quantity++);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryGreenDark,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add, color: Colors.white, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Action Buttons: Add to Cart and Buy Now (English)
                    Row(
                      children: [
                        // Add to Cart
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              widget.onAddToCart(p, _quantity, _selectedWeight, unitPrice);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Added ${p.tamilName} ($_selectedWeight x $_quantity) to Cart'),
                                  backgroundColor: AppColors.primaryGreenDark,
                                  duration: const Duration(milliseconds: 1400),
                                ),
                              );
                            },
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.primaryGreen, width: 1.5),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.shopping_cart_outlined, color: AppColors.primaryGreenLight, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Add to Cart',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Buy Now
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              widget.onBuyNow(p, _quantity, _selectedWeight, unitPrice);
                            },
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: AppColors.coralButtonGradient,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accentCoral.withOpacity(0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Buy Now',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
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
                    const SizedBox(height: 24),

                    // Three Value Badges (English)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ValueBadge(
                          icon: Icons.verified_user_rounded,
                          label: p.badges.isNotEmpty ? p.badges[0] : '100% Pure',
                        ),
                        _ValueBadge(
                          icon: Icons.cleaning_services_rounded,
                          label: p.badges.length > 1 ? p.badges[1] : 'Stone Free',
                        ),
                        _ValueBadge(
                          icon: Icons.military_tech_rounded,
                          label: p.badges.length > 2 ? p.badges[2] : 'Premium Quality',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            const StepFooterBadge(
              number: '05',
              title: 'Product Detail (Kg & Weight Selector)',
            ),
          ],
        ),
      ),
    );
  }
}

class _ValueBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ValueBadge({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primaryGreen.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: AppColors.primaryGreenLight,
            size: 20,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
