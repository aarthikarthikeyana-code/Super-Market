import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class Admin01Login extends StatefulWidget {
  final Function(String, String) onLogin;

  const Admin01Login({
    super.key,
    required this.onLogin,
  });

  @override
  State<Admin01Login> createState() => _Admin01LoginState();
}

class _Admin01LoginState extends State<Admin01Login> {
  final TextEditingController _idController = TextEditingController(text: 'admin');
  final TextEditingController _passController = TextEditingController(text: '••••••••');

  @override
  void dispose() {
    _idController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF14241B),
            Color(0xFF09120D),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              // Admin Shield / Store Logo Icon
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.primaryGreen, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreen.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: AppColors.primaryGreenLight,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Admin Portal',
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sign in to continue',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 36),

              // Admin ID field
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceBorder, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, color: AppColors.primaryGreen, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _idController,
                        style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Admin ID',
                          hintStyle: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Password field
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceBorder, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline_rounded, color: AppColors.primaryGreen, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _passController,
                        obscureText: true,
                        style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Password',
                          hintStyle: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Login Button
              SizedBox(
                width: double.infinity,
                child: CoralButton(
                  label: 'Login',
                  showArrow: false,
                  onPressed: () => widget.onLogin(_idController.text, _passController.text),
                ),
              ),

              const Spacer(),
              const StepFooterBadge(
                number: '01',
                title: 'Admin Login',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
