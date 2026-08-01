import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:al_ruby_ecommerce/presentation/admin/admin_layout.dart';
import 'package:al_ruby_ecommerce/presentation/providers/providers.dart';
import 'package:al_ruby_ecommerce/data/models/category.dart';

class AdminCategoriesScreen extends ConsumerStatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  ConsumerState<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends ConsumerState<AdminCategoriesScreen> {
  void _showCategoryDialog([Category? category]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CategoryFormDialog(category: category),
    );
  }

  Future<void> _deleteCategory(Category category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"? All products associated with this category will remain, but the category layout will be removed.'),
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
        if (category.imageUrl.isNotEmpty) {
          await storeRepo.deleteImage(category.imageUrl);
        }
        await storeRepo.deleteCategory(category.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category deleted successfully.')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final isHeaderDesktop = MediaQuery.of(context).size.width > 600;

    return AdminLayout(
      selectedIndex: 2,
      title: 'Categories Management',
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            isHeaderDesktop
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Categories List', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      ElevatedButton.icon(
                        onPressed: () => _showCategoryDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('CREATE CATEGORY'),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Categories List', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _showCategoryDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('CREATE CATEGORY'),
                      ),
                    ],
                  ),
            const SizedBox(height: 24),
            Expanded(
              child: categoriesAsync.when(
                data: (categories) {
                  if (categories.isEmpty) {
                    return const Center(child: Text('No categories found. Click "Create Category" to get started.'));
                  }
                  
                  final isDesktop = MediaQuery.of(context).size.width > 800;

                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isDesktop ? 4 : 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: isDesktop ? 1.1 : 0.85,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final c = categories[index];
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: c.imageUrl.isNotEmpty
                                  ? Image.network(c.imageUrl, fit: BoxFit.cover, width: double.infinity)
                                  : Container(
                                      color: const Color(0xFFF1F5F9),
                                      child: const Icon(Icons.folder_open_outlined, color: Color(0xFF94A3B8), size: 40),
                                    ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        if (c.description.isNotEmpty)
                                          Text(c.description, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 18),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => _showCategoryDialog(c),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => _deleteCategory(c),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Failed to load categories: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Category Form Dialog ---
class CategoryFormDialog extends ConsumerStatefulWidget {
  final Category? category;
  const CategoryFormDialog({super.key, this.category});

  @override
  ConsumerState<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends ConsumerState<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _urlController = TextEditingController();

  String _imageUrl = '';
  Uint8List? _newImageBytes;
  String? _newImageName;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _descController.text = widget.category!.description;
      _imageUrl = widget.category!.imageUrl;
      _urlController.text = widget.category!.imageUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _newImageBytes = result.files.single.bytes;
        _newImageName = result.files.single.name;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final storeRepo = ref.read(storeRepoProvider);
      String finalUrl = _urlController.text.trim();

      if (_newImageBytes != null) {
        final path = 'categories/${DateTime.now().millisecondsSinceEpoch}_$_newImageName';
        finalUrl = await storeRepo.uploadImage(_newImageBytes!, path);
      }

      final cat = Category(
        id: widget.category?.id ?? '',
        name: _nameController.text.trim(),
        imageUrl: finalUrl,
        description: _descController.text.trim(),
      );

      if (widget.category == null) {
        await storeRepo.addCategory(cat);
      } else {
        await storeRepo.editCategory(cat);
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category saved successfully.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving category: $e')));
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
    final isDesktop = MediaQuery.of(context).size.width > 600;
    return AlertDialog(
      title: Text(widget.category == null ? 'Create Category' : 'Edit Category'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Category Name'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description (Optional)'),
                ),
                const SizedBox(height: 20),
                const Text('Category Image', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                isDesktop
                    ? Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Pick Image'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF64748B)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _urlController,
                              decoration: const InputDecoration(labelText: 'Or Paste Image URL'),
                              onChanged: (val) {
                                setState(() {
                                  _imageUrl = val.trim();
                                  _newImageBytes = null;
                                });
                              },
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Pick Image'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _urlController,
                            decoration: const InputDecoration(labelText: 'Or Paste Image URL'),
                            onChanged: (val) {
                              setState(() {
                                _imageUrl = val.trim();
                                _newImageBytes = null;
                              });
                            },
                          ),
                        ],
                      ),
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _newImageBytes != null
                        ? Image.memory(_newImageBytes!, fit: BoxFit.cover)
                        : (_imageUrl.isNotEmpty
                            ? Image.network(_imageUrl, fit: BoxFit.cover)
                            : const Icon(Icons.image_outlined)),
                  ),
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
              : const Text('Save Category'),
        ),
      ],
    );
  }
}
