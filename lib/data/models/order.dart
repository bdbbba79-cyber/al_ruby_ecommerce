import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pending,
  paymentVerificationPending,
  confirmed,
  processing,
  packed,
  shipped,
  outForDelivery,
  delivered,
  cancelled,
  refunded;

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.paymentVerificationPending:
        return 'Payment Verification Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.packed:
        return 'Packed';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.refunded:
        return 'Refunded';
    }
  }

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == value || e.displayName == value,
      orElse: () => OrderStatus.pending,
    );
  }
}

class ShippingAddress {
  final String houseStreet;
  final String city;
  final String district;
  final String state;
  final String pinCode;

  ShippingAddress({
    required this.houseStreet,
    required this.city,
    required this.district,
    required this.state,
    required this.pinCode,
  });

  factory ShippingAddress.fromMap(Map<String, dynamic> map) {
    return ShippingAddress(
      houseStreet: map['houseStreet'] ?? '',
      city: map['city'] ?? '',
      district: map['district'] ?? '',
      state: map['state'] ?? '',
      pinCode: map['pinCode'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'houseStreet': houseStreet,
      'city': city,
      'district': district,
      'state': state,
      'pinCode': pinCode,
    };
  }

  String get fullAddress => '$houseStreet, $city, $district, $state - $pinCode';
}

class OrderItem {
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final String imageUrl;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.imageUrl,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: map['quantity'] ?? 1,
      imageUrl: map['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
    };
  }
}

class OrderModel {
  final String id;
  final String userId;
  final String customerName;
  final String customerMobile;
  final String? customerEmail;
  final ShippingAddress shippingAddress;
  final List<OrderItem> items;
  final double subtotal;
  final double shippingCharge;
  final double grandTotal;
  final String paymentMethod; // 'UPI' or 'COD'
  final String paymentStatus; // 'Pending', 'Verification Pending', 'Paid'
  final String? transactionId; // UTR Number entered by customer
  final OrderStatus orderStatus;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.customerMobile,
    this.customerEmail,
    required this.shippingAddress,
    required this.items,
    required this.subtotal,
    required this.shippingCharge,
    required this.grandTotal,
    required this.paymentMethod,
    required this.paymentStatus,
    this.transactionId,
    required this.orderStatus,
    required this.createdAt,
  });

  factory OrderModel.fromMap(String id, Map<String, dynamic> map) {
    return OrderModel(
      id: id,
      userId: map['userId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerMobile: map['customerMobile'] ?? '',
      customerEmail: map['customerEmail'],
      shippingAddress: ShippingAddress.fromMap(map['shippingAddress'] ?? {}),
      items: (map['items'] as List?)?.map((item) => OrderItem.fromMap(item)).toList() ?? [],
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      shippingCharge: (map['shippingCharge'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (map['grandTotal'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod'] ?? 'COD',
      paymentStatus: map['paymentStatus'] ?? 'Pending',
      transactionId: map['transactionId'],
      orderStatus: OrderStatus.fromString(map['orderStatus'] ?? 'pending'),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'customerName': customerName,
      'customerMobile': customerMobile,
      'customerEmail': customerEmail,
      'shippingAddress': shippingAddress.toMap(),
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'shippingCharge': shippingCharge,
      'grandTotal': grandTotal,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'transactionId': transactionId,
      'orderStatus': orderStatus.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  OrderModel copyWith({
    String? id,
    String? userId,
    String? customerName,
    String? customerMobile,
    String? customerEmail,
    ShippingAddress? shippingAddress,
    List<OrderItem>? items,
    double? subtotal,
    double? shippingCharge,
    double? grandTotal,
    String? paymentMethod,
    String? paymentStatus,
    String? transactionId,
    OrderStatus? orderStatus,
    DateTime? createdAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      customerName: customerName ?? this.customerName,
      customerMobile: customerMobile ?? this.customerMobile,
      customerEmail: customerEmail ?? this.customerEmail,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      shippingCharge: shippingCharge ?? this.shippingCharge,
      grandTotal: grandTotal ?? this.grandTotal,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      transactionId: transactionId ?? this.transactionId,
      orderStatus: orderStatus ?? this.orderStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
