import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class Admin12Reports extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onDownloadReport;

  const Admin12Reports({
    super.key,
    required this.onBack,
    required this.onDownloadReport,
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
              title: 'Reports',
              onBack: onBack,
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Summary filter dropdown header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order Summary',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.surfaceBorder, width: 1),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Today',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryGreenLight,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Colors.white),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Metrics Grid (2x2)
                    Row(
                      children: [
                        Expanded(
                          child: _ReportMetricCard(
                            number: '28',
                            label: 'Total Orders',
                            accentColor: AppColors.primaryGreenLight,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ReportMetricCard(
                            number: '24',
                            label: 'Delivered',
                            accentColor: const Color(0xFF60A5FA),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ReportMetricCard(
                            number: '4',
                            label: 'Out of Stock Items',
                            accentColor: AppColors.outOfStockText,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ReportMetricCard(
                            number: '6',
                            label: 'New Item Requests',
                            accentColor: const Color(0xFFC084FC),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Daily Highlights Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.surfaceBorder, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Operational Highlights',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '• 86% of orders delivered within target time window\n'
                            '• Top requested produce item: புதினா (Mint)\n'
                            '• Highest volume item: தக்காளி (50 Kg dispatched)\n'
                            '• Zero payment disputes (100% Cash on Delivery reconciliation)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
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
                child: DarkOutlineButton(
                  label: 'Download Report',
                  icon: Icons.download_rounded,
                  onPressed: onDownloadReport,
                ),
              ),
            ),

            const StepFooterBadge(
              number: '12',
              title: 'Reports (Orders, Stock & Requests)',
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportMetricCard extends StatelessWidget {
  final String number;
  final String label;
  final Color accentColor;

  const _ReportMetricCard({
    required this.number,
    required this.label,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
