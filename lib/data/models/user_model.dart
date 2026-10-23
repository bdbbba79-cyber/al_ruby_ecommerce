import 'package:al_ruby_ecommerce/data/models/address_model.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'admin' or 'customer'
  final List<String> wishlist;
  final List<Map<String, dynamic>> cart;
  
  // Marketing & Commission details
  final String phoneNumber;
  final String upiId;
  final double totalEarned;
  final double totalPaid;
  final String referralCode;
  final bool withdrawalRequested;
  final double withdrawalRequestedAmount;
 
  // Saved Address Details (Legacy single address)
  final String savedHouseStreet;
  final String savedCity;
  final String savedDistrict;
  final String savedState;
  final String savedPinCode;

  // Multiple Saved Addresses
  final List<AddressModel> addresses;
 
  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.wishlist,
    this.cart = const [],
    this.phoneNumber = '',
    this.upiId = '',
    this.totalEarned = 0.0,
    this.totalPaid = 0.0,
    this.referralCode = '',
    this.withdrawalRequested = false,
    this.withdrawalRequestedAmount = 0.0,
    this.savedHouseStreet = '',
    this.savedCity = '',
    this.savedDistrict = '',
    this.savedState = '',
    this.savedPinCode = '',
    this.addresses = const [],
  });

  List<AddressModel> get allAddresses {
    if (addresses.isNotEmpty) return addresses;
    if (savedHouseStreet.isNotEmpty) {
      return [
        AddressModel(
          id: 'default',
          name: name,
          phoneNumber: phoneNumber,
          houseStreet: savedHouseStreet,
          city: savedCity,
          district: savedDistrict,
          state: savedState,
          pinCode: savedPinCode,
          tag: 'Home',
          isDefault: true,
        ),
      ];
    }
    return [];
  }
 
  double get walletBalance => totalEarned - totalPaid;
 
  static String generateReferralCode(String name, String uid) {
    final cleanName = name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    final prefix = cleanName.length > 4 ? cleanName.substring(0, 4) : (cleanName.isEmpty ? 'USER' : cleanName);
    final suffix = uid.length > 4 ? uid.substring(uid.length - 4) : uid;
    return '$prefix$suffix'.toUpperCase();
  }
 
  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    final name = map['name'] ?? '';
    final refCode = map['referralCode'] ?? generateReferralCode(name, id);
    return UserModel(
      id: id,
      name: name,
      email: map['email'] ?? '',
      role: map['role'] ?? 'customer',
      wishlist: List<String>.from(map['wishlist'] ?? []),
      cart: List<Map<String, dynamic>>.from(
        (map['cart'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? []
      ),
      phoneNumber: map['phoneNumber'] ?? '',
      upiId: map['upiId'] ?? '',
      totalEarned: (map['totalEarned'] as num?)?.toDouble() ?? 0.0,
      totalPaid: (map['totalPaid'] as num?)?.toDouble() ?? 0.0,
      referralCode: refCode,
      withdrawalRequested: map['withdrawalRequested'] ?? false,
      withdrawalRequestedAmount: (map['withdrawalRequestedAmount'] as num?)?.toDouble() ?? 0.0,
      savedHouseStreet: map['savedHouseStreet'] ?? '',
      savedCity: map['savedCity'] ?? '',
      savedDistrict: map['savedDistrict'] ?? '',
      savedState: map['savedState'] ?? '',
      savedPinCode: map['savedPinCode'] ?? '',
      addresses: (map['addresses'] as List?)
          ?.map((a) => AddressModel.fromMap(Map<String, dynamic>.from(a)))
          .toList() ?? [],
    );
  }
 
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'wishlist': wishlist,
      'cart': cart,
      'phoneNumber': phoneNumber,
      'upiId': upiId,
      'totalEarned': totalEarned,
      'totalPaid': totalPaid,
      'referralCode': referralCode,
      'withdrawalRequested': withdrawalRequested,
      'withdrawalRequestedAmount': withdrawalRequestedAmount,
      'savedHouseStreet': savedHouseStreet,
      'savedCity': savedCity,
      'savedDistrict': savedDistrict,
      'savedState': savedState,
      'savedPinCode': savedPinCode,
      'addresses': addresses.map((a) => a.toMap()).toList(),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    List<String>? wishlist,
    List<Map<String, dynamic>>? cart,
    String? phoneNumber,
    String? upiId,
    double? totalEarned,
    double? totalPaid,
    String? referralCode,
    bool? withdrawalRequested,
    double? withdrawalRequestedAmount,
    String? savedHouseStreet,
    String? savedCity,
    String? savedDistrict,
    String? savedState,
    String? savedPinCode,
    List<AddressModel>? addresses,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      wishlist: wishlist ?? this.wishlist,
      cart: cart ?? this.cart,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      upiId: upiId ?? this.upiId,
      totalEarned: totalEarned ?? this.totalEarned,
      totalPaid: totalPaid ?? this.totalPaid,
      referralCode: referralCode ?? this.referralCode,
      withdrawalRequested: withdrawalRequested ?? this.withdrawalRequested,
      withdrawalRequestedAmount: withdrawalRequestedAmount ?? this.withdrawalRequestedAmount,
      savedHouseStreet: savedHouseStreet ?? this.savedHouseStreet,
      savedCity: savedCity ?? this.savedCity,
      savedDistrict: savedDistrict ?? this.savedDistrict,
      savedState: savedState ?? this.savedState,
      savedPinCode: savedPinCode ?? this.savedPinCode,
      addresses: addresses ?? this.addresses,
    );
  }
}
