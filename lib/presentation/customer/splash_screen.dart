import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:al_ruby_ecommerce/presentation/providers/providers.dart';
import 'package:al_ruby_ecommerce/presentation/widgets/app_network_image.dart';

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
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (!mounted) return;

    // If the user has already navigated away (e.g., deep linking on boot), abort redirect
    try {
      final router = GoRouter.of(context);
      final currentPath = router.routerDelegate.currentConfiguration.uri.path;
      if (currentPath != '/') {
        debugPrint("Splash screen redirect aborted: current path is $currentPath");
        return;
      }
    } catch (e) {
      debugPrint("Error checking splash path: $e");
    }

    final authUser = ref.read(authRepoProvider).currentUser;
    if (authUser == null) {
      context.go('/home');
      return;
    }

    try {
      final userDetails = await ref.read(authRepoProvider).getUserDetails(authUser.uid);
      if (userDetails != null) {
        ref.read(currentUserDetailsProvider.notifier).state = userDetails;
        
        // Sync wishlist & cart
        final products = await ref.read(storeRepoProvider).getProducts(activeOnly: false);
        ref.read(wishlistProvider.notifier).loadWishlist(products, userDetails.wishlist);
        ref.read(cartProvider.notifier).loadCart(products, userDetails.cart);

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
                  ? AppNetworkImage(
                      imageUrl: info.companyLogoUrl,
                      height: 150,
                      width: 150,
                      cacheWidth: 300,
                      cacheHeight: 300,
                      fit: BoxFit.contain,
                      fallbackAsset: 'assets/logo/logo.png',
                    )
                  : _buildFallbackLogo(info.companyName),
              loading: () => _buildFallbackLogo(null),
              error: (_, __) => _buildFallbackLogo(null),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 140,
              child: LinearProgressIndicator(
                color: Color(0xFF1E60D5),
                backgroundColor: Color(0xFFEFF6FF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackLogo(String? name) {
    return Image.asset(
      'assets/logo/logo.png',
      height: 150,
      width: 150,
      cacheWidth: 300,
      cacheHeight: 300,
      fit: BoxFit.contain,
    );
  }
}
