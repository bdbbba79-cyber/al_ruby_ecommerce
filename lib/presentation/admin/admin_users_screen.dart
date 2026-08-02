import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:al_ruby_ecommerce/presentation/admin/admin_layout.dart';
import 'package:al_ruby_ecommerce/presentation/providers/providers.dart';
import 'package:al_ruby_ecommerce/data/models/user_model.dart';

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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Record Manual Payment for ${user.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('UPI ID: ${user.upiId.isNotEmpty ? user.upiId : "Not updated"}', style: const TextStyle(fontWeight: FontWeight.w500)),
            Text('Phone: ${user.phoneNumber.isNotEmpty ? user.phoneNumber : "Not updated"}'),
            const SizedBox(height: 8),
            Text('Current Wallet Balance: ₹${user.walletBalance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            if (user.withdrawalRequested) ...[
              const SizedBox(height: 4),
              Text('Requested Withdrawal: ₹${user.withdrawalRequestedAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Payment Amount (₹)',
                hintText: 'Enter amount paid to user',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
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
            child: const Text('RECORD PAYMENT'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);

    return AdminLayout(
      selectedIndex: 5,
      title: 'Users & Referrals',
      child: usersAsync.when(
        data: (users) {
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
            padding: const EdgeInsets.all(24.0),
            itemCount: sortedUsers.length,
            itemBuilder: (context, index) {
              final u = sortedUsers[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    u.name,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
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
                              Text(u.email, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                            ],
                          ),
                          if (u.withdrawalRequested)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.pending_actions, color: Colors.orange, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Payout Requested: ₹${u.withdrawalRequestedAmount.toStringAsFixed(0)}',
                                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
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
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading users: $err')),
      ),
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
        Row(
          children: [
            Text('Balance: ₹${user.walletBalance.toStringAsFixed(0)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(width: 8),
            Text('(Earned: ₹${user.totalEarned.toStringAsFixed(0)} | Paid: ₹${user.totalPaid.toStringAsFixed(0)})', style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ],
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
