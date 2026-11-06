import 'package:flutter/material.dart';

import 'models.dart';
import 'widgets.dart';

const opsBaseCream = Color(0xFFF7FAF8);
const opsWarmWhite = Color(0xFFFFFDF9);
const opsMint = Color(0xFFE8F7EE);
const opsGlassMint = Color(0xFFDDF2E5);
const opsPaleSage = Color(0xFFDDF2E5);
const opsGreen = Color(0xFF12A05B);
const opsForestGreen = Color(0xFF087247);
const opsDeepGreen = opsForestGreen;
const opsBorder = Color(0xFFDEE8E2);
const opsGlassBorder = Color(0xCCFFFFFF);
const opsInk = Color(0xFF152019);
const opsMuted = Color(0xFF68736D);
const opsLightMuted = Color(0xFF94A49B);
const opsWarning = Color(0xFF996014);
const opsWarningBg = Color(0xFFFFF3DC);
const opsRed = Color(0xFFC43B45);
const opsRedBg = Color(0xFFFFEAEA);
const opsSuccess = opsGreen;
const opsSuccessBg = opsMint;
const opsInfo = Color(0xFF2869AB);
const opsInfoBg = Color(0xFFEAF3FF);

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
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE9F8EF),
                opsBaseCream,
                opsWarmWhite,
                Color(0xFFEFF8F3),
              ],
              stops: [0, .28, .75, 1],
            ),
          ),
        ),
      ),
      Positioned(
        top: -60,
        left: -40,
        child: Container(
          width: 320,
          height: 320,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFF10B981).withOpacity(0.18),
                const Color(0xFF10B981).withOpacity(0.0),
              ],
            ),
          ),
        ),
      ),
      Positioned(
        top: 280,
        right: -50,
        child: Container(
          width: 340,
          height: 340,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFFBBF24).withOpacity(0.16),
                const Color(0xFFFBBF24).withOpacity(0.0),
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
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: Color(0xFFE2EBE5), width: 1.2),
    ),
    elevation: 0,
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              background.withOpacity(0.35),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F3B25).withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withOpacity(0.25), width: 1),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.north_east_rounded, size: 14, color: color),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: opsInk,
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: 4),
              Text(
                detail!,
                style: const TextStyle(fontSize: 11.5, color: opsMuted, height: 1.3),
              ),
            ],
          ],
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
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: color.withOpacity(0.20), width: 1.2),
    ),
    elevation: 0,
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              background.withOpacity(0.40),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.07),
              blurRadius: 16,
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.25), width: 1),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: color.withOpacity(0.45),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: -0.5,
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
                color: opsInk,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
    child: Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2EBE5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF087247).withOpacity(0.08),
            blurRadius: 24,
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: selected == item.$1
                                ? const Color(0xFFD1FAE5)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            item.$2.$1,
                            size: 21,
                            color: selected == item.$1
                                ? const Color(0xFF047857)
                                : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.$2.$2,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: selected == item.$1
                                ? FontWeight.w900
                                : FontWeight.w600,
                            color: selected == item.$1
                                ? const Color(0xFF047857)
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
                    FilledButton(
                      onPressed: onCta,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0F5132),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        minimumSize: const Size(0, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
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
                          const Icon(Icons.arrow_forward_rounded, size: 14),
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
                // Header: #ID · Date/Time · Status Pill · Chevron
                Row(
                  children: [
                    Text(
                      '#${order.shortId}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (date != null)
                      Text(
                        '${date.day}/${date.month}/${date.year} • ${TimeOfDay.fromDateTime(date).format(context)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    const Spacer(),
                    AdminStatusBadge(order.status),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: Color(0xFF94A3B8),
                    ),
                  ],
                ),
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

                // Footer: Price bold + Cash status + CTA Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
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
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          cash,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF059669),
                          ),
                        ),
                        const SizedBox(height: 5),
                        if (actionLabel != null)
                          FilledButton.icon(
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
                            ),
                            label: Text(
                              actionLabel!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF16A05D),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                      ],
                    ),
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
    final riderName = order.data['employee_name'] ?? order.data['assigned_employee_name'] ?? 'Agaram Delivery Partner';
    final riderPhone = order.data['employee_phone'] ?? '';

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
                const Text(
                  'Your order is on the way!',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Arriving soon to customer address with fresh groceries.',
                  style: TextStyle(
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
                              riderName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              riderPhone.isNotEmpty ? riderPhone : 'Assigned Rider',
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

