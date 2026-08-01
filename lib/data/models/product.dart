class Product {
  final String id;
  final String name;
  final String sku;
  final String category;
  final String brand;
  final String description;
  final double mrp;
  final double sellingPrice;
  final double discount; // discount percentage or flat amount, let's store it as double value
  final int stock;
  final List<String> images;
  final Map<String, String> specifications;
  final String status; // 'active' or 'inactive'

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
    );
  }
}
