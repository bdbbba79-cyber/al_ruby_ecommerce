import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:al_ruby_ecommerce/data/models/user_model.dart';
import 'package:al_ruby_ecommerce/data/models/address_model.dart';
import 'package:al_ruby_ecommerce/data/services/whatsapp_otp_service.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  ConfirmationResult? _webConfirmationResult;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserModel?> getUserDetails(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final userModel = UserModel.fromMap(doc.id, data);
        // Automatically heal/backfill referralCode if missing in Firestore
        if (!data.containsKey('referralCode')) {
          await _firestore.collection('users').doc(uid).update({
            'referralCode': userModel.referralCode,
          });
        }
        return userModel;
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
    
    // Default role logic: first user or admin email becomes admin
    String role = 'customer';
    final lowerEmail = email.trim().toLowerCase();
    if (lowerEmail == 'vpsafvanfaizy@gmail.com' || lowerEmail == 'admin@webcartstore.com' || lowerEmail == 'admin@izzfahnoobi.com') {
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
    
    // Check if the document exists in Firestore first
    final docRef = _firestore.collection('users').doc(user.uid);
    final docSnap = await docRef.get();
    if (docSnap.exists && docSnap.data() != null) {
      try {
        return UserModel.fromMap(docSnap.id, docSnap.data()!);
      } catch (e) {
        throw Exception("Failed to load user details: $e");
      }
    }

    // If auth succeeds but document missing (e.g. legacy/social login mismatch), create default doc
    final name = email.split('@')[0];
    final lowerEmail = email.trim().toLowerCase();
    final userModel = UserModel(
      id: user.uid,
      name: name,
      email: email,
      role: (lowerEmail == 'vpsafvanfaizy@gmail.com' || lowerEmail == 'admin@webcartstore.com' || lowerEmail == 'admin@izzfahnoobi.com') ? 'admin' : 'customer',
      wishlist: [],
      cart: [],
      referralCode: UserModel.generateReferralCode(name, user.uid),
    );
    await docRef.set(userModel.toMap());
    return userModel;
  }

  final WhatsAppOtpService _whatsAppOtpService = WhatsAppOtpService();
  WhatsAppOtpService get whatsAppOtpService => _whatsAppOtpService;

  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String error) onError,
    required void Function(PhoneAuthCredential credential) onAutoVerification,
    int? resendToken,
  }) async {
    try {
      if (kIsWeb) {
        _webConfirmationResult = await _auth.signInWithPhoneNumber(phoneNumber);
        onCodeSent('web_confirmation', null);
      } else {
        await _auth.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          forceResendingToken: resendToken,
          timeout: const Duration(seconds: 60),
          verificationCompleted: (PhoneAuthCredential credential) async {
            onAutoVerification(credential);
          },
          verificationFailed: (FirebaseAuthException e) {
            onError(e.message ?? 'Phone verification failed');
          },
          codeSent: (String verificationId, int? resendToken) {
            onCodeSent(verificationId, resendToken);
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            // Auto-retrieval timeout
          },
        );
      }
    } catch (e) {
      onError(e.toString().replaceAll(RegExp(r'\[.*\]'), '').trim());
    }
  }

  Future<UserModel> verifyOtpAndSignIn({
    required String verificationId,
    required String smsCode,
    String? defaultName,
  }) async {
    UserCredential credential;
    if (kIsWeb) {
      if (_webConfirmationResult == null) {
        throw Exception('Please request a new OTP code.');
      }
      credential = await _webConfirmationResult!.confirm(smsCode);
    } else {
      final phoneAuthCredential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      credential = await _auth.signInWithCredential(phoneAuthCredential);
    }

    final user = credential.user;
    if (user == null) {
      throw Exception('Authentication failed. No user returned.');
    }
    return await _handleUserDocAfterSignIn(user, defaultName: defaultName);
  }

  /// Initiates a 100% Free WhatsApp OTP session
  Future<WhatsAppOtpSession> initiateWhatsAppOtp({required String phoneNumber}) async {
    return await _whatsAppOtpService.generateOtp(phoneNumber: phoneNumber);
  }

  /// Verifies the WhatsApp OTP and authenticates the user into Firebase Auth
  Future<UserModel> verifyWhatsAppOtpAndSignIn({
    required String phoneNumber,
    required String enteredCode,
    String? defaultName,
  }) async {
    final isValid = await _whatsAppOtpService.verifyOtp(
      phoneNumber: phoneNumber,
      enteredCode: enteredCode,
    );

    if (!isValid) {
      throw Exception('Invalid or expired verification code. Please check and try again.');
    }

    // Format clean digits for deterministic Firebase user identity
    final cleanDigits = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final authEmail = 'wa_$cleanDigits@auth.webcartstore.com';
    final authPassword = 'WebCart#WA_${cleanDigits}_SecureAuthKey!';

    UserCredential credential;
    try {
      credential = await _auth.signInWithEmailAndPassword(
        email: authEmail,
        password: authPassword,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential' || e.code == 'wrong-password') {
        try {
          credential = await _auth.createUserWithEmailAndPassword(
            email: authEmail,
            password: authPassword,
          );
        } catch (_) {
          // If already exists, attempt one more sign in
          credential = await _auth.signInWithEmailAndPassword(
            email: authEmail,
            password: authPassword,
          );
        }
      } else {
        rethrow;
      }
    }

    final user = credential.user;
    if (user == null) {
      throw Exception('Authentication failed. No user returned.');
    }

    return await _handleUserDocAfterSignIn(
      user,
      defaultName: defaultName,
      overridePhone: phoneNumber,
    );
  }

  Future<UserModel> signInWithPhoneCredential(
    PhoneAuthCredential phoneAuthCredential, {
    String? defaultName,
  }) async {
    final credential = await _auth.signInWithCredential(phoneAuthCredential);
    final user = credential.user;
    if (user == null) {
      throw Exception('Auto verification failed. No user returned.');
    }
    return await _handleUserDocAfterSignIn(user, defaultName: defaultName);
  }

  Future<UserModel> _handleUserDocAfterSignIn(
    User user, {
    String? defaultName,
    String? overridePhone,
  }) async {
    final uid = user.uid;
    final phone = (overridePhone != null && overridePhone.trim().isNotEmpty)
        ? overridePhone.trim()
        : (user.phoneNumber ?? '');

    final existingUser = await getUserDetails(uid);
    if (existingUser != null) {
      if (existingUser.phoneNumber.isEmpty && phone.isNotEmpty) {
        await _firestore.collection('users').doc(uid).update({
          'phoneNumber': phone,
        });
        return existingUser.copyWith(phoneNumber: phone);
      }
      return existingUser;
    }

    // New user registration via WhatsApp / Phone
    String name = (defaultName != null && defaultName.trim().isNotEmpty)
        ? defaultName.trim()
        : (phone.isNotEmpty
            ? 'User ${phone.length > 4 ? phone.substring(phone.length - 4) : phone}'
            : 'Customer');

    String role = 'customer';
    final cleanDigits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if ((user.email != null && user.email!.trim().toLowerCase() == 'vpsafvanfaizy@gmail.com') ||
        cleanDigits.endsWith('9400859846')) {
      role = 'admin';
    } else {
      final usersSnapshot = await _firestore.collection('users').limit(1).get();
      if (usersSnapshot.docs.isEmpty) {
        role = 'admin'; // First registered user is admin
      }
    }

    final newUser = UserModel(
      id: uid,
      name: name,
      email: user.email ?? '',
      role: role,
      phoneNumber: phone,
      wishlist: [],
      cart: [],
      referralCode: UserModel.generateReferralCode(name, uid),
    );

    await _firestore.collection('users').doc(uid).set(newUser.toMap());
    return newUser;
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

  Future<void> saveAddressList(String uid, List<AddressModel> addresses) async {
    final Map<String, dynamic> updateData = {
      'addresses': addresses.map((a) => a.toMap()).toList(),
    };

    if (addresses.isNotEmpty) {
      final defaultAddr = addresses.firstWhere((a) => a.isDefault, orElse: () => addresses.first);
      updateData['phoneNumber'] = defaultAddr.phoneNumber;
      updateData['savedHouseStreet'] = defaultAddr.houseStreet;
      updateData['savedCity'] = defaultAddr.city;
      updateData['savedDistrict'] = defaultAddr.district;
      updateData['savedState'] = defaultAddr.state;
      updateData['savedPinCode'] = defaultAddr.pinCode;
    }

    await _firestore.collection('users').doc(uid).update(updateData);
  }
}
