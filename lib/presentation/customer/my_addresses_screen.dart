import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:al_ruby_ecommerce/data/models/address_model.dart';
import 'package:al_ruby_ecommerce/data/models/user_model.dart';
import 'package:al_ruby_ecommerce/presentation/providers/providers.dart';
import 'package:al_ruby_ecommerce/core/constants/india_places.dart';

class MyAddressesScreen extends ConsumerStatefulWidget {
  final bool isPicker;
  const MyAddressesScreen({super.key, this.isPicker = false});

  @override
  ConsumerState<MyAddressesScreen> createState() => _MyAddressesScreenState();
}

class _MyAddressesScreenState extends ConsumerState<MyAddressesScreen> {
  void _openAddressDialog([AddressModel? existingAddress]) {
    final user = ref.read(currentUserDetailsProvider);
    if (user == null) return;

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: existingAddress?.name ?? user.name);
    final phoneController = TextEditingController(text: existingAddress?.phoneNumber ?? user.phoneNumber);
    final houseStreetController = TextEditingController(text: existingAddress?.houseStreet ?? '');
    final cityController = TextEditingController(text: existingAddress?.city ?? '');
    final pinCodeController = TextEditingController(text: existingAddress?.pinCode ?? '');
    
    String? selectedState = existingAddress?.state ?? (user.savedState.isNotEmpty ? user.savedState : 'Kerala');
    if (!indiaStatesAndDistricts.containsKey(selectedState)) {
      selectedState = 'Kerala';
    }

    String? selectedDistrict = existingAddress?.district ?? (user.savedDistrict.isNotEmpty ? user.savedDistrict : null);
    final districts = indiaStatesAndDistricts[selectedState] ?? [];
    if (selectedDistrict != null && !districts.contains(selectedDistrict)) {
      selectedDistrict = null;
    }

