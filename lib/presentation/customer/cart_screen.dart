import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:al_ruby_ecommerce/presentation/providers/providers.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final subtotal = cartNotifier.subtotal;
    const shippingCharge = 50.0; // Flat shipping rate
    final grandTotal = subtotal + shippingCharge;

    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Shopping Cart', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => context.pop(),
        ),
      ),
      body: cartItems.isEmpty
          ? _buildEmptyCart(context)
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 2, child: _buildCartItemsList(context, cartItems, cartNotifier)),
                            const SizedBox(width: 32),
                            Expanded(child: _buildOrderSummaryCard(context, subtotal, shippingCharge, grandTotal)),
                          ],
                        )
                      : Column(
                          children: [
                            _buildCartItemsList(context, cartItems, cartNotifier),
                            const SizedBox(height: 24),
                            _buildOrderSummaryCard(context, subtotal, shippingCharge, grandTotal),
                          ],
                        ),
                ),
              ),
            ),
    );
  }

  // --- Empty Cart View ---
  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_bag_outlined, size: 100, color: Color(0xFF94A3B8)),
            const SizedBox(height: 24),
            const Text(
              'Your Cart is Empty',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),
            const Text(
              'Explore our premium collection of perfumes and attars and add them to your cart.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F62FE),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('START SHOPPING'),
            ),
          ],
        ),
      ),
    );
  }

  // --- Cart Items list ---
  Widget _buildCartItemsList(BuildContext context, List<CartItem> items, CartNotifier notifier) {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) => const Divider(color: Color(0xFFE2E8F0), height: 1),
        itemBuilder: (context, index) {
          final item = items[index];
          final product = item.product;
          
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Product Thumbnail
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: product.images.isNotEmpty
                      ? Image.network(product.images.first, fit: BoxFit.cover)
                      : Container(color: const Color(0xFFF1F5F9)),
                ),
                const SizedBox(width: 16),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${product.sellingPrice.toStringAsFixed(0)} each',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      // Mobile quantity controls
                      Row(
                        children: [
                          _buildQuantityButton(Icons.remove, () {
                            notifier.updateQuantity(product, item.quantity - 1);
                          }),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0),
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                          _buildQuantityButton(Icons.add, () {
                            notifier.updateQuantity(product, item.quantity + 1);
                          }),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Total price & delete
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${item.totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F62FE)),
                    ),
                    const SizedBox(height: 12),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => notifier.removeItem(product),
                    )
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuantityButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: const Color(0xFFF1F5F9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Icon(icon, size: 16, color: const Color(0xFF0F172A)),
        ),
      ),
    );
  }

  // --- Order Summary Card ---
  Widget _buildOrderSummaryCard(BuildContext context, double subtotal, double shipping, double total) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal', style: TextStyle(color: Color(0xFF64748B))),
                Text('₹${subtotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Shipping Rate', style: TextStyle(color: Color(0xFF64748B))),
                Text('₹${shipping.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(color: Color(0xFFE2E8F0), height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Grand Total',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                Text(
                  '₹${total.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F62FE)),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                context.push('/checkout');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F62FE),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('PROCEED TO CHECKOUT'),
            ),
          ],
        ),
      ),
    );
  }
}
