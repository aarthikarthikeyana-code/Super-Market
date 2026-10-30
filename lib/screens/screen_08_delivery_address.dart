import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_widgets.dart';

class Screen08DeliveryAddress extends StatelessWidget {
  final List<DeliveryAddress> addresses;
  final DeliveryAddress selectedAddress;
  final Function(DeliveryAddress) onSelectAddress;
  final VoidCallback onAddNewAddress;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const Screen08DeliveryAddress({
    super.key,
    required this.addresses,
    required this.selectedAddress,
    required this.onSelectAddress,
    required this.onAddNewAddress,
    required this.onContinue,
    required this.onBack,
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
              title: 'Delivery Address',
              onBack: onBack,
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Delivery Location',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Addresses List
                    ...addresses.map((addr) {
                      final isSelected = addr.id == selectedAddress.id;
                      return GestureDetector(
                        onTap: () => onSelectAddress(addr),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF162D20)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryGreen
                                  : AppColors.surfaceBorder,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Green check circle or outline
                              Container(
                                width: 22,
                                height: 22,
                                margin: const EdgeInsets.only(top: 2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? AppColors.primaryGreen
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primaryGreen
                                        : AppColors.textMuted,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        size: 14,
                                        color: Colors.black,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          addr.title,
                                          style: GoogleFonts.outfit(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          'Edit',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primaryGreenLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      addr.formatted,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 10),

                    // + Add New Address Button
                    GestureDetector(
                      onTap: onAddNewAddress,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.surfaceBorderLight,
                            style: BorderStyle.solid,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_circle_outline_rounded,
                              color: AppColors.primaryGreenLight,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '+ Add New Address',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
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
                  label: 'Continue to Instructions',
                  onPressed: onContinue,
                ),
              ),
            ),

            const StepFooterBadge(
              number: '08',
              title: 'Delivery Address Select / Add Address',
            ),
          ],
        ),
      ),
    );
  }
}
