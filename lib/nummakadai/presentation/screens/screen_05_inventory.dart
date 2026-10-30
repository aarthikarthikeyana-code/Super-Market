import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/numma_theme.dart';
import '../../data/models/numma_models.dart';
import '../providers/numma_providers.dart';
import '../widgets/numma_common_widgets.dart';

class Numma05InventoryScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  final void Function(NummaProduct product)? onSelectProduct;

  const Numma05InventoryScreen({
    super.key,
    this.onBack,
    this.onSelectProduct,
  });

  @override
  ConsumerState<Numma05InventoryScreen> createState() => _Numma05InventoryScreenState();
}

class _Numma05InventoryScreenState extends ConsumerState<Numma05InventoryScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';

  void _showUpdateStockDialog(BuildContext context, NummaProduct product) {
    int currentStock = product.stockQuantity;
    final textController = TextEditingController(text: currentStock.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
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
                      Text(
                        'Update Stock: ${product.nameTamil}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: NummaColors.textMain,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: NummaColors.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  Text(
                    '${product.nameEnglish} • SKU: ${product.sku}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: NummaColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Stock Stepper
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        style: IconButton.styleFrom(
                          backgroundColor: NummaColors.lightGreen,
                          foregroundColor: NummaColors.primaryGreen,
                        ),
                        onPressed: () {
                          if (currentStock > 0) {
                            setModalState(() {
                              currentStock--;
                              textController.text = currentStock.toString();
                            });
                          }
                        },
                        icon: const Icon(Icons.remove),
                      ),
                      const SizedBox(width: 20),
                      SizedBox(
                        width: 90,
                        child: TextField(
                          controller: textController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: NummaColors.textMain,
                          ),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: NummaColors.border),
                            ),
                          ),
                          onChanged: (val) {
                            final parsed = int.tryParse(val);
                            if (parsed != null) {
                              setModalState(() => currentStock = parsed);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 20),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: NummaColors.primaryGreen,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          setModalState(() {
                            currentStock++;
                            textController.text = currentStock.toString();
                          });
                        },
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  NummaPrimaryButton(
                    text: 'Confirm Update',
                    onPressed: () {
                      ref.read(nummaProductsProvider.notifier).updateStock(product.id, currentStock);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Stock updated for ${product.nameTamil} ($currentStock units)'),
                          backgroundColor: NummaColors.primaryGreen,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(nummaProductsProvider);

    // Compute counts
    final totalCount = products.length;
    final inStockCount = products.where((p) => p.stockStatus == StockStatus.inStock).length;
    final lowStockCount = products.where((p) => p.stockStatus == StockStatus.lowStock).length;
    final outOfStockCount = products.where((p) => p.stockStatus == StockStatus.outOfStock).length;

    // Filter products
    final filtered = products.where((p) {
      if (_selectedFilter == 'In Stock' && p.stockStatus != StockStatus.inStock) return false;
      if (_selectedFilter == 'Low Stock' && p.stockStatus != StockStatus.lowStock) return false;
      if (_selectedFilter == 'Out of Stock' && p.stockStatus != StockStatus.outOfStock) return false;

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchTa = p.nameTamil.toLowerCase().contains(query);
        final matchEn = p.nameEnglish.toLowerCase().contains(query);
        final matchSku = p.sku.toLowerCase().contains(query);
        if (!matchTa && !matchEn && !matchSku) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: NummaColors.creamBg,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            NummaAppBar(
              title: 'Inventory Management',
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: NummaColors.darkGreen),
                onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: NummaColors.lightGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.inventory_2_outlined, color: NummaColors.primaryGreen, size: 20),
                ),
              ],
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: NummaSearchField(
                hintText: 'Search products, SKU...',
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),

            // Filter Chips
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildFilterChip('All', 'All ($totalCount)'),
                  const SizedBox(width: 8),
                  _buildFilterChip('In Stock', 'In Stock ($inStockCount)'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Low Stock', 'Low Stock ($lowStockCount)'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Out of Stock', 'Out of Stock ($outOfStockCount)'),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Inventory List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_outlined, size: 54, color: NummaColors.textSecondary.withOpacity(0.5)),
                          const SizedBox(height: 10),
                          const Text(
                            'No inventory items found',
                            style: TextStyle(color: NummaColors.textSecondary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final product = filtered[index];
                        return _buildInventoryCard(product);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _selectedFilter == filterKey;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filterKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? NummaColors.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? NummaColors.primaryGreen : NummaColors.border,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: NummaColors.primaryGreen.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : NummaColors.textMain,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInventoryCard(NummaProduct product) {
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showUpdateStockDialog(context, product),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Product Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: NummaProductImage(
                    imageUrl: product.imageUrl,
                    width: 52,
                    height: 52,
                  ),
                ),
                const SizedBox(width: 14),

                // Name and SKU
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.nameTamil,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: NummaColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${product.weight} | SKU: ${product.sku}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: NummaColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Stock count & Status badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Stock: ${product.stockQuantity}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: product.stockQuantity == 0
                            ? NummaColors.error
                            : (product.stockQuantity <= 10 ? NummaColors.warning : NummaColors.textMain),
                      ),
                    ),
                    const SizedBox(height: 6),
                    NummaStatusBadge.stock(product.stockStatus),
                  ],
                ),
                const SizedBox(width: 8),

                const Icon(
                  Icons.chevron_right,
                  color: NummaColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
