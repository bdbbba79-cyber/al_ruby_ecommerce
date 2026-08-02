import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:al_ruby_ecommerce/presentation/providers/providers.dart';
import 'package:al_ruby_ecommerce/data/models/business_info.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _couponController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final applied = ref.read(appliedCouponProvider);
      if (applied != null) {
        _couponController.text = applied;
      }
    });
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _applyCoupon(String code, BusinessInfo? businessInfo) {
    if (businessInfo == null) return;
    if (code.trim().isEmpty) {
      ref.read(appliedCouponProvider.notifier).state = null;
      return;
    }

    if (code.trim().toUpperCase() == businessInfo.couponCode.toUpperCase()) {
      ref.read(appliedCouponProvider.notifier).state = code.trim().toUpperCase();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Coupon "${businessInfo.couponCode}" applied successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid coupon code')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final businessInfo = ref.watch(businessInfoProvider).value;
    final appliedCoupon = ref.watch(appliedCouponProvider);

    final subtotal = cartNotifier.subtotal;
    final shippingCharge = cartNotifier.shippingFee;

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
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('MY CART', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: cartItems.isEmpty
          ? _buildEmptyCart(context)
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 2, child: _buildCartItemsList(context, cartItems, cartNotifier)),
                            const SizedBox(width: 32),
                            Expanded(
                              child: _buildOrderSummaryCard(
                                context,
                                subtotal,
                                couponDiscount,
                                shippingCharge,
                                grandTotal,
                                appliedCoupon,
                                businessInfo,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _buildCartItemsList(context, cartItems, cartNotifier),
                            const SizedBox(height: 24),
                            _buildOrderSummaryCard(
                              context,
                              subtotal,
                              couponDiscount,
                              shippingCharge,
                              grandTotal,
                              appliedCoupon,
                              businessInfo,
                            ),
                          ],
                        ),
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 24),
            const Text(
              'Your Cart is Empty',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('START SHOPPING'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemsList(BuildContext context, List<CartItem> items, CartNotifier notifier) {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) => const Divider(color: Color(0xFF05372B), height: 1),
        itemBuilder: (context, index) {
          final item = items[index];
          final product = item.product;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF05372B)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: product.images.isNotEmpty
                      ? Image.network(product.images.first, fit: BoxFit.cover)
                      : Container(color: Colors.grey.shade800),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.selectedVariantSize != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Size: ${item.selectedVariantSize}',
                          style: const TextStyle(color: Color(0xFFC6A473), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        '₹${item.unitPrice.toStringAsFixed(0)} each',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      if (product.shippingFee > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Shipping: ₹${product.shippingFee.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildQuantityButton(context, Icons.remove, () {
                            notifier.updateQuantity(product, item.quantity - 1, selectedVariantSize: item.selectedVariantSize);
                          }),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0),
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                          _buildQuantityButton(context, Icons.add, () {
                            notifier.updateQuantity(product, item.quantity + 1, selectedVariantSize: item.selectedVariantSize);
                          }),
                          const Spacer(),
                          Text(
                            '₹${item.totalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuantityButton(BuildContext context, IconData icon, VoidCallback onTap) {
    return Material(
      color: const Color(0xFF05372B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Icon(icon, size: 14, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard(
    BuildContext context,
    double subtotal,
    double discount,
    double shipping,
    double total,
    String? appliedCoupon,
    BusinessInfo? businessInfo,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 20),
            
            // Coupon Code Field
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _couponController,
                    enabled: appliedCoupon == null,
                    decoration: const InputDecoration(
                      hintText: 'Coupon Code',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    if (appliedCoupon != null) {
                      ref.read(appliedCouponProvider.notifier).state = null;
                      _couponController.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coupon removed')),
                      );
                    } else {
                      _applyCoupon(_couponController.text, businessInfo);
                    }
                  },
                  child: Text(
                    appliedCoupon != null ? 'Remove' : 'Apply',
                    style: const TextStyle(color: Color(0xFFC6A473), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (appliedCoupon != null && businessInfo != null) ...[
              const SizedBox(height: 8),
              Text(
                'Coupon applied: ${businessInfo.couponDiscountPercentage.toStringAsFixed(0)}% OFF on covered products',
                style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal', style: TextStyle(color: Colors.grey)),
                Text('₹${subtotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            if (discount > 0) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Discount', style: TextStyle(color: Colors.grey)),
                  Text('- ₹${discount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Shipping', style: TextStyle(color: Colors.grey)),
                Text(
                  shipping == 0 ? 'Free' : '₹${shipping.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: shipping == 0 ? Colors.green : Colors.white,
                  ),
                ),
              ],
            ),
            const Divider(color: Color(0xFF05372B), height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  '₹${total.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.push('/checkout');
              },
              child: const Text('PROCEED TO CHECKOUT'),
            ),
          ],
        ),
      ),
    );
  }
}
