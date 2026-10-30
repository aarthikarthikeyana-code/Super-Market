import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class Admin09AssignDelivery extends StatelessWidget {
  final VoidCallback onBack;
  final String selectedPerson;
  final Function(String) onSelectPerson;
  final VoidCallback onAssign;

  const Admin09AssignDelivery({
    super.key,
    required this.onBack,
    required this.selectedPerson,
    required this.onSelectPerson,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final drivers = [
      {'name': 'Karthik', 'status': 'Available', 'isAvailable': true},
      {'name': 'Suresh', 'status': 'Available', 'isAvailable': true},
      {'name': 'Manoj', 'status': 'Busy', 'isAvailable': false},
    ];

    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            // App Bar
            DarkAppBar(
              title: 'Assign Delivery Person',
              onBack: onBack,
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select available delivery partner',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Drivers List
                    ...drivers.map((d) {
                      final name = d['name'] as String;
                      final isSelected = name == selectedPerson;
                      final isAvailable = d['isAvailable'] as bool;

                      return GestureDetector(
                        onTap: isAvailable ? () => onSelectPerson(name) : null,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF142F20) : AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryGreen
                                  : AppColors.surfaceBorder,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: isAvailable
                                    ? AppColors.primaryGreen.withOpacity(0.2)
                                    : AppColors.surfaceLight,
                                child: Icon(
                                  Icons.two_wheeler_rounded,
                                  color: isAvailable ? AppColors.primaryGreenLight : AppColors.textMuted,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isAvailable
                                      ? AppColors.badgeBg
                                      : AppColors.outOfStockBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  d['status'] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isAvailable
                                        ? AppColors.badgeText
                                        : AppColors.outOfStockText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
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
                  label: 'Assign',
                  icon: Icons.check_circle_rounded,
                  onPressed: onAssign,
                ),
              ),
            ),

            const StepFooterBadge(
              number: '09',
              title: 'Assign Delivery Person',
            ),
          ],
        ),
      ),
    );
  }
}
