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

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(adminProductsProvider); // allows viewing disabled ones if loaded by id
    final wishlist = ref.watch(wishlistProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined),
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

          // Get related products from the same category
          final relatedProducts = products
              .where((p) => p.category == product.category && p.id != product.id && p.status == 'active')
              .take(4)
              .toList();

          final isDesktop = MediaQuery.of(context).size.width > 800;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main Split Section (Image Gallery + Info)
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
                      
                      const SizedBox(height: 48),
                      const Divider(color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 32),

                      // Related Products Section
                      if (relatedProducts.isNotEmpty) ...[
                        const Text(
                          'You May Also Like',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 16),
                        _buildRelatedProductsGrid(relatedProducts),
                        const SizedBox(height: 48),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading product details: $err')),
      ),
    );
  }

  // --- Gallery ---
  Widget _buildGallerySection(Product product) {
    if (product.images.isEmpty) {
      return Container(
        height: 400,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined, color: Color(0xFF94A3B8), size: 80),
        ),
      );
    }

    final imageUrl = product.images[_activeImageIndex];

    return Column(
      children: [
        // Large Image Display
        GestureDetector(
          onDoubleTap: () {
            setState(() {
              _isZoomed = !_isZoomed;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 400,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
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
        // Double tap tip
        const Text(
          'Double tap / pinch to zoom',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
        ),
        const SizedBox(height: 16),
        // Miniatures List
        if (product.images.length > 1)
          SizedBox(
            height: 70,
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
                      width: 70,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? const Color(0xFF0F62FE) : const Color(0xFFE2E8F0),
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

  // --- Info Section ---
  Widget _buildInfoSection(Product product, bool isFav) {
    final discountAmount = product.mrp - product.sellingPrice;
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
                color: Color(0xFF64748B),
                letterSpacing: 1.5,
              ),
            ),
            // Wishlist Toggle
            IconButton(
              icon: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? Colors.red : const Color(0xFF64748B),
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
        const SizedBox(height: 8),
        Text(
          product.name,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'SKU: ${product.sku}',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
            const Icon(Icons.circle, size: 6, color: Color(0xFF94A3B8)),
            Text(
              'Category: ${product.category}',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '₹${product.sellingPrice.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F62FE)),
            ),
            if (product.mrp > product.sellingPrice) ...[
              Text(
                '₹${product.mrp.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFF94A3B8),
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                child: Text(
                  'Save ₹${discountAmount.toStringAsFixed(0)} (${product.discount.toStringAsFixed(0)}%)',
                  style: TextStyle(color: Colors.red.shade800, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        // Stock status
        Row(
          children: [
            Container(
              height: 10,
              width: 10,
              decoration: BoxDecoration(
                color: product.stock > 0 ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              product.stock > 0 ? 'In Stock (${product.stock} units available)' : 'Out of Stock',
              style: TextStyle(
                color: product.stock > 0 ? Colors.green.shade800 : Colors.red.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        // Action Buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
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
                icon: const Icon(Icons.shopping_bag_outlined),
                label: const Text('ADD TO CART'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F62FE),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        // Description
        const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        const SizedBox(height: 8),
        Text(
          product.description,
          style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.5),
        ),
        const SizedBox(height: 24),
        // Specifications
        if (product.specifications.isNotEmpty) ...[
          const Text('Specifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 12),
          Table(
            border: TableBorder.all(color: const Color(0xFFE2E8F0), width: 1, borderRadius: BorderRadius.circular(4)),
            columnWidths: const {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(2),
            },
            children: product.specifications.entries.map((spec) {
              return TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      spec.key,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      spec.value,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // --- Related Products ---
  Widget _buildRelatedProductsGrid(List<Product> products) {
    return SizedBox(
      height: 260,
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
                width: 160,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: p.images.isNotEmpty
                          ? Image.network(p.images.first, fit: BoxFit.cover)
                          : Container(color: const Color(0xFFF1F5F9)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${p.sellingPrice.toStringAsFixed(0)}',
                            style: const TextStyle(color: Color(0xFF0F62FE), fontWeight: FontWeight.bold, fontSize: 13),
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
