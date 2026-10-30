import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/customer_theme.dart';
import '../widgets/customer_common_widgets.dart';

class Customer14AccountScreen extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback onOpenOrders;
  final VoidCallback onOpenAddresses;
  final VoidCallback onLogout;

  const Customer14AccountScreen({
    super.key,
    this.onBack,
    required this.onOpenOrders,
    required this.onOpenAddresses,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NummaCustomerColors.creamBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            CustomerAppBar(
              title: 'My Account',
              onBack: onBack,
            ),

            // Profile section: Avatar, Priya S, Phone
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: NummaCustomerColors.border),
                      boxShadow: NummaCustomerColors.lightShadow,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: NummaCustomerColors.lightGreen,
                          child: const Icon(Icons.person, color: NummaCustomerColors.darkGreen, size: 32),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Priya S',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: NummaCustomerColors.darkText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '+91 98765 43210',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: NummaCustomerColors.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.verified_user_outlined, color: NummaCustomerColors.success, size: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Menu: My Orders, My Addresses, Saved Items, Reorder, Offers & Rewards, Help & Support, About Us
                  _buildMenuItem(Icons.receipt_long_outlined, 'My Orders', onOpenOrders),
                  _buildMenuItem(Icons.location_on_outlined, 'My Addresses', onOpenAddresses),
                  _buildMenuItem(Icons.favorite_outline_rounded, 'Saved Items', () {}),
                  _buildMenuItem(Icons.repeat_rounded, 'Reorder', () {}),
                  _buildMenuItem(Icons.local_offer_outlined, 'Offers & Rewards', () {}),
                  _buildMenuItem(Icons.headset_mic_outlined, 'Help & Support', () {}),
                  _buildMenuItem(Icons.info_outline_rounded, 'About Us', () {}),
                  const SizedBox(height: 20),

                  // Bottom button: Logout (White background, Red border, Red icon, Red text)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: NummaCustomerColors.errorRed,
                      side: const BorderSide(color: NummaCustomerColors.errorRed, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout_rounded, color: NummaCustomerColors.errorRed),
                    label: Text(
                      'Logout',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: NummaCustomerColors.errorRed,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const CustomerBottomGroceryArt(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NummaCustomerColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: NummaCustomerColors.lightGreen,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: NummaCustomerColors.darkGreen, size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: NummaCustomerColors.darkText,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: NummaCustomerColors.secondaryText,
          size: 20,
        ),
      ),
    );
  }
}

