import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:al_ruby_ecommerce/presentation/providers/providers.dart';
import 'package:al_ruby_ecommerce/presentation/customer/customer_layout.dart';

class ProfileScreen extends ConsumerWidget {
  final bool isEmbedded;
  const ProfileScreen({super.key, this.isEmbedded = false});

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        leading: isEmbedded
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
                // Profile Details Card (Screen 7)
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
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () {
                            // Dummy edit profile click
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Edit Profile is currently disabled')),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          ),
                          child: const Text('Edit Profile', style: TextStyle(fontSize: 13)),
                        ),
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
                          ref.read(customerTabIndexProvider.notifier).state = 3; // Swap to Orders tab
                        },
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        context,
                        Icons.favorite_border,
                        'Wishlist',
                        onTap: () {
                          ref.read(customerTabIndexProvider.notifier).state = 2; // Swap to Wishlist tab
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
                      _buildMenuItem(
                        context,
                        Icons.people_outline,
                        'Refer & Earn',
                        onTap: () {},
                      ),
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
                          await ref.read(authRepoProvider).signOut();
                          ref.read(currentUserDetailsProvider.notifier).state = null;
                          ref.read(cartProvider.notifier).clear();
                          context.go('/home');
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
