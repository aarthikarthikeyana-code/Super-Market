import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

import 'models.dart';
import 'widgets.dart';

const opsBaseCream = Color(0xFFF6FAF8);
const opsWarmWhite = Color(0xFFFFFFFF);
const opsMint = Color(0xFFE8F7EE);
const opsGlassMint = Color(0xFFDDF2E5);
const opsPaleSage = Color(0xFFDDF2E5);
const opsGreen = Color(0xFF10B981);
const opsForestGreen = Color(0xFF047857);
const opsDeepGreen = Color(0xFF064E3B);
const opsBorder = Color(0xFFE2EBE5);
const opsGlassBorder = Color(0xCCFFFFFF);
const opsInk = Color(0xFF0F172A);
const opsMuted = Color(0xFF64748B);
const opsLightMuted = Color(0xFF94A3B8);
const opsWarning = Color(0xFFD97706);
const opsWarningBg = Color(0xFFFEF3C7);
const opsRed = Color(0xFFE11D48);
const opsRedBg = Color(0xFFFFE4E6);
const opsSuccess = opsGreen;
const opsSuccessBg = opsMint;
const opsInfo = Color(0xFF2563EB);
const opsInfoBg = Color(0xFFEFF6FF);

String opsMoney(dynamic value) => value == null ? '—' : money(amount(value));

String opsTime(dynamic value) {
  final date = DateTime.tryParse('$value')?.toLocal();
  if (date == null) return 'Time not recorded';
  return '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

ThemeData operationsTheme() {
  final base = storeTheme();
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: opsBorder),
  );
  return base.copyWith(
    scaffoldBackgroundColor: opsBaseCream,
    colorScheme: ColorScheme.fromSeed(seedColor: opsGreen).copyWith(
      primary: opsForestGreen,
      surface: opsWarmWhite,
      onSurface: opsInk,
    ),
    textTheme: base.textTheme
        .copyWith(
          headlineLarge: const TextStyle(
            fontFamily: 'NotoSansTamil',
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
          headlineMedium: const TextStyle(
            fontFamily: 'NotoSansTamil',
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
          headlineSmall: const TextStyle(
            fontFamily: 'NotoSansTamil',
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
          titleLarge: const TextStyle(
            fontFamily: 'NotoSansTamil',
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
          titleMedium: const TextStyle(
            fontFamily: 'NotoSansTamil',
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: const TextStyle(
            fontFamily: 'NotoSansTamil',
            fontSize: 14,
            color: opsInk,
            height: 1.45,
          ),
          bodyMedium: const TextStyle(
            fontFamily: 'NotoSansTamil',
            fontSize: 13,
            color: opsInk,
            height: 1.4,
          ),
          bodySmall: const TextStyle(
            fontFamily: 'NotoSansTamil',
            fontSize: 11,
            color: opsMuted,
            height: 1.4,
          ),
        )
        .apply(fontFamily: 'NotoSansTamil'),
    appBarTheme: const AppBarTheme(
      backgroundColor: opsBaseCream,
      foregroundColor: opsInk,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 58,
      titleTextStyle: TextStyle(
        fontFamily: 'NotoSansTamil',
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: opsInk,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: opsBorder),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: opsGreen, width: 1.5),
      ),
      hintStyle: const TextStyle(
        fontFamily: 'NotoSansTamil',
        fontSize: 13,
        color: opsMuted,
      ),
      labelStyle: const TextStyle(
        fontFamily: 'NotoSansTamil',
        fontSize: 13,
        color: opsMuted,
      ),
      helperStyle: const TextStyle(
        fontFamily: 'NotoSansTamil',
        fontSize: 11,
        color: opsMuted,
      ),
      helperMaxLines: 3,
      errorMaxLines: 3,
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: Colors.white,
      selectedColor: opsGlassMint,
      side: const BorderSide(color: opsBorder),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      labelStyle: const TextStyle(
        fontFamily: 'NotoSansTamil',
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: opsInk,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: opsForestGreen,
        foregroundColor: Colors.white,
        minimumSize: const Size(44, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        textStyle: const TextStyle(
          fontFamily: 'NotoSansTamil',
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: opsForestGreen,
        side: const BorderSide(color: opsBorder),
        minimumSize: const Size(44, 44),
        textStyle: const TextStyle(
          fontFamily: 'NotoSansTamil',
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      dense: true,
      minVerticalPadding: 10,
      titleTextStyle: TextStyle(
        fontFamily: 'NotoSansTamil',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: opsInk,
      ),
      subtitleTextStyle: TextStyle(
        fontFamily: 'NotoSansTamil',
        fontSize: 11,
        color: opsMuted,
      ),
    ),
    dividerTheme: const DividerThemeData(color: opsBorder, thickness: .7),
  );
}

/// Modern Ambient Operations Canvas with gentle radial auroras.
class AdminCanvas extends StatelessWidget {
  final Widget child;
  const AdminCanvas({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF7FBF8),
                Color(0xFFFAFCFA),
                Color(0xFFF3F7F5),
              ],
            ),
          ),
        ),
      ),
      Positioned(
        top: -80,
        left: -40,
        child: Container(
          width: 360,
          height: 360,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFF10B981).withOpacity(0.09),
                const Color(0xFF10B981).withOpacity(0.0),
              ],
            ),
          ),
        ),
      ),
      Positioned(
        top: 240,
        right: -60,
        child: Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFF047857).withOpacity(0.04),
                const Color(0xFF047857).withOpacity(0.0),
              ],
            ),
          ),
        ),
      ),
      child,
    ],
  );
}

