import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/customer_theme.dart';

// Brand Logo & Tagline Header for Customer App
class CustomerBrandLogo extends StatelessWidget {
  final double iconSize;
  final bool showTagline;

  const CustomerBrandLogo({
    super.key,
    this.iconSize = 28,
    this.showTagline = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: NummaCustomerColors.darkGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.shopping_cart_rounded,
                color: Colors.white,
                size: iconSize * 0.7,
              ),
            ),
            const SizedBox(width: 8),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'AGARAM',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: iconSize * 0.85,
                      fontWeight: FontWeight.w800,
                      color: NummaCustomerColors.darkGreen,
                    ),
                  ),
                  TextSpan(
                    text: ' Supermarket',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: iconSize * 0.72,
                      fontWeight: FontWeight.w800,
                      color: NummaCustomerColors.orangeAccent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (showTagline) ...[
          const SizedBox(height: 4),
          Text(
            'Fresh Groceries',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: NummaCustomerColors.darkGreen,
            ),
          ),
          Text(
            'For a Better Tomorrow',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: NummaCustomerColors.secondaryText,
            ),
          ),
        ],
      ],
    );
  }
}

// Reusable Customer Top App Bar
class CustomerAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBack;
  final Widget? leading;
  final List<Widget>? actions;

  const CustomerAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.onBack,
    this.leading,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            if (leading != null)
              leading!
            else if (showBackButton)
              GestureDetector(
                onTap: onBack ?? () => Navigator.of(context).maybePop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: NummaCustomerColors.border, width: 1),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 14,
                    color: NummaCustomerColors.darkText,
                  ),
                ),
              )
            else
              const SizedBox(width: 4),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: NummaCustomerColors.darkText,
                ),
              ),
            ),
            if (actions != null) ...actions!,
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(54);
}

// Primary Green CTA Button
class CustomerPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isLoading;

  const CustomerPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: NummaCustomerColors.darkGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Product Thumbnail
class CustomerProductImage extends StatelessWidget {
  final String imageUrl;
  final double size;
  final double? width;
  final double? height;
  final BorderRadiusGeometry radius;

  const CustomerProductImage({
    super.key,
    required this.imageUrl,
    this.size = 60,
    this.width,
    this.height,
    this.radius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    final w = width ?? size;
    final h = height ?? size;

    if (imageUrl.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          imageUrl,
          width: w,
          height: h,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(w, h),
        ),
      );
    }

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        border: Border.all(color: NummaCustomerColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        imageUrl,
        width: w,
        height: h,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(w, h),
      ),
    );
  }

  Widget _buildPlaceholder(double w, double h) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: NummaCustomerColors.lightGreen,
        borderRadius: radius,
      ),
      child: const Center(
        child: Icon(
          Icons.shopping_bag_outlined,
          color: NummaCustomerColors.darkGreen,
          size: 24,
        ),
      ),
    );
  }
}

// Decorative Bottom Grocery Leaves/Elements
class CustomerBottomGroceryArt extends StatelessWidget {
  const CustomerBottomGroceryArt({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.eco, size: 16, color: NummaCustomerColors.secondaryGreen),
            const SizedBox(width: 6),
            Text(
              'Good Food  •  Happy Homes ❤️',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: NummaCustomerColors.secondaryText,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.eco, size: 16, color: NummaCustomerColors.secondaryGreen),
          ],
        ),
      ),
    );
  }
}

