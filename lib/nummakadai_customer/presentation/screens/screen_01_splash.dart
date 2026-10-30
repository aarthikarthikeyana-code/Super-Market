import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/customer_theme.dart';
import '../widgets/customer_common_widgets.dart';

class Customer01SplashScreen extends StatelessWidget {
  final VoidCallback onContinue;

  const Customer01SplashScreen({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NummaCustomerColors.creamBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Brand
              const CustomerBrandLogo(iconSize: 34),

              // Center Grocery Basket Hero
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 240,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: NummaCustomerColors.cardShadow,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              'assets/images/splash_harvest_basket.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                color: NummaCustomerColors.lightGreen,
                                child: const Icon(
                                  Icons.shopping_basket_rounded,
                                  size: 80,
                                  color: NummaCustomerColors.darkGreen,
                                ),
                              ),
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
                      const SizedBox(height: 24),
                      Text(
                        'Good Food  •  Happy Homes ❤️',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: NummaCustomerColors.darkGreen,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Fresh produce and authentic staples delivered at your door',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: NummaCustomerColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom CTA
              Column(
                children: [
                  CustomerPrimaryButton(
                    text: 'Get Started →',
                    onPressed: onContinue,
                  ),
                  const SizedBox(height: 12),
                  const CustomerBottomGroceryArt(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

