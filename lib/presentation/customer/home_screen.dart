import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:al_ruby_ecommerce/presentation/providers/providers.dart';
import 'package:al_ruby_ecommerce/data/models/product.dart';
import 'package:al_ruby_ecommerce/data/models/category.dart';
import 'package:al_ruby_ecommerce/data/models/business_info.dart';
import 'package:al_ruby_ecommerce/presentation/customer/customer_layout.dart';

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
    final bannersAsync = ref.watch(bannersProvider);
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
            bannersAsync.when(
              data: (bannersList) => _buildHeroBanner(bannersList),
              loading: () => const SizedBox(height: 280, child: Center(child: CircularProgressIndicator())),
              error: (_, __) => _buildHeroBanner([]),
            ),

            const SizedBox(height: 24),

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
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              ref.read(customerTabIndexProvider.notifier).state = 1; // Swap to Products tab
                            },
                            child: const Row(
                              children: [
                                Text('View All', style: TextStyle(color: Color(0xFFC6A473))),
                                Icon(Icons.chevron_right, size: 16, color: Color(0xFFC6A473)),
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

                      // Combo Offers Banner
                      _buildComboBanner(context),

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

  // --- Mobile App Bar ---
  PreferredSizeWidget _buildMobileAppBar(BuildContext context, int cartCount) {
    return AppBar(
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
          Icon(Icons.stars, color: Theme.of(context).colorScheme.primary, size: 24),
          const SizedBox(width: 8),
          const Text(
            'AL RUBY PERFUMES',
            style: TextStyle(
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
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$cartCount',
                    style: const TextStyle(color: Color(0xFF011E16), fontSize: 10, fontWeight: FontWeight.bold),
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
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.background,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF022B20),
              border: Border(bottom: BorderSide(color: Color(0xFF05372B), width: 1.5)),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.stars, color: Theme.of(context).colorScheme.primary, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'AL RUBY PERFUMES',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined, color: Colors.white),
            title: const Text('Home', style: TextStyle(color: Colors.white)),
            onTap: () {
              context.pop();
              ref.read(customerTabIndexProvider.notifier).state = 0;
            },
          ),
          ListTile(
            leading: const Icon(Icons.grid_view_outlined, color: Colors.white),
            title: const Text('Products', style: TextStyle(color: Colors.white)),
            onTap: () {
              context.pop();
              ref.read(customerTabIndexProvider.notifier).state = 1;
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite_border, color: Colors.white),
            title: const Text('Wishlist', style: TextStyle(color: Colors.white)),
            onTap: () {
              context.pop();
              ref.read(customerTabIndexProvider.notifier).state = 2;
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined, color: Colors.white),
            title: const Text('My Orders', style: TextStyle(color: Colors.white)),
            onTap: () {
              context.pop();
              ref.read(customerTabIndexProvider.notifier).state = 3;
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline, color: Colors.white),
            title: const Text('My Account', style: TextStyle(color: Colors.white)),
            onTap: () {
              context.pop();
              ref.read(customerTabIndexProvider.notifier).state = 4;
            },
          ),
          const Divider(color: Color(0xFF05372B)),
          businessInfoAsync.when(
            data: (info) => ListTile(
              leading: const Icon(Icons.chat_bubble_outline, color: Color(0xFF25D366)),
              title: const Text('WhatsApp Support', style: TextStyle(color: Color(0xFF25D366))),
              onTap: () {
                context.pop();
                _launchURL('https://wa.me/${info.whatsappNumber}');
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
  Widget _buildHeroBanner(List<String> banners) {
    if (banners.isNotEmpty) {
      return SizedBox(
        height: 280,
        child: PageView.builder(
          itemCount: banners.length,
          itemBuilder: (context, index) {
            return Image.network(banners[index], fit: BoxFit.cover, width: double.infinity);
          },
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        gradient: const LinearGradient(
          colors: [Color(0xFF011E16), Color(0xFF05372B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Feel the\nLuxury in\nEvery Spray',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(customerTabIndexProvider.notifier).state = 1; // Swap to Products tab
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('SHOP NOW'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Premium Gold Perfume Bottle Graphic Placeholder
            Container(
              height: 160,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
              ),
              child: Icon(Icons.local_florist, color: Theme.of(context).colorScheme.primary, size: 60),
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
        hintText: 'Search perfumes...',
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
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: InkWell(
                  onTap: () {
                    // Set category filter and jump to Products view
                    // We can either set category or let the products tab load it
                    ref.read(customerTabIndexProvider.notifier).state = 1;
                  },
                  child: Column(
                    children: [
                      Container(
                        height: 70,
                        width: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Theme.of(context).colorScheme.primary, width: 1.5),
                          color: Theme.of(context).colorScheme.surface,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: ClipOval(
                          child: cat.imageUrl.isNotEmpty
                              ? Image.network(cat.imageUrl, fit: BoxFit.cover)
                              : const Icon(Icons.folder_open, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cat.name,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(height: 110),
      error: (_, __) => const SizedBox(),
    );
  }

  // --- Best Sellers Grid ---
  Widget _buildBestSellersGrid(List<Product> products) {
    // Show top 3 products
    final bestSellers = products.where((p) => p.status == 'active').take(3).toList();

    if (bestSellers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text('No products available.', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 3;
    if (screenWidth < 600) {
      crossAxisCount = 2; // Grid layout on smaller screens
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
                        Image.network(
                          product.images.first,
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
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₹${product.sellingPrice.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFC6A473)),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 12),
                              const SizedBox(width: 2),
                              Text(
                                '4.8',
                                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 10),
                              ),
                            ],
                          )
                        ],
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

  // --- Combo Banner Section ---
  Widget _buildComboBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF05372B), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'COMBO OFFERS',
            style: TextStyle(color: Color(0xFFC6A473), fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          const Text(
            'UP TO 20% OFF ON OUDH SETS',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(customerTabIndexProvider.notifier).state = 1; // Jump to products
            },
            child: const Text('SHOP NOW'),
          ),
        ],
      ),
    );
  }

  // --- Footer ---
  Widget _buildFooter(BusinessInfo? info) {
    final name = info?.companyName ?? 'Al Ruby Perfumes';
    final address = info?.address ?? 'Erumathadam Malappuram - 679338';
    final email = info?.email ?? 'info@alrubyperfumes.com';
    final mobile = info?.mobileNumber ?? '9400859846';

    return Container(
      color: const Color(0xFF01140E),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(address, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text('Phone: $mobile', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text('Email: $email', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const Divider(color: Color(0xFF05372B), height: 40),
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
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
