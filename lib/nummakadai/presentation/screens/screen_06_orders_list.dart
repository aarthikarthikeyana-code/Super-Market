import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/numma_theme.dart';
import '../../data/models/numma_models.dart';
import '../providers/numma_providers.dart';
import '../widgets/numma_common_widgets.dart';

class Numma06OrdersListScreen extends ConsumerStatefulWidget {
  final void Function(NummaOrder order)? onSelectOrder;
  final VoidCallback? onBack;

  const Numma06OrdersListScreen({
    super.key,
    this.onSelectOrder,
    this.onBack,
  });

  @override
  ConsumerState<Numma06OrdersListScreen> createState() => _Numma06OrdersListScreenState();
}

class _Numma06OrdersListScreenState extends ConsumerState<Numma06OrdersListScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(nummaOrdersProvider);

    // Filter counts
    final totalCount = orders.length;
    final pendingCount = orders.where((o) => o.status == OrderStatus.pending).length;
    final processingCount = orders.where((o) => o.status == OrderStatus.processing).length;
    final deliveredCount = orders.where((o) => o.status == OrderStatus.delivered).length;

    // Filter list
    final filtered = orders.where((o) {
      if (_selectedFilter == 'Pending' && o.status != OrderStatus.pending) return false;
      if (_selectedFilter == 'Processing' && o.status != OrderStatus.processing) return false;
      if (_selectedFilter == 'Delivered' && o.status != OrderStatus.delivered) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchId = o.orderId.toLowerCase().contains(q);
        final matchCustomer = o.customerName.toLowerCase().contains(q);
        if (!matchId && !matchCustomer) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: NummaColors.creamBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            NummaAppBar(
              title: 'Orders',
              leading: widget.onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back, color: NummaColors.darkGreen),
                      onPressed: widget.onBack,
                    )
                  : null,
              actions: [
                IconButton(
                  icon: const Icon(Icons.filter_list, color: NummaColors.darkGreen),
                  onPressed: () {},
                ),
              ],
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: NummaSearchField(
                hintText: 'Search by Order ID, customer name...',
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),

            // Filter Chips
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildFilterChip('All', 'All ($totalCount)'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Pending', 'Pending ($pendingCount)'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Processing', 'Processing ($processingCount)'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Delivered', 'Delivered ($deliveredCount)'),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Orders List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 54, color: NummaColors.textSecondary.withOpacity(0.5)),
                          const SizedBox(height: 10),
                          const Text(
                            'No orders found',
                            style: TextStyle(color: NummaColors.textSecondary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final order = filtered[index];
                        return _buildOrderCard(order);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _selectedFilter == filterKey;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filterKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? NummaColors.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? NummaColors.primaryGreen : NummaColors.border,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: NummaColors.primaryGreen.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : NummaColors.textMain,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(NummaOrder order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NummaColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => widget.onSelectOrder?.call(order),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: ID + Amount + Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order.orderId,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: NummaColors.primaryGreen,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '₹${order.totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: NummaColors.textMain,
                          ),
                        ),
                        const SizedBox(width: 8),
                        NummaStatusBadge.order(order.status),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Customer info & date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 16, color: NummaColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          order.customerName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: NummaColors.textMain,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          '${order.orderDate.day} Oct 2024, ${order.timeSlot}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: NummaColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, size: 16, color: NummaColors.textSecondary),
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
