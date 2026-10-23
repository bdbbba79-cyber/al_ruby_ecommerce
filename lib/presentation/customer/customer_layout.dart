import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:al_ruby_ecommerce/presentation/providers/providers.dart';
import 'package:al_ruby_ecommerce/data/models/business_info.dart';
import 'package:al_ruby_ecommerce/presentation/widgets/app_network_image.dart';

// Tab Views
import 'package:al_ruby_ecommerce/presentation/customer/home_screen.dart';
import 'package:al_ruby_ecommerce/presentation/customer/products_view.dart';
import 'package:al_ruby_ecommerce/presentation/customer/wishlist_view.dart';
import 'package:al_ruby_ecommerce/presentation/customer/orders_view.dart';
import 'package:al_ruby_ecommerce/presentation/customer/profile_screen.dart';

final customerTabIndexProvider = StateProvider<int>((ref) => 0);

class CustomerLayout extends ConsumerStatefulWidget {
  final int initialIndex;
  const CustomerLayout({super.key, this.initialIndex = 0});

  @override
  ConsumerState<CustomerLayout> createState() => _CustomerLayoutState();
}

class _CustomerLayoutState extends ConsumerState<CustomerLayout> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerTabIndexProvider.notifier).state = widget.initialIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(customerTabIndexProvider);
    final user = ref.watch(currentUserDetailsProvider);
    final businessInfo = ref.watch(businessInfoProvider).valueOrNull;
    final isDesktop = MediaQuery.of(context).size.width > 800;

    // List of screens corresponding to the tab index
    final List<Widget> screens = [
      const HomeScreen(isEmbedded: true), // Tell HomeScreen it is embedded inside layout
      const ProductsView(),
      const WishlistView(),
      const OrdersView(),
      const ProfileScreen(isEmbedded: true), // Tell ProfileScreen it is embedded
    ];

    return Scaffold(
      appBar: isDesktop ? _buildDesktopHeader(context, selectedIndex, user, businessInfo) : null,
      body: screens[selectedIndex],
      bottomNavigationBar: isDesktop
          ? null
          : Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
                ),
              ),
              child: BottomNavigationBar(
                currentIndex: selectedIndex,
                onTap: (index) {
                  ref.read(customerTabIndexProvider.notifier).state = index;
                },
                backgroundColor: Colors.white,
                selectedItemColor: const Color(0xFF1E60D5),
                unselectedItemColor: const Color(0xFF64748B),
                type: BottomNavigationBarType.fixed,
                showUnselectedLabels: true,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                unselectedLabelStyle: const TextStyle(fontSize: 11),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.grid_view_outlined),
                    activeIcon: Icon(Icons.grid_view),
                    label: 'Products',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.favorite_border),
                    activeIcon: Icon(Icons.favorite),
                    label: 'Wishlist',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.receipt_long_outlined),
                    activeIcon: Icon(Icons.receipt_long),
                    label: 'Orders',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    activeIcon: Icon(Icons.person),
                    label: 'Account',
                  ),
                ],
              ),
            ),
    );
  }

  PreferredSizeWidget _buildDesktopHeader(BuildContext context, int selectedIndex, user, BusinessInfo? businessInfo) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (businessInfo?.companyLogoUrl != null && businessInfo!.companyLogoUrl.isNotEmpty)
            AppNetworkImage(
              imageUrl: businessInfo.companyLogoUrl,
              height: 36,
              width: 36,
              cacheWidth: 108,
              cacheHeight: 108,
              fit: BoxFit.contain,
              fallbackAsset: 'assets/logo/logo.png',
            )
          else
            Image.asset('assets/logo/logo.png', height: 36, width: 36, cacheWidth: 108, cacheHeight: 108, fit: BoxFit.contain),
          const SizedBox(width: 10),
          Text(
            businessInfo?.companyName ?? 'IZZFAH NOOBI',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF0F172A), letterSpacing: 0.5),
          ),
        ],
      ),
      actions: [
        // Navigation Buttons
        _buildNavButton(context, 0, 'Home', selectedIndex == 0),
        _buildNavButton(context, 1, 'Products', selectedIndex == 1),
        _buildNavButton(context, 2, 'Wishlist', selectedIndex == 2),
        _buildNavButton(context, 3, 'My Orders', selectedIndex == 3),
        _buildNavButton(context, 4, 'My Account', selectedIndex == 4),
        
        const SizedBox(width: 16),
        // Cart Icon
        IconButton(
          icon: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF1E60D5)),
          onPressed: () => context.push('/cart'),
        ),
        if (user?.role == 'admin') ...[
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => context.go('/admin'),
            icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
            label: const Text('Admin Panel'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1E60D5),
              side: const BorderSide(color: Color(0xFF1E60D5)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildNavButton(BuildContext context, int index, String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: TextButton(
        onPressed: () {
          ref.read(customerTabIndexProvider.notifier).state = index;
        },
        style: TextButton.styleFrom(
          foregroundColor: isSelected ? const Color(0xFF1E60D5) : const Color(0xFF64748B),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
