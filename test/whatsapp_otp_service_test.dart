import 'package:flutter_test/flutter_test.dart';
import 'package:al_ruby_ecommerce/data/services/whatsapp_otp_service.dart';

void main() {
  group('WhatsAppOtpService Tests', () {
    late WhatsAppOtpService service;

    setUp(() {
      service = WhatsAppOtpService();
      service.clearSession('9656978468');
      service.clearSession('+91 96569 78468');
    });

    test('generateOtp creates a 6-digit numeric OTP with valid expiration', () async {
      final session = await service.generateOtp(phoneNumber: '9656978468');

      expect(session.code.length, equals(6));
      expect(int.tryParse(session.code), isNotNull);
      expect(session.isExpired, isFalse);
      expect(session.isVerified, isFalse);
      expect(session.attempts, equals(0));
      expect(session.expiresAt.isAfter(session.createdAt), isTrue);
    });

    test('getVerificationMessage formats friendly WhatsApp handshake message', () {
      final message = service.getVerificationMessage(
        code: '582914',
        phoneNumber: '+91 96569 78468',
        companyName: 'IZZFAH NOOBI',
      );

      expect(message, contains('582914'));
      expect(message, contains('+91 96569 78468'));
      expect(message, contains('IZZFAH NOOBI'));
    });

    test('verifyOtp succeeds with correct code and clears active session', () async {
      final session = await service.generateOtp(phoneNumber: '9656978468');
      final correctCode = session.code;

      final isSuccess = await service.verifyOtp(
        phoneNumber: '9656978468',
        enteredCode: correctCode,
      );

      expect(isSuccess, isTrue);

      // Session should now be cleared
      final afterSession = await service.getSession('9656978468');
      expect(afterSession, isNull);
    });

    test('verifyOtp fails with incorrect code and increments attempts', () async {
      final session = await service.generateOtp(phoneNumber: '9656978468');
      final wrongCode = session.code == '123456' ? '654321' : '123456';

      final isSuccess = await service.verifyOtp(
        phoneNumber: '9656978468',
        enteredCode: wrongCode,
      );

      expect(isSuccess, isFalse);

      final currentSession = await service.getSession('9656978468');
      expect(currentSession, isNotNull);
      expect(currentSession!.attempts, equals(1));
    });

    test('getRemainingCooldownSeconds returns value within 60s window', () async {
      await service.generateOtp(phoneNumber: '9656978468');
      final cooldown = service.getRemainingCooldownSeconds('9656978468');

      expect(cooldown, greaterThan(0));
      expect(cooldown, lessThanOrEqualTo(60));
    });
  });
}
