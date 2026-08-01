import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:al_ruby_ecommerce/data/models/product.dart';
import 'package:al_ruby_ecommerce/data/models/category.dart';

class StoreRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- Image Upload ---
  Future<String> uploadImage(Uint8List imageBytes, String path) async {
    final ref = _storage.ref().child(path);
    final uploadTask = ref.putData(
      imageBytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> deleteImage(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      // Ignore or log error if image is already deleted
    }
  }

  // --- Categories ---
  Stream<List<Category>> watchCategories() {
    return _firestore.collection('categories').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Category.fromMap(doc.id, doc.data())).toList();
    });
  }

  Future<List<Category>> getCategories() async {
    final snapshot = await _firestore.collection('categories').get();
    return snapshot.docs.map((doc) => Category.fromMap(doc.id, doc.data())).toList();
  }

  Future<void> addCategory(Category category) async {
    await _firestore.collection('categories').add(category.toMap());
  }

  Future<void> editCategory(Category category) async {
    await _firestore.collection('categories').doc(category.id).update(category.toMap());
  }

  Future<void> deleteCategory(String id) async {
    await _firestore.collection('categories').doc(id).delete();
  }

  // --- Products ---
  Stream<List<Product>> watchProducts({String? category, bool activeOnly = true}) {
    Query query = _firestore.collection('products');
    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }
    if (activeOnly) {
      query = query.where('status', isEqualTo: 'active');
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
    });
  }

  Future<List<Product>> getProducts({String? category, bool activeOnly = true}) async {
    Query query = _firestore.collection('products');
    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }
    if (activeOnly) {
      query = query.where('status', isEqualTo: 'active');
    }
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Product.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
  }

  Future<void> addProduct(Product product) async {
    await _firestore.collection('products').add(product.toMap());
  }

  Future<void> editProduct(Product product) async {
    await _firestore.collection('products').doc(product.id).update(product.toMap());
  }

  Future<void> deleteProduct(String id) async {
    await _firestore.collection('products').doc(id).delete();
  }

  // --- Banners ---
  Stream<List<String>> watchBanners() {
    return _firestore
        .collection('banners')
        .where('active', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()['imageUrl'] as String).toList();
    });
  }

  Future<List<Map<String, dynamic>>> getBannersRaw() async {
    final snapshot = await _firestore.collection('banners').orderBy('order').get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<void> addBanner(String imageUrl, int order) async {
    await _firestore.collection('banners').add({
      'imageUrl': imageUrl,
      'order': order,
      'active': true,
    });
  }

  Future<void> deleteBanner(String id, String imageUrl) async {
    await _firestore.collection('banners').doc(id).delete();
    await deleteImage(imageUrl);
  }
}
