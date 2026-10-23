import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:al_ruby_ecommerce/presentation/admin/admin_layout.dart';
import 'package:al_ruby_ecommerce/presentation/providers/providers.dart';
import 'package:al_ruby_ecommerce/data/models/category.dart';

import 'package:al_ruby_ecommerce/core/theme/theme.dart';
import 'package:al_ruby_ecommerce/presentation/widgets/app_network_image.dart';

class AdminCategoriesScreen extends ConsumerStatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  ConsumerState<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends ConsumerState<AdminCategoriesScreen> {
  void _showCategoryDialog([Category? category]) {
    AdminLayout.showAdminDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CategoryFormDialog(category: category),
    );
  }

  Future<void> _deleteCategory(Category category) async {
    final confirm = await AdminLayout.showAdminDialog<bool>(
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
        padding: EdgeInsets.all(isHeaderDesktop ? 24.0 : 12.0),
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
                      childAspectRatio: isDesktop ? 1.1 : 0.82,
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
                                  ? AppNetworkImage.card(
                                      imageUrl: c.imageUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorWidget: Container(
                                        color: const Color(0xFFF1F5F9),
                                        child: const Icon(Icons.folder_open_outlined, color: Color(0xFF94A3B8), size: 40),
                                      ),
                                    )
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
                                        Text(
                                          c.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, height: 1.2),
                                        ),
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
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        Uint8List? bytes = file.bytes;
        if (bytes == null && file.path != null && file.path!.isNotEmpty) {
          bytes = await XFile(file.path!).readAsBytes();
        }
        if (bytes != null) {
          setState(() {
            _newImageBytes = bytes;
            _newImageName = file.name;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Selected image: ${file.name}')),
            );
          }
          return;
        }
      }
    } catch (_) {
      // Platform fallback to ImagePicker if FilePicker had issues
      try {
        final picker = ImagePicker();
        final picked = await picker.pickImage(source: ImageSource.gallery);
        if (picked != null) {
          final bytes = await picked.readAsBytes();
          setState(() {
            _newImageBytes = bytes;
            _newImageName = picked.name;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Selected image: ${picked.name}')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to pick image: $e')),
          );
        }
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newImageBytes != null) {
      final authUser = ref.read(authRepoProvider).currentUser;
      if (authUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication required: Please log in to upload category images.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

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
      String msg = 'Error saving category: $e';
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    final content = Form(
      key: _formKey,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(20),
        children: [
          // Section 1: Basic Information
          _buildFormSection(
            title: 'Basic Information',
            icon: Icons.folder_open_outlined,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  hintText: 'e.g. Watches, Pants, Shirts, Shoes, Bags, Jerseys',
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Category name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Short summary describing the collection',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Section 2: Category Image
          _buildFormSection(
            title: 'Category Cover Image',
            icon: Icons.image_outlined,
            children: [
              isMobile
                  ? Column(
                      children: [
                        _buildImagePreview(),
                        const SizedBox(height: 16),
                        _buildImageControls(),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildImagePreview(),
                        const SizedBox(width: 20),
                        Expanded(child: _buildImageControls()),
                      ],
                    ),
            ],
          ),
        ],
      ),
    );

    final bottomBar = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 14),
          ElevatedButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(widget.category == null ? 'Create Category' : 'Save Changes'),
          ),
        ],
      ),
    );

    if (isMobile) {
      return Theme(
        data: AppTheme.adminTheme,
        child: Dialog.fullscreen(
          child: Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: AppBar(
              title: Text(widget.category == null ? 'Create Category' : 'Edit Category'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: content,
            bottomNavigationBar: bottomBar,
          ),
        ),
      );
    }

    return Theme(
      data: AppTheme.adminTheme,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        backgroundColor: const Color(0xFFF8FAFC),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620, maxHeight: 680),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.category == null ? 'Create Category' : 'Edit Category',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Flexible(child: content),
              bottomBar,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: 120,
      width: 120,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        border: Border.all(color: const Color(0xFFCBD5E1)),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: _newImageBytes != null
          ? Image.memory(_newImageBytes!, fit: BoxFit.cover, cacheWidth: 240, cacheHeight: 240)
          : (_imageUrl.isNotEmpty
              ? AppNetworkImage.thumbnail(
                  imageUrl: _imageUrl,
                  size: 120,
                  fit: BoxFit.cover,
                  errorWidget: const Center(
                    child: Icon(Icons.broken_image_outlined, color: Colors.grey),
                  ),
                )
              : const Center(
                  child: Icon(Icons.image_outlined, color: Color(0xFF94A3B8), size: 40),
                )),
    );
  }

  Widget _buildImageControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.upload_file, size: 18),
          label: const Text('Pick Image File'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F62FE),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        if (_newImageName != null) ...[
          const SizedBox(height: 6),
          Text(
            'Selected: $_newImageName',
            style: const TextStyle(fontSize: 12, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 12),
        TextFormField(
          controller: _urlController,
          decoration: const InputDecoration(
            labelText: 'Or Paste Web Image URL',
            hintText: 'https://...',
          ),
          onChanged: (val) {
            setState(() {
              _imageUrl = val.trim();
              _newImageBytes = null;
              _newImageName = null;
            });
          },
        ),
      ],
    );
  }

  Widget _buildFormSection({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F62FE).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xFF0F62FE), size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            const Divider(height: 24, color: Color(0xFFF1F5F9)),
            ...children,
          ],
        ),
      ),
    );
  }
}
