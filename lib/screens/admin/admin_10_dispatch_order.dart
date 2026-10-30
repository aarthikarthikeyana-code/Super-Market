import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import '../../widgets/veg_illustrations.dart';

class Admin10DispatchOrder extends StatelessWidget {
  final VoidCallback onBack;
  final String orderId;
  final String assignedPerson;
  final VoidCallback onDispatch;

  const Admin10DispatchOrder({
    super.key,
    required this.onBack,
    this.orderId = '#ORD124578',
    this.assignedPerson = 'Karthik',
    required this.onDispatch,
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
              title: 'Dispatch Order',
              onBack: onBack,
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Column(
                  children: [
                    // Scooter Illustration Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF163222),
                            Color(0xFF0F2217),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.surfaceBorderLight, width: 1.2),
                      ),
                      child: Column(
                        children: [
                          const ScooterDeliveryIllustration(width: 220, height: 130),
                          const SizedBox(height: 12),
                          Text(
                            orderId,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreenLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Assigned to $assignedPerson',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '+91 98765 43211',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Dispatch Checklist details
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.surfaceBorder, width: 1),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Items Packed',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const Text(
                                '2 Items (1 Out of Stock)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Delivery Bag Code',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const Text(
                                'BAG-CH-82',
                                style: TextStyle(
                                  color: AppColors.primaryGreenLight,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
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
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: EmeraldButton(
                  label: 'Mark as Out for Delivery',
                  icon: Icons.local_shipping_rounded,
                  onPressed: onDispatch,
                ),
              ),
            ),

            const StepFooterBadge(
              number: '10',
              title: 'Dispatch Order',
            ),
          ],
        ),
      ),
    );
  }
}
