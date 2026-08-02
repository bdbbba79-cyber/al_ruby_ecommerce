class ProductVariant {
  final String size; // e.g. "50 ml", "100 ml", "10 Inches", "2 L"
  final double mrp;
  final double sellingPrice;
  final int stock;

  ProductVariant({
    required this.size,
    required this.mrp,
    required this.sellingPrice,
    required this.stock,
  });

  factory ProductVariant.fromMap(Map<String, dynamic> map) {
    return ProductVariant(
      size: map['size'] ?? '',
      mrp: (map['mrp'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (map['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      stock: map['stock'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'size': size,
      'mrp': mrp,
      'sellingPrice': sellingPrice,
      'stock': stock,
    };
  }
}

class Product {
  final String id;
  final String name;
  final String sku;
  final String category;
  final String brand;
  final String description;
  final double mrp;
  final double sellingPrice;
  final double discount; // discount percentage or flat amount
  final int stock;
  final List<String> images;
  final Map<String, String> specifications;
  final String status; // 'active' or 'inactive'
  final List<ProductVariant> variants;
  final double shippingFee;

  Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.brand,
    required this.description,
    required this.mrp,
    required this.sellingPrice,
    required this.discount,
    required this.stock,
    required this.images,
    required this.specifications,
    required this.status,
    this.variants = const [],
    this.shippingFee = 0.0,
  });

  factory Product.fromMap(String id, Map<String, dynamic> map) {
    return Product(
      id: id,
      name: map['name'] ?? '',
      sku: map['sku'] ?? '',
      category: map['category'] ?? '',
      brand: map['brand'] ?? '',
      description: map['description'] ?? '',
      mrp: (map['mrp'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (map['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      stock: map['stock'] ?? 0,
      images: List<String>.from(map['images'] ?? []),
      specifications: Map<String, String>.from(map['specifications'] ?? {}),
      status: map['status'] ?? 'active',
      variants: (map['variants'] as List?)
              ?.map((v) => ProductVariant.fromMap(Map<String, dynamic>.from(v)))
              .toList() ??
          [],
      shippingFee: (map['shippingFee'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'sku': sku,
      'category': category,
      'brand': brand,
      'description': description,
      'mrp': mrp,
      'sellingPrice': sellingPrice,
      'discount': discount,
      'stock': stock,
      'images': images,
      'specifications': specifications,
      'status': status,
      'variants': variants.map((v) => v.toMap()).toList(),
      'shippingFee': shippingFee,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? sku,
    String? category,
    String? brand,
    String? description,
    double? mrp,
    double? sellingPrice,
    double? discount,
    int? stock,
    List<String>? images,
    Map<String, String>? specifications,
    String? status,
    List<ProductVariant>? variants,
    double? shippingFee,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      description: description ?? this.description,
      mrp: mrp ?? this.mrp,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      discount: discount ?? this.discount,
      stock: stock ?? this.stock,
      images: images ?? this.images,
      specifications: specifications ?? this.specifications,
      status: status ?? this.status,
      variants: variants ?? this.variants,
      shippingFee: shippingFee ?? this.shippingFee,
    );
  }
}
