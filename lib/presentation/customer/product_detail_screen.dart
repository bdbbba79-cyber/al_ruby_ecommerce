import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:al_ruby_ecommerce/presentation/providers/providers.dart';
import 'package:al_ruby_ecommerce/data/models/product.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _activeImageIndex = 0;
  bool _isZoomed = false;
  String _selectedSize = '6 ML'; // Default size selector as in Screen 3

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(adminProductsProvider);
    final wishlist = ref.watch(wishlistProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
            onPressed: () => context.push('/cart'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: productsAsync.when(
        data: (products) {
          final productIndex = products.indexWhere((p) => p.id == widget.productId);
          if (productIndex < 0) {
            return const Center(child: Text('Product not found'));
          }
          final product = products[productIndex];
          final isFav = wishlist.any((p) => p.id == product.id);

          final relatedProducts = products
              .where((p) => p.category == product.category && p.id != product.id && p.status == 'active')
              .take(4)
              .toList();

          final isDesktop = MediaQuery.of(context).size.width > 800;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      isDesktop
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildGallerySection(product)),
                                const SizedBox(width: 48),
                                Expanded(child: _buildInfoSection(product, isFav)),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildGallerySection(product),
                                const SizedBox(height: 24),
                                _buildInfoSection(product, isFav),
                              ],
                            ),
                      const SizedBox(height: 32),
                      const Divider(color: Color(0xFF05372B)),
                      const SizedBox(height: 24),
                      if (relatedProducts.isNotEmpty) ...[
                        const Text(
                          'You May Also Like',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        _buildRelatedProductsGrid(relatedProducts),
                        const SizedBox(height: 32),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildGallerySection(Product product) {
    if (product.images.isEmpty) {
      return Container(
        height: 320,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 80),
        ),
      );
    }

    final imageUrl = product.images[_activeImageIndex];

    return Column(
      children: [
        GestureDetector(
          onDoubleTap: () {
            setState(() {
              _isZoomed = !_isZoomed;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 320,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF05372B)),
            ),
            clipBehavior: Clip.antiAlias,
            child: InteractiveViewer(
              panEnabled: _isZoomed,
              scaleEnabled: _isZoomed,
              minScale: 1.0,
              maxScale: 3.0,
              child: Image.network(
                imageUrl,
                fit: _isZoomed ? BoxFit.none : BoxFit.contain,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (product.images.length > 1)
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: product.images.length,
              itemBuilder: (context, index) {
                final isSelected = index == _activeImageIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _activeImageIndex = index;
                        _isZoomed = false;
                      });
                    },
                    child: Container(
                      width: 60,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? Theme.of(context).colorScheme.primary : const Color(0xFF05372B),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(product.images[index], fit: BoxFit.cover),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildInfoSection(Product product, bool isFav) {
    final user = ref.read(currentUserDetailsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              product.brand.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFFC6A473),
                letterSpacing: 1.5,
              ),
            ),
            IconButton(
              icon: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? Colors.red : Colors.white,
              ),
              onPressed: () {
                if (user == null) {
                  context.push('/login');
                } else {
                  ref.read(wishlistProvider.notifier).toggleWishlist(product);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          product.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 16),
            const SizedBox(width: 4),
            const Text(
              '4.8',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
            ),
            const SizedBox(width: 8),
            Text(
              '(256 Reviews)',
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Custom Badges (Long Lasting & Premium Quality)
        Row(
          children: [
            _buildInfoBadge(Icons.timer_outlined, 'Long Lasting'),
            const SizedBox(width: 12),
            _buildInfoBadge(Icons.workspace_premium_outlined, 'Premium Quality'),
          ],
        ),
        const SizedBox(height: 20),

        // Size Selector
        const Text('Size', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: ['3 ML', '6 ML', '12 ML'].map((size) {
            final isSelected = _selectedSize == size;
            return Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedSize = size;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
                    border: Border.all(color: const Color(0xFF05372B)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    size,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF011E16) : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),
        Text(
          '₹${product.sellingPrice.toStringAsFixed(0)}',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 20),

        // Action Buttons: Add to Cart and Buy Now
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: product.stock > 0
                    ? () {
                        ref.read(cartProvider.notifier).addItem(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${product.name} added to cart')),
                        );
                      }
                    : null,
                child: const Text('ADD TO CART'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: product.stock > 0
                    ? () {
                        ref.read(cartProvider.notifier).addItem(product);
                        context.push('/cart');
                      }
                    : null,
                child: const Text('BUY NOW'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
        const Text('Product Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        Text(
          product.description,
          style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildInfoBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF022B20),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFC6A473), size: 14),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildRelatedProductsGrid(List<Product> products) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        itemBuilder: (context, index) {
          final p = products[index];
          return Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: InkWell(
              onTap: () {
                context.pushReplacement('/product/${p.id}');
              },
              child: Container(
                width: 140,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF05372B)),
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.surface,
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: p.images.isNotEmpty
                          ? Image.network(p.images.first, fit: BoxFit.cover)
                          : Container(color: Colors.grey.shade800),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${p.sellingPrice.toStringAsFixed(0)}',
                            style: const TextStyle(color: Color(0xFFC6A473), fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
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
  }
}
