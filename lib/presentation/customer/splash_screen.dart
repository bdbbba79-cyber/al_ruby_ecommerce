import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:al_ruby_ecommerce/presentation/providers/providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait for the Firebase Auth to initialize and check session
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (!mounted) return;

    final authUser = ref.read(authRepoProvider).currentUser;
    if (authUser == null) {
      context.go('/home');
      return;
    }

    try {
      final userDetails = await ref.read(authRepoProvider).getUserDetails(authUser.uid);
      if (userDetails != null) {
        ref.read(currentUserDetailsProvider.notifier).state = userDetails;
        
        // Sync wishlist
        final products = await ref.read(storeRepoProvider).getProducts(activeOnly: false);
        ref.read(wishlistProvider.notifier).loadWishlist(products, userDetails.wishlist);

        if (userDetails.role == 'admin') {
          context.go('/admin');
        } else {
          context.go('/home');
        }
      } else {
        context.go('/home');
      }
    } catch (e) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final businessInfoAsync = ref.watch(businessInfoProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            businessInfoAsync.when(
              data: (info) => info.companyLogoUrl.isNotEmpty
                  ? Image.network(info.companyLogoUrl, height: 160, width: 160, fit: BoxFit.contain)
                  : _buildFallbackLogo(),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => _buildFallbackLogo(),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 140,
              child: LinearProgressIndicator(
                color: Color(0xFF0F62FE),
                backgroundColor: Color(0xFFF1F5F9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackLogo() {
    return Column(
      children: [
        Container(
          height: 100,
          width: 100,
          decoration: BoxDecoration(
            color: const Color(0xFF0F62FE),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: const Text(
            'AR',
            style: TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Al Ruby Perfumes',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
