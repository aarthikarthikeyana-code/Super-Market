import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/numma_theme.dart';
import '../../data/models/numma_models.dart';
import '../providers/numma_providers.dart';
import '../widgets/numma_common_widgets.dart';

class Numma08CategoriesScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const Numma08CategoriesScreen({super.key, this.onBack});

  @override
  ConsumerState<Numma08CategoriesScreen> createState() => _Numma08CategoriesScreenState();
}

class _Numma08CategoriesScreenState extends ConsumerState<Numma08CategoriesScreen> {
  void _showAddOrEditCategoryDialog({NummaCategory? category}) {
    final isEditing = category != null;
    final taController = TextEditingController(text: category?.nameTamil ?? '');
    final enController = TextEditingController(text: category?.nameEnglish ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isEditing ? 'Edit Category' : 'Add Category',
            style: const TextStyle(fontWeight: FontWeight.bold, color: NummaColors.textMain),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Category Name (Tamil)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: taController,
                decoration: InputDecoration(
                  hintText: 'எ.கா. பருப்பு வகைகள்',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Category Name (English)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: enController,
                decoration: InputDecoration(
                  hintText: 'e.g. Pulses & Dals',
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
                if (taController.text.trim().isNotEmpty) {
                  if (isEditing) {
                    ref.read(nummaCategoriesProvider.notifier).updateCategory(
                          category.id,
                          taController.text.trim(),
                          enController.text.trim(),
                        );
                  } else {
                    ref.read(nummaCategoriesProvider.notifier).addCategory(
                          NummaCategory(
                            id: 'C_${DateTime.now().millisecondsSinceEpoch}',
                            nameTamil: taController.text.trim(),
                            nameEnglish: enController.text.trim(),
                            productCount: 0,
                            iconKey: 'assets/images/products/dal.png',
                          ),
                        );
                  }
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEditing ? 'Category updated!' : 'Category added!'),
                      backgroundColor: NummaColors.primaryGreen,
                    ),
                  );
                }
              },
              child: Text(isEditing ? 'Save' : 'Add'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(NummaCategory category) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Category', style: TextStyle(fontWeight: FontWeight.bold, color: NummaColors.error)),
          content: Text('Are you sure you want to delete "${category.nameTamil}"?'),
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
                ref.read(nummaCategoriesProvider.notifier).deleteCategory(category.id);
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
    final categories = ref.watch(nummaCategoriesProvider);

    return Scaffold(
      backgroundColor: NummaColors.creamBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            NummaAppBar(
              title: 'Categories',
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
                    onPressed: () => _showAddOrEditCategoryDialog(),
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
                      'Add Category',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),

            // Categories List
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
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: NummaProductImage(
                              imageUrl: cat.iconKey,
                              width: 48,
                              height: 48,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cat.nameTamil,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: NummaColors.textMain,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${cat.productCount} Products',
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
                            onPressed: () => _showAddOrEditCategoryDialog(category: cat),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: NummaColors.error),
                            onPressed: () => _showDeleteDialog(cat),
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
