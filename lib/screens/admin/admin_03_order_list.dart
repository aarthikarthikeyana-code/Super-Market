import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class Admin03OrderList extends StatefulWidget {
  final VoidCallback onBack;
  final Function(String) onSelectOrder;

  const Admin03OrderList({
    super.key,
    required this.onBack,
    required this.onSelectOrder,
  });

  @override
  State<Admin03OrderList> createState() => _Admin03OrderListState();
}

class _Admin03OrderListState extends State<Admin03OrderList> {
  String _selectedFilter = 'All';

  final List<Map<String, dynamic>> _orders = [
    {
      'id': '#ORD124578',
      'time': 'Today, 10:22 AM',
      'amount': '₹82',
      'status': 'New',
      'statusColor': AppColors.primaryGreenLight,
      'category': 'New',
    },
    {
      'id': '#ORD124577',
      'time': 'Today, 09:15 AM',
      'amount': '₹140',
      'status': 'Preparing',
      'statusColor': const Color(0xFF60A5FA),
      'category': 'New',
    },
    {
      'id': '#ORD124576',
      'time': 'Yesterday, 08:40 PM',
      'amount': '₹96',
      'status': 'Packed',
      'statusColor': AppColors.primaryGreen,
      'category': 'Packed',
    },
    {
      'id': '#ORD124575',
      'time': 'Yesterday, 06:10 PM',
      'amount': '₹110',
      'status': 'Out for Delivery',
      'statusColor': const Color(0xFF2DD4BF),
      'category': 'Packed',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedFilter == 'All'
        ? _orders
        : _orders.where((o) => o['category'] == _selectedFilter).toList();

    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            // App Bar
            DarkAppBar(
              title: 'Orders',
              onBack: widget.onBack,
              actions: [
                IconButton(
                  icon: const Icon(Icons.filter_list_rounded, color: Colors.white, size: 20),
                  onPressed: () {},
                ),
              ],
            ),

            // Filter Tabs (All 28, New 12, Packed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _FilterTab(
                    label: 'All (28)',
                    isSelected: _selectedFilter == 'All',
                    onTap: () => setState(() => _selectedFilter = 'All'),
                  ),
                  const SizedBox(width: 8),
                  _FilterTab(
                    label: 'New (12)',
                    isSelected: _selectedFilter == 'New',
                    onTap: () => setState(() => _selectedFilter = 'New'),
                  ),
                  const SizedBox(width: 8),
                  _FilterTab(
                    label: 'Packed',
                    isSelected: _selectedFilter == 'Packed',
                    onTap: () => setState(() => _selectedFilter = 'Packed'),
                  ),
                ],
              ),
            ),

            // Orders List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final order = filtered[index];
                  return GestureDetector(
                    onTap: () => widget.onSelectOrder(order['id'] as String),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.surfaceBorder, width: 1),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order['id'] as String,
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  order['time'] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                order['amount'] as String,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGreenLight,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (order['statusColor'] as Color).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: (order['statusColor'] as Color).withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  order['status'] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: order['statusColor'] as Color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const StepFooterBadge(
              number: '03',
              title: 'Order List',
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreenDark : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : AppColors.surfaceBorder,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
