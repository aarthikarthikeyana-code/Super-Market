import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class Admin02Dashboard extends StatelessWidget {
  final VoidCallback onOpenOrders;
  final VoidCallback onOpenStock;
  final VoidCallback onOpenRequests;
  final Function(String) onSelectOrder;

  const Admin02Dashboard({
    super.key,
    required this.onOpenOrders,
    required this.onOpenStock,
    required this.onOpenRequests,
    required this.onSelectOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primaryGreenDark,
                    child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Store Manager Portal',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surfaceBorder, width: 1),
                    ),
                    child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 4 Stat Cards in 2x2 Grid
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: onOpenOrders,
                            child: _StatCard(
                              number: '12',
                              label: 'New Orders',
                              bgColor: const Color(0xFF1B3D2A),
                              accentColor: const Color(0xFF34D399),
                              icon: Icons.receipt_rounded,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: onOpenOrders,
                            child: _StatCard(
                              number: '28',
                              label: 'Total Orders',
                              bgColor: const Color(0xFF2A3D1B),
                              accentColor: const Color(0xFFA3E635),
                              icon: Icons.shopping_bag_rounded,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: onOpenStock,
                            child: _StatCard(
                              number: '6',
                              label: 'Out of Stock',
                              bgColor: const Color(0xFF3D1B1B),
                              accentColor: const Color(0xFFF87171),
                              icon: Icons.production_quantity_limits_rounded,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: onOpenRequests,
                            child: _StatCard(
                              number: '4',
                              label: 'New Item Requests',
                              bgColor: const Color(0xFF2B1B3D),
                              accentColor: const Color(0xFFC084FC),
                              icon: Icons.add_task_rounded,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Today's Orders section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Today's Orders",
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        GestureDetector(
                          onTap: onOpenOrders,
                          child: Text(
                            'View All (28)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGreenLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Order #ORD124578 Card
                    _OrderPreviewCard(
                      orderId: '#ORD124578',
                      status: 'Preparing',
                      statusColor: AppColors.primaryGreenLight,
                      time: 'Today, 10:22 AM',
                      amount: '₹82',
                      itemsSummary: 'தக்காளி (1 Kg), கேரட் (500 g)...',
                      onTap: () => onSelectOrder('#ORD124578'),
                    ),
                    const SizedBox(height: 10),

                    // Order #ORD124577 Card
                    _OrderPreviewCard(
                      orderId: '#ORD124577',
                      status: 'Packed',
                      statusColor: const Color(0xFF60A5FA),
                      time: 'Today, 09:15 AM',
                      amount: '₹140',
                      itemsSummary: 'உருளைக்கிழங்கு (2 Kg), வெங்காயம் (1 Kg)...',
                      onTap: () => onSelectOrder('#ORD124577'),
                    ),
                  ],
                ),
              ),
            ),

            const StepFooterBadge(
              number: '02',
              title: 'Dashboard',
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String number;
  final String label;
  final Color bgColor;
  final Color accentColor;
  final IconData icon;

  const _StatCard({
    required this.number,
    required this.label,
    required this.bgColor,
    required this.accentColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                number,
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Icon(icon, color: accentColor, size: 20),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderPreviewCard extends StatelessWidget {
  final String orderId;
  final String status;
  final Color statusColor;
  final String time;
  final String amount;
  final String itemsSummary;
  final VoidCallback onTap;

  const _OrderPreviewCard({
    required this.orderId,
    required this.status,
    required this.statusColor,
    required this.time,
    required this.amount,
    required this.itemsSummary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorder, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  orderId,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.5), width: 1),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              itemsSummary,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  amount,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreenLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
