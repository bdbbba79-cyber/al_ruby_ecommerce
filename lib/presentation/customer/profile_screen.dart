import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:al_ruby_ecommerce/core/utils/url_launcher_utils.dart';
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

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _showEditProfileDialog(UserModel user) {
    _phoneController.text = user.phoneNumber;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Profile Details', style: TextStyle(fontWeight: FontWeight.bold)),
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
              
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              await ref.read(authRepoProvider).updateMarketingProfile(user.id, phone, '');
              
              ref.read(currentUserDetailsProvider.notifier).state = user.copyWith(
                phoneNumber: phone,
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
                icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
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
                            color: const Color(0xFFEFF6FF),
                          ),
                          child: const Icon(Icons.person, size: 48, color: Color(0xFF1E60D5)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        ),
                        if (user.phoneNumber.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text('Phone: ${user.phoneNumber}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
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

                const SizedBox(height: 20),

                // Options List Menu
                Card(
                  color: Theme.of(context).colorScheme.surface,
                  child: Column(
                    children: [
                      _buildMenuItem(
                        context,
                        Icons.location_on_outlined,
                        'My Addresses',
                        onTap: () => context.push('/addresses'),
                      ),
                      _buildDivider(),
                      businessInfoAsync.when(
                        data: (info) => _buildMenuItem(
                          context,
                          Icons.chat_bubble_outline,
                          'WhatsApp Support',
                          textColor: const Color(0xFF25D366),
                          iconColor: const Color(0xFF25D366),
                          onTap: () => launchWhatsApp(
                            context: context,
                            phone: info.whatsappNumber,
                            message: 'Hello Izzfah Noobi, I need support.',
                          ),
                        ),
                        loading: () => const SizedBox(),
                        error: (_, _) => _buildMenuItem(
                          context,
                          Icons.chat_bubble_outline,
                          'WhatsApp Support',
                          textColor: const Color(0xFF25D366),
                          iconColor: const Color(0xFF25D366),
                          onTap: () => launchWhatsApp(
                            context: context,
                            phone: '919656978468',
                            message: 'Hello Izzfah Noobi, I need support.',
                          ),
                        ),
                      ),
                      if (user.role == 'admin') ...[
                        _buildDivider(),
                        _buildMenuItem(
                          context,
                          Icons.admin_panel_settings_outlined,
                          'Admin Panel',
                          textColor: const Color(0xFF1E60D5),
                          iconColor: const Color(0xFF1E60D5),
                          onTap: () => context.go('/admin'),
                        ),
                      ],
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
      title: Text(title, style: TextStyle(color: textColor ?? const Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 18),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(color: Color(0xFFE2E8F0), height: 1, indent: 16, endIndent: 16);
  }
}
