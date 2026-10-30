import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/numma_theme.dart';
import '../../data/models/numma_models.dart';
import '../providers/numma_providers.dart';
import '../widgets/numma_common_widgets.dart';

class Numma09BrandsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const Numma09BrandsScreen({super.key, this.onBack});

  @override
  ConsumerState<Numma09BrandsScreen> createState() => _Numma09BrandsScreenState();
}

class _Numma09BrandsScreenState extends ConsumerState<Numma09BrandsScreen> {
  void _showAddOrEditBrandDialog({NummaBrand? brand}) {
    final isEditing = brand != null;
    final nameController = TextEditingController(text: brand?.name ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isEditing ? 'Edit Brand' : 'Add Brand',
            style: const TextStyle(fontWeight: FontWeight.bold, color: NummaColors.textMain),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Brand Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'e.g. Aachi, Tata, Fortune',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: NummaColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: NummaColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  if (isEditing) {
                    ref.read(nummaBrandsProvider.notifier).updateBrand(brand.id, nameController.text.trim());
                  } else {
                    ref.read(nummaBrandsProvider.notifier).addBrand(
                          NummaBrand(
                            id: 'B_${DateTime.now().millisecondsSinceEpoch}',
                            name: nameController.text.trim(),
                            productCount: 0,
                            logoText: nameController.text.trim().substring(0, 2).toUpperCase(),
                          ),
                        );
                  }
                  Navigator.pop(ctx);
                }
              },
              child: Text(isEditing ? 'Save' : 'Add'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteBrandDialog(NummaBrand brand) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Brand', style: TextStyle(fontWeight: FontWeight.bold, color: NummaColors.error)),
          content: Text('Are you sure you want to delete brand "${brand.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: NummaColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: NummaColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                ref.read(nummaBrandsProvider.notifier).deleteBrand(brand.id);
                Navigator.pop(ctx);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final brands = ref.watch(nummaBrandsProvider);

    return Scaffold(
      backgroundColor: NummaColors.creamBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            NummaAppBar(
              title: 'Brands',
              leading: widget.onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back, color: NummaColors.darkGreen),
                      onPressed: widget.onBack,
                    )
                  : null,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddOrEditBrandDialog(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NummaColors.primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text(
                      'Add Brand',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),

            // Brands List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: brands.length,
                itemBuilder: (context, index) {
                  final brand = brands[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: NummaColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          // Brand Logo Badge
                          Container(
                            width: 54,
                            height: 44,
                            decoration: BoxDecoration(
                              color: NummaColors.lightGreen,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: NummaColors.primaryGreen.withOpacity(0.2)),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              brand.logoText.isNotEmpty ? brand.logoText : brand.name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: NummaColors.primaryGreen,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Brand details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  brand.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: NummaColors.textMain,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${brand.productCount} Products',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: NummaColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: NummaColors.primaryGreen),
                            onPressed: () => _showAddOrEditBrandDialog(brand: brand),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: NummaColors.error),
                            onPressed: () => _showDeleteBrandDialog(brand),
                          ),
                        ],
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
