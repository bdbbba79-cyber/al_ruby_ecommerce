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

    final isDesktop = MediaQuery.of(context).size.width > 800;

    return AdminLayout(
      selectedIndex: 0,
      title: 'Dashboard Overview',
      child: productsAsync.when(
        data: (products) {
          final orders = ordersAsync.value ?? [];
          final hasOrderError = ordersAsync.hasError;
          final orderErrorMsg = ordersAsync.error?.toString() ?? '';

          // Compute metrics
          double totalSales = 0.0;
          double todaysSales = 0.0;
          int totalOrders = orders.length;
          int activeProducts = products.where((p) => p.status == 'active').length;
          
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          for (final o in orders) {
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

          return SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 24.0 : 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasOrderError) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Firestore Permission Notice',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF991B1B), fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                orderErrorMsg.contains('permission-denied')
                                    ? 'The orders collection is blocked by Firestore Security Rules. Publish the project security rules in Firebase Console to view live orders.'
                                    : 'Error loading orders: $orderErrorMsg',
                                style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Color(0xFF991B1B)),
                          tooltip: 'Retry',
                          onPressed: () => ref.refresh(adminOrdersProvider),
                        ),
                      ],
                    ),
                  ),
                ],

                // Stat cards
                GridView.count(
                  crossAxisCount: isDesktop ? 4 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: isDesktop ? 1.6 : 1.15,
                  children: [
                    _buildStatCard('Total Sales', '₹${totalSales.toStringAsFixed(0)}', Icons.payments_outlined, Colors.blue),
                    _buildStatCard("Today's Sales", '₹${todaysSales.toStringAsFixed(0)}', Icons.today_outlined, Colors.green),
                    _buildStatCard('Orders', hasOrderError ? 'Rules Pending' : '$totalOrders', Icons.receipt_long_outlined, Colors.orange),
                    _buildStatCard('Active Products', '$activeProducts', Icons.inventory_2_outlined, Colors.purple),
                  ],
                ),
                const SizedBox(height: 32),

                // Grid layout for tables
                isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _buildLatestOrdersCard(context, latestOrders, hasError: hasOrderError)),
                          const SizedBox(width: 24),
                          Expanded(flex: 2, child: _buildTopProductsCard(topSelling, productNameMap, productPriceMap)),
                        ],
                      )
                    : Column(
                        children: [
                          _buildLatestOrdersCard(context, latestOrders, hasError: hasOrderError),
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
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
              ],
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestOrdersCard(BuildContext context, List<OrderModel> orders, {bool hasError = false}) {
    return AdminLayout.buildSectionCard(
      title: 'Latest Orders',
      icon: Icons.receipt_long_outlined,
      subtitle: 'Most recent customer purchases',
      trailing: TextButton(
        onPressed: () => context.go('/admin/orders'),
        child: const Text('View All'),
      ),
      child: hasError
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Text(
                  'Orders restricted by Firestore rules.\nPublish rules in Firebase Console to unlock.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFDC2626), fontSize: 13),
                ),
              ),
            )
          : orders.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                  child: Center(child: Text('No orders yet.', style: TextStyle(color: Color(0xFF64748B)))),
                )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: orders.length,
              separatorBuilder: (context, index) => const Divider(color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final o = orders[index];
                final statusColor = _getStatusColor(o.orderStatus);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              o.customerName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ID: ...${o.id.substring(o.id.length - 8)} • ${DateFormat('dd MMM hh:mm a').format(o.createdAt)}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${o.grandTotal.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F62FE)),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              o.orderStatus.displayName,
                              style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildTopProductsCard(List<MapEntry<String, int>> topSelling, Map<String, String> nameMap, Map<String, double> priceMap) {
    return AdminLayout.buildSectionCard(
      title: 'Top Selling Products',
      icon: Icons.trending_up_outlined,
      subtitle: 'Products with highest order volume',
      child: topSelling.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: Center(child: Text('No sales data yet.', style: TextStyle(color: Color(0xFF64748B)))),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topSelling.length,
              separatorBuilder: (context, index) => const Divider(color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final entry = topSelling[index];
                final name = nameMap[entry.key] ?? 'Unknown Product';
                final qty = entry.value;
                final price = priceMap[entry.key] ?? 0.0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: const Color(0xFF0F62FE).withOpacity(0.1),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(color: Color(0xFF0F62FE), fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text('Sold: $qty units', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '₹${(qty * price).toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                );
              },
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
