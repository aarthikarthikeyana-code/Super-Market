import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/numma_theme.dart';
import '../widgets/numma_common_widgets.dart';

class Numma02DashboardScreen extends StatefulWidget {
  final VoidCallback onOpenProducts;
  final VoidCallback onOpenOrders;
  final VoidCallback onOpenCustomers;
  final VoidCallback onOpenReports;
  final VoidCallback onOpenSettings;
  final Function(int)? onNavigateToScreen;

  const Numma02DashboardScreen({
    super.key,
    required this.onOpenProducts,
    required this.onOpenOrders,
    required this.onOpenCustomers,
    required this.onOpenReports,
    required this.onOpenSettings,
    this.onNavigateToScreen,
  });

  @override
  State<Numma02DashboardScreen> createState() => _Numma02DashboardScreenState();
}

class _Numma02DashboardScreenState extends State<Numma02DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildAdminDrawer(context),
      backgroundColor: NummaColors.creamBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => _scaffoldKey.currentState?.openDrawer(),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: NummaColors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: NummaColors.border, width: 1),
                            boxShadow: NummaColors.cardShadow,
                          ),
                          child: const Icon(Icons.menu_rounded, size: 20, color: NummaColors.textMain),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const NummaBrandLogo(iconSize: 22, showTagline: false),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: NummaColors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: NummaColors.border, width: 1),
                      boxShadow: NummaColors.cardShadow,
                    ),
                    child: Stack(
                      children: [
                        const Icon(Icons.notifications_none_rounded, size: 20, color: NummaColors.textMain),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: NummaColors.orangeAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Welcome & Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Panel',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: NummaColors.textMain,
                        ),
                      ),
                      Text(
                        'Welcome back!',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: NummaColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tuesday, 22 Oct 2024',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: NummaColors.darkGreen,
                        ),
                      ),
                    ],
                  ),
                  // Fresh Vegetables Decorative Illustration
                  Container(
                    width: 70,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/images/vine_tomatoes_detail.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.eco_rounded,
                        color: NummaColors.primaryGreen,
                        size: 32,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 4 Statistic Cards (2x2 Grid)
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: const [
                  _DashboardStatCard(
                    title: 'Total Orders',
                    value: '152',
                    change: '+12%',
                    icon: Icons.receipt_long_rounded,
                    iconBg: Color(0xFFEAF7EF),
                    iconColor: NummaColors.primaryGreen,
                  ),
                  _DashboardStatCard(
                    title: 'Total Customers',
                    value: '1,248',
                    change: '+8%',
                    icon: Icons.people_outline_rounded,
                    iconBg: Color(0xFFEAF2FD),
                    iconColor: NummaColors.blueProcessing,
                  ),
                  _DashboardStatCard(
                    title: 'Total Products',
                    value: '432',
                    change: '+3%',
                    icon: Icons.apple_rounded,
                    iconBg: Color(0xFFFFF3E0),
                    iconColor: NummaColors.orangeAccent,
                  ),
                  _DashboardStatCard(
                    title: 'Total Sales',
                    value: '₹76,240',
                    change: '+12%',
                    icon: Icons.emoji_events_outlined,
                    iconBg: Color(0xFFFFF9E6),
                    iconColor: Color(0xFFF5A623),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Sales Overview Chart Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: NummaColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: NummaColors.border, width: 1),
                  boxShadow: NummaColors.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sales Overview',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: NummaColors.textMain,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: NummaColors.creamBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: NummaColors.border, width: 1),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'This Week',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: NummaColors.textSecondary,
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: NummaColors.textSecondary),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Bar Chart
                    SizedBox(
                      height: 150,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 40,
                          barTouchData: BarTouchData(enabled: false),
                          titlesData: FlTitlesData(
                            show: true,
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 28,
                                getTitlesWidget: (val, _) {
                                  if (val == 0) return const Text('0', style: TextStyle(fontSize: 9, color: NummaColors.textMuted));
                                  if (val == 20) return const Text('20k', style: TextStyle(fontSize: 9, color: NummaColors.textMuted));
                                  if (val == 40) return const Text('40k', style: TextStyle(fontSize: 9, color: NummaColors.textMuted));
                                  return const SizedBox();
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (val, _) {
                                  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                  if (val.toInt() >= 0 && val.toInt() < days.length) {
                                    return Text(
                                      days[val.toInt()],
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: NummaColors.textSecondary,
                                      ),
                                    );
                                  }
                                  return const SizedBox();
                                },
                              ),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 10,
                            getDrawingHorizontalLine: (val) => FlLine(
                              color: NummaColors.borderLight,
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: [
                            _makeBarGroup(0, 15),
                            _makeBarGroup(1, 22),
                            _makeBarGroup(2, 18),
                            _makeBarGroup(3, 26),
                            _makeBarGroup(4, 34),
                            _makeBarGroup(5, 38),
                            _makeBarGroup(6, 29),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Quick Actions
              Text(
                'Quick Actions',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: NummaColors.textMain,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _QuickActionTile(
                    title: 'Products',
                    icon: Icons.inventory_2_outlined,
                    color: NummaColors.primaryGreen,
                    onTap: widget.onOpenProducts,
                  ),
                  _QuickActionTile(
                    title: 'Orders',
                    icon: Icons.receipt_long_outlined,
                    color: NummaColors.orangeAccent,
                    onTap: widget.onOpenOrders,
                  ),
                  _QuickActionTile(
                    title: 'Customers',
                    icon: Icons.people_outline_rounded,
                    color: NummaColors.blueProcessing,
                    onTap: widget.onOpenCustomers,
                  ),
                  _QuickActionTile(
                    title: 'Reports',
                    icon: Icons.analytics_outlined,
                    color: const Color(0xFF8E44AD),
                    onTap: widget.onOpenReports,
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

  Widget _buildAdminDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: NummaColors.creamBg,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: NummaColors.darkGreen,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.shopping_cart_rounded, color: NummaColors.darkGreen, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'AGARAM ',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Supermarket',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: NummaColors.yellowAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Admin Management Panel',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.person, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Admin User',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'admin@agaramsupermarket.com',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Navigation Links
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                children: [
                  _drawerItem(
                    icon: Icons.dashboard_rounded,
                    title: 'Dashboard Overview',
                    isActive: true,
                    onTap: () => Navigator.pop(context),
                  ),
                  _drawerItem(
                    icon: Icons.inventory_2_rounded,
                    title: 'Products List',
                    onTap: () {
                      Navigator.pop(context);
                      widget.onOpenProducts();
                    },
                  ),
                  _drawerItem(
                    icon: Icons.add_box_rounded,
                    title: 'Add New Product',
                    onTap: () {
                      Navigator.pop(context);
                      widget.onNavigateToScreen?.call(4);
                    },
                  ),
                  _drawerItem(
                    icon: Icons.storage_rounded,
                    title: 'Inventory Management',
                    onTap: () {
                      Navigator.pop(context);
                      widget.onNavigateToScreen?.call(5);
                    },
                  ),
                  _drawerItem(
                    icon: Icons.receipt_long_rounded,
                    title: 'Orders List',
                    onTap: () {
                      Navigator.pop(context);
                      widget.onOpenOrders();
                    },
                  ),
                  _drawerItem(
                    icon: Icons.category_rounded,
                    title: 'Manage Categories',
                    onTap: () {
                      Navigator.pop(context);
                      widget.onNavigateToScreen?.call(8);
                    },
                  ),
                  _drawerItem(
                    icon: Icons.store_rounded,
                    title: 'Manage Brands',
                    onTap: () {
                      Navigator.pop(context);
                      widget.onNavigateToScreen?.call(9);
                    },
                  ),
                  _drawerItem(
                    icon: Icons.people_rounded,
                    title: 'Customers',
                    onTap: () {
                      Navigator.pop(context);
                      widget.onOpenCustomers();
                    },
                  ),
                  _drawerItem(
                    icon: Icons.analytics_rounded,
                    title: 'Reports & Analytics',
                    onTap: () {
                      Navigator.pop(context);
                      widget.onOpenReports();
                    },
                  ),
                  _drawerItem(
                    icon: Icons.local_shipping_rounded,
                    title: 'Delivery Management',
                    onTap: () {
                      Navigator.pop(context);
                      widget.onNavigateToScreen?.call(12);
                    },
                  ),
                  _drawerItem(
                    icon: Icons.local_offer_rounded,
                    title: 'Offers & Banners',
                    onTap: () {
                      Navigator.pop(context);
                      widget.onNavigateToScreen?.call(13);
                    },
                  ),
                  _drawerItem(
                    icon: Icons.settings_rounded,
                    title: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      widget.onOpenSettings();
                    },
                  ),
                  _drawerItem(
                    icon: Icons.account_circle_rounded,
                    title: 'My Profile',
                    onTap: () {
                      Navigator.pop(context);
                      widget.onNavigateToScreen?.call(15);
                    },
                  ),
                  const Divider(color: NummaColors.border, height: 20),
                  _drawerItem(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Switch to Customer App',
                    color: NummaColors.primaryGreen,
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/customer');
                    },
                  ),
                  _drawerItem(
                    icon: Icons.logout_rounded,
                    title: 'Logout',
                    color: NummaColors.error,
                    onTap: () {
                      Navigator.pop(context);
                      widget.onNavigateToScreen?.call(1);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    bool isActive = false,
    Color? color,
    required VoidCallback onTap,
  }) {
    final itemColor = color ?? (isActive ? NummaColors.darkGreen : NummaColors.textMain);
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: isActive ? NummaColors.lightGreen : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: Icon(icon, size: 20, color: itemColor),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            color: itemColor,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: NummaColors.primaryGreen,
          width: 18,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(5),
            topRight: Radius.circular(5),
          ),
        ),
      ],
    );
  }
}

class _DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const _DashboardStatCard({
    required this.title,
    required this.value,
    required this.change,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NummaColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NummaColors.border, width: 1),
        boxShadow: NummaColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7EF),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_upward_rounded, size: 9, color: NummaColors.success),
                    Text(
                      change,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: NummaColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: NummaColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: NummaColors.textMain,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: NummaColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: NummaColors.border, width: 1),
          boxShadow: NummaColors.cardShadow,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
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

