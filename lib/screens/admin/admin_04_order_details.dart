import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class Admin04OrderDetails extends StatelessWidget {
  final String orderId;
  final VoidCallback onBack;
  final VoidCallback onCheckStock;

  const Admin04OrderDetails({
    super.key,
    this.orderId = '#ORD124578',
    required this.onBack,
    required this.onCheckStock,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            // App Bar
            DarkAppBar(
              title: 'Order Details',
              onBack: onBack,
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order ID Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.surfaceBorder, width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            orderId,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreenLight,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'COD • ₹82',
                              style: TextStyle(
                                color: AppColors.primaryGreenLight,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Customer Details Card
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
                            children: [
                              const Icon(Icons.person_rounded, color: AppColors.primaryGreenLight, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Customer: Priya S',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.phone_rounded, color: AppColors.textSecondary, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                '+91 98765 43210',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Divider(color: AppColors.surfaceBorder, height: 1),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on_rounded, color: AppColors.accentCoral, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Delivery: Today, 04:00 PM - 06:00 PM\n123, Green Street, Chennai',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: Colors.white,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Items Header
                    Text(
                      'Items in Order (3)',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Items List
                    _OrderItemRow(
                      tamilName: 'தக்காளி',
                      englishName: 'Tomato',
                      qty: '1 Kg',
                      price: '₹30',
                    ),
                    const SizedBox(height: 8),
                    _OrderItemRow(
                      tamilName: 'கேரட்',
                      englishName: 'Carrot',
                      qty: '500 g',
                      price: '₹24',
                    ),
                    const SizedBox(height: 8),
                    _OrderItemRow(
                      tamilName: 'வெங்காயம்',
                      englishName: 'Onion',
                      qty: '1 Kg',
                      price: '₹28',
                    ),
                  ],
                ),
              ),
            ),

            // Bottom CTA
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: CoralButton(
                  label: 'Check Item Availability',
                  onPressed: onCheckStock,
                ),
              ),
            ),

            const StepFooterBadge(
              number: '04',
              title: 'Order Details',
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  final String tamilName;
  final String englishName;
  final String qty;
  final String price;

  const _OrderItemRow({
    required this.tamilName,
    required this.englishName,
    required this.qty,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tamilName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '$englishName • $qty',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Text(
            price,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGreenLight,
            ),
          ),
        ],
      ),
    );
  }
}
