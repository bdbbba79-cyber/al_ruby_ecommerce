class Category {
  final String id;
  final String name;
  final String imageUrl;
  final String description;

  Category({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
  });

  factory Category.fromMap(String id, Map<String, dynamic> map) {
    final rawUrl = map['imageUrl'] ??
        map['image'] ??
        map['photo'] ??
        map['photoUrl'] ??
        map['image_url'] ??
        map['icon'] ??
        map['url'] ??
        '';
    return Category(
      id: id,
      name: (map['name'] ?? '').toString(),
      imageUrl: rawUrl.toString().trim(),
      description: (map['description'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'description': description,
    };
  }

  Category copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? description,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
    );
  }
}
