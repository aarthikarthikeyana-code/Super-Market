import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_widgets.dart';
import '../widgets/veg_illustrations.dart';

class Screen14OrderTracking extends StatelessWidget {
  final CustomerOrder? order;
  final VoidCallback onBack;
  final VoidCallback onHome;

  const Screen14OrderTracking({
    super.key,
    required this.order,
    required this.onBack,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    const steps = [
      {'title': 'Preparing', 'done': true, 'active': false},
      {'title': 'Packed', 'done': true, 'active': false},
      {'title': 'Out for\nDelivery', 'done': true, 'active': true},
      {'title': 'Delivered', 'done': false, 'active': false},
    ];

    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            // App Bar
            DarkAppBar(
              title: 'Order Tracking',
              onBack: onBack,
              actions: [
                IconButton(
                  icon: const Icon(Icons.help_outline_rounded, color: Colors.white, size: 20),
                  onPressed: () {},
                ),
              ],
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: Column(
                  children: [
                    // Stepper Row
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.surfaceBorder, width: 1),
                      ),
                      child: Row(
                        children: List.generate(steps.length, (index) {
                          final step = steps[index];
                          final isDone = step['done'] as bool;
                          final isActive = step['active'] as bool;
                          final isLast = index == steps.length - 1;

                          return Expanded(
                            child: Row(
                              children: [
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isActive
                                            ? AppColors.primaryGreen
                                            : (isDone
                                                ? AppColors.primaryGreenDark
                                                : AppColors.surfaceLight),
                                        boxShadow: isActive
                                            ? [
                                                BoxShadow(
                                                  color: AppColors.primaryGreen.withOpacity(0.5),
                                                  blurRadius: 8,
                                                  spreadRadius: 2,
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Icon(
                                        isDone ? Icons.check : Icons.circle,
                                        size: isDone ? 16 : 8,
                                        color: isDone ? Colors.white : AppColors.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      step['title'] as String,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                                        color: isActive ? Colors.white : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                if (!isLast)
                                  Expanded(
                                    child: Container(
                                      height: 2,
                                      color: isDone
                                          ? AppColors.primaryGreen
                                          : AppColors.surfaceBorder,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Scooter Delivery Illustration Hero Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
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
                        border: Border.all(
                          color: AppColors.surfaceBorderLight,
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Left: Scooter Hero Image
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.surfaceBorder, width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.asset(
                              'assets/images/delivery_scooter_hero.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const ScooterDeliveryIllustration(width: 120, height: 100),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Right: Out for Delivery + Status + Estimated Time
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Out for Delivery',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Your order is on the way!',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: AppColors.primaryGreenLight,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.surfaceBorder, width: 1),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Estimated Delivery',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 9.5,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Today, 04:00 PM - 06:00 PM',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Delivery Details Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.surfaceBorder, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Order Reference',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                order?.id ?? '#ORD124578',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGreenLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(color: AppColors.surfaceBorder, height: 1),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                color: AppColors.primaryGreenLight,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  order?.address.formatted ??
                                      '123, Green Street, Chennai - 600023',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.payment_rounded,
                                color: AppColors.primaryGreenLight,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Payment: Cash on Delivery (₹${order?.totalAmount.toInt() ?? 82})',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: DarkOutlineButton(
                        label: 'Back to Home',
                        icon: Icons.home_rounded,
                        onPressed: onHome,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            const StepFooterBadge(
              number: '14',
              title: 'Order Tracking (Real-time Status)',
            ),
          ],
        ),
      ),
    );
  }
}
