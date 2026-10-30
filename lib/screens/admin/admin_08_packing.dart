import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class Admin08Packing extends StatelessWidget {
  final VoidCallback onBack;
  final String orderId;
  final Map<String, bool> checklist;
  final Function(String) onToggleCheck;
  final VoidCallback onMarkPacked;

  const Admin08Packing({
    super.key,
    required this.onBack,
    this.orderId = '#ORD124578',
    required this.checklist,
    required this.onToggleCheck,
    required this.onMarkPacked,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {'id': 'prod_tomato', 'name': 'தக்காளி', 'qty': '1 Kg', 'isOut': false},
      {'id': 'prod_carrot', 'name': 'கேரட்', 'qty': '500 g', 'isOut': false},
      {'id': 'prod_onion', 'name': 'வெங்காயம்', 'qty': '1 Kg', 'isOut': true},
    ];

    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            // App Bar
            DarkAppBar(
              title: 'Packing',
              onBack: onBack,
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                          Text(
                            'Packing Checklist',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Verify & Pack Items into Delivery Box',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Items Checklist
                    ...items.map((item) {
                      final id = item['id'] as String;
                      final isOut = item['isOut'] as bool;
                      final isChecked = checklist[id] ?? false;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isOut
                                ? AppColors.outOfStockText.withOpacity(0.3)
                                : (isChecked ? AppColors.primaryGreen : AppColors.surfaceBorder),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: isOut ? null : () => onToggleCheck(id),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isOut
                                      ? AppColors.outOfStockBg
                                      : (isChecked ? AppColors.primaryGreen : Colors.transparent),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isOut
                                        ? AppColors.outOfStockText
                                        : (isChecked ? AppColors.primaryGreen : AppColors.textMuted),
                                    width: 1.5,
                                  ),
                                ),
                                child: Icon(
                                  isOut ? Icons.close : Icons.check,
                                  size: 16,
                                  color: isOut ? AppColors.outOfStockText : Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'] as String,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      decoration: isOut ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  Text(
                                    isOut ? 'Marked Out of Stock' : (item['qty'] as String),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      color: isOut ? AppColors.outOfStockText : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                child: CoralButton(
                  label: 'Mark as Packed',
                  showArrow: false,
                  onPressed: onMarkPacked,
                ),
              ),
            ),

            const StepFooterBadge(
              number: '08',
              title: 'Packing',
            ),
          ],
        ),
      ),
    );
  }
}
