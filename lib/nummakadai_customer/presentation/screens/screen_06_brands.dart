import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/customer_theme.dart';
import '../../data/models/customer_models.dart';
import '../providers/customer_providers.dart';
import '../widgets/customer_common_widgets.dart';

class Customer06BrandsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  final void Function(CustomerBrand brand) onSelectBrand;

  const Customer06BrandsScreen({
    super.key,
    this.onBack,
    required this.onSelectBrand,
  });

  @override
  ConsumerState<Customer06BrandsScreen> createState() => _Customer06BrandsScreenState();
}

class _Customer06BrandsScreenState extends ConsumerState<Customer06BrandsScreen> {
  String _selectedChip = 'All Brands';

  @override
  Widget build(BuildContext context) {
    final brands = ref.watch(customerRepoProvider).brands;

    final filtered = brands.where((b) {
      if (_selectedChip == 'Popular' && b.categoryTag != 'Popular') return false;
      if (_selectedChip == 'Premium' && b.categoryTag != 'Premium') return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: NummaCustomerColors.creamBg,
      body: SafeArea(
        child: Column(
          children: [
            CustomerAppBar(
              title: 'Brands',
              onBack: widget.onBack,
              actions: [
                IconButton(
                  icon: const Icon(Icons.search_rounded, color: NummaCustomerColors.darkGreen),
                  onPressed: () {},
                ),
              ],
            ),

            // Top chips: All Brands, Popular, Premium
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildChip('All Brands'),
                  const SizedBox(width: 8),
                  _buildChip('Popular'),
                  const SizedBox(width: 8),
                  _buildChip('Premium'),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Brand List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final brand = filtered[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: NummaCustomerColors.border),
                      boxShadow: NummaCustomerColors.lightShadow,
                    ),
                    child: ListTile(
                      onTap: () => widget.onSelectBrand(brand),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: NummaCustomerColors.lightGreen,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: NummaCustomerColors.darkGreen.withOpacity(0.2)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          brand.name.substring(0, brand.name.length > 2 ? 2 : brand.name.length).toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: NummaCustomerColors.darkGreen,
                          ),
                        ),
                      ),
                      title: Text(
                        brand.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: NummaCustomerColors.darkText,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: NummaCustomerColors.secondaryText,
                        size: 22,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label) {
    final isSelected = _selectedChip == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedChip = label),
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
}

