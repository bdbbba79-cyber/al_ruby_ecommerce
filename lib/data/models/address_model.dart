class AddressModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String houseStreet;
  final String city;
  final String district;
  final String state;
  final String pinCode;
  final String tag; // 'Home', 'Work', 'Other'
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.houseStreet,
    required this.city,
    required this.district,
    required this.state,
    required this.pinCode,
    this.tag = 'Home',
    this.isDefault = false,
  });

  String get formattedAddress => '$houseStreet, $city, $district, $state - $pinCode';

  factory AddressModel.fromMap(Map<String, dynamic> map) {
    return AddressModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      houseStreet: map['houseStreet'] ?? '',
      city: map['city'] ?? '',
      district: map['district'] ?? '',
      state: map['state'] ?? '',
      pinCode: map['pinCode'] ?? '',
      tag: map['tag'] ?? 'Home',
      isDefault: map['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'houseStreet': houseStreet,
      'city': city,
      'district': district,
      'state': state,
      'pinCode': pinCode,
      'tag': tag,
      'isDefault': isDefault,
    };
  }

  AddressModel copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? houseStreet,
    String? city,
    String? district,
    String? state,
    String? pinCode,
    String? tag,
    bool? isDefault,
  }) {
    return AddressModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      houseStreet: houseStreet ?? this.houseStreet,
      city: city ?? this.city,
      district: district ?? this.district,
      state: state ?? this.state,
      pinCode: pinCode ?? this.pinCode,
      tag: tag ?? this.tag,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
