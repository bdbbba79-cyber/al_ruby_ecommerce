import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:al_ruby_ecommerce/presentation/providers/providers.dart';
import 'package:al_ruby_ecommerce/data/models/order.dart';

class OrdersView extends ConsumerStatefulWidget {
  const OrdersView({super.key});

  @override
  ConsumerState<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends ConsumerState<OrdersView> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(customerOrdersProvider);
    final user = ref.watch(currentUserDetailsProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('MY ORDERS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Please login to view your orders.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.push('/login'),
                child: const Text('Log In'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('MY ORDERS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Chips
          _buildFilterChips(),

          // Orders List
          Expanded(
            child: ordersAsync.when(
              data: (orders) => _buildOrdersList(orders),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Processing', 'Shipped', 'Delivered'];
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                }
              },
              selectedColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Colors.white,
                fontWeight: FontWeight.bold,
              ),
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrdersList(List<OrderModel> orders) {
    // Filter orders based on selected tab
    final filteredOrders = orders.where((order) {
      if (_selectedFilter == 'All') return true;
      final statusName = order.orderStatus.displayName.toLowerCase();
      if (_selectedFilter == 'Processing') {
        return statusName.contains('pending') || statusName.contains('confirm') || statusName.contains('process') || statusName.contains('pack');
      }
      return statusName.contains(_selectedFilter.toLowerCase());
    }).toList();

    if (filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_outlined, size: 70, color: Colors.grey),
            const SizedBox(height: 16),
            Text('No orders in status: $_selectedFilter', style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        final formattedDate = DateFormat('dd MMM yyyy').format(order.createdAt);
        final shortOrderId = order.id.length > 8 ? order.id.substring(order.id.length - 8).toUpperCase() : order.id.toUpperCase();

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #$shortOrderId',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedDate,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    _buildStatusBadge(order.orderStatus),
                  ],
                ),
                const Divider(height: 24, color: Color(0xFF05372B)),

                // Item Details & Horizontal Images Row
                Row(
                  children: [
                    // Horizontal images of items
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: order.items.length > 3 ? 3 : order.items.length,
                          itemBuilder: (context, idx) {
                            final item = order.items[idx];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Container(
                                height: 50,
                                width: 50,
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFF05372B), width: 1.5),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: item.imageUrl.isNotEmpty
                                      ? Image.network(item.imageUrl, fit: BoxFit.cover)
                                      : const Icon(Icons.image_not_supported_outlined, size: 20),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // Item Counter Offset
                    if (order.items.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, right: 12.0),
                        child: Text(
                          '+${order.items.length - 3}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                        ),
                      ),
                    
                    const SizedBox(width: 8),

                    // Total & Actions
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total: ₹${order.grandTotal.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => _showOrderDetailsDialog(context, order),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              border: Border.all(color: Theme.of(context).colorScheme.primary, width: 1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'View Details',
                              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildStatusBadge(OrderStatus status) {
    Color color;
    switch (status) {
      case OrderStatus.pending:
      case OrderStatus.paymentVerificationPending:
        color = Colors.amber;
        break;
      case OrderStatus.confirmed:
      case OrderStatus.processing:
      case OrderStatus.packed:
        color = Colors.blue;
        break;
      case OrderStatus.shipped:
      case OrderStatus.outForDelivery:
        color = Colors.orange;
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

  void _showOrderDetailsDialog(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text('Order Details', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order ID: ${order.id}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                  const SizedBox(height: 8),
                  Text('Payment Method: ${order.paymentMethod}', style: const TextStyle(color: Colors.grey)),
                  Text('Payment Status: ${order.paymentStatus}', style: const TextStyle(color: Colors.grey)),
                  const Divider(color: Color(0xFF05372B), height: 24),
                  const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: order.items.length,
                    itemBuilder: (context, idx) {
                      final item = order.items[idx];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(item.productName, style: const TextStyle(color: Colors.white))),
                            Text('${item.quantity} x ₹${item.price.toStringAsFixed(0)}', style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(color: Color(0xFF05372B), height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Grand Total:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('₹${order.grandTotal.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 16)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
