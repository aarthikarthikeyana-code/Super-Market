import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class Admin05ItemAvailability extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onOpenStockManagement;
  final VoidCallback onProceedToPacking;

  const Admin05ItemAvailability({
    super.key,
    required this.onBack,
    required this.onOpenStockManagement,
    required this.onProceedToPacking,
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
              title: 'Item Availability',
              onBack: onBack,
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Available Items (2)
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Available Items (2)',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _AvailabilityRow(
                      tamilName: 'தக்காளி',
                      qty: '1 Kg',
                      isAvailable: true,
                    ),
                    const SizedBox(height: 8),
                    _AvailabilityRow(
                      tamilName: 'கேரட்',
                      qty: '500 g',
                      isAvailable: true,
                    ),
                    const SizedBox(height: 20),

                    // Section 2: Out of Stock (1)
                    Row(
                      children: [
                        const Icon(Icons.cancel_rounded, color: AppColors.outOfStockText, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Out of Stock (1)',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.outOfStockText.withOpacity(0.4), width: 1),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'வெங்காயம்',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '1 Kg',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.outOfStockBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.outOfStockText, width: 1),
                            ),
                            child: Text(
                              'Mark Out of Stock',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.outOfStockText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 3: New Item Requests (1)
                    Row(
                      children: [
                        const Icon(Icons.notification_add_rounded, color: Color(0xFFC084FC), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'New Item Requests (1)',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFC084FC).withOpacity(0.4), width: 1),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'புதினா',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Requested by Customer',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: const Color(0xFFC084FC),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2B1B3D),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFC084FC), width: 1),
                            ),
                            child: Text(
                              'Approve & Add',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFC084FC),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Bottom CTA Row
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: CoralButton(
                      label: 'Proceed to Packing',
                      onPressed: onProceedToPacking,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: DarkOutlineButton(
                      label: 'View Stock Management',
                      icon: Icons.inventory_2_rounded,
                      onPressed: onOpenStockManagement,
                    ),
                  ),
                ],
              ),
            ),

            const StepFooterBadge(
              number: '05',
              title: 'Split Items (Stock Check)',
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailabilityRow extends StatelessWidget {
  final String tamilName;
  final String qty;
  final bool isAvailable;

  const _AvailabilityRow({
    required this.tamilName,
    required this.qty,
    required this.isAvailable,
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
                qty,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Available',
              style: TextStyle(
                color: AppColors.primaryGreenLight,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
