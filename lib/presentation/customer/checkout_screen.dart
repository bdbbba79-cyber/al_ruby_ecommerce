import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:al_ruby_ecommerce/presentation/providers/providers.dart';
import 'package:al_ruby_ecommerce/data/models/order.dart';
import 'package:al_ruby_ecommerce/data/models/user_model.dart';
import 'package:al_ruby_ecommerce/data/models/address_model.dart';
import 'package:al_ruby_ecommerce/presentation/customer/my_addresses_screen.dart';
import 'package:al_ruby_ecommerce/core/constants/india_places.dart';
import 'package:al_ruby_ecommerce/core/theme/theme.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  
  final _houseStreetController = TextEditingController();
  final _cityController = TextEditingController();
  final _pinCodeController = TextEditingController();

  final _utrController = TextEditingController();

  String? _selectedState;
  String? _selectedDistrict;
  bool _saveAddress = false;
  String? _selectedAddressId;

  String _paymentMethod = 'COD'; // 'COD' or 'UPI'
  bool _isLoading = false;

  List<String> get _districtsList => _selectedState != null ? (indiaStatesAndDistricts[_selectedState] ?? []) : [];

  void _applyAddress(AddressModel addr) {
    setState(() {
      _selectedAddressId = addr.id;
      if (addr.name.isNotEmpty) _nameController.text = addr.name;
      if (addr.phoneNumber.isNotEmpty) _mobileController.text = addr.phoneNumber;
      _houseStreetController.text = addr.houseStreet;
      _cityController.text = addr.city;
      _pinCodeController.text = addr.pinCode;
      if (addr.state.isNotEmpty && indiaStatesAndDistricts.containsKey(addr.state)) {
        _selectedState = addr.state;
        if (addr.district.isNotEmpty && (indiaStatesAndDistricts[addr.state]?.contains(addr.district) ?? false)) {
          _selectedDistrict = addr.district;
        } else {
          _selectedDistrict = null;
        }
      }
      _saveAddress = true;
    });
  }

  @override
  void initState() {
    super.initState();
    // Pre-populate user details if logged in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserDetailsProvider);
      if (user != null) {
        _nameController.text = user.name;
        _emailController.text = user.email;
        _mobileController.text = user.phoneNumber;

        final addresses = user.allAddresses;
        if (addresses.isNotEmpty) {
          final defaultAddr = addresses.firstWhere((a) => a.isDefault, orElse: () => addresses.first);
          _applyAddress(defaultAddr);
        } else if (user.savedHouseStreet.isNotEmpty) {
          _houseStreetController.text = user.savedHouseStreet;
          _cityController.text = user.savedCity;
          _pinCodeController.text = user.savedPinCode;
          if (user.savedState.isNotEmpty && indiaStatesAndDistricts.containsKey(user.savedState)) {
            _selectedState = user.savedState;
            if (user.savedDistrict.isNotEmpty && (indiaStatesAndDistricts[user.savedState]?.contains(user.savedDistrict) ?? false)) {
              _selectedDistrict = user.savedDistrict;
            }
          }
          _saveAddress = true;
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _houseStreetController.dispose();
    _cityController.dispose();
    _pinCodeController.dispose();
    _utrController.dispose();
    super.dispose();
  }

  Future<void> _launchPhonePe(String merchantUpiId, String merchantName, double amount) async {
    const note = 'IzzfahNoobiOrder';
    final phonePeScheme = 'phonepe://pay?pa=$merchantUpiId&pn=${Uri.encodeComponent(merchantName)}&am=${amount.toStringAsFixed(2)}&cu=INR&tn=$note';
    final phonePeUri = Uri.parse(phonePeScheme);

    final upiScheme = 'upi://pay?pa=$merchantUpiId&pn=${Uri.encodeComponent(merchantName)}&am=${amount.toStringAsFixed(2)}&cu=INR&tn=$note';
    final upiUri = Uri.parse(upiScheme);

    try {
      if (await canLaunchUrl(phonePeUri)) {
        await launchUrl(phonePeUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (e) {
      debugPrint('PhonePe scheme launch failed: $e');
    }

    // Try generic UPI intent as direct fallback
    try {
      if (await canLaunchUrl(upiUri)) {
        await launchUrl(upiUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (e) {
      debugPrint('Generic UPI intent launch failed: $e');
    }

    if (mounted) {
      _showUpiFallbackDialog(merchantUpiId, amount);
    }
  }

  Future<void> _launchGenericUpi(String merchantUpiId, String merchantName, double amount) async {
    const note = 'IzzfahNoobiOrder';
    final upiScheme = 'upi://pay?pa=$merchantUpiId&pn=${Uri.encodeComponent(merchantName)}&am=${amount.toStringAsFixed(2)}&cu=INR&tn=$note';
    final upiUri = Uri.parse(upiScheme);

    try {
      if (await canLaunchUrl(upiUri)) {
        await launchUrl(upiUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (e) {
      debugPrint('UPI intent failed: $e');
    }

    if (mounted) {
      _showUpiFallbackDialog(merchantUpiId, amount);
    }
  }

  void _showUpiFallbackDialog(String upiId, double amount) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('UPI Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'No compatible UPI app could be opened directly on this device or browser.\n\nPlease scan the QR code using PhonePe on your phone, or copy the UPI ID below to transfer:',
              style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFFCBD5E1)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      upiId,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryColor),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18, color: Colors.white),
                    tooltip: 'Copy UPI ID',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: upiId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('UPI ID copied to clipboard!')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK, Got it'),
          ),
        ],
      ),
    );
  }

  void _showUtrHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Where is the UTR Number?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The UTR (Unique Transaction Reference) is a 12-digit number generated for every UPI transfer.',
                style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFFCBD5E1)),
              ),
              SizedBox(height: 12),
              Text('• In PhonePe:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              Text('Go to History > Tap the payment > Look for "UTR" or "Transaction ID" (12 digits)', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              SizedBox(height: 10),
              Text('• In Google Pay:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              Text('Tap payment transaction > Look for "UPI transaction ID" (12 digits)', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              SizedBox(height: 10),
              Text('• In Paytm:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              Text('Tap payment receipt in Balance & History > "UPI Ref No." (12 digits)', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    
    final user = ref.read(currentUserDetailsProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to place an order.')),
      );
      context.push('/login');
      return;
    }

    final cartItems = ref.read(cartProvider);
    final subtotal = ref.read(cartProvider.notifier).subtotal;
    final shippingCharge = ref.read(cartProvider.notifier).shippingFee;
    final businessInfo = ref.read(businessInfoProvider).valueOrNull;
    final appliedCoupon = ref.read(appliedCouponProvider);

    double couponDiscount = 0.0;
    if (businessInfo != null &&
        appliedCoupon != null &&
        appliedCoupon.toUpperCase() == businessInfo.couponCode.toUpperCase()) {
      for (final item in cartItems) {
        if (businessInfo.couponProductIds.contains(item.product.id)) {
          couponDiscount += item.totalPrice * (businessInfo.couponDiscountPercentage / 100);
        }
      }
    }
    final grandTotal = (subtotal + shippingCharge - couponDiscount).clamp(0.0, double.infinity);

    if (_paymentMethod == 'UPI') {
      final utr = _utrController.text.trim();
      if (utr.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your 12-digit UPI UTR Transaction ID.')),
        );
        return;
      }
      if (utr.length < 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid 12-digit UPI UTR Transaction ID.')),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final order = OrderModel(
        id: '', // Generated in repository
        userId: user.id,
        customerName: _nameController.text.trim(),
        customerMobile: _mobileController.text.trim(),
        customerEmail: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        shippingAddress: ShippingAddress(
          houseStreet: _houseStreetController.text.trim(),
          city: _cityController.text.trim(),
          district: _selectedDistrict ?? '',
          state: _selectedState ?? '',
          pinCode: _pinCodeController.text.trim(),
        ),
        items: cartItems.map((item) => OrderItem(
          productId: item.product.id,
          productName: item.selectedVariantSize != null
              ? '${item.product.name} (${item.selectedVariantSize})'
              : item.product.name,
          price: item.unitPrice,
          quantity: item.quantity,
          imageUrl: item.product.images.isNotEmpty ? item.product.images.first : '',
          selectedSize: item.selectedVariantSize,
          referrerCode: item.referrerCode,
        )).toList(),
        subtotal: subtotal,
        shippingCharge: shippingCharge,
        grandTotal: grandTotal,
        paymentMethod: _paymentMethod,
        paymentStatus: _paymentMethod == 'UPI' ? 'Verification Pending' : 'Pending',
        transactionId: _paymentMethod == 'UPI' ? _utrController.text.trim() : null,
        orderStatus: _paymentMethod == 'UPI'
            ? OrderStatus.paymentVerificationPending
            : OrderStatus.pending,
        createdAt: DateTime.now(),
      );

      final orderId = await ref.read(orderRepoProvider).placeOrder(order);

      // Process automatic commissions based on cart items' referrer codes
      final Map<String, double> commissionByReferrerCode = {};
      for (final item in cartItems) {
        final refCode = item.referrerCode;
        if (refCode != null && refCode.isNotEmpty) {
          // A user cannot earn commission on their own purchase
          if (refCode.toUpperCase() == user.referralCode.toUpperCase()) {
            continue;
          }
          final itemCommission = item.totalPrice * 0.05;
          commissionByReferrerCode[refCode] = (commissionByReferrerCode[refCode] ?? 0.0) + itemCommission;
        }
      }

      for (final entry in commissionByReferrerCode.entries) {
        final refCode = entry.key.toUpperCase();
        final commission = entry.value;

        try {
          final referrerQuery = await FirebaseFirestore.instance
              .collection('users')
              .where('referralCode', isEqualTo: refCode)
              .get();
          if (referrerQuery.docs.isNotEmpty) {
            final referrerDoc = referrerQuery.docs.first;
            final referrerUid = referrerDoc.id;
            final currentEarned = (referrerDoc.data()['totalEarned'] as num?)?.toDouble() ?? 0.0;
            await FirebaseFirestore.instance.collection('users').doc(referrerUid).update({
              'totalEarned': currentEarned + commission,
            });
          }
        } catch (e) {
          debugPrint("Failed to update referral commission for code $refCode: $e");
        }
      }

      if (_saveAddress) {
        final name = _nameController.text.trim();
        final phone = _mobileController.text.trim();
        final houseStreet = _houseStreetController.text.trim();
        final city = _cityController.text.trim();
        final district = _selectedDistrict ?? '';
        final state = _selectedState ?? '';
        final pinCode = _pinCodeController.text.trim();

        final currentAddresses = List<AddressModel>.from(user.allAddresses);
        final existingIdx = currentAddresses.indexWhere(
          (a) => (a.id == _selectedAddressId && _selectedAddressId != null && _selectedAddressId != 'default') ||
                 (a.houseStreet.toLowerCase() == houseStreet.toLowerCase() && a.pinCode == pinCode),
        );

        if (existingIdx >= 0) {
          currentAddresses[existingIdx] = currentAddresses[existingIdx].copyWith(
            name: name,
            phoneNumber: phone,
            houseStreet: houseStreet,
            city: city,
            district: district,
            state: state,
            pinCode: pinCode,
          );
        } else {
          currentAddresses.add(AddressModel(
            id: const Uuid().v4(),
            name: name,
            phoneNumber: phone,
            houseStreet: houseStreet,
            city: city,
            district: district,
            state: state,
            pinCode: pinCode,
            tag: 'Home',
            isDefault: currentAddresses.isEmpty,
          ));
        }

        await ref.read(authRepoProvider).saveAddressList(user.id, currentAddresses);

        ref.read(currentUserDetailsProvider.notifier).state = user.copyWith(
          phoneNumber: phone,
          savedHouseStreet: houseStreet,
          savedCity: city,
          savedDistrict: district,
          savedState: state,
          savedPinCode: pinCode,
          addresses: currentAddresses,
        );
      }

      // Clear Cart
      ref.read(cartProvider.notifier).clear();
      ref.read(appliedCouponProvider.notifier).state = null;

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Order Placed Successfully!', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('Your order has been placed with ID: $orderId.\nOur team will process it shortly.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/home');
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserDetailsProvider);
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final subtotal = cartNotifier.subtotal;
    final shippingCharge = cartNotifier.shippingFee;
    final businessInfo = ref.watch(businessInfoProvider).valueOrNull;
    final appliedCoupon = ref.watch(appliedCouponProvider);

    double couponDiscount = 0.0;
    if (businessInfo != null &&
        appliedCoupon != null &&
        appliedCoupon.toUpperCase() == businessInfo.couponCode.toUpperCase()) {
      for (final item in cartItems) {
        if (businessInfo.couponProductIds.contains(item.product.id)) {
          couponDiscount += item.totalPrice * (businessInfo.couponDiscountPercentage / 100);
        }
      }
    }
    final grandTotal = (subtotal + shippingCharge - couponDiscount).clamp(0.0, double.infinity);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 80, color: Color(0xFF94A3B8)),
                const SizedBox(height: 24),
                const Text('Sign In Required', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('You need to be logged in to place an order.', style: TextStyle(color: Color(0xFF64748B))),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.push('/login'),
                  child: const Text('LOG IN / REGISTER'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (cartItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No items in cart to checkout.'),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => context.go('/home'), child: const Text('Go Home')),
            ],
          ),
        ),
      );
    }

    // Dynamic UPI URL Generation
    final merchantUpiId = businessInfo?.upiId ?? 'ismuchelembra-0002@oksbi';
    final merchantName = businessInfo?.companyName ?? 'IZZFAH NOOBI';
    final upiUrl = 'upi://pay?pa=$merchantUpiId&pn=${Uri.encodeComponent(merchantName)}&am=${grandTotal.toStringAsFixed(2)}&cu=INR&tn=IzzfahNoobiOrder';

    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Form(
              key: _formKey,
              child: isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _buildFormSections(user, merchantUpiId, merchantName, upiUrl, grandTotal, isDesktop)),
                        const SizedBox(width: 32),
                        Expanded(child: _buildSummaryAndPlaceOrder(grandTotal)),
                      ],
                    )
                  : Column(
                      children: [
                        _buildFormSections(user, merchantUpiId, merchantName, upiUrl, grandTotal, isDesktop),
                        const SizedBox(height: 24),
                        _buildSummaryAndPlaceOrder(grandTotal),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSavedAddressesSelector(UserModel user) {
    final addresses = user.allAddresses;
    if (addresses.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Select from Saved Addresses:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add_location_alt_outlined, size: 16),
              label: const Text('Manage', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: () async {
                final picked = await Navigator.push<AddressModel>(
                  context,
                  MaterialPageRoute(builder: (c) => const MyAddressesScreen(isPicker: true)),
                );
                if (picked != null) {
                  _applyAddress(picked);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 105,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: addresses.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (ctx, idx) {
              final addr = addresses[idx];
              final isSelected = _selectedAddressId == addr.id;

              return InkWell(
                onTap: () => _applyAddress(addr),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 240,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF1E60D5) : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.8 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                            size: 16,
                            color: isSelected ? const Color(0xFF1E60D5) : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            addr.tag.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? const Color(0xFF1E60D5) : const Color(0xFF64748B),
                            ),
                          ),
                          if (addr.isDefault) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('DEFAULT', style: TextStyle(fontSize: 9, color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        addr.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        '${addr.houseStreet}, ${addr.city} - ${addr.pinCode}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _buildFormSections(UserModel? user, String merchantUpiId, String merchantName, String upiUrl, double totalAmount, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Customer Information
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('1. Customer Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(hintText: 'Customer Name', prefixIcon: Icon(Icons.person_outline)),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(hintText: 'Mobile Number', prefixIcon: Icon(Icons.phone_outlined)),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter mobile number' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'Email (Optional)', prefixIcon: Icon(Icons.email_outlined)),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 20),

        // Shipping Address
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('2. Shipping Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (user != null) _buildSavedAddressesSelector(user),
                TextFormField(
                  controller: _houseStreetController,
                  decoration: const InputDecoration(hintText: 'House No / Street / Landmark', prefixIcon: Icon(Icons.home_outlined)),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter street info' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(hintText: 'City'),
                        validator: (value) => value == null || value.isEmpty ? 'City is required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _pinCodeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: 'PIN Code'),
                        validator: (value) => value == null || value.isEmpty ? 'PIN Code is required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                isDesktop
                    ? Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _selectedState,
                              decoration: const InputDecoration(hintText: 'Select State'),
                              items: indiaStatesAndDistricts.keys.map((state) {
                                return DropdownMenuItem<String>(
                                  value: state,
                                  child: Text(
                                    state,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedState = val;
                                  _selectedDistrict = null;
                                });
                              },
                              validator: (value) => value == null ? 'State is required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _selectedDistrict,
                              decoration: const InputDecoration(hintText: 'Select District'),
                              items: _districtsList.map((dist) {
                                return DropdownMenuItem<String>(
                                  value: dist,
                                  child: Text(
                                    dist,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedDistrict = val;
                                });
                              },
                              validator: (value) => value == null ? 'District is required' : null,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _selectedState,
                            decoration: const InputDecoration(hintText: 'Select State'),
                            items: indiaStatesAndDistricts.keys.map((state) {
                              return DropdownMenuItem<String>(
                                  value: state,
                                  child: Text(
                                    state,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                                  ),
                                );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedState = val;
                                _selectedDistrict = null;
                              });
                            },
                            validator: (value) => value == null ? 'State is required' : null,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _selectedDistrict,
                            decoration: const InputDecoration(hintText: 'Select District'),
                            items: _districtsList.map((dist) {
                              return DropdownMenuItem<String>(
                                value: dist,
                                child: Text(
                                  dist,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedDistrict = val;
                              });
                            },
                            validator: (value) => value == null ? 'District is required' : null,
                          ),
                        ],
                      ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Save Address & Mobile for future orders', style: TextStyle(fontSize: 12, color: Color(0xFF0F172A))),
                  value: _saveAddress,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    setState(() {
                      _saveAddress = val ?? false;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 20),

        // Payment Option
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('3. Payment Option', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                RadioListTile<String>(
                  title: const Text('Cash on Delivery'),
                  subtitle: const Text('Pay when order is delivered'),
                  value: 'COD',
                  groupValue: _paymentMethod,
                  onChanged: (val) {
                    setState(() {
                      _paymentMethod = val!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('UPI / PhonePe Payment'),
                  subtitle: const Text('Instant PhonePe 1-click & QR transfer'),
                  value: 'UPI',
                  groupValue: _paymentMethod,
                  onChanged: (val) {
                    setState(() {
                      _paymentMethod = val!;
                    });
                  },
                ),
                if (_paymentMethod == 'UPI') ...[
                  const Divider(height: 32),
                  _buildPhonePeAndUpiSection(merchantUpiId, merchantName, upiUrl, totalAmount),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhonePeAndUpiSection(String merchantUpiId, String merchantName, String upiUrl, double totalAmount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. PhonePe Direct Pay Primary Action Button
        Material(
          color: const Color(0xFF5F259F), // Official PhonePe Purple
          borderRadius: BorderRadius.circular(12),
          elevation: 3,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _launchPhonePe(merchantUpiId, merchantName, totalAmount),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: Color(0xFF5F259F),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Pay via PhonePe',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'FAST',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Instant 1-Click Pay ₹${totalAmount.toStringAsFixed(0)} in PhonePe app',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 2. Secondary Button: Pay via other UPI Apps
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.white.withOpacity(0.3)),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.apps, size: 20, color: AppTheme.primaryColor),
          label: const Text(
            'Pay with Other UPI App (GPay, Paytm, BHIM)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          onPressed: () => _launchGenericUpi(merchantUpiId, merchantName, totalAmount),
        ),

        const SizedBox(height: 20),

        // 3. Or Scan QR Divider & QR View
        Row(
          children: [
            Expanded(child: Divider(color: Colors.white.withOpacity(0.15))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'OR SCAN QR CODE',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.white.withOpacity(0.15))),
          ],
        ),

        const SizedBox(height: 16),

        Center(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: QrImageView(
              data: upiUrl,
              version: QrVersions.auto,
              size: 190.0,
            ),
          ),
        ),

        const SizedBox(height: 10),
        Center(
          child: Text(
            'Amount to Pay: ₹${totalAmount.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor),
          ),
        ),

        const SizedBox(height: 14),

        // 4. Merchant UPI ID with Quick-Copy Chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.qr_code_2, size: 20, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Merchant UPI ID', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                    SelectableText(
                      merchantUpiId,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: merchantUpiId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Merchant UPI ID copied to clipboard!')),
                  );
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy, size: 14, color: AppTheme.primaryColor),
                      SizedBox(width: 4),
                      Text('Copy', style: TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 5. How to Pay Steps Box
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Color(0xFF38BDF8)),
                  SizedBox(width: 6),
                  Text('How to complete your order:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 8),
              _buildInstructionStep('1', 'Tap "Pay via PhonePe" or scan QR code on mobile.'),
              _buildInstructionStep('2', 'Pay the exact amount (₹${totalAmount.toStringAsFixed(2)}).'),
              _buildInstructionStep('3', 'Copy the 12-digit UTR / Reference ID from the PhonePe receipt.'),
              _buildInstructionStep('4', 'Paste the UTR number below and click Place Order.'),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 6. UTR / Transaction ID Field
        TextFormField(
          controller: _utrController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(16),
          ],
          decoration: InputDecoration(
            labelText: '12-digit UPI Transaction ID / UTR',
            hintText: 'e.g. 425612345678',
            prefixIcon: const Icon(Icons.receipt_long_outlined, color: AppTheme.primaryColor),
            suffixIcon: IconButton(
              icon: const Icon(Icons.help_outline, color: Color(0xFF94A3B8), size: 20),
              tooltip: 'Where to find UTR?',
              onPressed: _showUtrHelpDialog,
            ),
            helperText: 'Found in PhonePe -> History -> Tap Payment -> UTR Number',
            helperStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
          validator: (value) {
            if (_paymentMethod == 'UPI') {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter 12-digit UTR / Transaction ID';
              }
              if (value.trim().length < 10) {
                return 'UTR Number must be at least 10-12 digits';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 16,
            height: 16,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1), height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryAndPlaceOrder(double total) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Grand Total', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
            const SizedBox(height: 4),
            Text(
              '₹${total.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _placeOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('CONFIRM & PLACE ORDER'),
            ),
          ],
        ),
      ),
    );
  }
}
