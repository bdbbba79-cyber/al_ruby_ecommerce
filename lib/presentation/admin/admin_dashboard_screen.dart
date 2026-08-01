import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:al_ruby_ecommerce/presentation/admin/admin_layout.dart';
import 'package:al_ruby_ecommerce/presentation/providers/providers.dart';
import 'package:al_ruby_ecommerce/data/models/order.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(adminOrdersProvider);
    final productsAsync = ref.watch(adminProductsProvider);

    return AdminLayout(
      selectedIndex: 0,
      title: 'Dashboard Overview',
      child: ordersAsync.when(
        data: (orders) {
          return productsAsync.when(
            data: (products) {
              // Compute metrics
              double totalSales = 0.0;
              double todaysSales = 0.0;
              int totalOrders = orders.length;
              int activeProducts = products.where((p) => p.status == 'active').length;
              
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);

              for (final o in orders) {
                // Ignore cancelled or refunded orders in revenue calculation
                if (o.orderStatus != OrderStatus.cancelled && o.orderStatus != OrderStatus.refunded) {
                  totalSales += o.grandTotal;
                  
                  final orderDate = DateTime(o.createdAt.year, o.createdAt.month, o.createdAt.day);
                  if (orderDate.isAtSameMomentAs(today)) {
                    todaysSales += o.grandTotal;
                  }
                }
              }

              // Top selling products count map
              final productCountMap = <String, int>{};
              final productNameMap = <String, String>{};
              final productPriceMap = <String, double>{};
              for (final o in orders) {
                if (o.orderStatus != OrderStatus.cancelled && o.orderStatus != OrderStatus.refunded) {
                  for (final item in o.items) {
                    productCountMap[item.productId] = (productCountMap[item.productId] ?? 0) + item.quantity;
                    productNameMap[item.productId] = item.productName;
                    productPriceMap[item.productId] = item.price;
                  }
                }
              }

              final sortedProducts = productCountMap.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              
              final topSelling = sortedProducts.take(5).toList();
              final latestOrders = orders.take(5).toList();

              final isDesktop = MediaQuery.of(context).size.width > 800;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stat cards
                    GridView.count(
                      crossAxisCount: isDesktop ? 4 : 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.45,
                      children: [
                        _buildStatCard('Total Sales', '₹${totalSales.toStringAsFixed(0)}', Icons.payments_outlined, Colors.blue),
                        _buildStatCard("Today's Sales", '₹${todaysSales.toStringAsFixed(0)}', Icons.today_outlined, Colors.green),
                        _buildStatCard('Orders', '$totalOrders', Icons.receipt_long_outlined, Colors.orange),
                        _buildStatCard('Active Products', '$activeProducts', Icons.inventory_2_outlined, Colors.purple),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Grid layout for tables
                    isDesktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: _buildLatestOrdersCard(context, latestOrders)),
                              const SizedBox(width: 24),
                              Expanded(flex: 2, child: _buildTopProductsCard(topSelling, productNameMap, productPriceMap)),
                            ],
                          )
                        : Column(
                            children: [
                              _buildLatestOrdersCard(context, latestOrders),
                              const SizedBox(height: 24),
                              _buildTopProductsCard(topSelling, productNameMap, productPriceMap),
                            ],
                          ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error loading products: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading orders: $err')),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 13)),
                Icon(icon, color: color, size: 22),
              ],
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestOrdersCard(BuildContext context, List<OrderModel> orders) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Latest Orders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => context.go('/admin/orders'),
                  child: const Text('View All'),
                )
              ],
            ),
            const SizedBox(height: 16),
            if (orders.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Center(child: Text('No orders yet.')),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: orders.length,
                separatorBuilder: (context, index) => const Divider(color: Color(0xFFE2E8F0)),
                itemBuilder: (context, index) {
                  final o = orders[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(o.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('ID: ...${o.id.substring(o.id.length - 8)} • ${DateFormat('dd MMM hh:mm a').format(o.createdAt)}', style: const TextStyle(fontSize: 12)),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₹${o.grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F62FE))),
                        const SizedBox(height: 4),
                        Text(o.orderStatus.displayName, style: TextStyle(fontSize: 10, color: _getStatusColor(o.orderStatus), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductsCard(List<MapEntry<String, int>> topSelling, Map<String, String> nameMap, Map<String, double> priceMap) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Top Selling Products', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (topSelling.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Center(child: Text('No sales data yet.')),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: topSelling.length,
                separatorBuilder: (context, index) => const Divider(color: Color(0xFFE2E8F0)),
                itemBuilder: (context, index) {
                  final entry = topSelling[index];
                  final name = nameMap[entry.key] ?? 'Unknown Product';
                  final qty = entry.value;
                  final price = priceMap[entry.key] ?? 0.0;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF0F62FE).withOpacity(0.08),
                      child: Text('${index + 1}', style: const TextStyle(color: Color(0xFF0F62FE), fontWeight: FontWeight.bold)),
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('Sold: $qty units', style: const TextStyle(fontSize: 11)),
                    trailing: Text('₹${(qty * price).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
      case OrderStatus.paymentVerificationPending:
        return Colors.orange;
      case OrderStatus.confirmed:
      case OrderStatus.processing:
      case OrderStatus.packed:
        return Colors.blue;
      case OrderStatus.shipped:
      case OrderStatus.outForDelivery:
        return Colors.indigo;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
      case OrderStatus.refunded:
        return Colors.red;
    }
  }
}
