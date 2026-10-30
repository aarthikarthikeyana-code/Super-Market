import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/numma_theme.dart';
import '../../data/models/numma_models.dart';

// Brand Logo & Tagline Header
class NummaBrandLogo extends StatelessWidget {
  final double iconSize;
  final bool showTagline;

  const NummaBrandLogo({
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
                color: NummaColors.primaryGreen,
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
                      color: NummaColors.primaryGreen,
                    ),
                  ),
                  TextSpan(
                    text: ' Supermarket',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: iconSize * 0.72,
                      fontWeight: FontWeight.w800,
                      color: NummaColors.orangeAccent,
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
              color: NummaColors.darkGreen,
            ),
          ),
          Text(
            'For a Better Tomorrow',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: NummaColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

// Top App Bar
class NummaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBack;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? trailing;
  final Color backgroundColor;

  const NummaAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.onBack,
    this.leading,
    this.actions,
    this.trailing,
    this.backgroundColor = Colors.transparent,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: backgroundColor,
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
                    color: NummaColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: NummaColors.border, width: 1),
                    boxShadow: NummaColors.cardShadow,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 14,
                    color: NummaColors.textMain,
                  ),
                ),
              )
            else
              const SizedBox(width: 8),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: NummaColors.textMain,
                ),
              ),
            ),
            if (actions != null)
              ...actions!
            else if (trailing != null)
              trailing!,
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}

// Search Field
class NummaSearchField extends StatelessWidget {
  final String hintText;
  final String hint;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;

  const NummaSearchField({
    super.key,
    this.hintText = 'Search products by name, category...',
    this.hint = '',
    this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveHint = hint.isNotEmpty ? hint : hintText;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: NummaColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NummaColors.border, width: 1),
        boxShadow: NummaColors.cardShadow,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: NummaColors.textMain,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 19,
            color: NummaColors.textSecondary,
          ),
          hintText: effectiveHint,
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: NummaColors.textMuted,
          ),
        ),
      ),
    );
  }
}

// Status Badges
class NummaStatusBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color text;

  const NummaStatusBadge({
    super.key,
    required this.label,
    Color? color,
    Color? backgroundColor,
    Color? bg,
    Color? text,
  })  : bg = bg ?? backgroundColor ?? const Color(0xFFEAF7EF),
        text = text ?? color ?? NummaColors.primaryGreen;

  factory NummaStatusBadge.stock(StockStatus status) {
    switch (status) {
      case StockStatus.inStock:
        return const NummaStatusBadge(
          label: 'In Stock',
          bg: Color(0xFFEAF7EF),
          text: NummaColors.success,
        );
      case StockStatus.lowStock:
        return const NummaStatusBadge(
          label: 'Low Stock',
          bg: Color(0xFFFFF6E9),
          text: NummaColors.warning,
        );
      case StockStatus.outOfStock:
        return const NummaStatusBadge(
          label: 'Out of Stock',
          bg: Color(0xFFFEEFEF),
          text: NummaColors.error,
        );
    }
  }

  factory NummaStatusBadge.order(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return const NummaStatusBadge(
          label: 'Pending',
          bg: Color(0xFFFFF6E9),
          text: NummaColors.warning,
        );
      case OrderStatus.processing:
        return const NummaStatusBadge(
          label: 'Processing',
          bg: Color(0xFFEAF2FD),
          text: NummaColors.blueProcessing,
        );
      case OrderStatus.outForDelivery:
        return const NummaStatusBadge(
          label: 'Out for Delivery',
          bg: Color(0xFFFFF3E0),
          text: NummaColors.orangeAccent,
        );
      case OrderStatus.delivered:
        return const NummaStatusBadge(
          label: 'Delivered',
          bg: Color(0xFFEAF7EF),
          text: NummaColors.success,
        );
      case OrderStatus.cancelled:
        return const NummaStatusBadge(
          label: 'Cancelled',
          bg: Color(0xFFFEEFEF),
          text: NummaColors.error,
        );
    }
  }

  factory NummaStatusBadge.customer(CustomerType type) {
    switch (type) {
      case CustomerType.regular:
        return const NummaStatusBadge(
          label: 'Regular',
          bg: Color(0xFFEAF7EF),
          text: NummaColors.primaryGreen,
        );
      case CustomerType.newCustomer:
        return const NummaStatusBadge(
          label: 'New',
          bg: Color(0xFFEAF2FD),
          text: NummaColors.blueProcessing,
        );
      case CustomerType.premium:
        return const NummaStatusBadge(
          label: 'Premium',
          bg: Color(0xFFFFF6E9),
          text: NummaColors.orangeAccent,
        );
      case CustomerType.inactive:
        return const NummaStatusBadge(
          label: 'Inactive',
          bg: Color(0xFFF3F4F6),
          text: NummaColors.textSecondary,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: text,
        ),
      ),
    );
  }
}

// Primary Green Button
class NummaPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isLoading;

  const NummaPrimaryButton({
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
          backgroundColor: NummaColors.primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
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

// Product Image Thumbnail
class NummaProductImage extends StatelessWidget {
  final String imageUrl;
  final double size;
  final double? width;
  final double? height;
  final BorderRadiusGeometry radius;

  const NummaProductImage({
    super.key,
    required this.imageUrl,
    this.size = 64,
    this.width,
    this.height,
    this.radius = const BorderRadius.all(Radius.circular(10)),
  });

  @override
  Widget build(BuildContext context) {
    final w = width ?? size;
    final h = height ?? size;

    Widget placeholder() {
      return Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: NummaColors.lightGreen,
          borderRadius: radius,
        ),
        child: const Center(
          child: Icon(
            Icons.shopping_bag_outlined,
            color: NummaColors.primaryGreen,
            size: 24,
          ),
        ),
      );
    }

    if (imageUrl.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          imageUrl,
          width: w,
          height: h,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => placeholder(),
        ),
      );
    }

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: NummaColors.white,
        borderRadius: radius,
        border: Border.all(color: NummaColors.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        imageUrl,
        width: w,
        height: h,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder(),
      ),
    );
  }
}
