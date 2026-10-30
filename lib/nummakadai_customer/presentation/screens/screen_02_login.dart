import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/customer_theme.dart';
import '../widgets/customer_common_widgets.dart';

class Customer02LoginScreen extends StatefulWidget {
  final VoidCallback onContinue;

  const Customer02LoginScreen({super.key, required this.onContinue});

  @override
  State<Customer02LoginScreen> createState() => _Customer02LoginScreenState();
}

class _Customer02LoginScreenState extends State<Customer02LoginScreen> {
  final _phoneController = TextEditingController(text: '98765 43210');

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NummaCustomerColors.creamBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              // Header grocery illustration
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
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

              // Title & Subtitle
              Text(
                'Welcome Back',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: NummaCustomerColors.darkText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sign in to continue',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: NummaCustomerColors.secondaryText,
                ),
              ),
              const SizedBox(height: 24),

              // Mobile number input
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: NummaCustomerColors.border),
                  boxShadow: NummaCustomerColors.lightShadow,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      '+91',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        color: NummaCustomerColors.darkText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(height: 24, width: 1, color: NummaCustomerColors.border),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter mobile number',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            color: NummaCustomerColors.secondaryText,
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Primary Continue Button
              CustomerPrimaryButton(
                text: 'Continue',
                onPressed: widget.onContinue,
              ),
              const SizedBox(height: 20),

              // Divider "or"
              Row(
                children: [
                  const Expanded(child: Divider(color: NummaCustomerColors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'or',
                      style: GoogleFonts.plusJakartaSans(
                        color: NummaCustomerColors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: NummaCustomerColors.border)),
                ],
              ),
              const SizedBox(height: 18),

              // Social Logins
              _buildSocialButton(
                icon: Icons.g_mobiledata_rounded,
                iconColor: Colors.red,
                label: 'Continue with Google',
                onPressed: widget.onContinue,
              ),
              const SizedBox(height: 10),
              _buildSocialButton(
                icon: Icons.apple,
                iconColor: Colors.black,
                label: 'Continue with Apple',
                onPressed: widget.onContinue,
              ),
              const SizedBox(height: 24),

              // Bottom footer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'New to AGARAM Supermarket? ',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: NummaCustomerColors.secondaryText,
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onContinue,
                    child: Text(
                      'Create Account',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: NummaCustomerColors.darkGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const CustomerBottomGroceryArt(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: NummaCustomerColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: NummaCustomerColors.darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

