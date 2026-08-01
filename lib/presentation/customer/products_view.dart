import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:al_ruby_ecommerce/presentation/providers/providers.dart';
import 'package:al_ruby_ecommerce/data/models/product.dart';
import 'package:al_ruby_ecommerce/data/models/category.dart';

class ProductsView extends ConsumerStatefulWidget {
  const ProductsView({super.key});

  @override
  ConsumerState<ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends ConsumerState<ProductsView> {
  String _searchQuery = '';
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final productsAsync = ref.watch(productsProvider(_selectedCategory));
    final wishlist = ref.watch(wishlistProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ALL PRODUCTS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search perfumes...',
                prefixIcon: const Icon(Icons.search),
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
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
            ),
          ),

          // Categories Chips
          categoriesAsync.when(
            data: (categories) => _buildCategoryChips(categories),
            loading: () => const SizedBox(height: 50),
            error: (_, __) => const SizedBox(),
          ),

          const SizedBox(height: 8),

          // Products Grid
          Expanded(
            child: productsAsync.when(
              data: (productsList) => _buildProductsGrid(productsList, wishlist),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(List<Category> categories) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          FilterChip(
            label: const Text('All'),
            selected: _selectedCategory == null,
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _selectedCategory = null;
                });
              }
            },
            selectedColor: Theme.of(context).colorScheme.primary,
            labelStyle: TextStyle(
              color: _selectedCategory == null
                  ? Theme.of(context).colorScheme.onPrimary
                  : Colors.white,
              fontWeight: FontWeight.bold,
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          const SizedBox(width: 8),
          ...categories.map((cat) {
            final isSelected = _selectedCategory == cat.name;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                label: Text(cat.name),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = selected ? cat.name : null;
                  });
                },
                selectedColor: Theme.of(context).colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                backgroundColor: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProductsGrid(List<Product> products, List<Product> wishlist) {
    final filtered = products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery) ||
          p.brand.toLowerCase().contains(_searchQuery) ||
          p.description.toLowerCase().contains(_searchQuery);
      return matchesSearch;
    }).toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No products match your search or filter.', style: TextStyle(color: Colors.grey)),
          ],
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
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final product = filtered[index];
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
                          color: Theme.of(context).colorScheme.surface,
                          child: const Center(
                            child: Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 40),
                          ),
                        ),
                      // Wishlist Button
                      Positioned(
                        top: 8,
                        right: 8,
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
                              padding: const EdgeInsets.all(6.0),
                              child: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav ? Colors.red : Colors.white,
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
                        product.brand.toUpperCase(),
                        style: const TextStyle(fontSize: 10, color: Color(0xFFC6A473), fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.name,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '₹${product.sellingPrice.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              if (product.mrp > product.sellingPrice)
                                Text(
                                  '₹${product.mrp.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                            ],
                          ),
                          // Mini Add to Cart Button
                          if (product.stock > 0)
                            IconButton(
                              icon: Icon(Icons.add_shopping_cart, color: Theme.of(context).colorScheme.primary, size: 20),
                              onPressed: () {
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
                              },
                            ),
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
}
