import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/numma_theme.dart';
import '../../data/models/numma_models.dart';
import '../providers/numma_providers.dart';
import '../widgets/numma_common_widgets.dart';

class Numma12DeliveryScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const Numma12DeliveryScreen({super.key, this.onBack});

  @override
  ConsumerState<Numma12DeliveryScreen> createState() => _Numma12DeliveryScreenState();
}

class _Numma12DeliveryScreenState extends ConsumerState<Numma12DeliveryScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final agents = ref.watch(nummaDeliveryAgentsProvider);

    return Scaffold(
      backgroundColor: NummaColors.creamBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            NummaAppBar(
              title: 'Delivery Management',
              leading: widget.onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back, color: NummaColors.darkGreen),
                      onPressed: widget.onBack,
                    )
                  : null,
              actions: [
                IconButton(
                  icon: const Icon(Icons.two_wheeler_outlined, color: NummaColors.darkGreen),
                  onPressed: () {},
                ),
              ],
            ),

            // Filters
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildFilterChip('All', 'All (42)'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Assigned', 'Assigned (18)'),
                  const SizedBox(width: 8),
                  _buildFilterChip('On Delivery', 'On Delivery (16)'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Delivered', 'Delivered (76)'),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Delivery Executives List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                itemCount: agents.length,
                itemBuilder: (context, index) {
                  final agent = agents[index];
                  return _buildAgentCard(agent);
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

  Widget _buildAgentCard(NummaDeliveryAgent agent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NummaColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Executive Top Bar
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: NummaColors.lightGreen,
                  child: Text(
                    agent.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: NummaColors.primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agent.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: NummaColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${agent.assignedOrders} Orders | ${agent.distance}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: NummaColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: NummaColors.lightGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: NummaColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        agent.isActive ? 'Active' : 'Offline',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: NummaColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: NummaColors.border),

          // Assigned Orders Sublist
          ...agent.orders.map((order) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping_outlined, size: 16, color: NummaColors.primaryGreen),
                  const SizedBox(width: 8),
                  Text(
                    order.orderId,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: NummaColors.textMain,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    order.customerName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: NummaColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  NummaStatusBadge.order(order.status),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
