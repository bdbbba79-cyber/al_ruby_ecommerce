import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:al_ruby_ecommerce/presentation/providers/providers.dart';
import 'package:al_ruby_ecommerce/core/theme/theme.dart';
import 'package:al_ruby_ecommerce/presentation/widgets/app_network_image.dart';
import 'package:al_ruby_ecommerce/data/services/order_alert_service.dart';
import 'package:al_ruby_ecommerce/data/models/order.dart';

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

  /// Helper to open any admin dialog with the high-contrast light admin theme
  static Future<T?> showAdminDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => Theme(
        data: AppTheme.adminTheme,
        child: builder(ctx),
      ),
    );
  }

  /// Reusable elevated section card matching the Product Add/Edit aesthetic
  static Widget buildSectionCard({
    required String title,
    required IconData icon,
    String? subtitle,
    required Widget child,
    Widget? trailing,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F62FE).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xFF0F62FE), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const Divider(height: 24, color: Color(0xFFF1F5F9)),
            child,
          ],
        ),
      ),
    );
  }

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
    // Initialize audio player if needed
    OrderAlertService().init();

    // Listen to adminOrdersProvider to detect incoming new orders
    ref.listen<AsyncValue<List<OrderModel>>>(adminOrdersProvider, (previous, next) {
      next.whenData((orders) {
        OrderAlertService().processOrders(orders);
      });
    });

    // Configure the alert banner when a new order arrives
    OrderAlertService().onNewOrder = (newOrder) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626), // High-alert red
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 30),
          elevation: 8,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: SnackBarAction(
            label: 'STOP ALARM',
            textColor: Colors.yellowAccent,
            onPressed: () {
              OrderAlertService().stopAlert();
            },
          ),
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_active, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🚨 NEW ORDER ARRIVED! (30s Alert)',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '#${newOrder.id.length > 8 ? newOrder.id.substring(0, 8) : newOrder.id} • ${newOrder.customerName} • ₹${newOrder.grandTotal.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  OrderAlertService().stopAlert();
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  context.go('/admin/orders');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFDC2626),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('VIEW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ),
      );
    };

    final businessInfo = ref.watch(businessInfoProvider).valueOrNull;
    final isDesktop = MediaQuery.of(context).size.width > 900;

    final navItems = [
      const NavigationDrawerValue(Icons.dashboard_outlined, 'Dashboard'),
      const NavigationDrawerValue(Icons.shopping_bag_outlined, 'Products'),
      const NavigationDrawerValue(Icons.folder_open_outlined, 'Categories'),
      const NavigationDrawerValue(Icons.receipt_long_outlined, 'Orders'),
      const NavigationDrawerValue(Icons.settings_outlined, 'Settings'),
      const NavigationDrawerValue(Icons.people_outline, 'Users'),
    ];

    return Theme(
      data: AppTheme.adminTheme,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Stop Alarm Quick Action in AppBar when active
          ValueListenableBuilder<bool>(
            valueListenable: OrderAlertService().isAlertActiveNotifier,
            builder: (context, isAlertActive, _) {
              if (!isAlertActive) return const SizedBox.shrink();
              return ValueListenableBuilder<int>(
                valueListenable: OrderAlertService().remainingSecondsNotifier,
                builder: (context, remaining, _) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        OrderAlertService().stopAlert();
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      },
                      icon: const Icon(Icons.stop_circle, size: 18, color: Colors.white),
                      label: Text(
                        'STOP ALARM (${remaining}s)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          // Order Sound Alert Action
          ValueListenableBuilder<bool>(
            valueListenable: OrderAlertService().isSoundEnabledNotifier,
            builder: (context, isSoundEnabled, _) {
              return PopupMenuButton<String>(
                tooltip: isSoundEnabled ? 'Order Alert Sound: Active' : 'Order Alert Sound: Muted',
                offset: const Offset(0, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSoundEnabled ? const Color(0xFFEF4444).withOpacity(0.1) : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSoundEnabled ? Icons.notifications_active : Icons.notifications_off_outlined,
                    color: isSoundEnabled ? const Color(0xFFDC2626) : const Color(0xFF94A3B8),
                    size: 20,
                  ),
                ),
                onSelected: (value) async {
                  if (value == 'toggle') {
                    OrderAlertService().toggleSound();
                    final enabled = OrderAlertService().isSoundEnabled;
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(enabled ? '🔔 Order alert sound ENABLED' : '🔕 Order alert sound MUTED'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else if (value == 'test') {
                    await OrderAlertService().playTestAlert();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🔊 30s High Alert Sound Test started. Click STOP ALARM to silence.'),
                          duration: Duration(seconds: 3),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'test',
                    child: Row(
                      children: [
                        Icon(Icons.volume_up, color: Color(0xFF0F62FE), size: 18),
                        SizedBox(width: 10),
                        Text('Test Alert Sound (30s)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          isSoundEnabled ? Icons.volume_off : Icons.volume_up,
                          color: isSoundEnabled ? Colors.red : Colors.green,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isSoundEnabled ? 'Mute Alert Sound' : 'Enable Alert Sound',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(width: isDesktop ? 8 : 4),
          if (isDesktop)
            TextButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.shopping_basket_outlined, size: 18),
              label: const Text('View Storefront'),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF0F62FE)),
            )
          else
            IconButton(
              tooltip: 'View Storefront',
              icon: const Icon(Icons.shopping_basket_outlined, color: Color(0xFF0F62FE)),
              onPressed: () => context.go('/home'),
            ),
          SizedBox(width: isDesktop ? 12 : 4),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: 'Sign Out',
            onPressed: () async {
              await ref.read(authRepoProvider).signOut();
              ref.read(currentUserDetailsProvider.notifier).state = null;
              ref.read(cartProvider.notifier).clear();
              context.go('/home');
            },
          ),
          SizedBox(width: isDesktop ? 16 : 8),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ActiveOrderAlertBanner(),
          Expanded(
            child: Row(
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
          Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: (businessInfo != null && businessInfo.companyLogoUrl.isNotEmpty)
                    ? AppNetworkImage(
                        imageUrl: businessInfo.companyLogoUrl,
                        height: 38,
                        width: 38,
                        cacheWidth: 80,
                        cacheHeight: 80,
                        fit: BoxFit.contain,
                        fallbackAsset: 'assets/logo/logo.png',
                      )
                    : Image.asset('assets/logo/logo.png', height: 38, width: 38, fit: BoxFit.contain),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  businessInfo?.companyName.toUpperCase() ?? 'IZZFAH NOOBI',
                  style: const TextStyle(
                    color: Color(0xFF0F62FE),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
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

class _ActiveOrderAlertBanner extends StatelessWidget {
  const _ActiveOrderAlertBanner();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: OrderAlertService().isAlertActiveNotifier,
      builder: (context, isActive, _) {
        if (!isActive) return const SizedBox.shrink();

        return ValueListenableBuilder<int>(
          valueListenable: OrderAlertService().remainingSecondsNotifier,
          builder: (context, remaining, _) {
            final order = OrderAlertService().currentAlertOrder;

            return Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFB91C1C), Color(0xFFDC2626), Color(0xFFEF4444)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x40DC2626),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 10,
                children: [
                  // Left side info
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.notifications_active, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                '🚨 NEW ORDER ARRIVED!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Ringing: ${remaining}s left',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            order != null
                                ? 'Order #${order.id.length > 8 ? order.id.substring(0, 8) : order.id} • ${order.customerName} • ₹${order.grandTotal.toStringAsFixed(0)} • ${order.paymentMethod}'
                                : 'High alert sound active for 30s. Click STOP ALARM to silence.',
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Right side actions
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          OrderAlertService().stopAlert();
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        },
                        icon: const Icon(Icons.stop_circle, size: 20),
                        label: const Text('STOP ALARM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFDC2626),
                          elevation: 3,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      if (order != null) ...[
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: () {
                            OrderAlertService().stopAlert();
                            context.go('/admin/orders');
                          },
                          icon: const Icon(Icons.receipt_long, size: 18, color: Colors.white),
                          label: const Text('VIEW ORDER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white, width: 1.5),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