    String selectedTag = existingAddress?.tag ?? 'Home';
    bool isDefault = existingAddress?.isDefault ?? (user.allAddresses.isEmpty);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final currentDistricts = selectedState != null ? (indiaStatesAndDistricts[selectedState] ?? []) : <String>[];

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          existingAddress != null ? 'Edit Address' : 'Add New Address',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Full Name *', prefixIcon: Icon(Icons.person_outline, size: 20)),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Please enter name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone Number (10 digits) *', prefixIcon: Icon(Icons.phone_outlined, size: 20)),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Please enter phone';
                        final clean = v.replaceAll(RegExp(r'[^0-9]'), '');
                        if (clean.length < 10) return 'Enter 10-digit number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: houseStreetController,
                      decoration: const InputDecoration(labelText: 'House / Building / Street *', prefixIcon: Icon(Icons.home_outlined, size: 20)),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Please enter street address' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: cityController,
                            decoration: const InputDecoration(labelText: 'City / Town *'),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Enter city' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: pinCodeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'PIN Code *'),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Enter PIN';
                              if (v.trim().length != 6) return '6 digits';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedState,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'State *'),
                      items: indiaStatesAndDistricts.keys.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) {
                        setModalState(() {
                          selectedState = val;
                          selectedDistrict = null;
                        });
                      },
                      validator: (v) => v == null || v.isEmpty ? 'Select state' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedDistrict,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'District *'),
                      items: currentDistricts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                      onChanged: (val) {
                        setModalState(() {
                          selectedDistrict = val;
                        });
                      },
                      validator: (v) => v == null || v.isEmpty ? 'Select district' : null,
                    ),
                    const SizedBox(height: 16),
                    const Text('Address Type:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                    const SizedBox(height: 8),
                    Row(
                      children: ['Home', 'Work', 'Other'].map((tag) {
                        final isSel = selectedTag == tag;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(tag),
                            selected: isSel,
                            selectedColor: const Color(0xFF1E60D5),
                            labelStyle: TextStyle(
                              color: isSel ? Colors.white : const Color(0xFF0F172A),
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            onSelected: (_) => setModalState(() => selectedTag = tag),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: isDefault,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text('Set as default delivery address', style: TextStyle(fontSize: 13)),
                      onChanged: (val) => setModalState(() => isDefault = val ?? false),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E60D5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;

                        final newAddress = AddressModel(
                          id: existingAddress?.id ?? const Uuid().v4(),
                          name: nameController.text.trim(),
                          phoneNumber: phoneController.text.trim(),
                          houseStreet: houseStreetController.text.trim(),
                          city: cityController.text.trim(),
                          district: selectedDistrict ?? '',
                          state: selectedState ?? '',
                          pinCode: pinCodeController.text.trim(),
                          tag: selectedTag,
                          isDefault: isDefault,
                        );

                        final currentList = List<AddressModel>.from(user.allAddresses);
                        if (existingAddress != null) {
                          final idx = currentList.indexWhere((a) => a.id == existingAddress.id);
                          if (idx >= 0) {
                            currentList[idx] = newAddress;
                          } else {
                            currentList.add(newAddress);
                          }
                        } else {
                          currentList.add(newAddress);
                        }

                        // If set to default or only address, make sure all others are not default
                        if (isDefault || currentList.length == 1) {
                          for (int i = 0; i < currentList.length; i++) {
                            currentList[i] = currentList[i].copyWith(isDefault: currentList[i].id == newAddress.id);
                          }
                        }

                        Navigator.pop(ctx);
                        await _saveAddressesToFirestore(currentList);
                      },
                      child: Text(existingAddress != null ? 'UPDATE ADDRESS' : 'SAVE ADDRESS'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveAddressesToFirestore(List<AddressModel> updatedList) async {
    final user = ref.read(currentUserDetailsProvider);
    if (user == null) return;

    try {
      await ref.read(authRepoProvider).saveAddressList(user.id, updatedList);
      ref.read(currentUserDetailsProvider.notifier).state = user.copyWith(addresses: updatedList);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Addresses updated successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save address: $e')),
        );
      }
    }
  }

  Future<void> _deleteAddress(AddressModel address) async {
    final user = ref.read(currentUserDetailsProvider);
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Address'),
        content: Text('Are you sure you want to delete the address "${address.houseStreet}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final updatedList = List<AddressModel>.from(user.allAddresses)..removeWhere((a) => a.id == address.id);
      if (address.isDefault && updatedList.isNotEmpty) {
        updatedList[0] = updatedList[0].copyWith(isDefault: true);
      }
      await _saveAddressesToFirestore(updatedList);
    }
  }

  Future<void> _setDefaultAddress(AddressModel address) async {
    final user = ref.read(currentUserDetailsProvider);
    if (user == null) return;

    final updatedList = user.allAddresses.map((a) {
      return a.copyWith(isDefault: a.id == address.id);
    }).toList();

    await _saveAddressesToFirestore(updatedList);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserDetailsProvider);
    final addresses = user?.allAddresses ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.isPicker ? 'SELECT DELIVERY ADDRESS' : 'MY ADDRESSES', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: addresses.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: addresses.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final addr = addresses[index];
                return _buildAddressCard(addr);
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E60D5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _openAddressDialog(),
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('ADD NEW ADDRESS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_off_outlined, size: 64, color: Color(0xFF1E60D5)),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Saved Addresses',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your delivery addresses here for quick and seamless checkout.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(AddressModel addr) {
    return InkWell(
      onTap: widget.isPicker
          ? () => Navigator.pop(context, addr)
          : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: addr.isDefault ? const Color(0xFF1E60D5) : const Color(0xFFE2E8F0),
            width: addr.isDefault ? 1.8 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    addr.tag.toUpperCase(),
                    style: const TextStyle(color: Color(0xFF1E60D5), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                if (addr.isDefault) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: const Text(
                      'DEFAULT',
                      style: TextStyle(color: Color(0xFF059669), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                const Spacer(),
                if (widget.isPicker)
                  const Icon(Icons.radio_button_checked, color: Color(0xFF1E60D5))
                else ...[
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF1E60D5)),
                    tooltip: 'Edit',
                    onPressed: () => _openAddressDialog(addr),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    tooltip: 'Delete',
                    onPressed: () => _deleteAddress(addr),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              addr.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            Text(
              '${addr.houseStreet}, ${addr.city}, ${addr.district}, ${addr.state} - ${addr.pinCode}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
            ),
            const SizedBox(height: 6),
            Text(
              'Phone: ${addr.phoneNumber}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E60D5)),
            ),
            if (!widget.isPicker && !addr.isDefault) ...[
              const Divider(height: 20, color: Color(0xFFF1F5F9)),
              InkWell(
                onTap: () => _setDefaultAddress(addr),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF64748B)),
                      SizedBox(width: 6),
                      Text('Set as default address', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
