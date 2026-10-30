import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_widgets.dart';

class Screen12OrderSummary extends StatelessWidget {
  final List<CartItem> cartItems;
  final DeliveryAddress address;
  final DateTime deliveryDate;
  final TimeSlot timeSlot;
  final VoidCallback onPlaceOrder;
  final VoidCallback onBack;

  const Screen12OrderSummary({
    super.key,
    required this.cartItems,
    required this.address,
    required this.deliveryDate,
    required this.timeSlot,
    required this.onPlaceOrder,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    double totalAmount = 0;
    int itemCount = 0;
    for (var item in cartItems) {
      totalAmount += item.totalPrice;
      itemCount += item.quantity;
    }

    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            // App Bar
            DarkAppBar(
              title: 'Order Summary',
              onBack: onBack,
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bill Breakdown Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.surfaceBorder,
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Items ($itemCount)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                '₹${totalAmount.toInt()}',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Delivery Charge',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                '₹0',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryGreenLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: AppColors.surfaceBorder, height: 1),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Amount',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '₹${totalAmount.toInt()}',
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGreenLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Payment Method Section
                    Text(
                      'Payment Method',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Cash on Delivery Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF132F20),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.primaryGreen,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGreen.withOpacity(0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryGreenDark,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.payments_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cash on Delivery (COD)',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'No Online Payments',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: AppColors.primaryGreenLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primaryGreen,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Schedule Info Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.surfaceBorder, width: 1),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                color: AppColors.primaryGreenLight,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${address.title} - ${address.formatted}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                color: AppColors.primaryGreenLight,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Apr ${deliveryDate.day}, 2025 • ${timeSlot.timeRange}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom CTA
            Padding(
              padding: const EdgeInsets.all(18),
              child: SizedBox(
                width: double.infinity,
                child: CoralButton(
                  label: 'Place Order',
                  showArrow: false,
                  onPressed: onPlaceOrder,
                ),
              ),
            ),

            const StepFooterBadge(
              number: '12',
              title: 'Order Confirmation (Only Cash on Delivery)',
            ),
          ],
        ),
      ),
    );
  }
}
