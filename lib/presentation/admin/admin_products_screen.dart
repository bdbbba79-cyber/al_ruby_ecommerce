import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:al_ruby_ecommerce/presentation/admin/admin_layout.dart';
import 'package:al_ruby_ecommerce/presentation/providers/providers.dart';
import 'package:al_ruby_ecommerce/data/models/product.dart';
import 'package:al_ruby_ecommerce/core/theme/theme.dart';
import 'package:al_ruby_ecommerce/presentation/widgets/app_network_image.dart';

class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  ConsumerState<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
  void _showProductDialog([Product? product]) {
    AdminLayout.showAdminDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProductFormDialog(product: product),
    );
  }

  Future<void> _deleteProduct(Product product) async {
    final confirm = await AdminLayout.showAdminDialog<bool>(
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
        padding: EdgeInsets.all(isHeaderDesktop ? 24.0 : 12.0),
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
                          ? AppNetworkImage.thumbnail(imageUrl: p.images.first, size: 50, fit: BoxFit.cover)
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
                ? AppNetworkImage.thumbnail(
                    imageUrl: p.images.first,
                    size: 50,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(4),
                  )
                : const Icon(Icons.image_outlined),
            title: Text(
              p.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'SKU: ${p.sku} • Stock: ${p.stock} • ₹${p.sellingPrice.toStringAsFixed(0)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
  String _uploadStatus = '';

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
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        int addedCount = 0;
        for (final file in result.files) {
          if (file.bytes != null) {
            setState(() {
              _newImageBytes.add(file.bytes!);
              _newImageNames.add(file.name);
            });
            addedCount++;
          }
        }
        if (addedCount > 0 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$addedCount photo(s) selected.')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to select photos: $e')),
      );
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

    if (_newImageBytes.isNotEmpty) {
      final authUser = ref.read(authRepoProvider).currentUser;
      if (authUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication required: Please log in to upload product images.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isSaving = true;
      _uploadStatus = _newImageBytes.isNotEmpty
          ? 'Uploading photo 1 of ${_newImageBytes.length}...'
          : 'Saving product...';
    });

    try {
      final storeRepo = ref.read(storeRepoProvider);
      final List<String> uploadedUrls = [..._images];

      // Upload new images
      for (int i = 0; i < _newImageBytes.length; i++) {
        if (mounted) {
          setState(() {
            _uploadStatus = 'Uploading photo ${i + 1} of ${_newImageBytes.length}...';
          });
        }
        final sanitizedName = _newImageNames[i].replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
        final path = 'products/${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';
        final url = await storeRepo.uploadImage(_newImageBytes[i], path);
        uploadedUrls.add(url);
      }

      if (mounted) {
        setState(() {
          _uploadStatus = 'Saving product details...';
        });
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
      String msg = 'Error saving: $e';
      if (e.toString().contains('unauthorized')) {
        msg = 'Upload failed: User not authorized in Firebase Storage. Please publish storage rules in Firebase Console.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red.shade800,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF0F62FE), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;
    final isDesktop = size.width > 900;

    final dialogContent = Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.product == null ? 'Add New Product' : 'Edit Product',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.product == null
                  ? 'Complete product details, pricing, variants, and photos'
                  : 'SKU: ${_skuController.text}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.normal),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF0F172A)),
          tooltip: 'Close',
          onPressed: _isSaving ? null : () => Navigator.pop(context),
        ),
        actions: [
          if (isMobile)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F62FE),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Section 1: Basic Details
              _buildSectionCard(
                icon: Icons.inventory_2_outlined,
                title: '1. Basic Information',
                subtitle: 'Product identification, classification, and visibility',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    isDesktop
                        ? Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _skuController,
                                  decoration: const InputDecoration(labelText: 'SKU Code', hintText: 'e.g. PERF-001'),
                                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(labelText: 'Product Name', hintText: 'e.g. Royal Amber Oud'),
                                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              TextFormField(
                                controller: _skuController,
                                decoration: const InputDecoration(labelText: 'SKU Code', hintText: 'e.g. PERF-001'),
                                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(labelText: 'Product Name', hintText: 'e.g. Royal Amber Oud'),
                                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                              ),
                            ],
                          ),
                    const SizedBox(height: 14),
                    isDesktop
                        ? Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _brandController,
                                  decoration: const InputDecoration(labelText: 'Brand / Maker', hintText: 'e.g. Izzfah Noobi'),
                                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: categoriesAsync.when(
                                  data: (cats) => DropdownButtonFormField<String>(
                                    value: _selectedCategory,
                                    decoration: const InputDecoration(labelText: 'Category'),
                                    items: cats.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
                                    onChanged: (val) => setState(() => _selectedCategory = val),
                                    validator: (v) => v == null ? 'Please select a category' : null,
                                  ),
                                  loading: () => const Center(child: CircularProgressIndicator()),
                                  error: (_, _) => const Text('Error loading categories'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _status,
                                  decoration: const InputDecoration(labelText: 'Store Status'),
                                  items: const [
                                    DropdownMenuItem(value: 'active', child: Text('Active (Visible)')),
                                    DropdownMenuItem(value: 'inactive', child: Text('Inactive (Hidden)')),
                                  ],
                                  onChanged: (val) => setState(() => _status = val!),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              TextFormField(
                                controller: _brandController,
                                decoration: const InputDecoration(labelText: 'Brand / Maker', hintText: 'e.g. Izzfah Noobi'),
                                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                              ),
                              const SizedBox(height: 14),
                              categoriesAsync.when(
                                data: (cats) => DropdownButtonFormField<String>(
                                  value: _selectedCategory,
                                  decoration: const InputDecoration(labelText: 'Category'),
                                  items: cats.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
                                  onChanged: (val) => setState(() => _selectedCategory = val),
                                  validator: (v) => v == null ? 'Please select a category' : null,
                                ),
                                loading: () => const Center(child: CircularProgressIndicator()),
                                error: (_, _) => const Text('Error loading categories'),
                              ),
                              const SizedBox(height: 14),
                              DropdownButtonFormField<String>(
                                value: _status,
                                decoration: const InputDecoration(labelText: 'Store Status'),
                                items: const [
                                  DropdownMenuItem(value: 'active', child: Text('Active (Visible in Store)')),
                                  DropdownMenuItem(value: 'inactive', child: Text('Inactive (Hidden from Store)')),
                                ],
                                onChanged: (val) => setState(() => _status = val!),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section 2: Pricing & Stock (Default)
              _buildSectionCard(
                icon: Icons.payments_outlined,
                title: '2. Pricing & Stock (Base)',
                subtitle: 'Base values used for single-size items or as fallbacks',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    isDesktop
                        ? Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _mrpController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Market Price (MRP ₹)', hintText: 'e.g. 1999'),
                                  validator: (v) => _variants.isEmpty && (v == null || v.isEmpty) ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _priceController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Selling Price (₹)', hintText: 'e.g. 1499'),
                                  validator: (v) => _variants.isEmpty && (v == null || v.isEmpty) ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _stockController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Stock Units', hintText: 'e.g. 50'),
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
                                decoration: const InputDecoration(labelText: 'Market Retail Price (MRP ₹)', hintText: 'e.g. 1999'),
                                validator: (v) => _variants.isEmpty && (v == null || v.isEmpty) ? 'Required' : null,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _priceController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Selling Price (₹)', hintText: 'e.g. 1499'),
                                validator: (v) => _variants.isEmpty && (v == null || v.isEmpty) ? 'Required' : null,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _stockController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Stock Units', hintText: 'e.g. 50'),
                                validator: (v) => _variants.isEmpty && (v == null || v.isEmpty) ? 'Required' : null,
                              ),
                            ],
                          ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _shippingFeeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Shipping Fee (₹)',
                        hintText: 'Enter 0 or leave empty for Free Shipping',
                        prefixIcon: Icon(Icons.local_shipping_outlined),
                      ),
                      validator: (v) {
                        if (v != null && v.isNotEmpty && double.tryParse(v) == null) {
                          return 'Enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section 3: Sizes / Quantities (Variants)
              _buildSectionCard(
                icon: Icons.tune_outlined,
                title: '3. Sizes / Quantities (Variants)',
                subtitle: 'Add specific sizes (e.g. S, M, L, XL, 42, 44, Standard) with individual prices and stock',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    isDesktop
                        ? Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _variantSizeController,
                                  decoration: const InputDecoration(labelText: 'Size / Variant', hintText: 'e.g. M, L, XL or 42, 44'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _variantMrpController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'MRP (₹)', hintText: 'MRP'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _variantPriceController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Price (₹)', hintText: 'Selling'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _variantStockController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Stock', hintText: 'Units'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F62FE),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: _addVariant,
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              TextFormField(
                                controller: _variantSizeController,
                                decoration: const InputDecoration(labelText: 'Size / Variant', hintText: 'e.g. M, L, XL or 42, 44'),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _variantMrpController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(labelText: 'MRP (₹)'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _variantPriceController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(labelText: 'Price (₹)'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _variantStockController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(labelText: 'Stock'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('Add Variant to List'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F62FE),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: _addVariant,
                              ),
                            ],
                          ),
                    if (_variants.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _variants.length,
                          separatorBuilder: (_, _) => const Divider(color: Color(0xFFE2E8F0), height: 16),
                          itemBuilder: (context, idx) {
                            final v = _variants[idx];
                            return Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFBFDBFE)),
                                  ),
                                  child: Text(
                                    v.size,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E40AF)),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '₹${v.sellingPrice.toStringAsFixed(0)} (MRP: ₹${v.mrp.toStringAsFixed(0)})',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Available Stock: ${v.stock} units',
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  tooltip: 'Remove variant',
                                  onPressed: () => setState(() => _variants.removeAt(idx)),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section 4: Description
              _buildSectionCard(
                icon: Icons.description_outlined,
                title: '4. Product Description',
                subtitle: 'Overview, material, fit, and lifestyle details displayed to customers',
                child: TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Full Description',
                    hintText: 'Enter product details, fabric material, fit, dial size, strap type, care instructions...',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(height: 20),

              // Section 5: Specifications
              _buildSectionCard(
                icon: Icons.list_alt_outlined,
                title: '5. Specifications (Optional)',
                subtitle: 'Custom key-value specifications (e.g. Material: Cotton, Dial: 42mm, Fit: Slim)',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    isDesktop
                        ? Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _specKeyController,
                                  decoration: const InputDecoration(labelText: 'Feature / Spec Name', hintText: 'e.g. Material, Color, Fit, Movement'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _specValController,
                                  decoration: const InputDecoration(labelText: 'Spec Value', hintText: 'e.g. 100% Cotton, Stainless Steel, Slim Fit'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add Spec'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F62FE),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: _addSpecification,
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              TextFormField(
                                controller: _specKeyController,
                                decoration: const InputDecoration(labelText: 'Feature / Spec Name', hintText: 'e.g. Material, Size, Movement'),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _specValController,
                                      decoration: const InputDecoration(labelText: 'Spec Value', hintText: 'e.g. Cotton, 42mm, Quartz'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0F62FE),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: _addSpecification,
                                    child: const Text('Add'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                    if (_specifications.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _specifications.entries.map((e) {
                          return Container(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 60),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            padding: const EdgeInsets.only(left: 12, right: 6, top: 4, bottom: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(text: '${e.key}: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                                        TextSpan(text: e.value, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
                                      ],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => setState(() => _specifications.remove(e.key)),
                                  child: const Icon(Icons.close, size: 16, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section 6: Product Images
              _buildSectionCard(
                icon: Icons.photo_library_outlined,
                title: '6. Product Images',
                subtitle: 'Upload product pictures (${_images.length + _newImageBytes.length} total attached)',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    isDesktop
                        ? Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: _isSaving ? null : _pickImages,
                                icon: const Icon(Icons.add_photo_alternate, size: 20),
                                label: const Text('Upload Photos from Device'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F62FE),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _imageUrlController,
                                  decoration: const InputDecoration(
                                    labelText: 'Or Paste Direct Image Link (URL)',
                                    hintText: 'https://...',
                                    prefixIcon: Icon(Icons.link),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton(
                                onPressed: () {
                                  final val = _imageUrlController.text.trim();
                                  if (val.isNotEmpty) {
                                    setState(() {
                                      _images.add(val);
                                      _imageUrlController.clear();
                                    });
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF0F62FE),
                                  side: const BorderSide(color: Color(0xFF0F62FE), width: 1.5),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Add Link', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _isSaving ? null : _pickImages,
                                icon: const Icon(Icons.add_photo_alternate, size: 20),
                                label: const Text('Upload Photos from Device'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F62FE),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _imageUrlController,
                                      decoration: const InputDecoration(
                                        labelText: 'Paste Image Link (URL)',
                                        hintText: 'https://...',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton(
                                    onPressed: () {
                                      final val = _imageUrlController.text.trim();
                                      if (val.isNotEmpty) {
                                        setState(() {
                                          _images.add(val);
                                          _imageUrlController.clear();
                                        });
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0F62FE),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text('Add'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                    const SizedBox(height: 16),
                    if (_images.isEmpty && _newImageBytes.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Center(
                          child: Column(
                            children: [
                              Icon(Icons.photo_outlined, size: 40, color: Color(0xFF94A3B8)),
                              SizedBox(height: 8),
                              Text(
                                'No photos added yet',
                                style: TextStyle(color: Color(0xFF475569), fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Tap "Upload Photos" to pick images from your device or paste a URL.',
                                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ...List.generate(_images.length, (idx) {
                            final url = _images[idx];
                            return Stack(
                              children: [
                                Container(
                                  height: 90,
                                  width: 90,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: AppNetworkImage.thumbnail(
                                    imageUrl: url,
                                    size: 90,
                                    fit: BoxFit.cover,
                                    errorWidget: const Center(
                                      child: Icon(Icons.broken_image, color: Colors.grey, size: 28),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 4,
                                  bottom: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Saved',
                                      style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 4,
                                  top: 4,
                                  child: CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.red.shade700,
                                    child: GestureDetector(
                                      onTap: () => setState(() => _images.removeAt(idx)),
                                      child: const Icon(Icons.close, color: Colors.white, size: 14),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                          ...List.generate(_newImageBytes.length, (idx) {
                            final bytes = _newImageBytes[idx];
                            return Stack(
                              children: [
                                Container(
                                  height: 90,
                                  width: 90,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFF0F62FE), width: 2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Image.memory(
                                    bytes,
                                    fit: BoxFit.cover,
                                    cacheWidth: 200,
                                    cacheHeight: 200,
                                  ),
                                ),
                                Positioned(
                                  left: 4,
                                  bottom: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF16A34A),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'New',
                                      style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 4,
                                  top: 4,
                                  child: CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.red.shade700,
                                    child: GestureDetector(
                                      onTap: () => setState(() {
                                        _newImageBytes.removeAt(idx);
                                        _newImageNames.removeAt(idx);
                                      }),
                                      child: const Icon(Icons.close, color: Colors.white, size: 14),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              offset: const Offset(0, -3),
              blurRadius: 10,
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_isSaving && _uploadStatus.isNotEmpty)
                Expanded(
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F62FE)),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          _uploadStatus,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF0F62FE), fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )
              else
                const SizedBox(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F62FE),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline, size: 20),
                    label: Text(
                      _isSaving
                          ? 'Saving...'
                          : (widget.product == null ? 'Save Product' : 'Update Product'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    final themedContent = Theme(
      data: AppTheme.adminTheme,
      child: dialogContent,
    );

    if (isMobile) {
      return Dialog.fullscreen(
        child: themedContent,
      );
    }

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 900,
          maxHeight: size.height * 0.92,
          minWidth: size.width < 650 ? size.width * 0.92 : 600,
        ),
        child: themedContent,
      ),
    );
  }
}
