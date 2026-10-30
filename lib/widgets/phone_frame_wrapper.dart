import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class PhoneFrameWrapper extends StatelessWidget {
  final Widget child;
  final AppState appState;

  const PhoneFrameWrapper({
    super.key,
    required this.child,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    if (appState.viewMode == AppViewMode.fullScreen) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _buildControlBar(context),
            Expanded(child: child),
          ],
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    return Scaffold(
      backgroundColor: const Color(0xFF060B08),
      body: SafeArea(
        child: Column(
          children: [
            // Top Master Header (Matching image banner)
            _buildControlBar(context),

            // Main Display Area
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Phone Chassis Container
                      Container(
                        width: isDesktop ? 390 : double.infinity,
                        height: isDesktop ? 780 : MediaQuery.of(context).size.height * 0.85,
                        margin: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 20 : 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(44),
                          border: Border.all(
                            color: const Color(0xFF334B3C),
                            width: 3.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGreen.withOpacity(0.12),
                              blurRadius: 40,
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.8),
                              blurRadius: 30,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            // Mobile Screen Content
                            Positioned.fill(
                              child: child,
                            ),

                            // Phone Bezel Top Speaker / Dynamic Island
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 34,
                                padding: const EdgeInsets.symmetric(horizontal: 22),
                                color: Colors.transparent,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '9:41',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    // Notch / Dynamic Island
                                    Container(
                                      width: 90,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFF1E2F24),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            margin: const EdgeInsets.only(right: 8),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF0F3D24),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Status icons
                                    Row(
                                      children: const [
                                        Icon(Icons.signal_cellular_alt_rounded, size: 14, color: Colors.white),
                                        SizedBox(width: 4),
                                        Icon(Icons.wifi_rounded, size: 14, color: Colors.white),
                                        SizedBox(width: 4),
                                        Icon(Icons.battery_full_rounded, size: 15, color: Colors.white),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Home Indicator Bar at bottom
                            Positioned(
                              bottom: 6,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  width: 120,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlBar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0A140E),
        border: Border(
          bottom: BorderSide(color: Color(0xFF1F382A), width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Badge 1 Customer Flow
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.accentCoral,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '1',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CUSTOMER APP FLOW',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Browse • Search • Add to Cart • Order • COD • Track',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.primaryGreenLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Prev Button
              IconButton(
                tooltip: 'Previous Screen',
                icon: const Icon(Icons.arrow_back_ios_rounded, size: 16),
                color: appState.currentStepIndex > 0 ? Colors.white : AppColors.textMuted,
                onPressed: appState.currentStepIndex > 0 ? appState.previousStep : null,
              ),

              // Screen counter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surfaceBorder, width: 1),
                ),
                child: Text(
                  '${appState.currentStepIndex + 1} / 14',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentCoral,
                  ),
                ),
              ),

              // Next Button
              IconButton(
                tooltip: 'Next Screen',
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                color: appState.currentStepIndex < 13 ? Colors.white : AppColors.textMuted,
                onPressed: appState.currentStepIndex < 13 ? appState.nextStep : null,
              ),

              // Toggle Frame mode
              IconButton(
                tooltip: appState.viewMode == AppViewMode.phoneFrame
                    ? 'Switch to Full Screen'
                    : 'Switch to Phone Mockup',
                icon: Icon(
                  appState.viewMode == AppViewMode.phoneFrame
                      ? Icons.fullscreen_rounded
                      : Icons.phone_iphone_rounded,
                  size: 20,
                  color: AppColors.primaryGreenLight,
                ),
                onPressed: appState.toggleViewMode,
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Flow Stepper Horizontal Bar
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: AppState.flowMetadata.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final isSelected = index == appState.currentStepIndex;
                final meta = AppState.flowMetadata[index];

                return GestureDetector(
                  onTap: () => appState.goToStep(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryGreenDark
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryGreen
                            : AppColors.surfaceBorder,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          meta['number']!,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppColors.accentCoral,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          meta['title']!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
