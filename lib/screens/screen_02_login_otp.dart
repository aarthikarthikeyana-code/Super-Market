import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_widgets.dart';

class Screen02LoginOtp extends StatefulWidget {
  final VoidCallback onContinue;

  const Screen02LoginOtp({
    super.key,
    required this.onContinue,
  });

  @override
  State<Screen02LoginOtp> createState() => _Screen02LoginOtpState();
}

class _Screen02LoginOtpState extends State<Screen02LoginOtp> {
  final TextEditingController _phoneController =
      TextEditingController(text: '98765 43210');
  final List<TextEditingController> _otpControllers = [
    TextEditingController(text: '4'),
    TextEditingController(text: '3'),
    TextEditingController(text: '2'),
    TextEditingController(text: '1'),
  ];
  bool _otpSent = true;

  @override
  void dispose() {
    _phoneController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Botanical leafy wallpaper background with dark overlay
          Opacity(
            opacity: 0.28,
            child: Image.asset(
              'assets/images/botanical_dark_bg.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF09160E).withOpacity(0.85),
                  const Color(0xFF060D08).withOpacity(0.95),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
              // Leafy ambient icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceLight,
                  border: Border.all(color: AppColors.surfaceBorder, width: 1.5),
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  color: AppColors.primaryGreen,
                  size: 30,
                ),
              ),
              const SizedBox(height: 24),
              // Heading
              Text(
                'Welcome',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Login or Create Account',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),

              // Phone Number Input Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.surfaceBorderLight, width: 1.2),
                ),
                child: Row(
                  children: [
                    Text(
                      '+91',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryGreenLight,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 20,
                      width: 1,
                      color: AppColors.surfaceBorderLight,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Enter Mobile Number',
                          hintStyle: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primaryGreen,
                      size: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Send OTP Button
              SizedBox(
                width: double.infinity,
                child: CoralButton(
                  label: _otpSent ? 'Resend OTP' : 'Send OTP',
                  showArrow: false,
                  height: 48,
                  onPressed: () {
                    setState(() {
                      _otpSent = true;
                    });
                  },
                ),
              ),

              if (_otpSent) ...[
                const SizedBox(height: 28),
                Text(
                  'Enter 4-Digit Verification Code',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                // OTP Input Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    return Container(
                      width: 48,
                      height: 52,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primaryGreen.withOpacity(0.8),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _otpControllers[index].text,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                // Continue with OTP Button
                SizedBox(
                  width: double.infinity,
                  child: EmeraldButton(
                    label: 'Continue with OTP',
                    icon: Icons.lock_open_rounded,
                    onPressed: widget.onContinue,
                  ),
                ),
              ],

              const Spacer(),
              const StepFooterBadge(
                number: '02',
                title: 'Login / Register with OTP',
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
