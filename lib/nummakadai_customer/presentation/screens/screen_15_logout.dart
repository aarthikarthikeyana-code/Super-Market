import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/customer_theme.dart';
import '../widgets/customer_common_widgets.dart';

class Customer15LogoutScreen extends StatelessWidget {
  final VoidCallback onLoginAgain;

  const Customer15LogoutScreen({super.key, required this.onLoginAgain});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NummaCustomerColors.creamBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 10),

              // Center: NummaKadai logo & Fresh Groceries
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CustomerBrandLogo(iconSize: 36),
                  const SizedBox(height: 24),
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: NummaCustomerColors.lightShadow,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/images/splash_harvest_basket.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: NummaCustomerColors.lightGreen),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Logged out successfully',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: NummaCustomerColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Thank you for shopping at AGARAM Supermarket!\nWe look forward to serving you again.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: NummaCustomerColors.secondaryText,
                      height: 1.4,
                    ),
                  ),
                ],
              ),

              // Bottom phrase & action
              Column(
                children: [
                  CustomerPrimaryButton(
                    text: 'Sign In Again',
                    onPressed: onLoginAgain,
                  ),
                  const SizedBox(height: 14),
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

