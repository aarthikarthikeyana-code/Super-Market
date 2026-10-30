import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_widgets.dart';

class Screen06SearchNotFound extends StatelessWidget {
  final String searchedQuery;
  final VoidCallback onRequestItem;
  final VoidCallback onCancel;

  const Screen06SearchNotFound({
    super.key,
    this.searchedQuery = 'Pothina',
    required this.onRequestItem,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0F2218),
            Color(0xFF07120C),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Header back button
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  color: Colors.white,
                  onPressed: onCancel,
                ),
              ),

              const Spacer(),

              // Magnifying Glass Search Icon Card
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  border: Border.all(
                    color: AppColors.primaryGreen.withOpacity(0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreen.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  color: AppColors.primaryGreenLight,
                  size: 42,
                ),
              ),
              const SizedBox(height: 28),

              // Title
              Text(
                'No items found',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle / Prompt
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: "We couldn't find this item '"),
                    TextSpan(
                      text: searchedQuery,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(
                      text: "'.\nDo you want to add this item to your order?",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Yes, Request Item button
              SizedBox(
                width: double.infinity,
                child: EmeraldButton(
                  label: 'Yes, Request Item',
                  icon: Icons.check_circle_outline_rounded,
                  onPressed: onRequestItem,
                ),
              ),
              const SizedBox(height: 12),

              // No, Continue button
              SizedBox(
                width: double.infinity,
                child: DarkOutlineButton(
                  label: 'No, Continue',
                  icon: Icons.close_rounded,
                  onPressed: onCancel,
                ),
              ),

              const Spacer(),

              const StepFooterBadge(
                number: '06',
                title: 'Search Not Found (Add to Order Request)',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
