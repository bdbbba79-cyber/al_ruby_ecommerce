import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:al_ruby_ecommerce/core/utils/url_launcher_utils.dart';
import 'package:al_ruby_ecommerce/presentation/providers/providers.dart';
import 'package:al_ruby_ecommerce/data/models/product.dart';
import 'package:al_ruby_ecommerce/data/models/category.dart';
import 'package:al_ruby_ecommerce/data/models/business_info.dart';
import 'package:al_ruby_ecommerce/presentation/customer/customer_layout.dart';
import 'package:al_ruby_ecommerce/presentation/widgets/app_network_image.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final bool isEmbedded;
  const HomeScreen({super.key, this.isEmbedded = false});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final businessInfoAsync = ref.watch(businessInfoProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final productsAsync = ref.watch(productsProvider(null));
    final cart = ref.watch(cartProvider);
    final userDetails = ref.watch(currentUserDetailsProvider);

    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: (!isDesktop) ? _buildMobileAppBar(context, cart.length) : null,
      drawer: (!isDesktop) ? _buildMobileDrawer(context, userDetails) : null,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Banner Carousel
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1200),
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 16.0 : 12.0,
                  vertical: isDesktop ? 16.0 : 8.0,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
                  child: businessInfoAsync.when(
                    data: (info) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final double bannerHeight = isDesktop 
                          ? (screenWidth.clamp(0.0, 1200.0) * 0.32).clamp(280.0, 380.0)
                          : (screenWidth * 0.45).clamp(150.0, 240.0);
                      return _buildHeroBanner(info.activeBanners, bannerHeight);
                    },
                    loading: () {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final double bannerHeight = isDesktop 
                          ? (screenWidth.clamp(0.0, 1200.0) * 0.32).clamp(280.0, 380.0)
                          : (screenWidth * 0.45).clamp(150.0, 240.0);
                      return SizedBox(
                        height: bannerHeight, 
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    error: (_, __) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final double bannerHeight = isDesktop 
                          ? (screenWidth.clamp(0.0, 1200.0) * 0.32).clamp(280.0, 380.0)
                          : (screenWidth * 0.45).clamp(150.0, 240.0);
                      return _buildHeroBanner([], bannerHeight);
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Content Container
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search and filters quick navigator
                      _buildQuickSearch(context),

                      const SizedBox(height: 32),

                      // Categories circular selectors
                      _buildCircularCategories(categoriesAsync),

                      const SizedBox(height: 40),

                      // Best Sellers Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'BEST SELLERS',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                              letterSpacing: 1.2,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              ref.read(customerTabIndexProvider.notifier).state = 1; // Swap to Products tab
                            },
                            child: const Row(
                              children: [
                                Text('View All', style: TextStyle(color: Color(0xFF1E60D5), fontWeight: FontWeight.bold)),
                                Icon(Icons.chevron_right, size: 16, color: Color(0xFF1E60D5)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Best Sellers horizontal/grid products
                      productsAsync.when(
                        data: (productsList) => _buildBestSellersGrid(productsList),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Center(child: Text('Error: $err')),
                      ),

                      const SizedBox(height: 40),

                      // Promo / Lifestyle Specials Banner
                      _buildComboBanner(context, businessInfoAsync.valueOrNull),

                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            businessInfoAsync.when(
              data: (info) => _buildFooter(info),
              loading: () => const SizedBox(),
              error: (_, __) => _buildFooter(null),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar(BuildContext context, int cartCount) {
    final businessInfo = ref.watch(businessInfoProvider).valueOrNull;
    final companyName = businessInfo?.companyName ?? 'IZZFAH NOOBI';
    final logoUrl = businessInfo?.companyLogoUrl;

    return AppBar(
      backgroundColor: const Color(0xFF1E60D5),
      elevation: 0.5,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: (logoUrl != null && logoUrl.isNotEmpty)
                ? AppNetworkImage(
                    imageUrl: logoUrl,
                    height: 26,
                    width: 26,
                    cacheWidth: 80,
                    cacheHeight: 80,
                    fit: BoxFit.contain,
                    fallbackAsset: 'assets/logo/logo.png',
                  )
                : Image.asset('assets/logo/logo.png', height: 26, width: 26, cacheWidth: 80, cacheHeight: 80, fit: BoxFit.contain),
          ),
          const SizedBox(width: 8),
          Text(
            companyName.toUpperCase(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: Colors.white,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
              onPressed: () => context.push('/cart'),
            ),
            if (cartCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$cartCount',
                    style: const TextStyle(color: Color(0xFF1E60D5), fontSize: 10, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // --- Mobile Drawer ---
  Widget _buildMobileDrawer(BuildContext context, userDetails) {
    final businessInfoAsync = ref.watch(businessInfoProvider);
    final businessInfo = businessInfoAsync.valueOrNull;
    final companyName = businessInfo?.companyName ?? 'IZZFAH NOOBI';
    final logoUrl = businessInfo?.companyLogoUrl;

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF1E60D5),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: (logoUrl != null && logoUrl.isNotEmpty)
                        ? AppNetworkImage(
                            imageUrl: logoUrl,
                            height: 52,
                            width: 52,
                            cacheWidth: 104,
                            cacheHeight: 104,
                            fit: BoxFit.contain,
                            fallbackAsset: 'assets/logo/logo.png',
                          )
                        : Image.asset('assets/logo/logo.png', height: 52, width: 52, cacheWidth: 104, cacheHeight: 104, fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    companyName.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined, color: Color(0xFF1E60D5)),
            title: const Text('Home', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w500)),
            onTap: () {
              context.pop();
              ref.read(customerTabIndexProvider.notifier).state = 0;
            },
          ),
          ListTile(
            leading: const Icon(Icons.grid_view_outlined, color: Color(0xFF1E60D5)),
            title: const Text('Products', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w500)),
            onTap: () {
              context.pop();
              ref.read(customerTabIndexProvider.notifier).state = 1;
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite_border, color: Color(0xFF1E60D5)),
            title: const Text('Wishlist', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w500)),
            onTap: () {
              context.pop();
              ref.read(customerTabIndexProvider.notifier).state = 2;
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined, color: Color(0xFF1E60D5)),
            title: const Text('My Orders', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w500)),
            onTap: () {
              context.pop();
              ref.read(customerTabIndexProvider.notifier).state = 3;
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline, color: Color(0xFF1E60D5)),
            title: const Text('My Account', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w500)),
            onTap: () {
              context.pop();
              ref.read(customerTabIndexProvider.notifier).state = 4;
            },
          ),
          const Divider(color: Color(0xFFE2E8F0)),
          businessInfoAsync.when(
            data: (info) => ListTile(
              leading: const Icon(Icons.chat_bubble_outline, color: Color(0xFF25D366)),
              title: const Text('WhatsApp Support', style: TextStyle(color: Color(0xFF25D366))),
              onTap: () {
                context.pop();
                launchWhatsApp(
                  context: context,
                  phone: info.whatsappNumber,
                  message: 'Hello Izzfah Noobi, I need support.',
                );
              },
            ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
    );
  }

  // --- Hero Section ---
  Widget _buildHeroBanner(List<HomeBanner> banners, double height) {
    if (banners.isNotEmpty) {
      return SizedBox(
        height: height,
        child: AutoScrollingBanner(banners: banners),
      );
    }

    return Container(
      height: height,
      padding: EdgeInsets.symmetric(
        vertical: height > 240 ? 36.0 : 16.0,
        horizontal: height > 240 ? 24.0 : 16.0,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1E40AF),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Upgrade Your\nLifestyle &\nDaily Fashion',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: height > 240 ? 30 : 17,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: height > 240 ? 8 : 4),
                  Text(
                    'Watches • Shirts • Shoes • Bags • Jerseys',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: height > 240 ? 13 : 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: height > 240 ? 14 : 8),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(customerTabIndexProvider.notifier).state = 1; // Swap to Products tab
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1E60D5),
                      padding: EdgeInsets.symmetric(
                        horizontal: height > 240 ? 20 : 12,
                        vertical: height > 240 ? 12 : 6,
                      ),
                    ),
                    child: Text(
                      'SHOP NOW',
                      style: TextStyle(fontSize: height > 240 ? 14 : 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Lifestyle Fashion Graphic Placeholder
            Container(
              height: height * 0.7,
              width: height * 0.5,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.25)),
              ),
              child: Icon(
                Icons.checkroom_rounded,
                color: Colors.white,
                size: height * 0.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Quick Search Navigator ---
  Widget _buildQuickSearch(BuildContext context) {
    return TextFormField(
      controller: _searchController,
      readOnly: true,
      onTap: () {
        ref.read(customerTabIndexProvider.notifier).state = 1; // Jump to products
      },
      decoration: const InputDecoration(
        hintText: 'Search watches, shirts, pants, shoes, bags, jerseys...',
        prefixIcon: Icon(Icons.search),
      ),
    );
  }

  // --- Circular Categories ---
  Widget _buildCircularCategories(AsyncValue<List<Category>> categoriesAsync) {
    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) return const SizedBox();
        return SizedBox(
          height: 135,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    ref.read(selectedCategoryFilterProvider.notifier).state = cat.name;
                    ref.read(customerTabIndexProvider.notifier).state = 1;
                  },
                  child: SizedBox(
                    width: 80,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          height: 70,
                          width: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF1E60D5), width: 1.5),
                            color: const Color(0xFFEFF6FF),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: ClipOval(
                            child: cat.imageUrl.isNotEmpty
                                ? AppNetworkImage.thumbnail(
                                    imageUrl: cat.imageUrl,
                                    size: 70,
                                    fit: BoxFit.cover,
                                    errorWidget: const Icon(Icons.category_outlined, color: Color(0xFF1E60D5)),
                                  )
                                : const Icon(Icons.category_outlined, color: Color(0xFF1E60D5)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          cat.name,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(height: 135),
      error: (_, __) => const SizedBox(),
    );
  }

  // --- Best Sellers Grid ---
  Widget _buildBestSellersGrid(List<Product> products) {
    // Show top 4 products (minimum 4 if available)
    final bestSellers = products.where((p) => p.status == 'active').take(4).toList();

    if (bestSellers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text('No products available.', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 4;
    if (screenWidth < 600) {
      crossAxisCount = 2; // Grid layout on smaller mobile screens
    } else if (screenWidth < 900) {
      crossAxisCount = 3; // Grid layout on tablets/medium screens
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemCount: bestSellers.length,
      itemBuilder: (context, index) {
        final product = bestSellers[index];
        final wishlist = ref.watch(wishlistProvider);
        final isFav = wishlist.any((p) => p.id == product.id);

        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.push('/product/${product.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      if (product.images.isNotEmpty)
                        AppNetworkImage.card(
                          imageUrl: product.images.first,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        )
                      else
                        Container(
                          color: Theme.of(context).colorScheme.surface,
                          child: const Center(
                            child: Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 30),
                          ),
                        ),
                      // Wishlist heart
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Material(
                          color: Colors.black.withOpacity(0.4),
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: () {
                              final user = ref.read(currentUserDetailsProvider);
                              if (user == null) {
                                context.push('/login');
                              } else {
                                ref.read(wishlistProvider.notifier).toggleWishlist(product);
                              }
                            },
                            customBorder: const CircleBorder(),
                            child: Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav ? Colors.red : Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '₹${product.sellingPrice.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E60D5)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Promo Banner Section ---
  Widget _buildComboBanner(BuildContext context, BusinessInfo? info) {
    final tagText = (info?.promoBannerTag != null && info!.promoBannerTag.trim().isNotEmpty)
        ? info.promoBannerTag
        : 'LIFESTYLE SPECIALS';
    final titleText = (info?.promoBannerTitle != null && info!.promoBannerTitle.trim().isNotEmpty)
        ? info.promoBannerTitle
        : 'UP TO 40% OFF ON WATCHES, APPAREL & FOOTWEAR';
    final buttonText = (info?.promoBannerButtonText != null && info!.promoBannerButtonText.trim().isNotEmpty)
        ? info.promoBannerButtonText
        : 'SHOP NOW';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tagText.toUpperCase(),
            style: const TextStyle(color: Color(0xFF1E60D5), fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          Text(
            titleText,
            style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _handlePromoBannerNavigation(context, info),
            child: Text(buttonText.toUpperCase()),
          ),
        ],
      ),
    );
  }

  void _handlePromoBannerNavigation(BuildContext context, BusinessInfo? info) {
    if (info == null) {
      ref.read(selectedCategoryFilterProvider.notifier).state = null;
      ref.read(customerTabIndexProvider.notifier).state = 1;
      return;
    }

    final targetType = info.promoBannerTargetType;
    final targetValue = info.promoBannerTargetValue.trim();

    switch (targetType) {
      case 'category':
        ref.read(selectedCategoryFilterProvider.notifier).state = targetValue.isNotEmpty ? targetValue : null;
        ref.read(customerTabIndexProvider.notifier).state = 1;
        break;
      case 'product':
        if (targetValue.isNotEmpty) {
          context.push('/product/$targetValue');
        } else {
          ref.read(selectedCategoryFilterProvider.notifier).state = null;
          ref.read(customerTabIndexProvider.notifier).state = 1;
        }
        break;
      case 'url':
        if (targetValue.startsWith('http://') || targetValue.startsWith('https://')) {
          _launchURL(targetValue);
        } else if (targetValue.isNotEmpty) {
          context.push(targetValue.startsWith('/') ? targetValue : '/$targetValue');
        } else {
          ref.read(selectedCategoryFilterProvider.notifier).state = null;
          ref.read(customerTabIndexProvider.notifier).state = 1;
        }
        break;
      case 'all_products':
      default:
        ref.read(selectedCategoryFilterProvider.notifier).state = null;
        ref.read(customerTabIndexProvider.notifier).state = 1;
        break;
    }
  }

  // --- Footer ---
  Widget _buildFooter(BusinessInfo? info) {
    final name = info?.companyName ?? 'IZZFAH NOOBI';
    final address = info?.address ?? 'Erumathadam Malappuram - 679338';
    final email = info?.email ?? 'support@izzfahnoobi.com';
    final mobile = info?.mobileNumber ?? '9400859846';

    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(address, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text('Phone: $mobile', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text('Email: $email', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          if ((info?.facebookLink != null && info!.facebookLink.isNotEmpty) || 
              (info?.instagramLink != null && info!.instagramLink.isNotEmpty)) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (info.facebookLink.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: InkWell(
                      onTap: () => _launchURL(info.facebookLink),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.facebook, color: Color(0xFF1E60D5), size: 20),
                          const SizedBox(width: 6),
                          Text('Facebook', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                if (info.instagramLink.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: InkWell(
                      onTap: () => _launchURL(info.instagramLink),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.camera_alt, color: Color(0xFF1E60D5), size: 20),
                          const SizedBox(width: 6),
                          Text('Instagram', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const Divider(color: Color(0xFFE2E8F0), height: 40),
          Center(
            child: Text(
              '© ${DateTime.now().year} $name. All rights reserved.',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    await openExternalUrl(url, context: context);
  }
}

class AutoScrollingBanner extends StatefulWidget {
  final List<HomeBanner> banners;
  const AutoScrollingBanner({super.key, required this.banners});

  @override
  State<AutoScrollingBanner> createState() => _AutoScrollingBannerState();
}

class _AutoScrollingBannerState extends State<AutoScrollingBanner> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (widget.banners.length <= 1) return;
      if (_pageController.hasClients) {
        _currentPage = (_currentPage + 1) % widget.banners.length;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (value) {
        _currentPage = value;
      },
      itemCount: widget.banners.length,
      itemBuilder: (context, index) {
        final banner = widget.banners[index];
        return InkWell(
          onTap: banner.productId != null && banner.productId!.isNotEmpty
              ? () => context.push('/product/${banner.productId}')
              : null,
          child: Container(
            color: const Color(0xFF01140E),
            child: AppNetworkImage.banner(
              imageUrl: banner.imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorWidget: const Center(
                child: Icon(Icons.broken_image, color: Colors.white30, size: 40),
              ),
            ),
          ),
        );
      },
    );
  }
}
