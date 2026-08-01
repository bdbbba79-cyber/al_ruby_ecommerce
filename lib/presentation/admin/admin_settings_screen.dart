import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:al_ruby_ecommerce/presentation/admin/admin_layout.dart';
import 'package:al_ruby_ecommerce/presentation/providers/providers.dart';
import 'package:al_ruby_ecommerce/data/models/business_info.dart';

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
  final _bannerUrlController = TextEditingController();

  String _logoUrl = '';
  String _faviconUrl = '';
  bool _isSavingInfo = false;

  // Banner states
  List<Map<String, dynamic>> _rawBanners = [];
  bool _isLoadingBanners = false;
  Uint8List? _newBannerBytes;
  String? _newBannerName;
  final _bannerOrderController = TextEditingController(text: '1');
  bool _isUploadingBanner = false;

  @override
  void initState() {
    super.initState();
    _loadBanners();
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
    _bannerOrderController.dispose();
    _logoUrlController.dispose();
    _faviconUrlController.dispose();
    _bannerUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadBanners() async {
    setState(() => _isLoadingBanners = true);
    try {
      final banners = await ref.read(storeRepoProvider).getBannersRaw();
      setState(() => _rawBanners = banners);
    } catch (e) {
      // Handle banner fetch error
    } finally {
      setState(() => _isLoadingBanners = false);
    }
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

  Future<void> _pickBanner() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _newBannerBytes = result.files.single.bytes;
        _newBannerName = result.files.single.name;
      });
    }
  }

  Future<void> _uploadBanner() async {
    final val = _bannerUrlController.text.trim();
    final orderIndex = int.tryParse(_bannerOrderController.text) ?? 1;

    if (val.isNotEmpty) {
      setState(() => _isUploadingBanner = true);
      try {
        await ref.read(storeRepoProvider).addBanner(val, orderIndex);
        setState(() {
          _bannerUrlController.clear();
          _bannerOrderController.text = '${orderIndex + 1}';
        });
        await _loadBanners();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Banner added successfully.')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add banner: $e')));
        }
      } finally {
        if (mounted) {
          setState(() => _isUploadingBanner = false);
        }
      }
      return;
    }

    if (_newBannerBytes == null) return;
    setState(() => _isUploadingBanner = true);

    try {
      final path = 'banners/${DateTime.now().millisecondsSinceEpoch}_$_newBannerName';
      final url = await ref.read(storeRepoProvider).uploadImage(_newBannerBytes!, path);
      
      await ref.read(storeRepoProvider).addBanner(url, orderIndex);
      
      setState(() {
        _newBannerBytes = null;
        _newBannerName = null;
        _bannerOrderController.text = '${orderIndex + 1}';
      });
      
      await _loadBanners();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Banner uploaded successfully.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add banner: $e')));
    } finally {
      if (mounted) {
        setState(() => _isUploadingBanner = false);
      }
    }
  }

  Future<void> _deleteBanner(String id, String imageUrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Banner'),
        content: const Text('Are you sure you want to remove this banner image?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(storeRepoProvider).deleteBanner(id, imageUrl);
      await _loadBanners();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Banner removed.')));
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

    final isDesktop = MediaQuery.of(context).size.width > 900;

    return AdminLayout(
      selectedIndex: 4,
      title: 'Global Settings',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildFormFields()),
                    const SizedBox(width: 24),
                    Expanded(child: _buildAssetsAndBanners()),
                  ],
                )
              : Column(
                  children: [
                    _buildFormFields(),
                    const SizedBox(height: 24),
                    _buildAssetsAndBanners(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildFormFields() {
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
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isSavingInfo ? null : _saveBusinessInfo,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20)),
          child: _isSavingInfo
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('SAVE SETTINGS PROFILE'),
        )
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

  Widget _buildAssetsAndBanners() {
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
                const SizedBox(height: 16),
                
                // Pick & upload banner Form
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickBanner,
                      icon: const Icon(Icons.image),
                      label: Text(_newBannerName == null ? 'Pick Banner File' : 'Change File'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _bannerUrlController,
                        decoration: const InputDecoration(labelText: 'Or Paste Banner URL'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 60,
                      child: TextFormField(
                        controller: _bannerOrderController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Order'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _bannerUrlController,
                  builder: (context, value, child) {
                    final hasUrl = value.text.trim().isNotEmpty;
                    if (_newBannerBytes != null || hasUrl) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasUrl) ...[
                            Container(
                              height: 100,
                              width: double.infinity,
                              decoration: BoxDecoration(border: Border.all(color: Colors.blue), borderRadius: BorderRadius.circular(8)),
                              clipBehavior: Clip.antiAlias,
                              child: Image.network(value.text.trim(), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Text('Invalid Image URL'))),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (_newBannerBytes != null && !hasUrl) ...[
                            Container(
                              height: 100,
                              width: double.infinity,
                              decoration: BoxDecoration(border: Border.all(color: Colors.blue), borderRadius: BorderRadius.circular(8)),
                              clipBehavior: Clip.antiAlias,
                              child: Image.memory(_newBannerBytes!, fit: BoxFit.cover),
                            ),
                            const SizedBox(height: 12),
                          ],
                          ElevatedButton(
                            onPressed: _isUploadingBanner ? null : _uploadBanner,
                            child: _isUploadingBanner
                                ? const SizedBox(height: 15, width: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Add Banner'),
                          ),
                        ],
                      );
                    }
                    return const SizedBox();
                  },
                ),

                const Divider(height: 32),

                // Existing Banners List
                const Text('Active Banners', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 12),
                _isLoadingBanners
                    ? const Center(child: CircularProgressIndicator())
                    : (_rawBanners.isEmpty
                        ? const Text('No active banners. Default combo offer will be displayed.', style: TextStyle(fontSize: 12, color: Colors.grey))
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _rawBanners.length,
                            itemBuilder: (context, index) {
                              final b = _rawBanners[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12.0),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        height: 50,
                                        width: 80,
                                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
                                        clipBehavior: Clip.antiAlias,
                                        child: Image.network(b['imageUrl'], fit: BoxFit.cover),
                                      ),
                                      const SizedBox(width: 16),
                                      Text('Order: ${b['order']}'),
                                      const Spacer(),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: () => _deleteBanner(b['id'], b['imageUrl']),
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
