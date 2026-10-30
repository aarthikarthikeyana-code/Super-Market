import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/customer_theme.dart';
import '../widgets/customer_common_widgets.dart';

class Customer03OtpScreen extends StatefulWidget {
  final VoidCallback onVerifySuccess;
  final VoidCallback? onBack;

  const Customer03OtpScreen({
    super.key,
    required this.onVerifySuccess,
    this.onBack,
  });

  @override
  State<Customer03OtpScreen> createState() => _Customer03OtpScreenState();
}

class _Customer03OtpScreenState extends State<Customer03OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (i) => TextEditingController(text: '${i + 1}'));

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
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
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
                ),
              ),
              const SizedBox(height: 12),

              // Header icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: NummaCustomerColors.lightGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: NummaCustomerColors.darkGreen,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),

              // Title & Text
              Text(
                'Enter OTP',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: NummaCustomerColors.darkText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'We have sent a 6-digit code to\n+91 98765 43210',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: NummaCustomerColors.secondaryText,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              // Six OTP Input Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return Container(
                    width: 44,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: index < 4 ? NummaCustomerColors.darkGreen : NummaCustomerColors.border,
                        width: index < 4 ? 1.5 : 1.0,
                      ),
                      boxShadow: NummaCustomerColors.lightShadow,
                    ),
                    alignment: Alignment.center,
                    child: TextField(
                      controller: _controllers[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: NummaCustomerColors.darkText,
                      ),
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // Resend OTP timer
              Text(
                'Resend OTP in 00:28',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: NummaCustomerColors.secondaryText,
                ),
              ),
              const SizedBox(height: 28),

              // Verify CTA
              CustomerPrimaryButton(
                text: 'Verify & Continue',
                onPressed: widget.onVerifySuccess,
              ),
              const SizedBox(height: 24),
              const CustomerBottomGroceryArt(),
            ],
          ),
        ),
      ),
    );
  }
}

