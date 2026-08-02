import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:al_ruby_ecommerce/presentation/admin/admin_layout.dart';
import 'package:al_ruby_ecommerce/presentation/providers/providers.dart';
import 'package:al_ruby_ecommerce/data/models/product.dart';

class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  ConsumerState<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
  final _uuid = const Uuid();

  void _showProductDialog([Product? product]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProductFormDialog(product: product),
    );
  }

  Future<void> _deleteProduct(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final storeRepo = ref.read(storeRepoProvider);
        // Delete images from Storage first
        for (final img in product.images) {
          await storeRepo.deleteImage(img);
        }
        await storeRepo.deleteProduct(product.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted successfully.')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(adminProductsProvider);
    final isHeaderDesktop = MediaQuery.of(context).size.width > 600;

    return AdminLayout(
      selectedIndex: 1,
      title: 'Products Management',
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            isHeaderDesktop
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Store Products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      ElevatedButton.icon(
                        onPressed: () => _showProductDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('ADD PRODUCT'),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Store Products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _showProductDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('ADD PRODUCT'),
                      ),
                    ],
                  ),
            const SizedBox(height: 24),
            Expanded(
              child: productsAsync.when(
                data: (products) {
                  if (products.isEmpty) {
                    return const Center(child: Text('No products found. Click "Add Product" to get started.'));
                  }
                  
                  final isDesktop = MediaQuery.of(context).size.width > 900;
                  
                  if (isDesktop) {
                    return _buildDesktopTable(products);
                  } else {
                    return _buildMobileList(products);
                  }
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Failed to load products: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTable(List<Product> products) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
            dataRowHeight: 70,
            columns: const [
              DataColumn(label: Text('Image')),
              DataColumn(label: Text('SKU / Name')),
              DataColumn(label: Text('Category')),
              DataColumn(label: Text('Stock')),
              DataColumn(label: Text('MRP / Price')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Actions')),
            ],
            rows: products.map((p) {
              return DataRow(
                cells: [
                  DataCell(
                    Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: p.images.isNotEmpty
                          ? Image.network(p.images.first, fit: BoxFit.cover)
                          : const Icon(Icons.image_outlined),
                    ),
                  ),
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(p.sku, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF64748B))),
                        Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      ],
                    ),
                  ),
                  DataCell(Text(p.category)),
                  DataCell(
                    Text(
                      '${p.stock}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: p.stock <= 0 ? Colors.red : (p.stock <= 5 ? Colors.orange : Colors.green),
                      ),
                    ),
                  ),
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Selling: ₹${p.sellingPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F62FE))),
                        if (p.mrp > p.sellingPrice)
                          Text('MRP: ₹${p.mrp.toStringAsFixed(0)}', style: const TextStyle(decoration: TextDecoration.lineThrough, fontSize: 11, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: p.status == 'active' ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        p.status.toUpperCase(),
                        style: TextStyle(
                          color: p.status == 'active' ? Colors.green.shade800 : Colors.red.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue), onPressed: () => _showProductDialog(p)),
                        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteProduct(p)),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileList(List<Product> products) {
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final p = products[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          child: ListTile(
            leading: p.images.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(p.images.first, height: 50, width: 50, fit: BoxFit.cover),
                  )
                : const Icon(Icons.image_outlined),
            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('SKU: ${p.sku} • Stock: ${p.stock} • ₹${p.sellingPrice.toStringAsFixed(0)}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue), onPressed: () => _showProductDialog(p)),
                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteProduct(p)),
              ],
            ),
          ),
        );
      },
    );
  }
}

// --- Form Dialog for Add/Edit Product ---
class ProductFormDialog extends ConsumerStatefulWidget {
  final Product? product;
  const ProductFormDialog({super.key, this.product});

  @override
  ConsumerState<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  
  final _skuController = TextEditingController();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _mrpController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _shippingFeeController = TextEditingController();

  final List<ProductVariant> _variants = [];
  final _variantSizeController = TextEditingController();
  final _variantMrpController = TextEditingController();
  final _variantPriceController = TextEditingController();
  final _variantStockController = TextEditingController();

