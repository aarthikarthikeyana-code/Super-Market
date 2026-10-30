import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class Admin11DeliveryTracking extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onOpenReports;

  const Admin11DeliveryTracking({
    super.key,
    required this.onBack,
    required this.onOpenReports,
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
              title: 'Live Tracking',
              onBack: onBack,
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: Column(
                  children: [
                    // Mock Map View Card with Vector Route
                    Container(
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        color: const Color(0xFF132219),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.surfaceBorder, width: 1.2),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(double.infinity, 180),
                            painter: _MapRoutePainter(),
                          ),
                          // Moving Scooter marker
                          Positioned(
                            top: 60,
                            right: 90,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.accentCoral,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accentCoral.withOpacity(0.5),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.two_wheeler_rounded, size: 18, color: Colors.white),
                            ),
                          ),
                          // Destination Pin
                          Positioned(
                            bottom: 30,
                            left: 50,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryGreen,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.home_rounded, size: 14, color: Colors.black),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Customer',
                                    style: TextStyle(fontSize: 9, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status Timeline Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.surfaceBorder, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TimelineItem(
                            isDone: true,
                            isActive: false,
                            title: 'Packed',
                            time: '11:20 AM',
                            isLast: false,
                          ),
                          _TimelineItem(
                            isDone: true,
                            isActive: true,
                            title: 'Out for Delivery',
                            time: '01:10 PM',
                            isLast: false,
                          ),
                          _TimelineItem(
                            isDone: false,
                            isActive: false,
                            title: 'Delivered',
                            time: 'Pending',
                            isLast: true,
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
                child: CoralButton(
                  label: 'View Reports & Analytics',
                  onPressed: onOpenReports,
                ),
              ),
            ),

            const StepFooterBadge(
              number: '11',
              title: 'Delivery Tracking (Admin View)',
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final bool isDone;
  final bool isActive;
  final String title;
  final String time;
  final bool isLast;

  const _TimelineItem({
    required this.isDone,
    required this.isActive,
    required this.title,
    required this.time,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? AppColors.primaryGreen
                    : (isDone ? AppColors.primaryGreenDark : AppColors.surfaceLight),
                border: Border.all(
                  color: isDone ? AppColors.primaryGreen : AppColors.surfaceBorder,
                  width: 1.5,
                ),
              ),
              child: Icon(
                isDone ? Icons.check : Icons.circle,
                size: 12,
                color: isDone ? Colors.black : AppColors.textMuted,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: isDone ? AppColors.primaryGreen : AppColors.surfaceBorder,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                  color: isActive ? AppColors.primaryGreenLight : Colors.white,
                ),
              ),
              Text(
                time,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
              if (!isLast) const SizedBox(height: 18),
            ],
          ),
        ),
      ],
    );
  }
}

class _MapRoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = const Color(0xFF1E3A28)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final routePaint = Paint()
      ..color = AppColors.primaryGreen
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.8, size.height * 0.2);
    path.cubicTo(
      size.width * 0.6,
      size.height * 0.3,
      size.width * 0.7,
      size.height * 0.7,
      size.width * 0.2,
      size.height * 0.8,
    );

    canvas.drawPath(path, roadPaint);
    canvas.drawPath(path, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
