import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/customer_theme.dart';
import '../../data/models/customer_models.dart';
import '../providers/customer_providers.dart';
import '../widgets/customer_common_widgets.dart';

class Customer05CategoriesScreen extends ConsumerWidget {
  final VoidCallback? onBack;
  final void Function(CustomerCategory category) onSelectCategory;

  const Customer05CategoriesScreen({
    super.key,
    this.onBack,
    required this.onSelectCategory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(customerRepoProvider).categories;

    return Scaffold(
      backgroundColor: NummaCustomerColors.creamBg,
      body: SafeArea(
        child: Column(
          children: [
            CustomerAppBar(
              title: 'Categories',
              onBack: onBack,
              actions: [
                IconButton(
                  icon: const Icon(Icons.search_rounded, color: NummaCustomerColors.darkGreen),
                  onPressed: () {},
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: NummaCustomerColors.border),
                      boxShadow: NummaCustomerColors.lightShadow,
                    ),
                    child: ListTile(
                      onTap: () => onSelectCategory(cat),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      leading: CustomerProductImage(
                        imageUrl: cat.imageUrl,
                        size: 46,
                        radius: BorderRadius.circular(10),
                      ),
                      title: Text(
                        cat.nameTamil,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: NummaCustomerColors.darkText,
                        ),
                      ),
                      subtitle: Text(
                        cat.nameEnglish,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: NummaCustomerColors.secondaryText,
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
}

