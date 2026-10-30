import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/numma_theme.dart';
import '../../data/models/numma_models.dart';
import '../providers/numma_providers.dart';
import '../widgets/numma_common_widgets.dart';

class Numma07OrderDetailsScreen extends ConsumerWidget {
  final NummaOrder order;
  final VoidCallback? onBack;

  const Numma07OrderDetailsScreen({
    super.key,
    required this.order,
    this.onBack,
  });

  void _showStatusUpdateDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Update Order Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: NummaColors.textMain,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...OrderStatus.values.map((status) {
                final isSelected = order.status == status;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: NummaColors.lightGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.circle, size: 10, color: NummaColors.primaryGreen),
                  ),
                  title: Text(
                    status.name.toUpperCase(),
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: NummaColors.textMain,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: NummaColors.primaryGreen)
                      : null,
                  onTap: () {
                    ref.read(nummaOrdersProvider.notifier).updateStatus(order.orderId, status);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Order ${order.orderId} status changed to ${status.name}'),
                        backgroundColor: NummaColors.primaryGreen,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch current order state in case status updated
    final currentOrder = ref.watch(nummaOrdersProvider).firstWhere(
      (o) => o.orderId == order.orderId,
      orElse: () => order,
    );

    return Scaffold(
      backgroundColor: NummaColors.creamBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            NummaAppBar(
              title: 'Order Details',
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: NummaColors.darkGreen),
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.print_outlined, color: NummaColors.darkGreen),
                  onPressed: () {},
                ),
              ],
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order ID & Status banner card
                    Container(
                      padding: const EdgeInsets.all(16),
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentOrder.orderId,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: NummaColors.textMain,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${currentOrder.orderDate.day} Oct 2024, ${currentOrder.timeSlot}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: NummaColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          NummaStatusBadge.order(currentOrder.status),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Customer Information
                    _buildSectionHeader('Customer Information'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: NummaColors.border),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: NummaColors.lightGreen,
                            child: const Icon(Icons.person, color: NummaColors.primaryGreen, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentOrder.customerName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: NummaColors.textMain,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currentOrder.customerPhone,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: NummaColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.phone_outlined, color: NummaColors.primaryGreen, size: 20),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Delivery Address
                    _buildSectionHeader('Delivery Address'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: NummaColors.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: NummaColors.lightGreen,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.location_on_outlined, color: NummaColors.primaryGreen, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              currentOrder.deliveryAddress,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: NummaColors.textMain,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Ordered Items
                    _buildSectionHeader('Ordered Items'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: NummaColors.border),
                      ),
                      child: Column(
                        children: [
                          ...currentOrder.items.map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: NummaProductImage(
                                      imageUrl: item.product.imageUrl,
                                      width: 44,
                                      height: 44,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.product.nameTamil,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: NummaColors.textMain,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${item.product.weight} × ${item.quantity}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: NummaColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '₹${item.price.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: NummaColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    '₹${item.subtotal.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: NummaColors.textMain,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Price Summary
                    _buildSectionHeader('Price Summary'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: NummaColors.border),
                      ),
                      child: Column(
                        children: [
                          _buildPriceRow('Items Total', '₹${currentOrder.itemsTotal.toStringAsFixed(0)}'),
                          const SizedBox(height: 8),
                          _buildPriceRow('Delivery Charge', '₹${currentOrder.deliveryCharge.toStringAsFixed(0)}'),
                          const Divider(height: 20, color: NummaColors.border),
                          _buildPriceRow(
                            'Total Amount',
                            '₹${currentOrder.totalAmount.toStringAsFixed(0)}',
                            isTotal: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Update Order Status Button
                    NummaPrimaryButton(
                      text: 'Update Order Status',
                      onPressed: () => _showStatusUpdateDialog(context, ref),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: NummaColors.textMain,
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 14 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? NummaColors.textMain : NummaColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? NummaColors.primaryGreen : NummaColors.textMain,
          ),
        ),
      ],
    );
  }
}
