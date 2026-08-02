import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:al_ruby_ecommerce/data/models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserModel?> getUserDetails(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;
    
    // Default role logic: first user or admin@alruby.com becomes admin
    String role = 'customer';
    if (email.trim().toLowerCase() == 'admin@alruby.com') {
      role = 'admin';
    } else {
      final usersSnapshot = await _firestore.collection('users').limit(1).get();
      if (usersSnapshot.docs.isEmpty) {
        role = 'admin'; // First registered user becomes admin
      }
    }

    final userModel = UserModel(
      id: user.uid,
      name: name,
      email: email,
      role: role,
      wishlist: [],
      cart: [],
      referralCode: UserModel.generateReferralCode(name, user.uid),
    );

    await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
    return userModel;
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;
    final details = await getUserDetails(user.uid);
    if (details != null) {
      return details;
    }
    // If auth succeeds but document missing (e.g. legacy/social login mismatch), create default doc
    final name = email.split('@')[0];
    final userModel = UserModel(
      id: user.uid,
      name: name,
      email: email,
      role: email.trim().toLowerCase() == 'admin@alruby.com' ? 'admin' : 'customer',
      wishlist: [],
      cart: [],
      referralCode: UserModel.generateReferralCode(name, user.uid),
    );
    await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
    return userModel;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateWishlist(String uid, List<String> wishlist) async {
    await _firestore.collection('users').doc(uid).update({
      'wishlist': wishlist,
    });
  }

  Future<void> updateCart(String uid, List<Map<String, dynamic>> cart) async {
    await _firestore.collection('users').doc(uid).update({
      'cart': cart,
    });
  }

  Future<void> updateMarketingProfile(String uid, String phoneNumber, String upiId) async {
    await _firestore.collection('users').doc(uid).update({
      'phoneNumber': phoneNumber,
      'upiId': upiId,
    });
  }

  Future<void> requestWithdrawal(String uid, double amount) async {
    await _firestore.collection('users').doc(uid).update({
      'withdrawalRequested': true,
      'withdrawalRequestedAmount': amount,
    });
  }

  Future<void> updatePaidAmount(String uid, double newPaidAmount) async {
    // Retrieve user doc to compute balance and check withdrawal
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      final u = UserModel.fromMap(doc.id, doc.data()!);
      final updatedPaid = u.totalPaid + newPaidAmount;
      await _firestore.collection('users').doc(uid).update({
        'totalPaid': updatedPaid,
        'withdrawalRequested': false,
        'withdrawalRequestedAmount': 0.0,
      });
    }
  }

  Stream<List<UserModel>> watchAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromMap(doc.id, doc.data())).toList();
    });
  }

  Future<void> saveShippingAddress(String uid, {
    required String phoneNumber,
    required String houseStreet,
    required String city,
    required String district,
    required String state,
    required String pinCode,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'phoneNumber': phoneNumber,
      'savedHouseStreet': houseStreet,
      'savedCity': city,
      'savedDistrict': district,
      'savedState': state,
      'savedPinCode': pinCode,
    });
  }
}
