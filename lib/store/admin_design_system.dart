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

/// Lightweight surfaces for lists; no scrolling blur layers.
class AdminCanvas extends StatelessWidget {
  final Widget child;
  const AdminCanvas({super.key, required this.child});
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFE8F7EE),
          opsBaseCream,
          opsWarmWhite,
          Color(0xFFE8F7EE),
        ],
        stops: [0, .24, .78, 1],
      ),
    ),
    child: child,
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
    final danger = [
      'cancel',
      'out of stock',
      'inactive',
      'attempt',
      'review',
    ].any(lower.contains);
    final warning = [
      'new',
      'pending',
      'low stock',
      'unassigned',
      'onboarding',
      'cod',
      'awaiting',
    ].any(lower.contains);
    final blue = [
      'prepar',
      'packed',
      'assigned',
      'delivery',
      'on the way',
    ].any(lower.contains);
    final foreground = danger
        ? opsRed
        : warning
        ? opsWarning
        : blue
        ? opsInfo
        : opsForestGreen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: danger
            ? opsRedBg
            : warning
            ? opsWarningBg
            : blue
            ? opsInfoBg
            : opsMint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        softWrap: true,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
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
    color: Colors.white.withValues(alpha: .94),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: opsBorder),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AdminIcon(icon, color: color, background: background, size: 36),
                const Spacer(),
                const Icon(Icons.north_east, size: 14, color: opsLightMuted),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            if (detail != null) ...[
              const SizedBox(height: 4),
              Text(
                detail!,
                style: const TextStyle(fontSize: 11, color: opsMuted),
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
    color: background,
    borderRadius: BorderRadius.circular(18),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 21, color: color),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: opsInk),
              maxLines: 2,
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
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: opsBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D087247),
            blurRadius: 22,
            offset: Offset(0, 6),
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
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => onSelected(item.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selected == item.$1 ? opsMint : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.$2.$1,
                          size: 21,
                          color: selected == item.$1
                              ? opsForestGreen
                              : opsMuted,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.$2.$2,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: selected == item.$1
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: selected == item.$1
                                ? opsForestGreen
                                : opsMuted,
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

/// A quiet decorative header; operational values stay in the widgets below it.
class AdminWorkflowBanner extends StatelessWidget {
  final String title, subtitle;
  const AdminWorkflowBanner({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/admin-dashboard-banner.png',
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
              excludeFromSemantics: true,
              errorBuilder: (_, error, stackTrace) =>
                  const ColoredBox(color: opsMint),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    opsMint,
                    opsMint.withValues(alpha: .94),
                    opsMint.withValues(alpha: .05),
                  ],
                  stops: const [0, .62, 1],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FractionallySizedBox(
              widthFactor: .67,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: opsForestGreen,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.5,
                      color: opsInk,
                    ),
                  ),
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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.shortId,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Flexible(child: AdminStatusBadge(order.status)),
                  const Icon(Icons.chevron_right, size: 18, color: opsMuted),
                ],
              ),
              const SizedBox(height: 4),
              if (date != null)
                Text(
                  '${date.day}/${date.month}/${date.year} · ${TimeOfDay.fromDateTime(date).format(context)}',
                  style: const TextStyle(fontSize: 10, color: opsMuted),
                ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (order.items.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 48,
                        height: 52,
                        child: ProductPhoto(
                          '${order.items.first['image_url'] ?? ''}',
                          height: 52,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${order.data['customer_name'] ?? ''}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          order.items
                              .map(
                                (i) => '${productLabel(i)} × ${i['quantity']}',
                              )
                              .join(', '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: opsMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: opsMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${order.items.length} product lines · ${person?['name'] ?? (cancelled ? 'Closed' : 'Unassigned')}',
                      style: const TextStyle(fontSize: 11, color: opsMuted),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      money(order.total),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      cash,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 11,
                        color: opsForestGreen,
                      ),
                    ),
                  ),
                ],
              ),
              if (actionLabel != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        order.nextAction,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: opsMuted),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: FilledButton.tonal(
                        onPressed: onAction,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(44, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: Text(
                          actionLabel!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
