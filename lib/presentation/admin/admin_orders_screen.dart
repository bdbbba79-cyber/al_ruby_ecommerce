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
    final businessInfo = ref.read(businessInfoProvider).valueOrNull;
    final companyName = businessInfo?.companyName ?? 'IZZFAH NOOBI';
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
                  child: pw.Text('Thank you for shopping with IZZFAH NOOBI!', style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 12)),
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
    final confirm = await AdminLayout.showAdminDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.verified_outlined, color: Colors.orange, size: 22),
            ),
            const SizedBox(width: 12),
            const Text('Confirm UPI Payment'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please verify that the payment has been credited to your bank/merchant UPI account before confirming.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Amount:', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                      Text(
                        '₹${order.grandTotal.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F62FE)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Customer:', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.customerName,
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('UTR / Ref ID:', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.transactionId ?? 'N/A',
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F62FE)),
            child: const Text('Verify & Confirm'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(orderRepoProvider).updatePaymentStatus(order.id, 'Paid');
      await ref.read(orderRepoProvider).updateOrderStatus(order.id, OrderStatus.confirmed);
      
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
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(text: 'All Orders'),
                Tab(text: 'UPI Verification Pending'),
                Tab(text: 'Completed / Shipped'),
              ],
              labelColor: const Color(0xFF0F62FE),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFF0F62FE),
              indicatorWeight: 3,
            ),
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
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_clock_outlined, size: 56, color: Color(0xFFDC2626)),
                      const SizedBox(height: 16),
                      const Text(
                        'Firestore Permission Required',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'The orders collection is protected by Cloud Firestore rules.\nPlease publish the project Firestore Security Rules in the Firebase Console to unlock full order management.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => ref.refresh(adminOrdersProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry Loading Orders'),
                      ),
                    ],
                  ),
                ),
              ),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;
        return ListView.builder(
          padding: EdgeInsets.all(isDesktop ? 24.0 : 12.0),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt);
            
            return Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: EdgeInsets.all(isDesktop ? 20.0 : 14.0),
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
                              Flexible(child: _buildStatusDropdown(order)),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              '${item.productName}  (x${item.quantity})',
                              style: const TextStyle(color: Color(0xFF475569)),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                          const SizedBox(width: 8),
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
