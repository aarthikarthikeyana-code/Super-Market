import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class Admin07RequestApproval extends StatelessWidget {
  final VoidCallback onBack;
  final String status;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const Admin07RequestApproval({
    super.key,
    required this.onBack,
    required this.status,
    required this.onApprove,
    required this.onReject,
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
              title: 'New Item Requests',
              onBack: onBack,
              actions: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  margin: const EdgeInsets.only(right: 12),
                  decoration: const BoxDecoration(
                    color: AppColors.accentCoral,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '1',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Request Detail Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: status == 'Approved'
                              ? AppColors.primaryGreen
                              : (status == 'Rejected'
                                  ? AppColors.outOfStockText
                                  : AppColors.surfaceBorder),
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
                                'புதினா (Mint)',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: status == 'Approved'
                                      ? AppColors.badgeBg
                                      : (status == 'Rejected'
                                          ? AppColors.outOfStockBg
                                          : const Color(0xFF2B1B3D)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  status,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: status == 'Approved'
                                        ? AppColors.badgeText
                                        : (status == 'Rejected'
                                            ? AppColors.outOfStockText
                                            : const Color(0xFFC084FC)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Requested on 16 Apr 2025, 10:22 AM',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Requested by customer from Chennai (Phone: +91 98765 43210)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Action Buttons
                          SizedBox(
                            width: double.infinity,
                            child: EmeraldButton(
                              label: 'Approve & Add to Stock',
                              icon: Icons.check_circle_outline_rounded,
                              onPressed: onApprove,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: DarkOutlineButton(
                              label: 'Reject',
                              icon: Icons.close_rounded,
                              onPressed: onReject,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const StepFooterBadge(
              number: '07',
              title: 'Request Approval (New Items)',
            ),
          ],
        ),
      ),
    );
  }
}
