import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:al_ruby_ecommerce/presentation/providers/providers.dart';
import 'package:al_ruby_ecommerce/data/models/order.dart';

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
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();
  final _pinCodeController = TextEditingController();

  final _utrController = TextEditingController();

  String _paymentMethod = 'COD'; // 'COD' or 'UPI'
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-populate user details if logged in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserDetailsProvider);
      if (user != null) {
        _nameController.text = user.name;
        _emailController.text = user.email;
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
    _districtController.dispose();
    _stateController.dispose();
    _pinCodeController.dispose();
    _utrController.dispose();
    super.dispose();
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
    const shippingCharge = 50.0;
    final grandTotal = subtotal + shippingCharge;

    if (_paymentMethod == 'UPI' && _utrController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your UPI UTR Transaction ID.')),
      );
      return;
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
          district: _districtController.text.trim(),
          state: _stateController.text.trim(),
          pinCode: _pinCodeController.text.trim(),
        ),
        items: cartItems.map((item) => OrderItem(
          productId: item.product.id,
          productName: item.product.name,
          price: item.product.sellingPrice,
          quantity: item.quantity,
          imageUrl: item.product.images.isNotEmpty ? item.product.images.first : '',
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

      // Clear Cart
      ref.read(cartProvider.notifier).clear();

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
    final subtotal = ref.read(cartProvider.notifier).subtotal;
    const shippingCharge = 50.0;
    final grandTotal = subtotal + shippingCharge;
    final businessInfo = ref.watch(businessInfoProvider).value;

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
    final merchantName = businessInfo?.companyName ?? 'Al Ruby Perfumes';
    final upiUrl = 'upi://pay?pa=$merchantUpiId&pn=${Uri.encodeComponent(merchantName)}&am=${grandTotal.toStringAsFixed(2)}&cu=INR&tn=AlRubyPerfumesOrder';

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
                        Expanded(flex: 2, child: _buildFormSections(upiUrl, grandTotal)),
                        const SizedBox(width: 32),
                        Expanded(child: _buildSummaryAndPlaceOrder(grandTotal)),
                      ],
                    )
                  : Column(
                      children: [
                        _buildFormSections(upiUrl, grandTotal),
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

  Widget _buildFormSections(String upiUrl, double totalAmount) {
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
                        controller: _districtController,
                        decoration: const InputDecoration(hintText: 'District'),
                        validator: (value) => value == null || value.isEmpty ? 'District is required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stateController,
                        decoration: const InputDecoration(hintText: 'State'),
                        validator: (value) => value == null || value.isEmpty ? 'State is required' : null,
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
                  title: const Text('UPI Payment'),
                  subtitle: const Text('Instant QR scan & transfer'),
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
                  const Text(
                    'Scan the QR code below using Google Pay, PhonePe, Paytm, BHIM, or any UPI app to complete the transaction:',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: QrImageView(
                        data: upiUrl,
                        version: QrVersions.auto,
                        size: 200.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Amount: ₹${totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _utrController,
                    decoration: const InputDecoration(
                      hintText: 'Enter 12-digit UPI Transaction ID / UTR Number',
                      prefixIcon: Icon(Icons.receipt_outlined),
                    ),
                    validator: (value) {
                      if (_paymentMethod == 'UPI' && (value == null || value.trim().isEmpty)) {
                        return 'UTR Number / Transaction ID is required for verification';
                      }
                      return null;
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
