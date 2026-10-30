import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_widgets.dart';
import '../widgets/veg_illustrations.dart';

class Screen13OrderSuccess extends StatelessWidget {
  final String orderId;
  final VoidCallback onViewOrder;
  final VoidCallback onContinueShopping;

  const Screen13OrderSuccess({
    super.key,
    this.orderId = '#ORD124578',
    required this.onViewOrder,
    required this.onContinueShopping,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF10281C),
            Color(0xFF08120B),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // Celebratory Confetti & Green Success Check
              Stack(
                alignment: Alignment.center,
                children: [
                  const CelebrationConfetti(size: 200),
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [
                          Color(0xFF34D399),
                          Color(0xFF059669),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGreen.withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 52,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Success Message
              Text(
                'Order Placed\nSuccessfully!',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),

              // Order ID Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceBorderLight, width: 1),
                ),
                child: Text(
                  'Order ID $orderId',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryGreenLight,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Text(
                'A confirmation has been sent to your registered mobile number.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),

              const Spacer(),

              // Buttons
              SizedBox(
                width: double.infinity,
                child: CoralButton(
                  label: 'View Order',
                  showArrow: false,
                  onPressed: onViewOrder,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: DarkOutlineButton(
                  label: 'Continue Shopping',
                  onPressed: onContinueShopping,
                ),
              ),

              const SizedBox(height: 16),
              const StepFooterBadge(
                number: '13',
                title: 'Order Success',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
