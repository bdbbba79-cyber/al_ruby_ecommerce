import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:al_ruby_ecommerce/presentation/admin/admin_layout.dart';
import 'package:al_ruby_ecommerce/presentation/providers/providers.dart';
import 'package:al_ruby_ecommerce/data/models/order.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _generateAndPrintInvoice(OrderModel order) async {
    final businessInfo = ref.read(businessInfoProvider).value;
    final companyName = businessInfo?.companyName ?? 'Al Ruby Perfumes';
    final address = businessInfo?.address ?? 'Erumathadam Malappuram';
    final mobileNumber = businessInfo?.mobileNumber ?? '9400859846';

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('INVOICE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                        pw.Text('Order ID: ${order.id}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(companyName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                        pw.Text(address, style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('Phone: $mobileNumber', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ],
                ),
                pw.Divider(thickness: 1, color: PdfColors.grey300),
                pw.SizedBox(height: 20),

                // Customer Info
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Billed To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                          pw.Text(order.customerName, style: const pw.TextStyle(fontSize: 11)),
                          pw.Text('Phone: ${order.customerMobile}', style: const pw.TextStyle(fontSize: 11)),
                          if (order.customerEmail != null) pw.Text('Email: ${order.customerEmail}', style: const pw.TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Shipping Address:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                          pw.Text(order.shippingAddress.fullAddress, style: const pw.TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),

                // Items Table
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1),
                    3: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    // Table Header
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Item Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Subtotal', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                    // Table Body
                    ...order.items.map((item) {
                      return pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(item.productName)),
                          pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('INR ${item.price.toStringAsFixed(0)}')),
                          pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${item.quantity}')),
                          pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('INR ${(item.price * item.quantity).toStringAsFixed(0)}')),
                        ],
                      );
                    }),
                  ],
                ),
                pw.SizedBox(height: 30),

                // Summary Row
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Container(
                    width: 200,
                    child: pw.Column(
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Subtotal:'),
                            pw.Text('INR ${order.subtotal.toStringAsFixed(0)}'),
                          ],
                        ),
                        pw.SizedBox(height: 6),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Shipping:'),
                            pw.Text('INR ${order.shippingCharge.toStringAsFixed(0)}'),
                          ],
                        ),
                        pw.Divider(thickness: 1, color: PdfColors.grey300),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Grand Total:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                            pw.Text('INR ${order.grandTotal.toStringAsFixed(0)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(height: 40),

                // Footer Info
                pw.Center(
                  child: pw.Text('Thank you for shopping with Al Ruby Perfumes!', style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 12)),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  Future<void> _verifyUPIPayment(OrderModel order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Text('Are you sure you want to verify UPI Payment with UTR/Ref ID: ${order.transactionId}?\nThis will mark the payment as PAID and confirm the order.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Verify & Confirm'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(orderRepoProvider).updatePaymentStatus(order.id, 'Paid');
      await ref.read(orderRepoProvider).updateOrderStatus(order.id, OrderStatus.confirmed);
      
      // Trigger notification placeholder
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment verified and order confirmed successfully.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(adminOrdersProvider);

    return AdminLayout(
      selectedIndex: 3,
      title: 'Orders Management',
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'All Orders'),
              Tab(text: 'UPI Verification Pending'),
              Tab(text: 'Completed / Shipped'),
            ],
            labelColor: const Color(0xFF0F62FE),
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: const Color(0xFF0F62FE),
          ),
          Expanded(
            child: ordersAsync.when(
              data: (orders) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOrdersList(orders),
                    _buildOrdersList(orders.where((o) => o.orderStatus == OrderStatus.paymentVerificationPending).toList()),
                    _buildOrdersList(orders.where((o) => o.orderStatus == OrderStatus.delivered || o.orderStatus == OrderStatus.shipped).toList()),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Failed to load orders: $err')),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<OrderModel> orders) {
    if (orders.isEmpty) {
      return const Center(child: Text('No orders found matching this filter.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24.0),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt);
        final isDesktop = MediaQuery.of(context).size.width > 900;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 20.0),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                isDesktop
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Order ID: ${order.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text('Placed on: $dateStr', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              // Status Badge
                              _buildStatusDropdown(order),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(Icons.print_outlined, color: Colors.blue),
                                onPressed: () => _generateAndPrintInvoice(order),
                                tooltip: 'Print Invoice',
                              )
                            ],
                          )
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order ID: ...${order.id.substring(order.id.length - 8)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('Placed on: $dateStr', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Status Badge
                              _buildStatusDropdown(order),
                              IconButton(
                                icon: const Icon(Icons.print_outlined, color: Colors.blue),
                                onPressed: () => _generateAndPrintInvoice(order),
                                tooltip: 'Print Invoice',
                              )
                            ],
                          )
                        ],
                      ),
                const Divider(height: 32, color: Color(0xFFE2E8F0)),

                // Customer / Shipping detail row
                isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Customer Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 8),
                                Text(order.customerName),
                                Text('Mobile: ${order.customerMobile}'),
                                if (order.customerEmail != null) Text('Email: ${order.customerEmail}'),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Shipping Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 8),
                                Text(order.shippingAddress.fullAddress),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Payment Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 8),
                                Text('Method: ${order.paymentMethod}'),
                                Text('Status: ${order.paymentStatus}'),
                                if (order.paymentMethod == 'UPI') ...[
                                  Text('UTR Ref: ${order.transactionId ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                                  if (order.paymentStatus == 'Verification Pending') ...[
                                    const SizedBox(height: 10),
                                    ElevatedButton(
                                      onPressed: () => _verifyUPIPayment(order),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange.shade700,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      ),
                                      child: const Text('Verify & Approve', style: TextStyle(fontSize: 12)),
                                    ),
                                  ]
                                ],
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Customer Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 8),
                              Text(order.customerName),
                              Text('Mobile: ${order.customerMobile}'),
                              if (order.customerEmail != null) Text('Email: ${order.customerEmail}'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Shipping Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 8),
                              Text(order.shippingAddress.fullAddress),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Payment Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 8),
                              Text('Method: ${order.paymentMethod}'),
                              Text('Status: ${order.paymentStatus}'),
                              if (order.paymentMethod == 'UPI') ...[
                                Text('UTR Ref: ${order.transactionId ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                                if (order.paymentStatus == 'Verification Pending') ...[
                                  const SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: () => _verifyUPIPayment(order),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange.shade700,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    ),
                                    child: const Text('Verify & Approve', style: TextStyle(fontSize: 12)),
                                  ),
                                ]
                              ],
                            ],
                          ),
                        ],
                      ),

                const Divider(height: 32, color: Color(0xFFE2E8F0)),

                // Order items list
                const Text('Items Purchased', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                        children: [
                          Text('${item.productName}  (x${item.quantity})', style: const TextStyle(color: Color(0xFF475569))),
                          const Spacer(),
                          Text('₹${(item.price * item.quantity).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(height: 24, color: Color(0xFFE2E8F0)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Total Earnings: ₹${order.grandTotal.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F62FE)),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusDropdown(OrderModel order) {
    return DropdownButton<OrderStatus>(
      value: order.orderStatus,
      onChanged: (OrderStatus? newStatus) {
        if (newStatus != null) {
          ref.read(orderRepoProvider).updateOrderStatus(order.id, newStatus);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order status updated to: ${newStatus.displayName}')));
        }
      },
      items: OrderStatus.values.map((OrderStatus val) {
        return DropdownMenuItem<OrderStatus>(
          value: val,
          child: Text(val.displayName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        );
      }).toList(),
    );
  }
}
