import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:al_ruby_ecommerce/presentation/providers/providers.dart';
import 'package:al_ruby_ecommerce/data/models/product.dart';
import 'package:al_ruby_ecommerce/data/models/category.dart';
import 'package:al_ruby_ecommerce/data/models/business_info.dart';


class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _searchQuery = '';
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedCategory = null;
      _searchController.clear();
    });
  }

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
    final productsAsync = ref.watch(productsProvider(_selectedCategory));
    final cart = ref.watch(cartProvider);
    final userDetails = ref.watch(currentUserDetailsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context, userDetails, cart.length),
      drawer: _buildDrawer(context, userDetails),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner Slider / Hero Card
            bannersAsync.when(
              data: (bannersList) => _buildHeroSection(bannersList),
              loading: () => const SizedBox(height: 300, child: Center(child: CircularProgressIndicator())),
              error: (_, __) => _buildHeroSection([]),
            ),

            const SizedBox(height: 32),

            // Main Content Area (Responsive Grid)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search and Filter Bar
                      _buildSearchAndFilters(categoriesAsync),
                      
                      const SizedBox(height: 24),
                      
                      // Categories Section
                      _buildCategoriesSection(categoriesAsync),

                      const SizedBox(height: 40),

                      // Products Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedCategory == null ? 'Featured Perfumes' : 'Perfumes in Category',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty || _selectedCategory != null)
                            TextButton.icon(
                              onPressed: _clearFilters,
                              icon: const Icon(Icons.clear_all, size: 18),
                              label: const Text('Clear Filters'),
                              style: TextButton.styleFrom(foregroundColor: const Color(0xFF0F62FE)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      productsAsync.when(
                        data: (productsList) => _buildProductsGrid(productsList),
                        loading: () => const Center(child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: CircularProgressIndicator(),
                        )),
                        error: (err, _) => Center(child: Text('Failed to load products: $err')),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 80),

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

  // --- AppBar ---
  PreferredSizeWidget _buildAppBar(BuildContext context, userDetails, int cartCount) {
    final businessInfoAsync = ref.watch(businessInfoProvider);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return AppBar(
      title: businessInfoAsync.when(
        data: (info) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (info.companyLogoUrl.isNotEmpty) ...[
              Image.network(info.companyLogoUrl, height: 40, fit: BoxFit.contain),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                info.companyName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isDesktop ? 20 : 18,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        loading: () => Text(
          'Al Ruby Perfumes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isDesktop ? 20 : 18,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        error: (_, __) => Text(
          'Al Ruby Perfumes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isDesktop ? 20 : 18,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
      actions: [
        if (isDesktop) ...[
          TextButton(onPressed: () => context.go('/home'), child: const Text('Home')),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedCategory = null;
              });
            },
            child: const Text('Shop'),
          ),
          if (userDetails?.role == 'admin')
            TextButton.icon(
              onPressed: () => context.go('/admin'),
              icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
              label: const Text('Admin Panel'),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF0F62FE)),
            ),
        ],
        IconButton(
          icon: const Icon(Icons.favorite_border_outlined),
          onPressed: () {
            if (userDetails == null) {
              context.push('/login');
            } else {
              context.push('/profile');
            }
          },
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_bag_outlined),
              onPressed: () => context.push('/cart'),
            ),
            if (cartCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F62FE),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$cartCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        IconButton(
          icon: Icon(userDetails != null ? Icons.person_outline : Icons.login),
          onPressed: () {
            if (userDetails != null) {
              context.push('/profile');
            } else {
              context.push('/login');
            }
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // --- Drawer for Mobile ---
  Widget _buildDrawer(BuildContext context, userDetails) {
    final businessInfoAsync = ref.watch(businessInfoProvider);

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
            child: businessInfoAsync.when(
              data: (info) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (info.companyLogoUrl.isNotEmpty)
                    Image.network(info.companyLogoUrl, height: 60, fit: BoxFit.contain)
                  else
                    const Text('AR', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F62FE)), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text(info.companyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Al Ruby Perfumes'),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Home'),
            onTap: () {
              context.pop();
              context.go('/home');
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag_outlined),
            title: const Text('Cart'),
            onTap: () {
              context.pop();
              context.push('/cart');
            },
          ),
          if (userDetails != null)
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('My Orders'),
              onTap: () {
                context.pop();
                context.push('/profile');
              },
            ),
          if (userDetails?.role == 'admin')
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined, color: Color(0xFF0F62FE)),
              title: const Text('Admin Panel', style: TextStyle(color: Color(0xFF0F62FE), fontWeight: FontWeight.bold)),
              onTap: () {
                context.pop();
                context.go('/admin');
              },
            ),
          const Spacer(),
          businessInfoAsync.when(
            data: (info) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _launchURL('https://wa.me/${info.whatsappNumber}'),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('WhatsApp Support'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white, minimumSize: const Size.fromHeight(50)),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _launchURL('tel:${info.mobileNumber}'),
                    icon: const Icon(Icons.call),
                    label: const Text('Call Us'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
    );
  }

  // --- Hero Section (Banners / Fallback Combo Offer) ---
  Widget _buildHeroSection(List<String> banners) {
    if (banners.isNotEmpty) {
      // Return a horizontal scrollable view of uploaded banners
      return SizedBox(
        height: 350,
        child: PageView.builder(
          itemCount: banners.length,
          itemBuilder: (context, index) {
            return Image.network(banners[index], fit: BoxFit.cover, width: double.infinity);
          },
        ),
      );
    }

    // Default premium interactive fallback "Combo Offer" card modeled from the provided reference image
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade700,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'COMBO OFFER',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Al Nuaim Premium Attar\n5 Bottle Combo Set',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Includes Chocolate Musk, Blue Wave, Black Orchid, Musk Rizali, and White Oudh. 0% Alcohol, long lasting premium perfume blends.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          '₹499',
                          style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '₹800',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 20,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.green.shade600, borderRadius: BorderRadius.circular(4)),
                          child: const Text('37% OFF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_shipping_outlined, color: Colors.amber, size: 20),
                            const SizedBox(width: 8),
                            const Text('All Kerala Delivery Available', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.monetization_on_outlined, color: Colors.green.shade400, size: 20),
                            const SizedBox(width: 8),
                            const Text('Cash On Delivery', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 40),
              // Right side represents the mockup image of product set (only visible on large screens)
              if (MediaQuery.of(context).size.width > 800)
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    alignment: Alignment.center,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.filter_vintage_outlined, color: Colors.amber, size: 60),
                        SizedBox(height: 16),
                        Text(
                          'Al Ruby Perfumes Collection',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Text(
                          'Pure oils & premium spray scents',
                          style: TextStyle(color: Colors.grey),
                        )
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Search & Filters ---
  Widget _buildSearchAndFilters(AsyncValue<List<Category>> categoriesAsync) {
    return Card(
      elevation: 0,
      color: const Color(0xFFF8FAFC),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search for perfumes, oils, stone collections...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                  fillColor: Colors.white,
                  filled: true,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim().toLowerCase();
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Categories Section ---
  Widget _buildCategoriesSection(AsyncValue<List<Category>> categoriesAsync) {
    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) return const SizedBox();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            const Text(
              'Browse Categories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = _selectedCategory == cat.name;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedCategory = isSelected ? null : cat.name;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 120,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF0F62FE).withOpacity(0.1) : const Color(0xFFF8FAFC),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF0F62FE) : const Color(0xFFE2E8F0),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (cat.imageUrl.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(cat.imageUrl, height: 40, width: 40, fit: BoxFit.cover),
                              )
                            else
                              const Icon(Icons.folder_open_outlined, color: Color(0xFF64748B)),
                            const SizedBox(height: 8),
                            Text(
                              cat.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? const Color(0xFF0F62FE) : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  // --- Products Grid ---
  Widget _buildProductsGrid(List<Product> products) {
    final filtered = products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery) ||
          p.sku.toLowerCase().contains(_searchQuery) ||
          p.brand.toLowerCase().contains(_searchQuery) ||
          p.description.toLowerCase().contains(_searchQuery);
      return matchesSearch;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60.0),
          child: Column(
            children: [
              const Icon(Icons.sentiment_dissatisfied_outlined, size: 60, color: Color(0xFF94A3B8)),
              const SizedBox(height: 16),
              const Text('No Perfumes Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Try adjusting your search query or filters.', style: TextStyle(color: Color(0xFF64748B))),
              if (_searchQuery.isNotEmpty || _selectedCategory != null) ...[
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _clearFilters, child: const Text('Reset All Filters')),
              ]
            ],
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 2;
    if (screenWidth > 1200) {
      crossAxisCount = 4;
    } else if (screenWidth > 800) {
      crossAxisCount = 3;
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
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final product = filtered[index];
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
                      // Product Image
                      if (product.images.isNotEmpty)
                        Image.network(
                          product.images.first,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        )
                      else
                        Container(
                          color: const Color(0xFFF1F5F9),
                          child: const Center(
                            child: Icon(Icons.image_not_supported_outlined, color: Color(0xFF94A3B8), size: 40),
                          ),
                        ),
                      // Discount Badge
                      if (product.discount > 0)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.red.shade600, borderRadius: BorderRadius.circular(4)),
                            child: Text(
                              '${product.discount.toStringAsFixed(0)}% OFF',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      // Wishlist Button
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          elevation: 2,
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
                              padding: const EdgeInsets.all(6.0),
                              child: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav ? Colors.red : const Color(0xFF64748B),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Out of Stock Overlay
                      if (product.stock <= 0)
                        Container(
                          color: Colors.black.withOpacity(0.6),
                          child: const Center(
                            child: Text(
                              'OUT OF STOCK',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.brand,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.name,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '₹${product.sellingPrice.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F62FE)),
                          ),
                          if (product.mrp > product.sellingPrice)
                            Text(
                              '₹${product.mrp.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF94A3B8),
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: product.stock > 0
                              ? () {
                                  ref.read(cartProvider.notifier).addItem(product);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${product.name} added to cart'),
                                      action: SnackBarAction(
                                        label: 'View Cart',
                                        onPressed: () => context.push('/cart'),
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            side: const BorderSide(color: Color(0xFF0F62FE)),
                          ),
                          child: const Text('Add to Cart', style: TextStyle(fontSize: 13)),
                        ),
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

  // --- Footer ---
  Widget _buildFooter(BusinessInfo? info) {
    final name = info?.companyName ?? 'Al Ruby Perfumes';
    final address = info?.address ?? 'Erumathadam Malappuram - 679338';
    final email = info?.email ?? 'info@alrubyperfumes.com';
    final mobile = info?.mobileNumber ?? '9400859846';

    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                address,
                                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                              ),
                              const SizedBox(height: 12),
                              Text('Phone: $mobile', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
                              Text('Email: $email', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 40),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Quick Links', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              _buildFooterLink('Privacy Policy', () => _showPolicyDialog('Privacy Policy', info?.privacyPolicy)),
                              _buildFooterLink('Refund Policy', () => _showPolicyDialog('Refund Policy', info?.refundPolicy)),
                              _buildFooterLink('Shipping Policy', () => _showPolicyDialog('Shipping Policy', info?.shippingPolicy)),
                              _buildFooterLink('Terms & Conditions', () => _showPolicyDialog('Terms & Conditions', info?.termsAndConditions)),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          address,
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        Text('Phone: $mobile', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
                        Text('Email: $email', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
                        const SizedBox(height: 32),
                        const Text('Quick Links', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _buildFooterLink('Privacy Policy', () => _showPolicyDialog('Privacy Policy', info?.privacyPolicy)),
                        _buildFooterLink('Refund Policy', () => _showPolicyDialog('Refund Policy', info?.refundPolicy)),
                        _buildFooterLink('Shipping Policy', () => _showPolicyDialog('Shipping Policy', info?.shippingPolicy)),
                        _buildFooterLink('Terms & Conditions', () => _showPolicyDialog('Terms & Conditions', info?.termsAndConditions)),
                      ],
                    ),
              const Divider(color: Color(0xFF334155), height: 60),
              isDesktop
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('© ${DateTime.now().year} $name. All rights reserved.', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                        Row(
                          children: [
                            if (info?.facebookLink.isNotEmpty ?? false)
                              IconButton(
                                icon: const Icon(Icons.facebook, color: Color(0xFF94A3B8)),
                                onPressed: () => _launchURL(info!.facebookLink),
                              ),
                            if (info?.instagramLink.isNotEmpty ?? false)
                              IconButton(
                                icon: const Icon(Icons.camera_alt, color: Color(0xFF94A3B8)),
                                onPressed: () => _launchURL(info!.instagramLink),
                              ),
                          ],
                        )
                      ],
                    )
                  : Column(
                      children: [
                        Text('© ${DateTime.now().year} $name. All rights reserved.', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13), textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (info?.facebookLink.isNotEmpty ?? false)
                              IconButton(
                                icon: const Icon(Icons.facebook, color: Color(0xFF94A3B8)),
                                onPressed: () => _launchURL(info!.facebookLink),
                              ),
                            if (info?.instagramLink.isNotEmpty ?? false)
                              IconButton(
                                icon: const Icon(Icons.camera_alt, color: Color(0xFF94A3B8)),
                                onPressed: () => _launchURL(info!.instagramLink),
                              ),
                          ],
                        )
                      ],
                    )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterLink(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: InkWell(
        onTap: onTap,
        child: Text(
          label,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        ),
      ),
    );
  }

  void _showPolicyDialog(String title, String? content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(
            (content == null || content.isEmpty)
                ? 'Policy details will be uploaded by the administrator soon.'
                : content,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
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
