import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Screens
import 'package:al_ruby_ecommerce/presentation/customer/splash_screen.dart';
import 'package:al_ruby_ecommerce/presentation/customer/login_screen.dart';
import 'package:al_ruby_ecommerce/presentation/customer/register_screen.dart';
import 'package:al_ruby_ecommerce/presentation/customer/forgot_password_screen.dart';
import 'package:al_ruby_ecommerce/presentation/customer/home_screen.dart';
import 'package:al_ruby_ecommerce/presentation/customer/product_detail_screen.dart';
import 'package:al_ruby_ecommerce/presentation/customer/cart_screen.dart';
import 'package:al_ruby_ecommerce/presentation/customer/checkout_screen.dart';
import 'package:al_ruby_ecommerce/presentation/customer/profile_screen.dart';
import 'package:al_ruby_ecommerce/presentation/admin/admin_dashboard_screen.dart';
import 'package:al_ruby_ecommerce/presentation/admin/admin_products_screen.dart';
import 'package:al_ruby_ecommerce/presentation/admin/admin_categories_screen.dart';
import 'package:al_ruby_ecommerce/presentation/admin/admin_orders_screen.dart';
import 'package:al_ruby_ecommerce/presentation/admin/admin_settings_screen.dart';

import 'package:al_ruby_ecommerce/presentation/providers/providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final user = ref.read(currentUserDetailsProvider);
      final loggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/';

      // Accessing admin routes
      if (state.matchedLocation.startsWith('/admin')) {
        if (user == null) return '/login';
        if (user.role != 'admin') return '/home';
      }

      // Accessing private customer routes
      if (state.matchedLocation == '/profile' || state.matchedLocation == '/checkout') {
        if (user == null) return '/login';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) {
          final productId = state.pathParameters['id'] ?? '';
          return ProductDetailScreen(productId: productId);
        },
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      
      // Admin Panel Routes
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/products',
        builder: (context, state) => const AdminProductsScreen(),
      ),
      GoRoute(
        path: '/admin/categories',
        builder: (context, state) => const AdminCategoriesScreen(),
      ),
      GoRoute(
        path: '/admin/orders',
        builder: (context, state) => const AdminOrdersScreen(),
      ),
      GoRoute(
        path: '/admin/settings',
        builder: (context, state) => const AdminSettingsScreen(),
      ),
    ],
  );
});
