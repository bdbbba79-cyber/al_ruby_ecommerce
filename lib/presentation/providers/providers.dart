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


// --- Referral State ---
// Mappings of productId to the referral code used to visit the product
final productReferralsProvider = StateProvider<Map<String, String>>((ref) => {});

// --- Cart State ---
class CartItem {
  final Product product;
  final int quantity;
  final String? selectedVariantSize;
  final String? referrerCode;

  CartItem({
    required this.product,
    required this.quantity,
    this.selectedVariantSize,
    this.referrerCode,
  });

  CartItem copyWith({
    Product? product,
    int? quantity,
    String? selectedVariantSize,
    String? referrerCode,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      selectedVariantSize: selectedVariantSize ?? this.selectedVariantSize,
      referrerCode: referrerCode ?? this.referrerCode,
    );
  }

  double get unitPrice {
    if (selectedVariantSize != null && product.variants.isNotEmpty) {
      final variant = product.variants.firstWhere(
        (v) => v.size == selectedVariantSize,
        orElse: () => ProductVariant(size: selectedVariantSize!, mrp: product.mrp, sellingPrice: product.sellingPrice, stock: product.stock),
      );
      return variant.sellingPrice;
    }
    return product.sellingPrice;
  }

  double get totalPrice => unitPrice * quantity;
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  final Ref _ref;
  CartNotifier(this._ref) : super([]);

  void addItem(Product product, {String? selectedVariantSize, String? referrerCode}) {
    // Determine the referral code automatically if not explicitly provided
    final resolvedReferrerCode = referrerCode ?? _ref.read(productReferralsProvider)[product.id];

    final index = state.indexWhere((item) =>
        item.product.id == product.id &&
        item.selectedVariantSize == selectedVariantSize);
    if (index >= 0) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == index)
            state[i].copyWith(
              quantity: state[i].quantity + 1,
              referrerCode: resolvedReferrerCode ?? state[i].referrerCode,
            )
          else
            state[i]
      ];
    } else {
      state = [
        ...state,
        CartItem(
          product: product,
          quantity: 1,
          selectedVariantSize: selectedVariantSize,
          referrerCode: resolvedReferrerCode,
        )
      ];
    }
    _syncWithFirebase();
  }

  void removeItem(Product product, {String? selectedVariantSize}) {
    state = state.where((item) =>
        !(item.product.id == product.id &&
          item.selectedVariantSize == selectedVariantSize)).toList();
    _syncWithFirebase();
  }

  void updateQuantity(Product product, int quantity, {String? selectedVariantSize}) {
    if (quantity <= 0) {
      removeItem(product, selectedVariantSize: selectedVariantSize);
      return;
    }
    state = [
      for (final item in state)
        if (item.product.id == product.id && item.selectedVariantSize == selectedVariantSize)
          item.copyWith(quantity: quantity)
        else
          item
    ];
    _syncWithFirebase();
  }

  void clear() {
    state = [];
    _syncWithFirebase();
  }

  void loadCart(List<Product> products, List<Map<String, dynamic>> savedCart) {
    state = savedCart.map((map) {
      final productId = map['productId'] ?? '';
      final matching = products.where((p) => p.id == productId);
      if (matching.isEmpty) return null;
      return CartItem(
        product: matching.first,
        quantity: map['quantity'] ?? 1,
        selectedVariantSize: map['selectedVariantSize'],
        referrerCode: map['referrerCode'],
      );
    }).whereType<CartItem>().toList();
  }

  void _syncWithFirebase() {
    final details = _ref.read(currentUserDetailsProvider);
    if (details != null) {
      final cartList = state.map((item) => {
        'productId': item.product.id,
        'quantity': item.quantity,
        'selectedVariantSize': item.selectedVariantSize,
        'referrerCode': item.referrerCode,
      }).toList();
      _ref.read(authRepoProvider).updateCart(details.id, cartList);
      _ref.read(currentUserDetailsProvider.notifier).state = details.copyWith(cart: cartList);
    }
  }

  double get subtotal => state.fold(0, (sum, item) => sum + item.totalPrice);
  double get shippingFee => state.fold(0.0, (sum, item) => sum + (item.product.shippingFee * item.quantity));
}

final appliedCouponProvider = StateProvider<String?>((ref) => null);

final cartProvider = StateNotifierNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier(ref);
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

final adminUsersProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(authRepoProvider).watchAllUsers();
});
