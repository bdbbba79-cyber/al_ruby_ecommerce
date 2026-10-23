import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:al_ruby_ecommerce/presentation/admin/admin_layout.dart';
import 'package:al_ruby_ecommerce/presentation/providers/providers.dart';
import 'package:al_ruby_ecommerce/data/models/user_model.dart';
import 'package:al_ruby_ecommerce/data/models/product.dart';
import 'package:al_ruby_ecommerce/presentation/widgets/app_network_image.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _showUpdatePaidDialog(UserModel user) {
    _amountController.clear();
    if (user.withdrawalRequested) {
      _amountController.text = user.withdrawalRequestedAmount.toStringAsFixed(0);
    }

    AdminLayout.showAdminDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F62FE).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.payment, color: Color(0xFF0F62FE), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Record Payment for ${user.name}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('UPI ID:', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            user.upiId.isNotEmpty ? user.upiId : 'Not configured',
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Phone:', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            user.phoneNumber.isNotEmpty ? user.phoneNumber : 'Not set',
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
                        const Text('Current Wallet:', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                        Text(
                          '₹${user.walletBalance.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    if (user.withdrawalRequested) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Requested Payout:', style: TextStyle(fontSize: 13, color: Colors.orange, fontWeight: FontWeight.bold)),
                          Text(
                            '₹${user.withdrawalRequestedAmount.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Payment Amount (₹)',
                  hintText: 'Enter amount paid to user',
                  prefixText: '₹ ',
                ),
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final val = _amountController.text.trim();
              if (val.isEmpty || double.tryParse(val) == null || double.parse(val) <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid positive number')),
                );
                return;
              }

              final payAmount = double.parse(val);
              try {
                await ref.read(authRepoProvider).updatePaidAmount(user.id, payAmount);
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Successfully recorded payment of ₹${payAmount.toStringAsFixed(0)} for ${user.name}.')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Record Payment'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);
    final productsAsync = ref.watch(adminProductsProvider);

    return AdminLayout(
      selectedIndex: 5,
      title: 'Users & Referrals',
      child: usersAsync.when(
        data: (users) {
          return productsAsync.when(
            data: (products) {
              // Sort so users with pending withdrawals are shown first
              final sortedUsers = [...users]
                ..sort((a, b) {
                  if (a.withdrawalRequested && !b.withdrawalRequested) return -1;
                  if (!a.withdrawalRequested && b.withdrawalRequested) return 1;
                  return a.name.compareTo(b.name);
                });

              if (sortedUsers.isEmpty) {
                return const Center(child: Text('No users registered yet.'));
              }

              final isDesktop = MediaQuery.of(context).size.width > 800;

              return ListView.builder(
                padding: EdgeInsets.all(isDesktop ? 24.0 : 12.0),
                itemCount: sortedUsers.length,
                itemBuilder: (context, index) {
                  final u = sortedUsers[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    child: Padding(
                      padding: EdgeInsets.all(isDesktop ? 20.0 : 14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Row
                          isDesktop
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  u.name,
                                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: u.role == 'admin' ? Colors.red.shade50 : Colors.blue.shade50,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  u.role.toUpperCase(),
                                                  style: TextStyle(
                                                    color: u.role == 'admin' ? Colors.red : Colors.blue,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(u.email, style: TextStyle(color: Colors.grey[500], fontSize: 13), overflow: TextOverflow.ellipsis),
                                        ],
                                      ),
                                    ),
                                    if (u.withdrawalRequested) ...[
                                      const SizedBox(width: 12),
                                      _buildWithdrawalBadge(u),
                                    ],
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            u.name,
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: u.role == 'admin' ? Colors.red.shade50 : Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            u.role.toUpperCase(),
                                            style: TextStyle(
                                              color: u.role == 'admin' ? Colors.red : Colors.blue,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(u.email, style: TextStyle(color: Colors.grey[500], fontSize: 13), overflow: TextOverflow.ellipsis),
                                    if (u.withdrawalRequested) ...[
                                      const SizedBox(height: 10),
                                      _buildWithdrawalBadge(u),
                                    ],
                                  ],
                                ),
                          const Divider(height: 24, color: Color(0xFFE2E8F0)),

                          // User Details Grid / Row
                          isDesktop
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildDetailItem('Phone Number', u.phoneNumber.isNotEmpty ? u.phoneNumber : 'Not set'),
                                    _buildDetailItem('UPI ID', u.upiId.isNotEmpty ? u.upiId : 'Not set'),
                                    _buildDetailItem('Referral Code', u.referralCode),
                                    _buildWalletBreakdown(u),
                                    _buildActions(u),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildDetailItem('Phone Number', u.phoneNumber.isNotEmpty ? u.phoneNumber : 'Not set'),
                                    const SizedBox(height: 12),
                                    _buildDetailItem('UPI ID', u.upiId.isNotEmpty ? u.upiId : 'Not set'),
                                    const SizedBox(height: 12),
                                    _buildDetailItem('Referral Code', u.referralCode),
                                    const SizedBox(height: 16),
                                    _buildWalletBreakdown(u),
                                    const SizedBox(height: 20),
                                    _buildActions(u),
                                  ],
                                ),
                          
                          // Collapsible user interactions (Cart & Wishlist)
                          _buildUserInteractions(u, products),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error loading products: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading users: $err')),
      ),
    );
  }

  Widget _buildUserInteractions(UserModel user, List<Product> allProducts) {
    final wishlisted = allProducts.where((p) => user.wishlist.contains(p.id)).toList();
    
    final cartItems = user.cart.map((cMap) {
      final pId = cMap['productId'] ?? '';
      final matching = allProducts.where((p) => p.id == pId);
      if (matching.isEmpty) return null;
      return _AdminCartItem(
        product: matching.first,
        quantity: cMap['quantity'] ?? 1,
        variantSize: cMap['selectedVariantSize'],
        referrer: cMap['referrerCode'],
      );
    }).whereType<_AdminCartItem>().toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        const SizedBox(height: 12),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: PageStorageKey('user_cart_${user.id}'),
            iconColor: const Color(0xFF0F62FE),
            collapsedIconColor: Colors.grey,
            title: Row(
              children: [
                const Icon(Icons.shopping_cart_outlined, size: 18, color: Color(0xFF0F62FE)),
                const SizedBox(width: 8),
                Text(
                  'Cart Items (${cartItems.length})',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
              ],
            ),
            children: [
              if (cartItems.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                  child: Text('No items in cart.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          if (item.product.images.isNotEmpty)
                            AppNetworkImage.thumbnail(
                              imageUrl: item.product.images.first,
                              size: 40,
                              fit: BoxFit.cover,
                              borderRadius: BorderRadius.circular(4),
                            )
                          else
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(Icons.image_not_supported, size: 20, color: Colors.grey),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                                ),
                                const SizedBox(height: 2),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 2,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text('Qty: ${item.quantity}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                    if (item.variantSize != null && item.variantSize!.isNotEmpty)
                                      Text('| Size: ${item.variantSize}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                    if (item.referrer != null && item.referrer!.isNotEmpty)
                                      Text('| Ref: ${item.referrer}', style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${(item.product.sellingPrice * item.quantity).toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F62FE)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: PageStorageKey('user_wishlist_${user.id}'),
            iconColor: Colors.red,
            collapsedIconColor: Colors.grey,
            title: Row(
              children: [
                const Icon(Icons.favorite_border, size: 18, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Wishlist (${wishlisted.length})',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
              ],
            ),
            children: [
              if (wishlisted.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                  child: Text('No items in wishlist.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: wishlisted.map((p) {
                      return Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 60),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red.shade100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (p.images.isNotEmpty) ...[
                              AppNetworkImage.thumbnail(
                                imageUrl: p.images.first,
                                size: 18,
                                fit: BoxFit.cover,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Flexible(
                              child: Text(
                                p.name,
                                style: TextStyle(color: Colors.red.shade900, fontSize: 12, fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
      ],
    );
  }

  Widget _buildWalletBreakdown(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Earnings', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Balance: ₹${user.walletBalance.toStringAsFixed(0)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
            Text('(Earned: ₹${user.totalEarned.toStringAsFixed(0)} | Paid: ₹${user.totalPaid.toStringAsFixed(0)})', style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ],
    );
  }

  Widget _buildWithdrawalBadge(UserModel u) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.pending_actions, color: Colors.orange, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Payout Requested: ₹${u.withdrawalRequestedAmount.toStringAsFixed(0)}',
              style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(UserModel user) {
    return ElevatedButton.icon(
      onPressed: () => _showEditProfileDialogOrPayment(user),
      icon: const Icon(Icons.payment, size: 16),
      label: const Text('Update Paid Amount'),
      style: ElevatedButton.styleFrom(
        backgroundColor: user.withdrawalRequested ? const Color(0xFF0F62FE) : Colors.grey.shade100,
        foregroundColor: user.withdrawalRequested ? Colors.white : const Color(0xFF0F62FE),
        elevation: 0,
      ),
    );
  }

  void _showEditProfileDialogOrPayment(UserModel user) {
    _showUpdatePaidDialog(user);
  }
}

class _AdminCartItem {
  final Product product;
  final int quantity;
  final String? variantSize;
  final String? referrer;

  _AdminCartItem({
    required this.product,
    required this.quantity,
    this.variantSize,
    this.referrer,
  });
}
