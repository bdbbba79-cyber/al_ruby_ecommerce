import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:al_ruby_ecommerce/presentation/providers/providers.dart';

class WhatsappSupportView extends ConsumerWidget {
  const WhatsappSupportView({super.key});

  Future<void> _launchWhatsApp(String number) async {
    final url = 'https://wa.me/$number';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessInfoAsync = ref.watch(businessInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('WHATSAPP SUPPORT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // WhatsApp Large Circular Emblem
                Container(
                  height: 120,
                  width: 120,
                  decoration: const BoxDecoration(
                    color: Color(0xFF25D366),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.whatsapp,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),

                const Text(
                  'Need Help?',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Chat with us on WhatsApp',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFC6A473)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'We are online and ready to help you with order placement, product selection, or delivery issues!',
                  style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // WhatsApp Support Action Button
                businessInfoAsync.when(
                  data: (info) => ElevatedButton.icon(
                    onPressed: () => _launchWhatsApp(info.whatsappNumber),
                    icon: const Icon(Icons.whatsapp, size: 24),
                    label: const Text('CHAT ON WHATSAPP'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => ElevatedButton.icon(
                    onPressed: () => _launchWhatsApp('+919998887776'),
                    icon: const Icon(Icons.whatsapp, size: 24),
                    label: const Text('CHAT ON WHATSAPP'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // Features Grid/Row at the bottom
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFeatureIcon(Icons.chat_bubble_outline, 'Quick\nReply'),
                    _buildFeatureIcon(Icons.shopping_bag_outlined, 'Order\nSupport'),
                    _buildFeatureIcon(Icons.sentiment_satisfied_alt_outlined, 'Friendly\nService'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Color(0xFF022B20),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFFC6A473), size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.2),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
