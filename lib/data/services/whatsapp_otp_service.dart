import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Represents an active WhatsApp OTP verification session.
class WhatsAppOtpSession {
  final String phoneNumber;
  final String code;
  final DateTime createdAt;
  final DateTime expiresAt;
  int attempts;
  bool isVerified;

  WhatsAppOtpSession({
    required this.phoneNumber,
    required this.code,
    required this.createdAt,
    required this.expiresAt,
    this.attempts = 0,
    this.isVerified = false,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toMap() {
    return {
      'phoneNumber': phoneNumber,
      'code': code,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'attempts': attempts,
      'isVerified': isVerified,
    };
  }

  factory WhatsAppOtpSession.fromMap(Map<String, dynamic> map) {
    return WhatsAppOtpSession(
      phoneNumber: map['phoneNumber'] ?? '',
      code: map['code'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      expiresAt: DateTime.tryParse(map['expiresAt'] ?? '') ?? DateTime.now(),
      attempts: map['attempts'] ?? 0,
      isVerified: map['isVerified'] ?? false,
    );
  }
}

/// Service handling 100% Free WhatsApp OTP generation, session storage, and verification.
class WhatsAppOtpService {
  static final WhatsAppOtpService _instance = WhatsAppOtpService._internal();
  factory WhatsAppOtpService() => _instance;
  WhatsAppOtpService._internal();

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }
  final Map<String, WhatsAppOtpSession> _memorySessions = {};

  /// Normalizes a phone number to digits only for session keys
  String _normalize(String phone) {
    String digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0')) {
      digits = digits.replaceFirst(RegExp(r'^0+'), '');
    }
    if (digits.length == 10) {
      digits = '91$digits';
    }
    return digits;
  }

  /// Generates a new 6-digit OTP for the given phone number with a 5-minute validity window.
  Future<WhatsAppOtpSession> generateOtp({required String phoneNumber}) async {
    final key = _normalize(phoneNumber);

    // Generate secure 6-digit random code (100000 - 999999)
    final random = Random.secure();
    final code = (100000 + random.nextInt(900000)).toString();

    final now = DateTime.now();
    final expiresAt = now.add(const Duration(minutes: 5));

    final session = WhatsAppOtpSession(
      phoneNumber: phoneNumber,
      code: code,
      createdAt: now,
      expiresAt: expiresAt,
    );

    _memorySessions[key] = session;

    // Persist to Firestore so sessions survive browser/app reloads
    try {
      await _firestore?.collection('whatsapp_verifications').doc(key).set(session.toMap());
    } catch (e) {
      debugPrint('Note: WhatsApp OTP cached in memory. Firestore sync info: $e');
    }

    return session;
  }

  /// Returns the current active session for the phone number, if any.
  Future<WhatsAppOtpSession?> getSession(String phoneNumber) async {
    final key = _normalize(phoneNumber);
    if (_memorySessions.containsKey(key)) {
      final session = _memorySessions[key]!;
      if (!session.isExpired) return session;
    }

    // Try reading from Firestore if not in memory or expired
    try {
      final doc = await _firestore?.collection('whatsapp_verifications').doc(key).get();
      if (doc != null && doc.exists && doc.data() != null) {
        final session = WhatsAppOtpSession.fromMap(doc.data()!);
        if (!session.isExpired) {
          _memorySessions[key] = session;
          return session;
        }
      }
    } catch (e) {
      debugPrint('Error reading session from Firestore: $e');
    }

    return null;
  }

  /// Formats the message sent via WhatsApp to complete verification
  String getVerificationMessage({
    required String code,
    required String phoneNumber,
    String companyName = 'IZZFAH NOOBI',
  }) {
    return 'Hello $companyName, my login verification code is: $code for $phoneNumber. Please verify my account.';
  }

  /// Verifies the entered 6-digit OTP code against the active session.
  Future<bool> verifyOtp({
    required String phoneNumber,
    required String enteredCode,
  }) async {
    final key = _normalize(phoneNumber);
    final session = await getSession(phoneNumber);

    if (session == null) {
      debugPrint('No active WhatsApp OTP session found for $key');
      return false;
    }

    if (session.isExpired) {
      debugPrint('WhatsApp OTP has expired for $key');
      return false;
    }

    if (session.attempts >= 5) {
      debugPrint('Too many failed WhatsApp OTP attempts for $key');
      return false;
    }

    final trimmedEntered = enteredCode.trim();
    if (session.code == trimmedEntered) {
      session.isVerified = true;
      _memorySessions.remove(key);

      try {
        await _firestore?.collection('whatsapp_verifications').doc(key).delete();
      } catch (_) {}

      return true;
    } else {
      session.attempts += 1;
      try {
        await _firestore?.collection('whatsapp_verifications').doc(key).update({
          'attempts': session.attempts,
        });
      } catch (_) {}
      return false;
    }
  }

  /// Calculates remaining seconds before user can request a resend (60-second cooldown)
  int getRemainingCooldownSeconds(String phoneNumber) {
    final key = _normalize(phoneNumber);
    if (!_memorySessions.containsKey(key)) return 0;

    final session = _memorySessions[key]!;
    final elapsed = DateTime.now().difference(session.createdAt).inSeconds;
    final remaining = 60 - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  /// Clears session for a phone number
  void clearSession(String phoneNumber) {
    final key = _normalize(phoneNumber);
    _memorySessions.remove(key);
  }
}
