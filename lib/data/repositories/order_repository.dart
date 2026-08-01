import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:al_ruby_ecommerce/data/models/order.dart';

class OrderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<OrderModel>> watchUserOrders(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
      // Firestore sort in memory if index not yet built
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<OrderModel>> watchAllOrders() {
    return _firestore
        .collection('orders')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<String> placeOrder(OrderModel order) async {
    // Generate unique order ID if empty
    final ref = _firestore.collection('orders').doc();
    final newOrder = order.copyWith(id: ref.id);
    await ref.set(newOrder.toMap());
    
    // Update inventory stock levels
    for (final item in order.items) {
      final productRef = _firestore.collection('products').doc(item.productId);
      _firestore.runTransaction((transaction) async {
        final productDoc = await transaction.get(productRef);
        if (productDoc.exists) {
          final currentStock = productDoc.data()?['stock'] ?? 0;
          final newStock = (currentStock - item.quantity).clamp(0, 999999);
          transaction.update(productRef, {'stock': newStock});
        }
      });
    }

    return ref.id;
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _firestore.collection('orders').doc(orderId).update({
      'orderStatus': status.name,
    });
  }

  Future<void> updatePaymentStatus(String orderId, String paymentStatus) async {
    await _firestore.collection('orders').doc(orderId).update({
      'paymentStatus': paymentStatus,
    });
  }
}
