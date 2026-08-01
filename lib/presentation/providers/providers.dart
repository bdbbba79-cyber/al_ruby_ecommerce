import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:al_ruby_ecommerce/data/models/product.dart';
import 'package:al_ruby_ecommerce/data/models/category.dart';
import 'package:al_ruby_ecommerce/data/models/order.dart';
import 'package:al_ruby_ecommerce/data/models/user_model.dart';
import 'package:al_ruby_ecommerce/data/models/business_info.dart';
import 'package:al_ruby_ecommerce/data/repositories/auth_repository.dart';
import 'package:al_ruby_ecommerce/data/repositories/store_repository.dart';
import 'package:al_ruby_ecommerce/data/repositories/order_repository.dart';
import 'package:al_ruby_ecommerce/data/repositories/business_repository.dart';

// --- Repositories ---
final authRepoProvider = Provider<AuthRepository>((ref) => AuthRepository());
final storeRepoProvider = Provider<StoreRepository>((ref) => StoreRepository());
final orderRepoProvider = Provider<OrderRepository>((ref) => OrderRepository());
final businessRepoProvider = Provider<BusinessRepository>((ref) => BusinessRepository());

// --- Authentication State ---
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepoProvider).authStateChanges;
});

final userDetailsProvider = FutureProvider<UserModel?>((ref) async {
  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) return null;
  return await ref.watch(authRepoProvider).getUserDetails(authUser.uid);
});

// For general UI logic, we can also maintain a state of the logged-in user details
final currentUserDetailsProvider = StateProvider<UserModel?>((ref) => null);

// --- Business & Catalog State ---
final businessInfoProvider = StreamProvider<BusinessInfo>((ref) {
  return ref.watch(businessRepoProvider).watchBusinessInfo();
});

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(storeRepoProvider).watchCategories();
});

final productsProvider = StreamProvider.family<List<Product>, String?>((ref, categoryId) {
  return ref.watch(storeRepoProvider).watchProducts(category: categoryId);
});

final adminProductsProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(storeRepoProvider).watchProducts(activeOnly: false);
});

final bannersProvider = StreamProvider<List<String>>((ref) {
  return ref.watch(storeRepoProvider).watchBanners();
});

// --- Cart State ---
class CartItem {
  final Product product;
  final int quantity;

  CartItem({required this.product, required this.quantity});

  CartItem copyWith({Product? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  double get totalPrice => product.sellingPrice * quantity;
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addItem(Product product) {
    final index = state.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == index)
            state[i].copyWith(quantity: state[i].quantity + 1)
          else
            state[i]
      ];
    } else {
      state = [...state, CartItem(product: product, quantity: 1)];
    }
  }

  void removeItem(Product product) {
    state = state.where((item) => item.product.id != product.id).toList();
  }

  void updateQuantity(Product product, int quantity) {
    if (quantity <= 0) {
      removeItem(product);
      return;
    }
    state = [
      for (final item in state)
        if (item.product.id == product.id)
          item.copyWith(quantity: quantity)
        else
          item
    ];
  }

  void clear() {
    state = [];
  }

  double get subtotal => state.fold(0, (sum, item) => sum + item.totalPrice);
}

final cartProvider = StateNotifierNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

// Helper for Riverpod 2 StateNotifierProvider syntax
typedef StateNotifierNotifierProvider<T extends StateNotifier<S>, S> = StateNotifierProvider<T, S>;

// --- Wishlist State ---
class WishlistNotifier extends StateNotifier<List<Product>> {
  final Ref _ref;
  WishlistNotifier(this._ref) : super([]);

  void toggleWishlist(Product product) {
    final isFav = state.any((p) => p.id == product.id);
    if (isFav) {
      state = state.where((p) => p.id != product.id).toList();
    } else {
      state = [...state, product];
    }
    _syncWithFirebase();
  }

  void loadWishlist(List<Product> products, List<String> wishIds) {
    state = products.where((p) => wishIds.contains(p.id)).toList();
  }

  void _syncWithFirebase() {
    final details = _ref.read(currentUserDetailsProvider);
    if (details != null) {
      final ids = state.map((p) => p.id).toList();
      _ref.read(authRepoProvider).updateWishlist(details.id, ids);
      _ref.read(currentUserDetailsProvider.notifier).state = details.copyWith(wishlist: ids);
    }
  }
}

final wishlistProvider = StateNotifierNotifierProvider<WishlistNotifier, List<Product>>((ref) {
  return WishlistNotifier(ref);
});

// --- Orders State ---
final customerOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final details = ref.watch(currentUserDetailsProvider);
  if (details == null) return Stream.value([]);
  return ref.watch(orderRepoProvider).watchUserOrders(details.id);
});

final adminOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  return ref.watch(orderRepoProvider).watchAllOrders();
});
