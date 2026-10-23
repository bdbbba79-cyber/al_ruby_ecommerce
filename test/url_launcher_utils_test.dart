import 'package:flutter_test/flutter_test.dart';
import 'package:al_ruby_ecommerce/core/utils/url_launcher_utils.dart';

void main() {
  group('formatWhatsAppNumber tests', () {
    test('standard 10-digit Indian number gets 91 prefixed', () {
      expect(formatWhatsAppNumber('9656978468'), equals('919656978468'));
      expect(formatWhatsAppNumber('9400859846'), equals('919400859846'));
    });

    test('10-digit number with leading zero gets zero stripped and 91 prefixed', () {
      expect(formatWhatsAppNumber('09656978468'), equals('919656978468'));
    });

    test('international format with plus and spaces is cleaned properly', () {
      expect(formatWhatsAppNumber('+91 96569 78468'), equals('919656978468'));
      expect(formatWhatsAppNumber('+91-9656978468'), equals('919656978468'));
      expect(formatWhatsAppNumber('+919656978468'), equals('919656978468'));
    });

    test('number with 91 already prefixed (12 digits) is preserved', () {
      expect(formatWhatsAppNumber('919656978468'), equals('919656978468'));
    });

    test('other international numbers are preserved without 91 prefix', () {
      expect(formatWhatsAppNumber('+971 50 123 4567'), equals('971501234567'));
      expect(formatWhatsAppNumber('+1 (555) 123-4567'), equals('15551234567'));
    });

    test('empty or whitespace input returns empty string', () {
      expect(formatWhatsAppNumber(''), equals(''));
      expect(formatWhatsAppNumber('   '), equals(''));
    });
  });
}
