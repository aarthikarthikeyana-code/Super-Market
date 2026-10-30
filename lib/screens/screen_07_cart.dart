import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_widgets.dart';
import '../widgets/veg_illustrations.dart';

class Screen07Cart extends StatelessWidget {
  final List<CartItem> cartItems;
  final VoidCallback onBack;
  final Function(String) onIncrement;
  final Function(String) onDecrement;
  final VoidCallback onProceedToCheckout;

  const Screen07Cart({
    super.key,
    required this.cartItems,
    required this.onBack,
    required this.onIncrement,
    required this.onDecrement,
    required this.onProceedToCheckout,
  });

  @override
  Widget build(BuildContext context) {
    double totalAmount = 0;
    for (var item in cartItems) {
      totalAmount += item.totalPrice;
    }

    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            DarkAppBar(
              title: 'Your Cart',
              onBack: onBack,
            ),

            // Cart Items List
            Expanded(
              child: cartItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shopping_basket_outlined,
                            size: 64,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Your cart is empty',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: cartItems.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        final p = item.product;

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.surfaceBorder, width: 1),
                          ),
                          child: Row(
                            children: [
                              ProductImageView(
                                imageUrl: p.imageUrl,
                                iconKey: p.iconKey,
                                width: 50,
                                height: 50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.tamilName,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      '${item.unitSelected} • ₹${item.unitPrice.toInt()}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Counter Stepper [-] qty [+]
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.surfaceBorderLight,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () => onDecrement(p.id),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 4),
                                        child: Icon(Icons.remove, size: 14, color: Colors.white),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Text(
                                        '${item.quantity}',
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => onIncrement(p.id),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 4),
                                        child: Icon(Icons.add, size: 14, color: AppColors.primaryGreenLight),
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

            // Bottom Summary & Checkout
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1E16),
                border: Border(
                  top: BorderSide(color: AppColors.surfaceBorder, width: 1),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '₹${totalAmount.toInt()}',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreenLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: CoralButton(
                      label: 'Proceed to Checkout',
                      onPressed: onProceedToCheckout,
                    ),
                  ),
                ],
              ),
            ),

            const StepFooterBadge(
              number: '07',
              title: 'Cart Review Items',
            ),
          ],
        ),
      ),
    );
  }
}
