import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:al_ruby_ecommerce/presentation/providers/providers.dart';
import 'package:al_ruby_ecommerce/data/models/order.dart';
import 'package:al_ruby_ecommerce/data/models/product.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserDetailsProvider);
    final ordersAsync = ref.watch(customerOrdersProvider);
    final wishlist = ref.watch(wishlistProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Please login to view your profile.'),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => context.push('/login'), child: const Text('Login')),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
            onPressed: () => context.go('/home'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: () async {
                await ref.read(authRepoProvider).signOut();
                ref.read(currentUserDetailsProvider.notifier).state = null;
                ref.read(cartProvider.notifier).clear();
                context.go('/home');
              },
            ),
            const SizedBox(width: 8),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.receipt_long_outlined), text: 'My Orders'),
              Tab(icon: Icon(Icons.favorite_border), text: 'My Wishlist'),
            ],
            labelColor: Color(0xFF0F62FE),
            unselectedLabelColor: Color(0xFF64748B),
            indicatorColor: Color(0xFF0F62FE),
          ),
        ),
        body: TabBarView(
          children: [
            // Orders Tab
            ordersAsync.when(
              data: (orders) => _buildOrdersTab(context, orders),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading orders: $err')),
            ),
            // Wishlist Tab
            _buildWishlistTab(context, wishlist, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersTab(BuildContext context, List<OrderModel> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_outlined, size: 70, color: Color(0xFF94A3B8)),
            const SizedBox(height: 16),
            const Text('No Orders Placed Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: () => context.go('/home'), child: const Text('Shop Now')),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order ID: ...${order.id.substring(order.id.length - 8)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    _buildStatusBadge(order.orderStatus),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Placed on: $formattedDate', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                const Divider(height: 24, color: Color(0xFFE2E8F0)),
                // Items List
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: order.items.length,
                  itemBuilder: (context, idx) {
                    final item = order.items[idx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          if (item.imageUrl.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(item.imageUrl, height: 40, width: 40, fit: BoxFit.cover),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.productName,
                              style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text('x${item.quantity}', style: const TextStyle(color: Color(0xFF64748B))),
                          const SizedBox(width: 16),
                          Text('₹${(item.price * item.quantity).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(height: 24, color: Color(0xFFE2E8F0)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Payment: ${order.paymentMethod}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                        Text('Status: ${order.paymentStatus}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                      ],
                    ),
                    Text(
                      'Total: ₹${order.grandTotal.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F62FE)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWishlistTab(BuildContext context, List<Product> wishlist, WidgetRef ref) {
    if (wishlist.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 70, color: Color(0xFF94A3B8)),
            SizedBox(height: 16),
            Text('Your Wishlist is Empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: wishlist.length,
      itemBuilder: (context, index) {
        final product = wishlist[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          child: ListTile(
            leading: product.images.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(product.images.first, height: 50, width: 50, fit: BoxFit.cover),
                  )
                : const Icon(Icons.image_not_supported_outlined),
            title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('₹${product.sellingPrice.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF0F62FE), fontWeight: FontWeight.bold)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                ref.read(wishlistProvider.notifier).toggleWishlist(product);
              },
            ),
            onTap: () => context.push('/product/${product.id}'),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    Color color;
    switch (status) {
      case OrderStatus.pending:
      case OrderStatus.paymentVerificationPending:
        color = Colors.orange;
        break;
      case OrderStatus.confirmed:
      case OrderStatus.processing:
      case OrderStatus.packed:
        color = Colors.blue;
        break;
      case OrderStatus.shipped:
      case OrderStatus.outForDelivery:
        color = Colors.indigo;
        break;
      case OrderStatus.delivered:
        color = Colors.green;
        break;
      case OrderStatus.cancelled:
      case OrderStatus.refunded:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }
}
