import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/customer_theme.dart';
import '../../data/models/customer_models.dart';
import '../providers/customer_providers.dart';
import '../widgets/customer_common_widgets.dart';

class Customer11PaymentReviewScreen extends ConsumerWidget {
  final VoidCallback? onBack;
  final VoidCallback onChangeAddress;
  final VoidCallback onChangeSlot;
  final VoidCallback onPlaceOrderSuccess;

  const Customer11PaymentReviewScreen({
    super.key,
    this.onBack,
    required this.onChangeAddress,
    required this.onChangeSlot,
    required this.onPlaceOrderSuccess,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(customerCartProvider);
    final cartNotifier = ref.read(customerCartProvider.notifier);
    final address = ref.watch(selectedAddressProvider);
    final slot = ref.watch(selectedDeliverySlotProvider);

    return Scaffold(
      backgroundColor: NummaCustomerColors.creamBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header: Back, Payment Order
            CustomerAppBar(
              title: 'Payment Order',
              onBack: onBack,
            ),

            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  // DELIVERY ADDRESS CARD
                  _buildSectionHeader('Delivery Address', 'Change', onChangeAddress),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: NummaCustomerColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: NummaCustomerColors.darkGreen, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                address.type,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${address.addressLine} ${address.cityPin}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: NummaCustomerColors.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // DELIVERY SLOT CARD
                  _buildSectionHeader('Delivery Slot', 'Change', onChangeSlot),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: NummaCustomerColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_rounded, color: NummaCustomerColors.darkGreen, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${slot.dateLabel}, ${slot.timeRange}',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: NummaCustomerColors.darkText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // PAYMENT METHOD: Cash on Delivery (COD ONLY)
                  Text(
                    'Payment Method',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: NummaCustomerColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: NummaCustomerColors.darkGreen, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: NummaCustomerColors.lightGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.money_rounded, color: NummaCustomerColors.darkGreen, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cash on Delivery (COD)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: NummaCustomerColors.darkText,
                                ),
                              ),
                              Text(
                                'Pay cash or UPI upon package handover',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: NummaCustomerColors.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.check_circle_rounded, color: NummaCustomerColors.darkGreen, size: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ORDER ITEMS (3)
                  Text(
                    'Order Items (${cartItems.length})',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: NummaCustomerColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: NummaCustomerColors.border),
                    ),
                    child: Column(
                      children: [
                        ...cartItems.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                CustomerProductImage(
                                  imageUrl: item.product.imageUrl,
                                  size: 40,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.product.nameTamil,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: NummaCustomerColors.darkText,
                                        ),
                                      ),
                                      Text(
                                        '${item.selectedSize.size} × ${item.quantity}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: NummaCustomerColors.secondaryText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '₹${item.subtotal.toStringAsFixed(0)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: NummaCustomerColors.darkText,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const Divider(height: 16, color: NummaCustomerColors.border),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Amount',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '₹${cartNotifier.grandTotal.toStringAsFixed(0)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: NummaCustomerColors.darkGreen,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Place Order Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: CustomerPrimaryButton(
                text: 'Place Order  •  ₹${cartNotifier.grandTotal.toStringAsFixed(0)}',
                onPressed: () {
                  final newOrder = CustomerOrderRecord(
                    orderId: '#NK20251022',
                    orderDate: DateTime.now(),
                    timeSlot: '${slot.dateLabel}, ${slot.timeRange}',
                    items: List.from(cartItems),
                    totalAmount: cartNotifier.grandTotal,
                    status: CustomerOrderStatus.placed,
                    address: address,
                  );
                  ref.read(customerOrdersProvider.notifier).placeOrder(newOrder);
                  onPlaceOrderSuccess();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String actionLabel, VoidCallback onAction) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: NummaCustomerColors.darkText,
          ),
        ),
        GestureDetector(
          onTap: onAction,
          child: Text(
            actionLabel,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: NummaCustomerColors.darkGreen,
            ),
          ),
        ),
      ],
    );
  }
}

