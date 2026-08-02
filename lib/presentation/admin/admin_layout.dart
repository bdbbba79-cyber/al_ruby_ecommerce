import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:al_ruby_ecommerce/presentation/providers/providers.dart';

class AdminLayout extends ConsumerWidget {
  final Widget child;
  final int selectedIndex;
  final String title;

  const AdminLayout({
    super.key,
    required this.child,
    required this.selectedIndex,
    required this.title,
  });

  void _onNavigation(BuildContext context, int index) {
    if (index == selectedIndex) return;
    switch (index) {
      case 0:
        context.go('/admin');
        break;
      case 1:
        context.go('/admin/products');
        break;
      case 2:
        context.go('/admin/categories');
        break;
      case 3:
        context.go('/admin/orders');
        break;
      case 4:
        context.go('/admin/settings');
        break;
      case 5:
        context.go('/admin/users');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessInfo = ref.watch(businessInfoProvider).value;
    final isDesktop = MediaQuery.of(context).size.width > 900;

    final navItems = [
      const NavigationDrawerValue(Icons.dashboard_outlined, 'Dashboard'),
      const NavigationDrawerValue(Icons.shopping_bag_outlined, 'Products'),
      const NavigationDrawerValue(Icons.folder_open_outlined, 'Categories'),
      const NavigationDrawerValue(Icons.receipt_long_outlined, 'Orders'),
      const NavigationDrawerValue(Icons.settings_outlined, 'Settings'),
      const NavigationDrawerValue(Icons.people_outline, 'Users'),
    ];

    final adminTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0F62FE),
        brightness: Brightness.light,
        background: const Color(0xFFF8FAFC),
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF0F172A),
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF0F172A)),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF0F62FE), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIconColor: const Color(0xFF64748B),
        suffixIconColor: const Color(0xFF64748B),
      ),
    );

    return Theme(
      data: adminTheme,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.shopping_basket_outlined, size: 18),
            label: const Text('View Storefront'),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF0F62FE)),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              await ref.read(authRepoProvider).signOut();
              ref.read(currentUserDetailsProvider.notifier).state = null;
              ref.read(cartProvider.notifier).clear();
              context.go('/home');
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      drawer: !isDesktop
          ? Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildHeader(businessInfo),
                  const Divider(height: 1),
                  ...List.generate(navItems.length, (index) {
                    final item = navItems[index];
                    return ListTile(
                      leading: Icon(item.icon, color: selectedIndex == index ? const Color(0xFF0F62FE) : const Color(0xFF64748B)),
                      title: Text(
                        item.label,
                        style: TextStyle(
                          fontWeight: selectedIndex == index ? FontWeight.bold : FontWeight.normal,
                          color: selectedIndex == index ? const Color(0xFF0F62FE) : const Color(0xFF0F172A),
                        ),
                      ),
                      selected: selectedIndex == index,
                      selectedTileColor: const Color(0xFF0F62FE).withOpacity(0.08),
                      onTap: () {
                        Navigator.pop(context);
                        _onNavigation(context, index);
                      },
                    );
                  }),
                ],
              ),
            )
          : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sidebar for Desktop
          if (isDesktop)
            Container(
              width: 260,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
              ),
              child: Column(
                children: [
                  _buildHeader(businessInfo),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: navItems.length,
                      itemBuilder: (context, index) {
                        final item = navItems[index];
                        final isSelected = selectedIndex == index;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                          child: InkWell(
                            onTap: () => _onNavigation(context, index),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF0F62FE).withOpacity(0.08) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    item.icon,
                                    color: isSelected ? const Color(0xFF0F62FE) : const Color(0xFF64748B),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    item.label,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected ? const Color(0xFF0F62FE) : const Color(0xFF475569),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          // Content
          Expanded(
            child: child,
          ),
        ],
      ),
    ),);
  }

  Widget _buildHeader(businessInfo) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (businessInfo != null && businessInfo.companyLogoUrl.isNotEmpty)
            Image.network(businessInfo.companyLogoUrl, height: 40, fit: BoxFit.contain)
          else
            Text(
              businessInfo?.companyName.toUpperCase() ?? 'AR ADMIN',
              style: const TextStyle(
                color: Color(0xFF0F62FE),
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          const SizedBox(height: 6),
          const Text(
            'Control Panel',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class NavigationDrawerValue {
  final IconData icon;
  final String label;
  const NavigationDrawerValue(this.icon, this.label);
}
