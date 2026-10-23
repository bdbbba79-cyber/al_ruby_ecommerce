import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:al_ruby_ecommerce/presentation/admin/admin_layout.dart';
import 'package:al_ruby_ecommerce/presentation/providers/providers.dart';
import 'package:al_ruby_ecommerce/data/models/business_info.dart';
import 'package:al_ruby_ecommerce/data/models/product.dart';
import 'package:al_ruby_ecommerce/data/models/category.dart';
import 'package:al_ruby_ecommerce/presentation/widgets/app_network_image.dart';
import 'package:al_ruby_ecommerce/data/services/order_alert_service.dart';

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

  // Promo / Lifestyle Specials Banner
  final _promoTagController = TextEditingController();
  final _promoTitleController = TextEditingController();
  final _promoButtonTextController = TextEditingController();
  final _promoCustomUrlController = TextEditingController();
  String _promoTargetType = 'all_products'; // 'all_products', 'category', 'product', 'url'
  String? _selectedPromoCategory;
  String? _selectedPromoProductId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final info = ref.read(businessInfoProvider).valueOrNull;
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
    _promoTagController.text = info.promoBannerTag;
    _promoTitleController.text = info.promoBannerTitle;
    _promoButtonTextController.text = info.promoBannerButtonText;
    _promoTargetType = info.promoBannerTargetType.isNotEmpty ? info.promoBannerTargetType : 'all_products';
    if (_promoTargetType == 'category') {
      _selectedPromoCategory = info.promoBannerTargetValue;
    } else if (_promoTargetType == 'product') {
      _selectedPromoProductId = info.promoBannerTargetValue;
    } else if (_promoTargetType == 'url') {
      _promoCustomUrlController.text = info.promoBannerTargetValue;
    }
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
    _promoTagController.dispose();
    _promoTitleController.dispose();
    _promoButtonTextController.dispose();
    _promoCustomUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadLogo() async {
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
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading Company Logo...')));
          final url = await ref.read(businessRepoProvider).uploadLogo(bytes);
          if (!mounted) return;
          setState(() {
            _logoUrl = url;
            _logoUrlController.text = url;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Company Logo uploaded.')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  Future<void> _pickAndUploadFavicon() async {
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
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading Favicon...')));
          final url = await ref.read(businessRepoProvider).uploadFavicon(bytes);
          if (!mounted) return;
          setState(() {
            _faviconUrl = url;
            _faviconUrlController.text = url;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Favicon uploaded.')));
        }
      }
    } catch (e) {
      if (mounted) {
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
        promoBannerTag: _promoTagController.text.trim().isEmpty ? 'LIFESTYLE SPECIALS' : _promoTagController.text.trim(),
        promoBannerTitle: _promoTitleController.text.trim().isEmpty ? 'UP TO 40% OFF ON WATCHES, APPAREL & FOOTWEAR' : _promoTitleController.text.trim(),
        promoBannerButtonText: _promoButtonTextController.text.trim().isEmpty ? 'SHOP NOW' : _promoButtonTextController.text.trim(),
        promoBannerTargetType: _promoTargetType,
        promoBannerTargetValue: _promoTargetType == 'category'
            ? (_selectedPromoCategory ?? '')
            : _promoTargetType == 'product'
                ? (_selectedPromoProductId ?? '')
                : _promoTargetType == 'url'
                    ? _promoCustomUrlController.text.trim()
                    : '',
      );

      await ref.read(businessRepoProvider).updateBusinessInfo(info);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Business Settings updated successfully.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSavingInfo = false);
      }
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
    final categories = ref.watch(categoriesProvider).value ?? [];
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
                        Expanded(child: _buildAssetsAndBanners(products, categories)),
                      ],
                    )
                  : Column(
                      children: [
                        _buildFormFields(products),
                        const SizedBox(height: 24),
                        _buildAssetsAndBanners(products, categories),
                      ],
                    ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSavingInfo ? null : _saveBusinessInfo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F62FE),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                icon: _isSavingInfo
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: const Text('SAVE ALL SETTINGS'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTwoFieldRow(Widget field1, Widget field2, bool isDesktop) {
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: field1),
          const SizedBox(width: 14),
          Expanded(child: field2),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          field1,
          const SizedBox(height: 14),
          field2,
        ],
      );
    }
  }

  Widget _buildFormFields(List<Product> products) {
    final isDesktop = MediaQuery.of(context).size.width > 768;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Store Details
        AdminLayout.buildSectionCard(
          title: 'Store Profile Details',
          icon: Icons.storefront_outlined,
          subtitle: 'Brand identity, official address, and communication channels',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Company Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address Details'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              _buildTwoFieldRow(
                TextFormField(
                  controller: _mobileController,
                  decoration: const InputDecoration(labelText: 'Mobile Phone Number'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _whatsappController,
                  decoration: const InputDecoration(
                    labelText: 'WhatsApp Number',
                    hintText: 'e.g. 9656978468 or 919656978468',
                    helperText: '10-digit mobile or with country code',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                isDesktop,
              ),
              const SizedBox(height: 14),
              _buildTwoFieldRow(
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Customer Email Support'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _upiController,
                  decoration: const InputDecoration(labelText: 'Merchant UPI ID'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                isDesktop,
              ),
              const SizedBox(height: 14),
              _buildTwoFieldRow(
                TextFormField(
                  controller: _facebookController,
                  decoration: const InputDecoration(labelText: 'Facebook Social Page Link'),
                ),
                TextFormField(
                  controller: _instagramController,
                  decoration: const InputDecoration(labelText: 'Instagram Page Link'),
                ),
                isDesktop,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),

        // Order Alert Sound Card
        AdminLayout.buildSectionCard(
          title: 'Order Arrival Sound Alert (30 Seconds)',
          icon: Icons.notifications_active_outlined,
          subtitle: 'Continuous 30-second alarm chime when a new order arrives (Admin panel only)',
          trailing: ValueListenableBuilder<bool>(
            valueListenable: OrderAlertService().isSoundEnabledNotifier,
            builder: (context, enabled, _) {
              return Switch(
                value: enabled,
                activeColor: const Color(0xFF0F62FE),
                onChanged: (val) {
                  OrderAlertService().isSoundEnabled = val;
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(val ? '🔔 Order alert sound ENABLED' : '🔕 Order alert sound MUTED'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              );
            },
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'When enabled, an urgent, loud alarm will ring continuously for 30 seconds whenever a customer places an order, or until you click STOP ALARM. The customer storefront remains completely silent.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<bool>(
                valueListenable: OrderAlertService().isAlertActiveNotifier,
                builder: (context, isActive, _) {
                  if (isActive) {
                    return ValueListenableBuilder<int>(
                      valueListenable: OrderAlertService().remainingSecondsNotifier,
                      builder: (context, remaining, _) {
                        return ElevatedButton.icon(
                          onPressed: () {
                            OrderAlertService().stopAlert();
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('⏹️ Alert stopped by admin'),
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.stop_circle, size: 20),
                          label: Text('STOP ALARM (${remaining}s remaining)', style: const TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        );
                      },
                    );
                  }

                  return OutlinedButton.icon(
                    onPressed: () async {
                      await OrderAlertService().playTestAlert();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🔊 30-second alarm test started. Click STOP ALARM to silence.'),
                            duration: Duration(seconds: 3),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.volume_up, size: 18, color: Color(0xFF0F62FE)),
                    label: const Text('Test Alert Sound (30s Loop)', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F62FE),
                      side: const BorderSide(color: Color(0xFF0F62FE)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Store policies & pages
        AdminLayout.buildSectionCard(
          title: 'Store Policies & Legal Pages',
          icon: Icons.policy_outlined,
          subtitle: 'Content shown on storefront customer support and legal policies',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(controller: _aboutUsController, maxLines: 3, decoration: const InputDecoration(labelText: 'About Us Summary')),
              const SizedBox(height: 14),
              TextFormField(controller: _termsController, maxLines: 3, decoration: const InputDecoration(labelText: 'Terms & Conditions Page Content')),
              const SizedBox(height: 14),
              TextFormField(controller: _privacyController, maxLines: 3, decoration: const InputDecoration(labelText: 'Privacy Policy Content')),
              const SizedBox(height: 14),
              TextFormField(controller: _refundController, maxLines: 3, decoration: const InputDecoration(labelText: 'Refund / Return Policy Content')),
              const SizedBox(height: 14),
              TextFormField(controller: _shippingController, maxLines: 3, decoration: const InputDecoration(labelText: 'Shipping Policy Details')),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Product Coupon Configuration Card
        AdminLayout.buildSectionCard(
          title: 'Product Coupons',
          icon: Icons.discount_outlined,
          subtitle: 'Set up discount codes and applicable products',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTwoFieldRow(
                TextFormField(
                  controller: _couponCodeController,
                  decoration: const InputDecoration(labelText: 'Coupon Code (e.g. SAVE10)'),
                ),
                TextFormField(
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
                isDesktop,
              ),
              const SizedBox(height: 20),
              const Text(
                'Select products covered under this coupon:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 10),
              
              Row(
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.select_all, size: 16),
                    onPressed: () {
                      setState(() {
                        _couponProductIds.clear();
                        _couponProductIds.addAll(products.map((p) => p.id));
                      });
                    },
                    label: const Text('Select All'),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    icon: const Icon(Icons.deselect, size: 16),
                    onPressed: () {
                      setState(() {
                        _couponProductIds.clear();
                      });
                    },
                    label: const Text('Deselect All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              Container(
                height: 220,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(10),
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
          child: _logoUrl.isNotEmpty
              ? AppNetworkImage(imageUrl: _logoUrl, height: 80, width: 80, cacheWidth: 160, cacheHeight: 160, fit: BoxFit.contain, fallbackAsset: 'assets/logo/logo.png')
              : Image.asset('assets/logo/logo.png', height: 80, width: 80, fit: BoxFit.contain),
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
          child: _faviconUrl.isNotEmpty
              ? AppNetworkImage(imageUrl: _faviconUrl, height: 80, width: 80, cacheWidth: 160, cacheHeight: 160, fit: BoxFit.contain, fallbackAsset: 'assets/logo/favicon.png')
              : Image.asset('assets/logo/favicon.png', height: 80, width: 80, fit: BoxFit.contain),
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

  Widget _buildAssetsAndBanners(List<Product> products, List<Category> categories) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Store Assets (Logo & Favicon)
        AdminLayout.buildSectionCard(
          title: 'Store Icons & Brand Assets',
          icon: Icons.image_outlined,
          subtitle: 'Upload brand logo and website favicon for store identity',
          child: isDesktop
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
        ),

        const SizedBox(height: 20),

        // Hero Banners list
        AdminLayout.buildSectionCard(
          title: 'Hero Carousel Banners',
          icon: Icons.view_carousel_outlined,
          subtitle: 'Configure promotional hero banners on the mobile & web storefront',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                              hintText: 'e.g. https://example.com/banner1.jpg',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedBannerProductId,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Redirect Product (Optional)'),
                            items: [
                              const DropdownMenuItem<String>(value: null, child: Text('No Redirect')),
                              ...products.map((p) => DropdownMenuItem<String>(
                                value: p.id,
                                child: Text(p.name, overflow: TextOverflow.ellipsis),
                              )),
                            ],
                            onChanged: (val) => setState(() => _selectedBannerProductId = val),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Color(0xFF0F62FE), size: 36),
                          tooltip: 'Add Banner',
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
                            hintText: 'e.g. https://example.com/banner1.jpg',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedBannerProductId,
                                isExpanded: true,
                                decoration: const InputDecoration(labelText: 'Redirect Product (Optional)'),
                                items: [
                                  const DropdownMenuItem<String>(value: null, child: Text('No Redirect')),
                                  ...products.map((p) => DropdownMenuItem<String>(
                                    value: p.id,
                                    child: Text(p.name, overflow: TextOverflow.ellipsis),
                                  )),
                                ],
                                onChanged: (val) => setState(() => _selectedBannerProductId = val),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.add_circle, color: Color(0xFF0F62FE), size: 36),
                              tooltip: 'Add Banner',
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
                const Text('Active Banners', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
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
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: b.imageUrl.isNotEmpty
                            ? AppNetworkImage(
                                imageUrl: b.imageUrl,
                                width: 60,
                                height: 40,
                                cacheWidth: 120,
                                cacheHeight: 80,
                                fit: BoxFit.cover,
                                borderRadius: BorderRadius.circular(6),
                                errorWidget: const Icon(Icons.image, color: Color(0xFF94A3B8)),
                              )
                            : const Icon(Icons.image, color: Color(0xFF94A3B8)),
                        title: Text(
                          b.imageUrl,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                        ),
                        subtitle: Text(
                          matchingProduct != null ? 'Redirects to: ${matchingProduct.name}' : 'No Redirect',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF0F62FE), fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
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

        const SizedBox(height: 20),

        // Homepage Promo Banner (Lifestyle Specials) Configuration Card
        _buildPromoBannerCard(products, categories, isDesktop),
      ],
    );
  }

  Widget _buildPromoBannerCard(List<Product> products, List<Category> categories, bool isDesktop) {
    return AdminLayout.buildSectionCard(
      title: 'Homepage Promo Banner (Lifestyle Specials)',
      icon: Icons.campaign_outlined,
      subtitle: 'Customize banner text, promotional headline, button label, and click destination',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Tag & Button Text in a row
          _buildTwoFieldRow(
            TextFormField(
              controller: _promoTagController,
              decoration: const InputDecoration(
                labelText: 'Banner Tag (Top Subtitle)',
                hintText: 'e.g. LIFESTYLE SPECIALS',
              ),
              onChanged: (_) => setState(() {}),
            ),
            TextFormField(
              controller: _promoButtonTextController,
              decoration: const InputDecoration(
                labelText: 'Button Label',
                hintText: 'e.g. SHOP NOW',
              ),
              onChanged: (_) => setState(() {}),
            ),
            isDesktop,
          ),
          const SizedBox(height: 14),

          // Banner Main Title
          TextFormField(
            controller: _promoTitleController,
            decoration: const InputDecoration(
              labelText: 'Main Promotion Headline',
              hintText: 'e.g. UP TO 40% OFF ON WATCHES, APPAREL & FOOTWEAR',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // Action Type Selector
          DropdownButtonFormField<String>(
            value: _promoTargetType,
            decoration: const InputDecoration(
              labelText: 'Button Navigation Action',
              helperText: 'Select where the customer is redirected upon tapping the button',
            ),
            items: const [
              DropdownMenuItem(value: 'all_products', child: Text('Open All Products (Catalog)')),
              DropdownMenuItem(value: 'category', child: Text('Filter by Specific Category')),
              DropdownMenuItem(value: 'product', child: Text('Open Specific Product Detail')),
              DropdownMenuItem(value: 'url', child: Text('Custom Web Link or App Route')),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _promoTargetType = val;
                });
              }
            },
          ),
          const SizedBox(height: 14),

          // Contextual Target Selector based on _promoTargetType
          if (_promoTargetType == 'category') ...[
            DropdownButtonFormField<String>(
              value: categories.any((c) => c.name == _selectedPromoCategory) ? _selectedPromoCategory : null,
              decoration: const InputDecoration(
                labelText: 'Select Destination Category',
                hintText: 'Choose a category',
              ),
              items: categories.map((c) {
                return DropdownMenuItem<String>(
                  value: c.name,
                  child: Text(c.name),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedPromoCategory = val),
            ),
            const SizedBox(height: 14),
          ] else if (_promoTargetType == 'product') ...[
            DropdownButtonFormField<String>(
              value: products.any((p) => p.id == _selectedPromoProductId) ? _selectedPromoProductId : null,
              decoration: const InputDecoration(
                labelText: 'Select Destination Product',
                hintText: 'Choose a product',
              ),
              isExpanded: true,
              items: products.map((p) {
                return DropdownMenuItem<String>(
                  value: p.id,
                  child: Text('${p.name} (₹${p.sellingPrice.toStringAsFixed(0)})', overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedPromoProductId = val),
            ),
            const SizedBox(height: 14),
          ] else if (_promoTargetType == 'url') ...[
            TextFormField(
              controller: _promoCustomUrlController,
              decoration: const InputDecoration(
                labelText: 'External URL or Custom Route',
                hintText: 'e.g. https://... or /cart',
              ),
            ),
            const SizedBox(height: 14),
          ],

          const Divider(height: 28, color: Color(0xFFE2E8F0)),

          // Live Preview
          const Row(
            children: [
              Icon(Icons.remove_red_eye_outlined, size: 16, color: Color(0xFF1E60D5)),
              SizedBox(width: 6),
              Text(
                'Live Storefront Preview:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E60D5)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _promoTagController.text.trim().isEmpty ? 'LIFESTYLE SPECIALS' : _promoTagController.text.trim().toUpperCase(),
                  style: const TextStyle(color: Color(0xFF1E60D5), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
                ),
                const SizedBox(height: 6),
                Text(
                  _promoTitleController.text.trim().isEmpty ? 'UP TO 40% OFF ON WATCHES, APPAREL & FOOTWEAR' : _promoTitleController.text.trim(),
                  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E60D5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: Text(
                    _promoButtonTextController.text.trim().isEmpty ? 'SHOP NOW' : _promoButtonTextController.text.trim().toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
