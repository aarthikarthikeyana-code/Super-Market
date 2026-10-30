import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_widgets.dart';
import '../widgets/veg_illustrations.dart';

class Screen01Splash extends StatelessWidget {
  final VoidCallback onGetStarted;

  const Screen01Splash({
    super.key,
    required this.onGetStarted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0F2217),
            Color(0xFF07120C),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Subtle background leafy decorative circles
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGreen.withOpacity(0.06),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Golden Script Brand Header
                  Text(
                    'Good Food\nBrighter Days',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      color: AppColors.goldAccent,
                      height: 1.1,
                      shadows: [
                        Shadow(
                          color: AppColors.goldAccent.withOpacity(0.4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Farm Fresh Harvest Basket Visual
                  Container(
                    height: 180,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF264C35), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGreen.withOpacity(0.25),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.7),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/images/splash_harvest_basket.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const HarvestBasketIllustration(height: 155),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.35),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Headings
                  Text(
                    'Fresh Groceries',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'for a Healthier Tomorrow',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // CTA Button
                  SizedBox(
                    width: double.infinity,
                    child: CoralButton(
                      label: 'Get Started',
                      onPressed: onGetStarted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const StepFooterBadge(
                    number: '01',
                    title: 'Splash / Welcome',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
