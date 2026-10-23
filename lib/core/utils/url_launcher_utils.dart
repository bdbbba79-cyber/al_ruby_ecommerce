import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Formats a phone number for the WhatsApp API.
/// Strips all non-digits, trims leading zeroes, and prepends '91' for 10-digit Indian numbers.
String formatWhatsAppNumber(String rawNumber) {
  if (rawNumber.trim().isEmpty) return '';

  // Strip all non-numeric characters (+, -, spaces, parentheses, etc.)
  String digits = rawNumber.replaceAll(RegExp(r'[^0-9]'), '');

  // Strip leading zeroes (e.g., 09656978468 -> 9656978468)
  if (digits.startsWith('0')) {
    digits = digits.replaceFirst(RegExp(r'^0+'), '');
  }

  // If it's a 10-digit Indian mobile number without country code, prepend 91
  if (digits.length == 10) {
    digits = '91$digits';
  }

  return digits;
}

/// Launches WhatsApp directly with the corresponding phone number and optional pre-filled message.
///
/// On mobile (Android/iOS), it first tries the native `whatsapp://send` scheme to open
/// the WhatsApp app directly. If not installed or fails, it falls back to `https://wa.me/`
/// in an external application (browser/universal link).
Future<bool> launchWhatsApp({
  BuildContext? context,
  required String phone,
  String? message,
}) async {
  final cleanNumber = formatWhatsAppNumber(phone);
  if (cleanNumber.isEmpty) {
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp number is not configured.')),
      );
    }
    return false;
  }

  final textParam = (message != null && message.trim().isNotEmpty)
      ? '?text=${Uri.encodeComponent(message.trim())}'
      : '';

  // 1. Direct native WhatsApp scheme (opens the WhatsApp app directly)
  final nativeUri = Uri.parse(
    'whatsapp://send?phone=$cleanNumber${(message != null && message.trim().isNotEmpty) ? '&text=${Uri.encodeComponent(message.trim())}' : ''}',
  );

  // 2. Universal / Web fallback link
  final webUri = Uri.parse('https://wa.me/$cleanNumber$textParam');

  // Attempt native scheme first on mobile devices
  if (!kIsWeb) {
    try {
      if (await canLaunchUrl(nativeUri)) {
        final launched = await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
        if (launched) return true;
      }
    } catch (e) {
      debugPrint('Error launching native WhatsApp scheme: $e');
    }
  }

  // Fallback to web link (external browser / universal app link)
  try {
    if (await canLaunchUrl(webUri)) {
      final launched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
      if (launched) return true;
    }
  } catch (e) {
    debugPrint('Error checking webUri: $e');
  }

  // Final direct attempt in case canLaunchUrl was restricted
  try {
    final launched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
    if (launched) return true;
  } catch (e) {
    debugPrint('Error launching WhatsApp web fallback: $e');
  }

  if (context != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not open WhatsApp. Please ensure WhatsApp is installed or try again.'),
      ),
    );
  }

  return false;
}

/// Opens an external URL in the device's browser or corresponding external app.
Future<bool> openExternalUrl(String url, {BuildContext? context}) async {
  if (url.trim().isEmpty) return false;

  var targetUrl = url.trim();
  if (!targetUrl.startsWith('http://') && !targetUrl.startsWith('https://')) {
    targetUrl = 'https://$targetUrl';
  }

  try {
    final uri = Uri.parse(targetUrl);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  } catch (e) {
    debugPrint('Error opening external URL ($url): $e');
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open link: $url')),
      );
    }
    return false;
  }
}