  String? _selectedCategory;
  String _status = 'active';

  final List<String> _images = [];
  final List<Uint8List> _newImageBytes = [];
  final List<String> _newImageNames = [];

  final Map<String, String> _specifications = {};
  final _specKeyController = TextEditingController();
  final _specValController = TextEditingController();
  final _imageUrlController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      final p = widget.product!;
      _skuController.text = p.sku;
      _nameController.text = p.name;
      _brandController.text = p.brand;
      _descriptionController.text = p.description;
      _mrpController.text = p.mrp.toStringAsFixed(0);
      _priceController.text = p.sellingPrice.toStringAsFixed(0);
      _stockController.text = p.stock.toString();
      _shippingFeeController.text = p.shippingFee.toStringAsFixed(0);
      _selectedCategory = p.category;
      _status = p.status;
      _images.addAll(p.images);
      _specifications.addAll(p.specifications);
      _variants.addAll(p.variants);
    } else {
      _shippingFeeController.text = '0';
    }
  }

  @override
  void dispose() {
    _skuController.dispose();
    _nameController.dispose();
    _brandController.dispose();
    _descriptionController.dispose();
    _mrpController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _shippingFeeController.dispose();
    _specKeyController.dispose();
    _specValController.dispose();
    _imageUrlController.dispose();
    _variantSizeController.dispose();
    _variantMrpController.dispose();
    _variantPriceController.dispose();
    _variantStockController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null) {
      for (final file in result.files) {
        if (file.bytes != null) {
          setState(() {
            _newImageBytes.add(file.bytes!);
            _newImageNames.add(file.name);
          });
        }
      }
    }
  }

  void _addSpecification() {
    final key = _specKeyController.text.trim();
    final val = _specValController.text.trim();
    if (key.isNotEmpty && val.isNotEmpty) {
      setState(() {
        _specifications[key] = val;
        _specKeyController.clear();
        _specValController.clear();
      });
    }
  }

  void _addVariant() {
    final size = _variantSizeController.text.trim();
    final double? mrp = double.tryParse(_variantMrpController.text.trim());
    final double? price = double.tryParse(_variantPriceController.text.trim());
    final int? stock = int.tryParse(_variantStockController.text.trim());

    if (size.isNotEmpty && mrp != null && price != null && stock != null) {
      setState(() {
        _variants.add(ProductVariant(
          size: size,
          mrp: mrp,
          sellingPrice: price,
          stock: stock,
        ));
        _variantSizeController.clear();
        _variantMrpController.clear();
        _variantPriceController.clear();
        _variantStockController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all variant fields with valid numbers')),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final storeRepo = ref.read(storeRepoProvider);
      final List<String> uploadedUrls = [..._images];

      // Upload new images
      for (int i = 0; i < _newImageBytes.length; i++) {
        final path = 'products/${DateTime.now().millisecondsSinceEpoch}_${_newImageNames[i]}';
        final url = await storeRepo.uploadImage(_newImageBytes[i], path);
        uploadedUrls.add(url);
      }

      double mrp = 0.0;
      double price = 0.0;
      int stock = 0;

      if (_variants.isNotEmpty) {
        mrp = _variants.first.mrp;
        price = _variants.first.sellingPrice;
        stock = _variants.fold(0, (sum, v) => sum + v.stock);
      } else {
        mrp = double.parse(_mrpController.text);
        price = double.parse(_priceController.text);
        stock = int.parse(_stockController.text);
      }

      final double discount = mrp > 0 ? ((mrp - price) / mrp) * 100 : 0.0;

      final p = Product(
        id: widget.product?.id ?? '',
        sku: _skuController.text.trim(),
        name: _nameController.text.trim(),
        brand: _brandController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory!,
        mrp: mrp,
        sellingPrice: price,
        discount: discount.clamp(0.0, 100.0),
        stock: stock,
        images: uploadedUrls,
        specifications: _specifications,
        status: _status,
        variants: _variants,
        shippingFee: double.tryParse(_shippingFeeController.text.trim()) ?? 0.0,
      );

      if (widget.product == null) {
        await storeRepo.addProduct(p);
      } else {
        await storeRepo.editProduct(p);
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product saved successfully.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return AlertDialog(
      title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // SKU & Name
                isDesktop
                    ? Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _skuController,
                              decoration: const InputDecoration(labelText: 'SKU Code'),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(labelText: 'Product Name'),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          TextFormField(
                            controller: _skuController,
                            decoration: const InputDecoration(labelText: 'SKU Code'),
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(labelText: 'Product Name'),
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ],
                      ),
                const SizedBox(height: 12),

                // Brand & Category Dropdown
                isDesktop
                    ? Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _brandController,
                              decoration: const InputDecoration(labelText: 'Brand / Maker'),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: categoriesAsync.when(
                              data: (cats) => DropdownButtonFormField<String>(
                                value: _selectedCategory,
                                decoration: const InputDecoration(labelText: 'Category'),
                                items: cats.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
                                onChanged: (val) => setState(() => _selectedCategory = val),
                              ),
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (_, __) => const Text('Error loading categories'),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          TextFormField(
                            controller: _brandController,
                            decoration: const InputDecoration(labelText: 'Brand / Maker'),
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          categoriesAsync.when(
                            data: (cats) => DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              decoration: const InputDecoration(labelText: 'Category'),
                              items: cats.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
                              onChanged: (val) => setState(() => _selectedCategory = val),
                            ),
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (_, __) => const Text('Error loading categories'),
                          ),
                        ],
                      ),
                const SizedBox(height: 12),

                // MRP, Selling Price & Stock
                isDesktop
                    ? Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _mrpController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Market Retail Price (MRP)'),
                              validator: (v) => _variants.isEmpty && (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Selling Price'),
                              validator: (v) => _variants.isEmpty && (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _stockController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Stock Units'),
                              validator: (v) => _variants.isEmpty && (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          TextFormField(
                            controller: _mrpController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Market Retail Price (MRP)'),
                            validator: (v) => _variants.isEmpty && (v == null || v.isEmpty) ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Selling Price'),
                            validator: (v) => _variants.isEmpty && (v == null || v.isEmpty) ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _stockController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Stock Units'),
                            validator: (v) => _variants.isEmpty && (v == null || v.isEmpty) ? 'Required' : null,
                          ),
                        ],
                      ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _shippingFeeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Shipping Fee (₹)',
                    hintText: 'Enter shipping fee (0 or empty for Free)',
                  ),
                  validator: (v) {
                    if (v != null && v.isNotEmpty && double.tryParse(v) == null) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Status
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active (Visible in Store)')),
                    DropdownMenuItem(value: 'inactive', child: Text('Inactive (Hidden from Store)')),
                  ],
                  onChanged: (val) => setState(() => _status = val!),
                ),
                const SizedBox(height: 20),

                // Sizes / Quantities (Variants)
                const Text('Sizes / Quantities (Variants)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                isDesktop
                    ? Row(
                        children: [
                          Expanded(
                            child: TextFormField(controller: _variantSizeController, decoration: const InputDecoration(hintText: 'Size (e.g. 50 ML, 1 L)')),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(controller: _variantMrpController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'MRP')),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(controller: _variantPriceController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Price')),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(controller: _variantStockController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Stock')),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Color(0xFF0F62FE)),
                            onPressed: _addVariant,
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          TextFormField(controller: _variantSizeController, decoration: const InputDecoration(labelText: 'Size (e.g. 50 ML)')),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(controller: _variantMrpController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'MRP')),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(controller: _variantPriceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Selling Price')),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(controller: _variantStockController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stock Units')),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle, color: Color(0xFF0F62FE)),
                                onPressed: _addVariant,
                              ),
                            ],
                          ),
                        ],
                      ),
                if (_variants.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _variants.length,
                    itemBuilder: (context, idx) {
                      final v = _variants[idx];
                      return Card(
                        color: Theme.of(context).colorScheme.surface,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text('${v.size} - ₹${v.sellingPrice.toStringAsFixed(0)} (MRP: ₹${v.mrp.toStringAsFixed(0)})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                          subtitle: Text('Stock: ${v.stock} units', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => setState(() => _variants.removeAt(idx)),
                          ),
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 12),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 20),

                // Dynamic Specifications Adding
                const Text('Specifications', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                isDesktop
                    ? Row(
                        children: [
                          Expanded(
                            child: TextFormField(controller: _specKeyController, decoration: const InputDecoration(hintText: 'Size, Color, Notes...')),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(controller: _specValController, decoration: const InputDecoration(hintText: '100ML, 0% Alcohol...')),
                          ),
                          IconButton(icon: const Icon(Icons.add_circle, color: Color(0xFF0F62FE)), onPressed: _addSpecification),
                        ],
                      )
                    : Column(
                        children: [
                          TextFormField(controller: _specKeyController, decoration: const InputDecoration(hintText: 'Specification Key (e.g. Size)')),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(controller: _specValController, decoration: const InputDecoration(hintText: 'Specification Value (e.g. 100ML)')),
                              ),
                              IconButton(icon: const Icon(Icons.add_circle, color: Color(0xFF0F62FE)), onPressed: _addSpecification),
                            ],
                          ),
                        ],
                      ),
                if (_specifications.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _specifications.entries.map((e) {
                      return Chip(
                        label: Text('${e.key}: ${e.value}', style: const TextStyle(fontSize: 12)),
                        onDeleted: () => setState(() => _specifications.remove(e.key)),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 20),

                // Images Section
                const Text('Product Images', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                isDesktop
                    ? Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickImages,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Add Images'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF64748B)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _imageUrlController,
                              decoration: const InputDecoration(
                                hintText: 'Or paste direct image URL link',
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Color(0xFF0F62FE)),
                            onPressed: () {
                              final val = _imageUrlController.text.trim();
                              if (val.isNotEmpty) {
                                setState(() {
                                  _images.add(val);
                                  _imageUrlController.clear();
                                });
                              }
                            },
                          )
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickImages,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Add Images'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _imageUrlController,
                                  decoration: const InputDecoration(
                                    hintText: 'Or paste direct image URL link',
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle, color: Color(0xFF0F62FE)),
                                onPressed: () {
                                  final val = _imageUrlController.text.trim();
                                  if (val.isNotEmpty) {
                                    setState(() {
                                      _images.add(val);
                                      _imageUrlController.clear();
                                    });
                                  }
                                },
                              )
                            ],
                          ),
                        ],
                      ),
                const SizedBox(height: 12),
                
                // Show current and newly picked image previews
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ...List.generate(_images.length, (idx) {
                      final url = _images[idx];
                      return Stack(
                        children: [
                          Container(
                            height: 70,
                            width: 70,
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                            clipBehavior: Clip.antiAlias,
                            child: Image.network(url, fit: BoxFit.cover),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.red,
                              child: GestureDetector(
                                onTap: () => setState(() => _images.removeAt(idx)),
                                child: const Icon(Icons.close, color: Colors.white, size: 12),
                              ),
                            ),
                          )
                        ],
                      );
                    }),
                    ...List.generate(_newImageBytes.length, (idx) {
                      final bytes = _newImageBytes[idx];
                      return Stack(
                        children: [
                          Container(
                            height: 70,
                            width: 70,
                            decoration: BoxDecoration(border: Border.all(color: Colors.blue), borderRadius: BorderRadius.circular(8)),
                            clipBehavior: Clip.antiAlias,
                            child: Image.memory(bytes, fit: BoxFit.cover),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.red,
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  _newImageBytes.removeAt(idx);
                                  _newImageNames.removeAt(idx);
                                }),
                                child: const Icon(Icons.close, color: Colors.white, size: 12),
                              ),
                            ),
                          )
                        ],
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _isSaving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Save Product'),
        ),
      ],
    );
  }
}
