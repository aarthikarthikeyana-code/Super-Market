import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/customer_theme.dart';
import '../providers/customer_providers.dart';
import '../widgets/customer_common_widgets.dart';

class Customer08CartScreen extends ConsumerWidget {
  final VoidCallback? onBack;
  final VoidCallback onProceedToCheckout;

  const Customer08CartScreen({
    super.key,
    this.onBack,
    required this.onProceedToCheckout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(customerCartProvider);
    final cartNotifier = ref.read(customerCartProvider.notifier);

    return Scaffold(
      backgroundColor: NummaCustomerColors.creamBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header: Back, My Cart (3 items), Delete-all icon
            CustomerAppBar(
              title: 'My Cart (${cartItems.length} items)',
              onBack: onBack,
              actions: [
                if (cartItems.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: NummaCustomerColors.errorRed),
                    onPressed: () => cartNotifier.clearCart(),
                  ),
              ],
            ),

            // Content
            Expanded(
              child: cartItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_bag_outlined, size: 64, color: NummaCustomerColors.secondaryText.withOpacity(0.4)),
                          const SizedBox(height: 12),
                          Text(
                            'Your cart is empty',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: NummaCustomerColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      children: [
                        // Cart Product Rows
                        ...List.generate(cartItems.length, (index) {
                          final item = cartItems[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: NummaCustomerColors.border),
                              boxShadow: NummaCustomerColors.lightShadow,
                            ),
                            child: Row(
                              children: [
                                CustomerProductImage(
                                  imageUrl: item.product.imageUrl,
                                  size: 58,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.product.nameTamil,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: NummaCustomerColors.darkText,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${item.product.brand} • ${item.selectedSize.size}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: NummaCustomerColors.secondaryText,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '₹${item.subtotal.toStringAsFixed(0)}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: NummaCustomerColors.darkGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Stepper + Delete
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, size: 22, color: NummaCustomerColors.secondaryText),
                                      onPressed: () => cartNotifier.updateQuantity(index, -1),
                                    ),
                                    Text(
                                      '${item.quantity}',
                                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle, size: 22, color: NummaCustomerColors.darkGreen),
                                      onPressed: () => cartNotifier.updateQuantity(index, 1),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 16),

                        // BILL DETAILS
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: NummaCustomerColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bill Details',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: NummaCustomerColors.darkText,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildBillRow('Items Total', '₹${cartNotifier.itemsTotal.toStringAsFixed(0)}'),
                              const SizedBox(height: 8),
                              _buildBillRow('Delivery Charge', 'FREE', isHighlight: true),
                              const Divider(height: 20, color: NummaCustomerColors.border),
                              _buildBillRow('Total', '₹${cartNotifier.grandTotal.toStringAsFixed(0)}', isTotal: true),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
            ),

            // Proceed to Checkout Bottom Button
            if (cartItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: CustomerPrimaryButton(
                  text: 'Proceed to Checkout  •  ₹${cartNotifier.grandTotal.toStringAsFixed(0)}',
                  onPressed: onProceedToCheckout,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillRow(String label, String value, {bool isHighlight = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isTotal ? 14 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? NummaCustomerColors.darkText : NummaCustomerColors.secondaryText,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isTotal ? 16 : 13,
            fontWeight: isTotal ? FontWeight.w900 : FontWeight.bold,
            color: isHighlight
                ? NummaCustomerColors.success
                : (isTotal ? NummaCustomerColors.darkGreen : NummaCustomerColors.darkText),
          ),
        ),
      ],
    );
  }
}

