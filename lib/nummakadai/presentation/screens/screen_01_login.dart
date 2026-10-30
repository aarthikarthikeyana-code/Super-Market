import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/numma_theme.dart';
import '../widgets/numma_common_widgets.dart';

class Numma01LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const Numma01LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<Numma01LoginScreen> createState() => _Numma01LoginScreenState();
}

class _Numma01LoginScreenState extends State<Numma01LoginScreen> {
  final _emailController = TextEditingController(text: 'admin@agaramsupermarket.com');
  final _passwordController = TextEditingController(text: 'admin123');
  final _captchaAnswerController = TextEditingController();

  bool _rememberMe = true;
  bool _obscurePassword = true;

  late int _num1;
  late int _num2;

  @override
  void initState() {
    super.initState();
    _generateCaptcha();
  }

  void _generateCaptcha() {
    final random = Random();
    setState(() {
      _num1 = 10 + random.nextInt(90); // 10 to 99 (2 digits)
      _num2 = 10 + random.nextInt(90); // 10 to 99 (2 digits)
      _captchaAnswerController.clear();
    });
  }

  void _handleLogin() {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();
    final captchaInput = _captchaAnswerController.text.trim();

    // 1. Validate Email & Password
    final isValidEmail = email == 'admin@agaramsupermarket.com' || email == 'admin';
    final isValidPassword = password == 'admin123' ||
        password == 'admin@123' ||
        password == 'admin' ||
        password == '••••••••';

    if (!isValidEmail || !isValidPassword) {
      _showErrorDialog(
        title: 'Wrong Email or Password',
        message: 'The email address or password you entered is incorrect.\n\nDefault Credentials:\nEmail: admin@agaramsupermarket.com\nPassword: admin123',
      );
      _generateCaptcha();
      return;
    }

    // 2. Validate Math CAPTCHA
    if (captchaInput.isEmpty) {
      _showErrorDialog(
        title: 'CAPTCHA Required',
        message: 'Please calculate $_num1 + $_num2 and enter the answer to proceed.',
      );
      return;
    }

    final userAnswer = int.tryParse(captchaInput);
    final correctAnswer = _num1 + _num2;

    if (userAnswer == null || userAnswer != correctAnswer) {
      _showErrorDialog(
        title: 'Wrong CAPTCHA Answer',
        message: 'Your answer "$captchaInput" for $_num1 + $_num2 is incorrect.\n\nA new question has been generated. Please try again.',
      );
      _generateCaptcha();
      return;
    }

    // Both credentials and CAPTCHA are correct!
    widget.onLoginSuccess();
  }

  void _showErrorDialog({required String title, required String message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFFDE8E8),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, color: NummaColors.error, size: 36),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: NummaColors.textMain,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: NummaColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: NummaColors.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Try Again',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _captchaAnswerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NummaColors.creamBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              // Brand Logo & Tagline
              const NummaBrandLogo(iconSize: 32),
              const SizedBox(height: 20),

              // Hero Illustration: Grocery Basket with Fresh Produce
              Container(
                width: double.infinity,
                height: 170,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: NummaColors.cardShadow,
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/splash_harvest_basket.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: NummaColors.lightGreen,
                        child: const Icon(
                          Icons.shopping_basket_rounded,
                          size: 72,
                          color: NummaColors.primaryGreen,
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
                            NummaColors.creamBg.withOpacity(0.4),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'Admin Login',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: NummaColors.textMain,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sign in to manage inventory & orders',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: NummaColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),

              // Email Field
              Container(
                decoration: BoxDecoration(
                  color: NummaColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: NummaColors.border, width: 1),
                  boxShadow: NummaColors.cardShadow,
                ),
                child: TextField(
                  controller: _emailController,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: NummaColors.textMain),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email_outlined, color: NummaColors.textSecondary, size: 20),
                    hintText: 'admin@agaramsupermarket.com',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Password Field
              Container(
                decoration: BoxDecoration(
                  color: NummaColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: NummaColors.border, width: 1),
                  boxShadow: NummaColors.cardShadow,
                ),
                child: TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: NummaColors.textMain),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: NummaColors.textSecondary, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: NummaColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    hintText: 'Password',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Math CAPTCHA Security Card (Only 2-digit Addition: e.g. 16 + 72 = ?)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: NummaColors.lightGreenCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: NummaColors.primaryGreen.withOpacity(0.25), width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.verified_user_rounded, size: 16, color: NummaColors.primaryGreen),
                            const SizedBox(width: 6),
                            Text(
                              'Security Math CAPTCHA',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: NummaColors.darkGreen,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: _generateCaptcha,
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Row(
                              children: [
                                const Icon(Icons.refresh_rounded, size: 14, color: NummaColors.primaryGreen),
                                const SizedBox(width: 3),
                                Text(
                                  'New Question',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: NummaColors.primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Equation Display
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: NummaColors.primaryGreen.withOpacity(0.35)),
                            boxShadow: [
                              BoxShadow(
                                color: NummaColors.primaryGreen.withOpacity(0.06),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '$_num1 + $_num2 = ?',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: NummaColors.darkGreen,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Answer Input Field
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: NummaColors.border, width: 1),
                            ),
                            child: TextField(
                              controller: _captchaAnswerController,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: NummaColors.textMain,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter answer',
                                hintStyle: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: NummaColors.textMuted,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Remember Me & Forgot Password
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: _rememberMe,
                          activeColor: NummaColors.primaryGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (v) => setState(() => _rememberMe = v ?? true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Remember me',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: NummaColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                    child: Text(
                      'Forgot Password?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: NummaColors.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Primary Login Button
              SizedBox(
                width: double.infinity,
                child: NummaPrimaryButton(
                  text: 'Login',
                  onPressed: _handleLogin,
                ),
              ),
              const SizedBox(height: 16),

              // Social Logins
              _SocialLoginButton(
                icon: Icons.g_mobiledata_rounded,
                iconColor: Colors.red,
                label: 'Continue with Google',
                onPressed: _handleLogin,
              ),
              const SizedBox(height: 10),
              _SocialLoginButton(
                icon: Icons.apple_rounded,
                iconColor: Colors.black,
                label: 'Continue with Apple',
                onPressed: _handleLogin,
              ),
              const SizedBox(height: 20),

              // Help & Support
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Need Help? ',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: NummaColors.textSecondary),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      'Contact Support',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: NummaColors.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onPressed;

  const _SocialLoginButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: NummaColors.border, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor: NummaColors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: NummaColors.textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