class AdminIcon extends StatelessWidget {
  final IconData icon;
  final Color color, background;
  final double size;
  const AdminIcon(
    this.icon, {
    super.key,
    this.color = opsForestGreen,
    this.background = opsMint,
    this.size = 40,
  });
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(12),
    ),
    alignment: Alignment.center,
    child: Icon(icon, color: color, size: size * .5),
  );
}

class AdminStatusBadge extends StatelessWidget {
  final String label;
  const AdminStatusBadge(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    final lower = label.toLowerCase();
    final isDelivered = lower.contains('delivered') && !lower.contains('attempt');
    final isNew = lower == 'new' || lower.contains('new order');
    final isOut = lower.contains('delivery') || lower.contains('on delivery') || lower.contains('on the way');
    final isCancel = lower.contains('cancel');
    final isWarning = lower.contains('low') || lower.contains('pending') || lower.contains('awaiting');
    final isDanger = lower.contains('out of stock') || lower.contains('attempt') || isCancel;

    final Color bg = isDelivered
        ? const Color(0xFFE8F7EE)
        : isNew
        ? const Color(0xFFFEF3C7)
        : isOut
        ? const Color(0xFFE0F2FE)
        : isDanger
        ? const Color(0xFFFEE2E2)
        : isWarning
        ? const Color(0xFFFEF3C7)
        : const Color(0xFFE8F7EE);

    final Color text = isDelivered
        ? const Color(0xFF16A05D)
        : isNew
        ? const Color(0xFFD97706)
        : isOut
        ? const Color(0xFF0284C7)
        : isDanger
        ? const Color(0xFFDC2626)
        : isWarning
        ? const Color(0xFFB45309)
        : const Color(0xFF0F7645);

    final Color border = isDelivered
        ? const Color(0xFFC7EBD4)
        : isNew
        ? const Color(0xFFFDE68A)
        : isOut
        ? const Color(0xFFBAE6FD)
        : isDanger
        ? const Color(0xFFFECDD3)
        : isWarning
        ? const Color(0xFFFDE68A)
        : const Color(0xFFC7EBD4);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            softWrap: true,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: text,
            ),
          ),
          if (isDelivered) ...[
            const SizedBox(width: 3),
            const Icon(Icons.check_rounded, size: 13, color: Color(0xFF16A05D)),
          ],
        ],
      ),
    );
  }
}

class AdminToolTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color, background;
  final String? detail;
  const AdminToolTile({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.detail,
    this.color = opsForestGreen,
    this.background = opsMint,
  });
  @override
  Widget build(BuildContext context) => BouncingTap(
    onTap: onTap,
    child: Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: const BorderSide(color: Color(0xFFF1F5F3), width: 1.0),
    ),
    elevation: 0,
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.04),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.82)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.24),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: Colors.white, size: 21),
                ),
                const Spacer(),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Icon(
                    Icons.north_east_rounded,
                    size: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: 4),
              Text(
                detail!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  ),
);
}

class AdminMetricCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color, background;
  final VoidCallback? onTap;
  const AdminMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = opsForestGreen,
    this.background = opsMint,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) => BouncingTap(
    onTap: onTap,
    child: Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: const BorderSide(color: Color(0xFFF1F5F3), width: 1.0),
    ),
    elevation: 0,
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.04),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 20, color: color),
                ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 10,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.6,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ),
  ),
);
}

class AdminBottomNavigation extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;
  const AdminBottomNavigation({
    super.key,
    required this.selected,
    required this.onSelected,
  });
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.94),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.85), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withOpacity(0.08),
                  blurRadius: 28,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                for (final item in <(IconData, String)>[
                  (Icons.space_dashboard_outlined, 'Dashboard'),
                  (Icons.receipt_long_outlined, 'Orders'),
                  (Icons.inventory_2_outlined, 'Products'),
                  (Icons.route_outlined, 'Delivery'),
                  (Icons.grid_view_rounded, 'More'),
                ].indexed)
                  Expanded(
                    child: Semantics(
                      selected: selected == item.$1,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => onSelected(item.$1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: selected == item.$1
                                      ? const LinearGradient(
                                          colors: [Color(0xFF10B981), Color(0xFF047857)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  color: selected == item.$1 ? null : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: selected == item.$1
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF10B981).withOpacity(0.35),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Icon(
                                  item.$2.$1,
                                  size: 20,
                                  color: selected == item.$1
                                      ? Colors.white
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.$2.$2,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: selected == item.$1
                                      ? FontWeight.w900
                                      : FontWeight.w600,
                                  color: selected == item.$1
                                      ? const Color(0xFF0F7645)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// A decorative header with supermarket grocery box artwork and optional CTA button.
class AdminWorkflowBanner extends StatelessWidget {
  final String title, subtitle;
  final String? ctaLabel;
  final VoidCallback? onCta;
  const AdminWorkflowBanner({
    super.key,
    required this.title,
    required this.subtitle,
    this.ctaLabel,
    this.onCta,
  });

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(22),
    child: Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFBEB), // Soft warm cream
            Color(0xFFEDF8F1), // Gentle mint
            Color(0xFFD1FAE5), // Fresh light emerald
          ],
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2EBE5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF087247).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -15,
            top: -15,
            width: 170,
            child: Opacity(
              opacity: 0.95,
              child: Image.asset(
                'assets/images/admin-dashboard-banner.png',
                fit: BoxFit.contain,
                alignment: Alignment.centerRight,
                excludeFromSemantics: true,
                errorBuilder: (_, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: FractionallySizedBox(
              widthFactor: .68,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F3B25),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF475569),
                    ),
                  ),
                  if (ctaLabel != null) ...[
                    const SizedBox(height: 12),
                    NummaKadaiGradientButton(
                      compact: true,
                      onPressed: onCta,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            ctaLabel!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class AdminOrderCard extends StatelessWidget {
  final StoreOrder order;
  final VoidCallback onTap;
  final VoidCallback? onAction;
  final String? actionLabel;
  const AdminOrderCard({
    super.key,
    required this.order,
    required this.onTap,
    this.onAction,
    this.actionLabel,
  });
  @override
  Widget build(BuildContext context) {
    final person = order.data['assigned_to_details'] as Map?;
    final date = DateTime.tryParse('${order.data['created_at']}')?.toLocal();
    final cancelled = order.status == 'Cancelled';
    final cash = cancelled
        ? 'No cash due'
        : order.paymentStatus == 'cod'
        ? 'Cash due at delivery'
        : order.paymentStatus == 'collected'
        ? 'Cash collected'
        : order.paymentStatus == 'paid'
        ? 'Paid online'
        : order.paymentStatus;
    final itemsWithPhotos = order.items
        .where((i) => '${i['image_url'] ?? ''}'.isNotEmpty)
        .take(3)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2EBE5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F3B25).withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Keep the ID and status together; put the timestamp below.
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '#${order.shortId}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AdminStatusBadge(order.status),
                  ],
                ),
                if (date != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}/${date.month}/${date.year} • ${TimeOfDay.fromDateTime(date).format(context)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // Body: Product Thumbnails + Customer Name + Items list
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (itemsWithPhotos.isNotEmpty) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final item in itemsWithPhotos)
                            Container(
                              width: 38,
                              height: 44,
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: ProductPhoto(
                                '${item['image_url']}',
                                height: 38,
                                fit: BoxFit.contain,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${order.data['customer_name'] ?? 'Customer'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            order.items
                                .map(
                                  (i) =>
                                      '${productLabel(i)} × ${i['quantity']}',
                                )
                                .join(', '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Line items count and staff assignment
                Row(
                  children: [
                    const Icon(
                      Icons.people_outline_rounded,
                      size: 15,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${order.items.length} product lines • ${person?['name'] ?? (cancelled ? 'Closed' : 'Unassigned')}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 22, color: Color(0xFFF1F5F9)),

                // Keep the action inside the card width on compact screens.
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                money(order.total),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                order.status == 'New'
                                    ? 'Next: accept & prepare the items'
                                    : order.status == 'Preparing'
                                    ? 'Next: check and pack items'
                                    : order.status == 'Packed'
                                    ? 'Next: assign delivery employee'
                                    : order.nextAction,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(
                              cash,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (actionLabel != null) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: NummaKadaiGradientButton(
                          compact: true,
                          onPressed: onAction,
                          icon: Icon(
                            actionLabel!.contains('Prepare') ||
                                    actionLabel!.contains('Start')
                                ? Icons.inventory_2_outlined
                                : actionLabel!.contains('Pack')
                                ? Icons.task_alt_rounded
                                : actionLabel!.contains('Assign')
                                ? Icons.two_wheeler_rounded
                                : Icons.arrow_forward_rounded,
                            size: 15,
                            color: Colors.white,
                          ),
                          label: Text(actionLabel!),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AdminOrderProgressTracker extends StatelessWidget {
  final StoreOrder order;

  const AdminOrderProgressTracker({super.key, required this.order});

  int get _currentStepIndex {
    switch (order.status) {
      case 'New':
        return 0;
      case 'Preparing':
        return 0;
      case 'Packed':
      case 'Assigned':
        return 1;
      case 'Out for Delivery':
      case 'Delivery Attempted':
      case 'Delayed':
        return 2;
      case 'Delivered':
        return 3;
      case 'Cancelled':
        return -1;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (order.status == 'Cancelled') {
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFECDD3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFE11D48),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Cancelled',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF9F1239),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    order.data['cancellation_reason'] ?? 'No payment or cancelled by customer',
                    style: const TextStyle(fontSize: 12, color: Color(0xFFBE123C)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final currentIndex = _currentStepIndex;
    const stages = [
      ('Placed', Icons.receipt_long_rounded),
      ('Packed', Icons.inventory_2_rounded),
      ('Out for Delivery', Icons.local_shipping_rounded),
      ('Delivered', Icons.done_all_rounded),
    ];

    final shortId = order.id.length > 8
        ? '#${order.id.substring(0, 8).toUpperCase()}'
        : '#${order.id.toUpperCase()}';

    final isDelivered = order.status == 'Delivered';
    final isOut = order.status == 'Out for Delivery' || order.status == 'Delivery Attempted';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5EDE8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                shortId,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.3,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDelivered
                      ? const Color(0xFFE8F7EE)
                      : isOut
                      ? const Color(0xFFE0F2FE)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDelivered
                        ? const Color(0xFF86EFAC)
                        : isOut
                        ? const Color(0xFFBAE6FD)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      order.status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isDelivered
                            ? const Color(0xFF16A05D)
                            : isOut
                            ? const Color(0xFF0284C7)
                            : const Color(0xFF4B5563),
                      ),
                    ),
                    if (isDelivered) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.check_rounded, size: 14, color: Color(0xFF16A05D)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isDelivered
                ? 'Delivered • ${opsTime(order.data['delivered_at'] ?? order.data['updated_at'] ?? order.data['created_at'])}'
                : 'Expected • Today, ${order.data['delivery_slot'] ?? 'Regular hours'}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  Row(
                    children: [
                      for (int i = 0; i < stages.length; i++) ...[
                        _buildStepIndicator(
                          index: i,
                          currentIndex: currentIndex,
                          isLast: i == stages.length - 1,
                        ),
                        if (i < stages.length - 1)
                          Expanded(
                            child: Container(
                              height: 3,
                              color: i < currentIndex
                                  ? const Color(0xFF16A05D)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (int i = 0; i < stages.length; i++)
                        SizedBox(
                          width: constraints.maxWidth / 4.2,
                          child: Text(
                            stages[i].$1,
                            textAlign: i == 0
                                ? TextAlign.left
                                : i == stages.length - 1
                                ? TextAlign.right
                                : TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: i <= currentIndex
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: i <= currentIndex
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator({
    required int index,
    required int currentIndex,
    required bool isLast,
  }) {
    final isDone = index < currentIndex;
    final isCurrent = index == currentIndex;

    if (isDone || (isLast && isCurrent)) {
      return Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: Color(0xFF16A05D),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_rounded,
          size: 14,
          color: Colors.white,
        ),
      );
    } else if (isCurrent) {
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF16A05D), width: 3),
        ),
        child: Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF16A05D),
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    } else {
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
        ),
      );
    }
  }
}

class AdminDeliveryStatusCard extends StatelessWidget {
  final StoreOrder order;
  final VoidCallback? onCall;

  const AdminDeliveryStatusCard({
    super.key,
    required this.order,
    this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final employee = order.data['assigned_to_details'] as Map?;
    final riderName = '${employee?['name'] ?? ''}'.trim();
    final riderPhone = '${employee?['phone'] ?? ''}'.trim();
    final estimate = DateTime.tryParse(
      '${order.data['estimated_delivery_at'] ?? ''}',
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF0FDF4),
            Color(0xFFE6F7EC),
            Color(0xFFDEF2E5),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFB8E6C8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A05D).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Opacity(
              opacity: 0.12,
              child: const Icon(
                Icons.two_wheeler_rounded,
                size: 130,
                color: Color(0xFF16A05D),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.eco_rounded, size: 14, color: Color(0xFF16A05D)),
                          SizedBox(width: 4),
                          Text(
                            'Live Delivery in Progress',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A05D),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF16A05D).withOpacity(0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.moped_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  order.status,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  estimate == null
                      ? 'Arrival estimate not recorded'
                      : 'Estimated ${estimate.day}/${estimate.month} • ${TimeOfDay.fromDateTime(estimate).format(context)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD1FAE5)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFFD1FAE5),
                        child: const Icon(Icons.person_rounded, size: 18, color: Color(0xFF065F46)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              riderName.isNotEmpty
                                  ? riderName
                                  : 'Delivery employee not recorded',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              riderPhone.isNotEmpty
                                  ? riderPhone
                                  : 'Phone not recorded',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      if (riderPhone.isNotEmpty)
                        IconButton.filled(
                          onPressed: onCall,
                          icon: const Icon(Icons.phone_rounded, size: 16),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF16A05D),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



// ==========================================
// INTERACTIVE ANIMATIONS & LUXURY THEME SUITE
// ==========================================

/// Tactile spring micro-interaction for cards and buttons.
class BouncingTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;

  const BouncingTap({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.96,
  });

  @override
  State<BouncingTap> createState() => _BouncingTapState();
}

class _BouncingTapState extends State<BouncingTap> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        if (widget.onTap != null && mounted) {
          setState(() => _pressed = true);
        }
      },
      onPointerUp: (_) {
        if (_pressed && mounted) {
          setState(() => _pressed = false);
        }
      },
      onPointerCancel: (_) {
        if (_pressed && mounted) {
          setState(() => _pressed = false);
        }
      },
      child: AnimatedScale(
        scale: _pressed ? widget.scaleFactor : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Real-time pulsing sonar radar ripple for status pills.
class LivePulseBeacon extends StatefulWidget {
  final Color color;
  final String label;
  final Color backgroundColor;
  final Color borderColor;

  const LivePulseBeacon({
    super.key,
    required this.color,
    required this.label,
    required this.backgroundColor,
    required this.borderColor,
  });

  @override
  State<LivePulseBeacon> createState() => _LivePulseBeaconState();
}

class _LivePulseBeaconState extends State<LivePulseBeacon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: widget.borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: widget.color.withOpacity(0.14),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final progress = _controller.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Sonar ripple outer ring
                  Transform.scale(
                    scale: 1.0 + (progress * 1.6),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.color.withOpacity((1.0 - progress) * 0.40),
                      ),
                    ),
                  ),
                  // Central luminous core
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withOpacity(0.65),
                          blurRadius: 6,
                          spreadRadius: 1.2,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: widget.color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Smooth counting number ticker for revenue and balances.
class AnimatedCountingCurrency extends StatelessWidget {
  final dynamic value;
  final TextStyle style;

  const AnimatedCountingCurrency({
    super.key,
    required this.value,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (value == null) {
      return Text('—', style: style);
    }
    final target = value is num ? value.toDouble() : double.tryParse('$value');
    if (target == null || !target.isFinite) {
      return Text('—', style: style);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: target),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, current, _) {
        return Text(money(current), style: style);
      },
    );
  }
}

/// Executive Luxury Midnight Obsidian & Shimmering Aurora Command Hero Card.
class ExecutiveAuroraHeroCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onReports;
  final VoidCallback onCash;

  const ExecutiveAuroraHeroCard({
    super.key,
    required this.data,
    required this.onReports,
    required this.onCash,
  });

  @override
  State<ExecutiveAuroraHeroCard> createState() => _ExecutiveAuroraHeroCardState();
}

class _ExecutiveAuroraHeroCardState extends State<ExecutiveAuroraHeroCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final progress = _controller.value;
        final sweepOffset = -1.0 + (progress * 3.0);

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.32),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: const Color(0xFF0284C7).withOpacity(0.08 + (progress * 0.08)),
                blurRadius: 36,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Stack(
              children: [
                // 1. Midnight Titanium Slate Base Gradient (No heavy green!)
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0F172A), // Midnight Slate
                        Color(0xFF1E293B), // Titanium Navy
                        Color(0xFF0F2038), // Deep Cosmic Sapphire
                      ],
                    ),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.14),
                      width: 1.2,
                    ),
                  ),
                  child: _buildCardContent(context),
                ),

                // 2. Animated Ambient Aurora Orb (Top-Left Cyan Glow)
                Positioned(
                  top: -50 + (math.sin(progress * math.pi) * 20),
                  left: -40 + (math.cos(progress * math.pi) * 25),
                  child: IgnorePointer(
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF0284C7).withOpacity(0.24),
                            const Color(0xFF06B6D4).withOpacity(0.10),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. Animated Ambient Aurora Orb (Bottom-Right Indigo/Violet Glow)
                Positioned(
                  bottom: -60 - (math.sin(progress * math.pi) * 18),
                  right: -40 - (math.cos(progress * math.pi) * 20),
                  child: IgnorePointer(
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF6366F1).withOpacity(0.22),
                            const Color(0xFF8B5CF6).withOpacity(0.09),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 4. Moving Liquid Shimmer Sheen Beam
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(sweepOffset - 0.4, -1.0),
                          end: Alignment(sweepOffset + 0.4, 1.0),
                          colors: [
                            Colors.white.withOpacity(0.0),
                            Colors.white.withOpacity(0.05),
                            Colors.white.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Row: Glowing Pulse Pill + Luxury Reports Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.16),
                  width: 1,
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.auto_graph_rounded,
                    color: Color(0xFF38BDF8),
                    size: 14,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'STORE REVENUE PULSE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            BouncingTap(
              onTap: widget.onReports,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFF59E0B).withOpacity(0.28),
                      const Color(0xFFD97706).withOpacity(0.18),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withOpacity(0.55),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Reports',
                      style: TextStyle(
                        color: Color(0xFFFEF3C7),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFFFEF3C7),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Middle: Recorded Gross Revenue
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF38BDF8),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'Recorded Gross Revenue',
              style: TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        AnimatedCountingCurrency(
          value: widget.data['revenue'],
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.6,
            shadows: [
              Shadow(
                color: Color(0x66000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Bottom Splits: With Staff & Store Safe
        Row(
          children: [
            Expanded(
              child: BouncingTap(
                onTap: widget.onCash,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withOpacity(0.35),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withOpacity(0.25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.two_wheeler_rounded,
                              size: 13,
                              color: Color(0xFFFDE68A),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                              'With Staff',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(0xFFE2E8F0),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      AnimatedCountingCurrency(
                        value: widget.data['cash_with_employees'],
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: BouncingTap(
                onTap: widget.onCash,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF38BDF8).withOpacity(0.35),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF38BDF8).withOpacity(0.25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              size: 13,
                              color: Color(0xFFBAE6FD),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                              'Store Safe',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(0xFFE2E8F0),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      AnimatedCountingCurrency(
                        value: widget.data['cash_with_store'],
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}


// ==========================================
// NUMMAKADAI FRESH GROCERY ADMIN SUITE (REF THEME)
// ==========================================

/// Fresh Grocery Welcome Banner with Admin Panel badge and basket illustration.
class NummaKadaiWelcomeBanner extends StatelessWidget {
  final String adminName;
  final String dateText;
  final Widget statusBeacon;

  const NummaKadaiWelcomeBanner({
    super.key,
    required this.adminName,
    required this.dateText,
    required this.statusBeacon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF7FCF9),
            Color(0xFFEFF9F3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD1FAE5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A05D).withOpacity(0.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F7EE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Admin Panel',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F7645),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Welcome back, ${adminName.isEmpty ? 'Admin' : adminName} 👋',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  dateText,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              statusBeacon,
              const SizedBox(height: 8),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F7EE),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFC7EBD4), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text('🧺', style: TextStyle(fontSize: 22)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// NummaKadai 2x2 Metric Card with growth badge and pastel background.
class NummaKadaiStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color background;
  final Color border;
  final String? growth;
  final VoidCallback? onTap;

  const NummaKadaiStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.background,
    required this.border,
    this.growth,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BouncingTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 20, color: color),
                ),
                if (growth != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_upward_rounded, size: 11, color: color),
                        const SizedBox(width: 2),
                        Text(
                          growth!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.4,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// NummaKadai Weekly Sales Bar Chart matching Screen 2.
class NummaKadaiWeeklySalesChart extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onReports;

  const NummaKadaiWeeklySalesChart({
    super.key,
    required this.data,
    required this.onReports,
  });

  @override
  Widget build(BuildContext context) {
    final revNum = (data['revenue'] is num)
        ? (data['revenue'] as num).toDouble()
        : (double.tryParse('') ?? 600.0);

    final weights = [0.12, 0.14, 0.10, 0.18, 0.22, 0.28, 0.16];
    const maxWeight = 0.28;
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2EBE5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sales Overview',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Weekly revenue performance',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              BouncingTap(
                onTap: onReports,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F7EE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFC7EBD4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'This Week',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F7645),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Color(0xFF0F7645)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          SizedBox(
            height: 138,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int i = 0; i < 7; i++)
                  _buildBar(
                    day: dayNames[i],
                    fraction: (weights[i] / maxWeight).clamp(0.18, 1.0),
                    isPeak: weights[i] == maxWeight,
                    amount: '₹${(revNum * weights[i]).toStringAsFixed(0)}',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar({
    required String day,
    required double fraction,
    required bool isPeak,
    required String amount,
  }) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isPeak)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F7645),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  amount,
                  style: const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          Container(
            width: 22,
            height: (72 * fraction).clamp(20.0, 72.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isPeak
                    ? [const Color(0xFF10B981), const Color(0xFF047857)]
                    : [const Color(0xFF34D399), const Color(0xFF059669)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(isPeak ? 0.35 : 0.15),
                  blurRadius: isPeak ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            day,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isPeak ? FontWeight.w800 : FontWeight.w600,
              color: isPeak ? const Color(0xFF0F7645) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}


class NummaKadaiGradientButton extends StatelessWidget {
  final Widget? icon;
  final Widget label;
  final VoidCallback? onPressed;
  final double? width;
  final double height;
  final double borderRadius;
  final List<Color>? gradientColors;
  final bool compact;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;

  const NummaKadaiGradientButton({
    super.key,
    this.icon,
    required this.label,
    required this.onPressed,
    this.width,
    this.height = 48,
    this.borderRadius = 16,
    this.gradientColors,
    this.compact = false,
    this.padding,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final colors = gradientColors ?? const [Color(0xFF10B981), Color(0xFF047857)];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      height: compact ? 36 : height,
      decoration: BoxDecoration(
        gradient: enabled
            ? LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFCBD5E1), Color(0xFF94A3B8)],
              ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: colors.first.withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onPressed,
          child: Padding(
            padding: padding ??
                EdgeInsets.symmetric(
                  horizontal: compact ? 12 : 18,
                  vertical: compact ? 6 : 10,
                ),
            child: Row(
              mainAxisSize: width == null ? MainAxisSize.min : MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  IconTheme(
                    data: const IconThemeData(color: Colors.white, size: 17),
                    child: icon!,
                  ),
                  const SizedBox(width: 8),
                ],
                DefaultTextStyle(
                  style: textStyle ??
                      TextStyle(
                        fontFamily: 'NotoSansTamil',
                        fontSize: compact ? 12 : 14.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                  child: label,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
