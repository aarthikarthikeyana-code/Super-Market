import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/numma_theme.dart';
import '../../data/models/numma_models.dart';
import '../providers/numma_providers.dart';
import '../widgets/numma_common_widgets.dart';

class Numma04AddProductScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onSaved;

  const Numma04AddProductScreen({
    super.key,
    this.onBack,
    this.onSaved,
  });

  @override
  ConsumerState<Numma04AddProductScreen> createState() => _Numma04AddProductScreenState();
}

class _Numma04AddProductScreenState extends ConsumerState<Numma04AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameEnController;
  late TextEditingController _nameTaController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _descController;
  late TextEditingController _weightController;

  String _selectedCategory = 'அரிசி';
  String _selectedBrand = 'Ponni';
  String _selectedImage = 'assets/images/products/rice.png';
  bool _hasImage = true;

  @override
  void initState() {
    super.initState();
    _nameEnController = TextEditingController(text: 'Raw Rice');
    _nameTaController = TextEditingController(text: 'அரிசி');
    _priceController = TextEditingController(text: '72');
    _stockController = TextEditingController(text: '120');
    _weightController = TextEditingController(text: '1 kg');
    _descController = TextEditingController();
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameTaController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _saveProduct() {
    if (_formKey.currentState?.validate() ?? false) {
      final double price = double.tryParse(_priceController.text) ?? 0.0;
      final int stock = int.tryParse(_stockController.text) ?? 0;

      final newProduct = NummaProduct(
        id: 'P_${DateTime.now().millisecondsSinceEpoch}',
        sku: 'R${(stock % 900) + 100}',
        nameEnglish: _nameEnController.text.trim(),
        nameTamil: _nameTaController.text.trim(),
        category: _selectedCategory,
        brand: _selectedBrand,
        weight: _weightController.text.trim().isNotEmpty ? _weightController.text.trim() : '1 kg',
        price: price,
        stockQuantity: stock,
        stockStatus: stock > 20
            ? StockStatus.inStock
            : (stock > 0 ? StockStatus.lowStock : StockStatus.outOfStock),
        imageUrl: _selectedImage,
        description: _descController.text.trim(),
      );

      ref.read(nummaProductsProvider.notifier).addProduct(newProduct);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Product "${newProduct.nameTamil}" added successfully!'),
          backgroundColor: NummaColors.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );

      widget.onSaved?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(nummaCategoriesProvider);
    final brands = ref.watch(nummaBrandsProvider);

    return Scaffold(
      backgroundColor: NummaColors.creamBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            NummaAppBar(
              title: 'Add New Product',
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: NummaColors.darkGreen),
                onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.more_vert, color: NummaColors.darkGreen),
                  onPressed: () {},
                ),
              ],
            ),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Upload Section
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Upload Box
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _hasImage = true;
                                  _selectedImage = 'assets/images/products/dal.png';
                                });
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                height: 110,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: NummaColors.border,
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: NummaColors.lightGreen,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_outlined,
                                        color: NummaColors.primaryGreen,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Add Product Image',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: NummaColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Image Preview (if present)
                          if (_hasImage)
                            Stack(
                              children: [
                                Container(
                                  width: 110,
                                  height: 110,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: NummaColors.border),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: NummaProductImage(
                                      imageUrl: _selectedImage,
                                      width: 94,
                                      height: 94,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: -2,
                                  right: -2,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _hasImage = false),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: NummaColors.error,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Product Name (English)
                      _buildFieldLabel('Product Name (English)'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameEnController,
                        decoration: _inputDecoration(hintText: 'e.g. Raw Rice'),
                        validator: (v) => (v == null || v.isEmpty) ? 'Please enter English name' : null,
                      ),
                      const SizedBox(height: 14),

                      // Product Name (Tamil)
                      _buildFieldLabel('Product Name (Tamil)'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameTaController,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        decoration: _inputDecoration(hintText: 'எ.கா. அரிசி'),
                        validator: (v) => (v == null || v.isEmpty) ? 'தயவுசெய்து தமிழ் பெயரை உள்ளிடவும்' : null,
                      ),
                      const SizedBox(height: 14),

                      // Category & Brand Row
                      Row(
                        children: [
                          // Category Dropdown
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Category'),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: NummaColors.border),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: categories.any((c) => c.nameTamil == _selectedCategory)
                                          ? _selectedCategory
                                          : (categories.isNotEmpty ? categories.first.nameTamil : 'அரிசி'),
                                      isExpanded: true,
                                      icon: const Icon(Icons.keyboard_arrow_down, color: NummaColors.textSecondary),
                                      items: categories.map((c) {
                                        return DropdownMenuItem<String>(
                                          value: c.nameTamil,
                                          child: Text(
                                            c.nameTamil,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) setState(() => _selectedCategory = val);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Brand Dropdown
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Brand'),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: NummaColors.border),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: brands.any((b) => b.name == _selectedBrand)
                                          ? _selectedBrand
                                          : (brands.isNotEmpty ? brands.first.name : 'Ponni'),
                                      isExpanded: true,
                                      icon: const Icon(Icons.keyboard_arrow_down, color: NummaColors.textSecondary),
                                      items: brands.map((b) {
                                        return DropdownMenuItem<String>(
                                          value: b.name,
                                          child: Text(
                                            b.name,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) setState(() => _selectedBrand = val);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Price & Stock Quantity Row
                      Row(
                        children: [
                          // Price
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Price (₹)'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _priceController,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration(hintText: '72'),
                                  validator: (v) => (v == null || v.isEmpty) ? 'Enter price' : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Stock Quantity
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Stock Quantity'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _stockController,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration(hintText: '120'),
                                  validator: (v) => (v == null || v.isEmpty) ? 'Enter stock' : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Weight / Unit
                      _buildFieldLabel('Weight / Unit'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _weightController,
                        decoration: _inputDecoration(hintText: 'e.g. 1 kg, 500 g, 1 L'),
                      ),
                      const SizedBox(height: 14),

                      // Product Description (Optional)
                      _buildFieldLabel('Product Description (Optional)'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _descController,
                        maxLines: 3,
                        decoration: _inputDecoration(
                          hintText: 'Enter product description...',
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Save Product Button
                      NummaPrimaryButton(
                        text: 'Save Product',
                        onPressed: _saveProduct,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: NummaColors.textMain,
      ),
    );
  }

  InputDecoration _inputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: NummaColors.textSecondary, fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: NummaColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: NummaColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: NummaColors.primaryGreen, width: 1.5),
      ),
    );
  }
}
