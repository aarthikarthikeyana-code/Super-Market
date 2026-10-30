import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/customer_theme.dart';
import '../providers/customer_providers.dart';
import '../widgets/customer_common_widgets.dart';

class Customer09AddressScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback onContinue;

  const Customer09AddressScreen({
    super.key,
    this.onBack,
    required this.onContinue,
  });

  @override
  ConsumerState<Customer09AddressScreen> createState() => _Customer09AddressScreenState();
}

class _Customer09AddressScreenState extends ConsumerState<Customer09AddressScreen> {
  String _selectedTab = 'Home';

  @override
  Widget build(BuildContext context) {
    final addresses = ref.watch(customerRepoProvider).addresses;
    final selectedAddress = ref.watch(selectedAddressProvider);

    return Scaffold(
      backgroundColor: NummaCustomerColors.creamBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header: Back, Delivery Address
            CustomerAppBar(
              title: 'Delivery Address',
              onBack: widget.onBack,
            ),

            // Tabs: Home, Office, Others
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildTab('Home'),
                  const SizedBox(width: 8),
                  _buildTab('Office'),
                  const SizedBox(width: 8),
                  _buildTab('Others'),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Address Cards
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                children: [
                  ...addresses.map((addr) {
                    final isSelected = selectedAddress.id == addr.id;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? NummaCustomerColors.darkGreen : NummaCustomerColors.border,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                        boxShadow: NummaCustomerColors.lightShadow,
                      ),
                      child: InkWell(
                        onTap: () => ref.read(selectedAddressProvider.notifier).setAddress(addr),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Radio<String>(
                              value: addr.id,
                              groupValue: selectedAddress.id,
                              activeColor: NummaCustomerColors.darkGreen,
                              onChanged: (_) => ref.read(selectedAddressProvider.notifier).setAddress(addr),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        addr.type,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: NummaCustomerColors.darkText,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 18, color: NummaCustomerColors.secondaryText),
                                        onPressed: () {},
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${addr.addressLine}\n${addr.cityPin}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      height: 1.4,
                                      color: NummaCustomerColors.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 10),

                  // Button: + Add New Address
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: NummaCustomerColors.darkGreen,
                      side: const BorderSide(color: NummaCustomerColors.darkGreen, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(
                      'Add New Address',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Bottom illustration: House / city / delivery themed
                  Container(
                    height: 110,
                    decoration: BoxDecoration(
                      color: NummaCustomerColors.lightGreen,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.home_work_outlined, size: 38, color: NummaCustomerColors.darkGreen),
                          const SizedBox(height: 6),
                          Text(
                            'Quick doorstep grocery delivery to your home',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: NummaCustomerColors.darkGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Continue CTA Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: CustomerPrimaryButton(
                text: 'Continue',
                onPressed: widget.onContinue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label) {
    final isSelected = _selectedTab == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
}
