import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/customer_theme.dart';
import '../../data/models/customer_models.dart';
import '../providers/customer_providers.dart';
import '../widgets/customer_common_widgets.dart';

class Customer13MyOrdersScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const Customer13MyOrdersScreen({super.key, this.onBack});

  @override
  ConsumerState<Customer13MyOrdersScreen> createState() => _Customer13MyOrdersScreenState();
}

class _Customer13MyOrdersScreenState extends ConsumerState<Customer13MyOrdersScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(customerOrdersProvider);

    return Scaffold(
      backgroundColor: NummaCustomerColors.creamBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header: Back, My Orders, Search
            CustomerAppBar(
              title: 'My Orders',
              onBack: widget.onBack,
              actions: [
                IconButton(
                  icon: const Icon(Icons.search_rounded, color: NummaCustomerColors.darkGreen),
                  onPressed: () {},
                ),
              ],
            ),

            // Filter chips: All, Ongoing, Delivered, Cancelled
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildChip('All'),
                  const SizedBox(width: 8),
                  _buildChip('Ongoing'),
                  const SizedBox(width: 8),
                  _buildChip('Delivered'),
                  const SizedBox(width: 8),
                  _buildChip('Cancelled'),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Orders List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return _buildOrderCard(order);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? NummaCustomerColors.darkGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? NummaCustomerColors.darkGreen : NummaCustomerColors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : NummaCustomerColors.darkText,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(CustomerOrderRecord order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NummaCustomerColors.border),
        boxShadow: NummaCustomerColors.lightShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID & Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.orderId,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: NummaCustomerColors.darkGreen,
                ),
              ),
              Text(
                '₹${order.totalAmount.toStringAsFixed(0)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: NummaCustomerColors.darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Date & Items Count
          Text(
            '${order.timeSlot} • ${order.items.length} items',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: NummaCustomerColors.secondaryText,
            ),
          ),
          const SizedBox(height: 14),

          // ORDER PROGRESS TIMELINE: Placed -> Preparing -> Out for Delivery -> Delivered
          _buildProgressTimeline(order.status),
          const SizedBox(height: 14),

          // View Details Button
          SizedBox(
            width: double.infinity,
            height: 38,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: NummaCustomerColors.darkGreen),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {},
              child: Text(
                'View Details',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: NummaCustomerColors.darkGreen,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTimeline(CustomerOrderStatus status) {
    final stages = ['Placed', 'Preparing', 'Out for Delivery', 'Delivered'];
    int currentStep = 1;
    if (status == CustomerOrderStatus.placed) currentStep = 0;
    if (status == CustomerOrderStatus.preparing) currentStep = 1;
    if (status == CustomerOrderStatus.outForDelivery) currentStep = 2;
    if (status == CustomerOrderStatus.delivered) currentStep = 3;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(stages.length, (index) {
        final isPassed = index <= currentStep;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index == 0 ? Colors.transparent : (isPassed ? NummaCustomerColors.darkGreen : NummaCustomerColors.border),
                    ),
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isPassed ? NummaCustomerColors.darkGreen : NummaCustomerColors.border,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index == stages.length - 1 ? Colors.transparent : (index < currentStep ? NummaCustomerColors.darkGreen : NummaCustomerColors.border),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                stages[index],
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: isPassed ? FontWeight.bold : FontWeight.normal,
                  color: isPassed ? NummaCustomerColors.darkText : NummaCustomerColors.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }),
    );
  }
}

