import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:al_ruby_ecommerce/presentation/providers/providers.dart';
import 'package:al_ruby_ecommerce/presentation/customer/customer_layout.dart';
import 'package:al_ruby_ecommerce/data/models/user_model.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final bool isEmbedded;
  const ProfileScreen({super.key, this.isEmbedded = false});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _phoneController = TextEditingController();
  final _upiController = TextEditingController();

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showEditProfileDialog(UserModel user) {
    _phoneController.text = user.phoneNumber;
    _upiController.text = user.upiId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Marketing Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Enter phone number',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _upiController,
              decoration: const InputDecoration(
                labelText: 'UPI ID',
                hintText: 'Enter UPI ID (e.g. name@upi)',
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
              final phone = _phoneController.text.trim();
              final upi = _upiController.text.trim();
              
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              await ref.read(authRepoProvider).updateMarketingProfile(user.id, phone, upi);
              
              ref.read(currentUserDetailsProvider.notifier).state = user.copyWith(
                phoneNumber: phone,
                upiId: upi,
              );
              
              navigator.pop();
              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text('Profile updated successfully.')),
              );
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestWithdrawal(UserModel user) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (user.walletBalance < 100) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Minimum withdrawal amount is ₹100.')),
      );
      return;
    }
    if (user.phoneNumber.isEmpty || user.upiId.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please update your Phone Number and UPI ID in profile before withdrawing.')),
      );
      return;
    }

    try {
      final amountToWithdraw = user.walletBalance;
      await ref.read(authRepoProvider).requestWithdrawal(user.id, amountToWithdraw);
      
      ref.read(currentUserDetailsProvider.notifier).state = user.copyWith(
        withdrawalRequested: true,
        withdrawalRequestedAmount: amountToWithdraw,
      );

      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Withdrawal request for ₹${amountToWithdraw.toStringAsFixed(0)} submitted successfully!')),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to submit request: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserDetailsProvider);
    final businessInfoAsync = ref.watch(businessInfoProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('MY ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_outline, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Please login to view your account.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.push('/login'),
                child: const Text('Log In / Register'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('MY ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        leading: widget.isEmbedded
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Details Card
                Card(
                  color: Theme.of(context).colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        // Large Profile Avatar
                        Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                            color: const Color(0xFF011E16),
                          ),
                          child: const Icon(Icons.person, size: 48, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        if (user.phoneNumber.isNotEmpty || user.upiId.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          if (user.phoneNumber.isNotEmpty)
                            Text('Phone: ${user.phoneNumber}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                          if (user.upiId.isNotEmpty)
                            Text('UPI: ${user.upiId}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                        ],
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () => _showEditProfileDialog(user),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          ),
                          child: const Text('Update Profile Details', style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Marketing / Commission Wallet Card
                Card(
                  color: Theme.of(context).colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Marketing Wallet',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            Icon(Icons.account_balance_wallet_outlined, color: Theme.of(context).colorScheme.primary),
                          ],
                        ),
                        const Divider(color: Color(0xFF05372B), height: 24),
                        
                        // Referral Code display
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Your Referral Code', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            Row(
                              children: [
                                SelectableText(
                                  user.referralCode,
                                  style: const TextStyle(color: Color(0xFFC6A473), fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 16, color: Colors.white70),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: user.referralCode));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Referral code copied to clipboard.')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Commission Balance', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            Text('₹${user.walletBalance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Earned', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            Text('₹${user.totalEarned.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Paid', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            Text('₹${user.totalPaid.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Withdrawal state rendering
                        if (user.withdrawalRequested) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              border: Border.all(color: Colors.orange.withOpacity(0.5)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.pending_actions, color: Colors.orange, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Withdrawal request of ₹${user.withdrawalRequestedAmount.toStringAsFixed(2)} is pending admin manual payment.',
                                    style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          ElevatedButton(
                            onPressed: (user.walletBalance >= 100 && user.phoneNumber.isNotEmpty && user.upiId.isNotEmpty)
                                ? () => _requestWithdrawal(user)
                                : null,
                            child: const Text('REQUEST WITHDRAWAL'),
                          ),
                          if (user.walletBalance < 100) ...[
                            const SizedBox(height: 6),
                            const Center(
                              child: Text(
                                'Requires minimum ₹100 balance to withdraw.',
                                style: TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                            ),
                          ] else if (user.phoneNumber.isEmpty || user.upiId.isEmpty) ...[
                            const SizedBox(height: 6),
                            const Center(
                              child: Text(
                                'Please update your phone and UPI details to request withdrawal.',
                                style: TextStyle(color: Colors.redAccent, fontSize: 11),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Options List Menu
                Card(
                  color: Theme.of(context).colorScheme.surface,
                  child: Column(
                    children: [
                      _buildMenuItem(
                        context,
                        Icons.home_outlined,
                        'My Addresses',
                        onTap: () {},
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        context,
                        Icons.receipt_long_outlined,
                        'My Orders',
                        onTap: () {
                          ref.read(customerTabIndexProvider.notifier).state = 3;
                        },
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        context,
                        Icons.favorite_border,
                        'Wishlist',
                        onTap: () {
                          ref.read(customerTabIndexProvider.notifier).state = 2;
                        },
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        context,
                        Icons.payment_outlined,
                        'Payment Methods',
                        onTap: () {},
                      ),
                      _buildDivider(),
                      _buildDivider(),
                      businessInfoAsync.when(
                        data: (info) => _buildMenuItem(
                          context,
                          Icons.chat_bubble_outline,
                          'WhatsApp Support',
                          onTap: () => _launchURL('https://wa.me/${info.whatsappNumber}'),
                        ),
                        loading: () => const SizedBox(),
                        error: (_, __) => _buildMenuItem(
                          context,
                          Icons.chat_bubble_outline,
                          'WhatsApp Support',
                          onTap: () => _launchURL('https://wa.me/+919998887776'),
                        ),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        context,
                        Icons.settings_outlined,
                        'Settings',
                        onTap: () {},
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        context,
                        Icons.logout,
                        'Logout',
                        textColor: Colors.red,
                        iconColor: Colors.red,
                        onTap: () async {
                          final router = GoRouter.of(context);
                          await ref.read(authRepoProvider).signOut();
                          ref.read(currentUserDetailsProvider.notifier).state = null;
                          ref.read(cartProvider.notifier).clear();
                          router.go('/home');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, {required VoidCallback onTap, Color? textColor, Color? iconColor}) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Theme.of(context).colorScheme.primary, size: 20),
      title: Text(title, style: TextStyle(color: textColor ?? Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      trailing: Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.4), size: 18),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(color: Color(0xFF05372B), height: 1, indent: 16, endIndent: 16);
  }
}
