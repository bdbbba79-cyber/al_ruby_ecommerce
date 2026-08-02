import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:al_ruby_ecommerce/presentation/admin/admin_layout.dart';
import 'package:al_ruby_ecommerce/presentation/providers/providers.dart';
import 'package:al_ruby_ecommerce/data/models/business_info.dart';
import 'package:al_ruby_ecommerce/data/models/product.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _mobileController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _upiController = TextEditingController();

  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();

  final _aboutUsController = TextEditingController();
  final _termsController = TextEditingController();
  final _privacyController = TextEditingController();
  final _refundController = TextEditingController();
  final _shippingController = TextEditingController();

  final _logoUrlController = TextEditingController();
  final _faviconUrlController = TextEditingController();
  final _bannerImageUrlController = TextEditingController();
  final _couponCodeController = TextEditingController();
  final _couponDiscountPercentageController = TextEditingController();

  String _logoUrl = '';
  String _faviconUrl = '';
  bool _isSavingInfo = false;

  final List<HomeBanner> _banners = [];
  String? _selectedBannerProductId;
  final List<String> _couponProductIds = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final info = ref.read(businessInfoProvider).value;
      if (info != null) {
        _populateFields(info);
      }
    });
  }

  void _populateFields(BusinessInfo info) {
    _nameController.text = info.companyName;
    _addressController.text = info.address;
    _mobileController.text = info.mobileNumber;
    _whatsappController.text = info.whatsappNumber;
    _emailController.text = info.email;
    _upiController.text = info.upiId;
    _facebookController.text = info.facebookLink;
    _instagramController.text = info.instagramLink;
    _aboutUsController.text = info.aboutUs;
    _termsController.text = info.termsAndConditions;
    _privacyController.text = info.privacyPolicy;
    _refundController.text = info.refundPolicy;
    _shippingController.text = info.shippingPolicy;
    _logoUrl = info.companyLogoUrl;
    _faviconUrl = info.faviconUrl;
    _logoUrlController.text = info.companyLogoUrl;
    _faviconUrlController.text = info.faviconUrl;
    _banners.clear();
    _banners.addAll(info.banners);
    _couponCodeController.text = info.couponCode;
    _couponDiscountPercentageController.text = info.couponDiscountPercentage.toStringAsFixed(0);
    _couponProductIds.clear();
    _couponProductIds.addAll(info.couponProductIds);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _mobileController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _upiController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _aboutUsController.dispose();
    _termsController.dispose();
    _privacyController.dispose();
    _refundController.dispose();
    _shippingController.dispose();
    _logoUrlController.dispose();
    _faviconUrlController.dispose();
    _bannerImageUrlController.dispose();
    _couponCodeController.dispose();
    _couponDiscountPercentageController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadLogo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.bytes != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading Company Logo...')));
      try {
        final url = await ref.read(businessRepoProvider).uploadLogo(result.files.single.bytes!);
        setState(() {
          _logoUrl = url;
          _logoUrlController.text = url;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Company Logo uploaded.')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  Future<void> _pickAndUploadFavicon() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.bytes != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading Favicon...')));
      try {
        final url = await ref.read(businessRepoProvider).uploadFavicon(result.files.single.bytes!);
        setState(() {
          _faviconUrl = url;
          _faviconUrlController.text = url;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Favicon uploaded.')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  Future<void> _saveBusinessInfo() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSavingInfo = true);

    try {
      final info = BusinessInfo(
        companyName: _nameController.text.trim(),
        companyLogoUrl: _logoUrlController.text.trim(),
        address: _addressController.text.trim(),
        mobileNumber: _mobileController.text.trim(),
        whatsappNumber: _whatsappController.text.trim(),
        email: _emailController.text.trim(),
        upiId: _upiController.text.trim(),
        facebookLink: _facebookController.text.trim(),
        instagramLink: _instagramController.text.trim(),
        aboutUs: _aboutUsController.text.trim(),
        termsAndConditions: _termsController.text.trim(),
        privacyPolicy: _privacyController.text.trim(),
        refundPolicy: _refundController.text.trim(),
        shippingPolicy: _shippingController.text.trim(),
        faviconUrl: _faviconUrlController.text.trim(),
        bannerUrls: _banners.map((b) => b.imageUrl).toList(),
        banners: _banners,
        couponCode: _couponCodeController.text.trim(),
        couponDiscountPercentage: double.tryParse(_couponDiscountPercentageController.text.trim()) ?? 0.0,
        couponProductIds: _couponProductIds,
      );

      await ref.read(businessRepoProvider).updateBusinessInfo(info);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Business Settings updated successfully.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
    } finally {
      setState(() => _isSavingInfo = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<BusinessInfo>>(businessInfoProvider, (_, state) {
      if (state.hasValue && state.value != null && !_isSavingInfo) {
        _populateFields(state.value!);
      }
    });

    final products = ref.watch(adminProductsProvider).value ?? [];
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return AdminLayout(
      selectedIndex: 4,
      title: 'Global Settings',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _buildFormFields(products)),
                        const SizedBox(width: 24),
                        Expanded(child: _buildAssetsAndBanners(products)),
                      ],
                    )
                  : Column(
                      children: [
                        _buildFormFields(products),
                        const SizedBox(height: 24),
                        _buildAssetsAndBanners(products),
                      ],
                    ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSavingInfo ? null : _saveBusinessInfo,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20)),
                child: _isSavingInfo
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('SAVE ALL SETTINGS'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormFields(List<Product> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Store Details
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Store Profile Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Company Name'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Address Details'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _mobileController,
                        decoration: const InputDecoration(labelText: 'Mobile Phone Number'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _whatsappController,
                        decoration: const InputDecoration(labelText: 'WhatsApp Number'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Customer Email Support'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _upiController,
                        decoration: const InputDecoration(labelText: 'Merchant UPI ID'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _facebookController,
                        decoration: const InputDecoration(labelText: 'Facebook Social Page Link'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _instagramController,
                        decoration: const InputDecoration(labelText: 'Instagram Page Link'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 20),

        // Store policies & pages
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Store Policies & Info Sections', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(controller: _aboutUsController, maxLines: 3, decoration: const InputDecoration(labelText: 'About Us Summary')),
                const SizedBox(height: 12),
                TextFormField(controller: _termsController, maxLines: 3, decoration: const InputDecoration(labelText: 'Terms & Conditions Page Content')),
                const SizedBox(height: 12),
                TextFormField(controller: _privacyController, maxLines: 3, decoration: const InputDecoration(labelText: 'Privacy Policy Content')),
                const SizedBox(height: 12),
                TextFormField(controller: _refundController, maxLines: 3, decoration: const InputDecoration(labelText: 'Refund / Return Policy Content')),
                const SizedBox(height: 12),
                TextFormField(controller: _shippingController, maxLines: 3, decoration: const InputDecoration(labelText: 'Shipping Policy Details')),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Product Coupon Configuration Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Product Coupons', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                  'Set up a coupon code, specify the discount percentage, and select which products are covered under this coupon.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _couponCodeController,
                        decoration: const InputDecoration(labelText: 'Coupon Code (e.g. SAVE10)'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _couponDiscountPercentageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Discount Percentage (%)'),
                        validator: (v) {
                          if (v != null && v.isNotEmpty && (double.tryParse(v) == null || double.parse(v) < 0 || double.parse(v) > 100)) {
                            return 'Enter 0 to 100';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Select products covered under this coupon:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 10),
                
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _couponProductIds.clear();
                          _couponProductIds.addAll(products.map((p) => p.id));
                        });
                      },
                      child: const Text('Select All'),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _couponProductIds.clear();
                        });
                      },
                      child: const Text('Deselect All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: products.isEmpty
                      ? const Center(child: Text('No products available.'))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: products.length,
                          separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          itemBuilder: (context, idx) {
                            final p = products[idx];
                            final isCovered = _couponProductIds.contains(p.id);
                            return CheckboxListTile(
                              value: isCovered,
                              controlAffinity: ListTileControlAffinity.leading,
                              title: Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              subtitle: Text('${p.brand} • Price: ₹${p.sellingPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11)),
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    if (!_couponProductIds.contains(p.id)) {
                                      _couponProductIds.add(p.id);
                                    }
                                  } else {
                                    _couponProductIds.remove(p.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoColumn() {
    return Column(
      children: [
        const Text('Store Logo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 12),
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
          clipBehavior: Clip.antiAlias,
          child: _logoUrl.isNotEmpty ? Image.network(_logoUrl, fit: BoxFit.contain) : const Icon(Icons.image_outlined),
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: _pickAndUploadLogo, child: const Text('Upload File')),
        TextFormField(
          controller: _logoUrlController,
          decoration: const InputDecoration(labelText: 'Or Paste Logo URL', contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
          onChanged: (val) => setState(() => _logoUrl = val.trim()),
        ),
      ],
    );
  }

  Widget _buildFaviconColumn() {
    return Column(
      children: [
        const Text('Favicon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 12),
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
          clipBehavior: Clip.antiAlias,
          child: _faviconUrl.isNotEmpty ? Image.network(_faviconUrl, fit: BoxFit.contain) : const Icon(Icons.blur_on),
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: _pickAndUploadFavicon, child: const Text('Upload File')),
        TextFormField(
          controller: _faviconUrlController,
          decoration: const InputDecoration(labelText: 'Or Paste Favicon URL', contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
          onChanged: (val) => setState(() => _faviconUrl = val.trim()),
        ),
      ],
    );
  }

  Widget _buildAssetsAndBanners(List<Product> products) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Store Assets (Logo & Favicon)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Store Icons & Logo Assets', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(child: _buildLogoColumn()),
                          const SizedBox(width: 24),
                          Expanded(child: _buildFaviconColumn()),
                        ],
                      )
                    : Column(
                        children: [
                          _buildLogoColumn(),
                          const SizedBox(height: 24),
                          _buildFaviconColumn(),
                        ],
                      ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Hero Banners list
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hero Carousel Banners', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                  'Add banner images and select a product to redirect the user to when they tap on the banner.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),

                // Fields to add a new banner
                isDesktop
                    ? Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _bannerImageUrlController,
                              decoration: const InputDecoration(
                                labelText: 'Banner Image URL',
                                hintText: 'e.g. https://alruby.in/asset/image/banner1.jpg',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedBannerProductId,
                              decoration: const InputDecoration(labelText: 'Redirect Product (Optional)'),
                              items: [
                                const DropdownMenuItem<String>(value: null, child: Text('No Redirect')),
                                ...products.map((p) => DropdownMenuItem<String>(value: p.id, child: Text(p.name))),
                              ],
                              onChanged: (val) => setState(() => _selectedBannerProductId = val),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Color(0xFF0F62FE), size: 32),
                            onPressed: () {
                              final url = _bannerImageUrlController.text.trim();
                              if (url.isNotEmpty) {
                                setState(() {
                                  _banners.add(HomeBanner(imageUrl: url, productId: _selectedBannerProductId));
                                  _bannerImageUrlController.clear();
                                  _selectedBannerProductId = null;
                                });
                              }
                            },
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          TextFormField(
                            controller: _bannerImageUrlController,
                            decoration: const InputDecoration(
                              labelText: 'Banner Image URL',
                              hintText: 'e.g. https://alruby.in/asset/image/banner1.jpg',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedBannerProductId,
                                  decoration: const InputDecoration(labelText: 'Redirect Product (Optional)'),
                                  items: [
                                    const DropdownMenuItem<String>(value: null, child: Text('No Redirect')),
                                    ...products.map((p) => DropdownMenuItem<String>(value: p.id, child: Text(p.name))),
                                  ],
                                  onChanged: (val) => setState(() => _selectedBannerProductId = val),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.add_circle, color: Color(0xFF0F62FE), size: 32),
                                onPressed: () {
                                  final url = _bannerImageUrlController.text.trim();
                                  if (url.isNotEmpty) {
                                    setState(() {
                                      _banners.add(HomeBanner(imageUrl: url, productId: _selectedBannerProductId));
                                      _bannerImageUrlController.clear();
                                      _selectedBannerProductId = null;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),

                if (_banners.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text('Active Banners', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _banners.length,
                    itemBuilder: (context, idx) {
                      final b = _banners[idx];
                      final matchingProduct = products.cast<Product?>().firstWhere(
                        (p) => p?.id == b.productId,
                        orElse: () => null,
                      );
                      return Card(
                        color: Theme.of(context).colorScheme.surface,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: b.imageUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    b.imageUrl,
                                    width: 60,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.image, color: Colors.white),
                                  ),
                                )
                              : const Icon(Icons.image, color: Colors.white),
                          title: Text(b.imageUrl, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.white)),
                          subtitle: Text(
                            matchingProduct != null ? 'Redirects to: ${matchingProduct.name}' : 'No Redirect',
                            style: const TextStyle(fontSize: 11, color: Color(0xFFC6A473)),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => setState(() => _banners.removeAt(idx)),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
