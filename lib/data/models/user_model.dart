class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'admin' or 'customer'
  final List<String> wishlist;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.wishlist,
  });

  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'customer',
      wishlist: List<String>.from(map['wishlist'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'wishlist': wishlist,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    List<String>? wishlist,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      wishlist: wishlist ?? this.wishlist,
    );
  }
}
