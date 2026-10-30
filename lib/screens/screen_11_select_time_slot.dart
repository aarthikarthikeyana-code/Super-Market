import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/sample_data.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_widgets.dart';

class Screen11SelectTimeSlot extends StatelessWidget {
  final TimeSlot selectedSlot;
  final Function(TimeSlot) onSlotSelected;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const Screen11SelectTimeSlot({
    super.key,
    required this.selectedSlot,
    required this.onSlotSelected,
    required this.onContinue,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final slots = SampleData.timeSlots;

    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            // App Bar
            DarkAppBar(
              title: 'Select Delivery Time Slot',
              onBack: onBack,
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose a convenient delivery window',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Slots list
                    ...slots.map((slot) {
                      final isSelected = slot.id == selectedSlot.id;

                      return GestureDetector(
                        onTap: () => onSlotSelected(slot),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF133221)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryGreen
                                  : AppColors.surfaceBorder,
                              width: isSelected ? 1.5 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color:
                                          AppColors.primaryGreen.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              // Letter Badge (A, B, C, D)
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? AppColors.primaryGreen
                                      : AppColors.surfaceLight,
                                ),
                                child: Center(
                                  child: Text(
                                    slot.letter,
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.black
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Time Range Text
                              Expanded(
                                child: Text(
                                  slot.timeRange,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              // Selection Indicator
                              Container(
                                width: 20,
                                height: 20,
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
              padding: const EdgeInsets.all(18),
              child: SizedBox(
                width: double.infinity,
                child: CoralButton(
                  label: 'Proceed to Summary',
                  onPressed: onContinue,
                ),
              ),
            ),

            const StepFooterBadge(
              number: '11',
              title: 'Select Time Slot',
            ),
          ],
        ),
      ),
    );
  }
}
