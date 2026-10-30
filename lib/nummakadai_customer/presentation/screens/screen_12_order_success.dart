import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/customer_theme.dart';
import '../widgets/customer_common_widgets.dart';

class Customer12OrderSuccessScreen extends StatelessWidget {
  final VoidCallback onViewOrderDetails;
  final VoidCallback onContinueShopping;

  const Customer12OrderSuccessScreen({
    super.key,
    required this.onViewOrderDetails,
    required this.onContinueShopping,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NummaCustomerColors.creamBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Success Icon with confetti/grocery bag
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: NummaCustomerColors.lightGreen,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: NummaCustomerColors.darkGreen,
                    size: 64,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title: Order Placed Successfully!
              Text(
                'Order Placed\nSuccessfully!',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: NummaCustomerColors.darkText,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 12),

              // Order ID & Estimated Delivery
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: NummaCustomerColors.border),
                  boxShadow: NummaCustomerColors.lightShadow,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order ID:',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: NummaCustomerColors.secondaryText,
                          ),
                        ),
                        Text(
                          '#NK20251022',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: NummaCustomerColors.darkGreen,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16, color: NummaCustomerColors.border),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Estimated Delivery:',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: NummaCustomerColors.secondaryText,
                          ),
                        ),
                        Text(
                          'Today, 10:00 AM – 12:00 PM',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: NummaCustomerColors.darkText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Buttons
              CustomerPrimaryButton(
                text: 'View Order Details',
                onPressed: onViewOrderDetails,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: NummaCustomerColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: onContinueShopping,
                  child: Text(
                    'Continue Shopping',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: NummaCustomerColors.darkGreen,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const CustomerBottomGroceryArt(),
            ],
          ),
        ),
      ),
    );
  }
}

