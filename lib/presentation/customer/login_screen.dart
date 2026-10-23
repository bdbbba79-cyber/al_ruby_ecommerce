import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:al_ruby_ecommerce/core/utils/url_launcher_utils.dart';
import 'package:al_ruby_ecommerce/presentation/providers/providers.dart';
import 'package:al_ruby_ecommerce/presentation/widgets/app_network_image.dart';
import 'package:al_ruby_ecommerce/presentation/widgets/otp_input_widget.dart';
import 'package:al_ruby_ecommerce/data/models/user_model.dart';

enum AuthMethod { whatsapp, email }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _phoneFormKey = GlobalKey<FormState>();

  AuthMethod _authMethod = AuthMethod.whatsapp;

  // Email controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Phone controllers & state
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _countryCode = '+91';

  bool _otpSent = false;
  String? _generatedOtpCode;
  String _enteredOtp = '';
  final GlobalKey<OtpInputWidgetState> _otpWidgetKey = GlobalKey<OtpInputWidgetState>();

  Timer? _resendTimer;
  int _resendSeconds = 60;

  bool _isLoading = false;
  String? _errorMessage;
  String? _infoMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() {
      _resendSeconds = 60;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() {
          _resendSeconds = 0;
        });
      } else {
        setState(() {
          _resendSeconds--;
        });
      }
    });
  }

  String _formatPhoneNumber(String raw) {
    String clean = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.startsWith('+')) {
      return clean;
    }
    if (clean.startsWith('0')) {
      clean = clean.substring(1);
    }
    return '$_countryCode$clean';
  }

  Future<void> _handleSuccessfulAuth(UserModel userModel) async {
    ref.read(currentUserDetailsProvider.notifier).state = userModel;

    // Sync wishlist & cart
    final products = await ref.read(storeRepoProvider).getProducts(activeOnly: false);
    ref.read(wishlistProvider.notifier).loadWishlist(products, userModel.wishlist);
    ref.read(cartProvider.notifier).loadCart(products, userModel.cart, merge: true);

    if (!mounted) return;
    if (userModel.role == 'admin') {
      context.go('/admin');
    } else {
      context.go('/home');
    }
  }

  Future<void> _sendWhatsAppOtp({bool launchChat = true}) async {
    if (!_phoneFormKey.currentState!.validate()) return;

    final fullPhoneNumber = _formatPhoneNumber(_phoneController.text.trim());

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      final session = await ref.read(authRepoProvider).initiateWhatsAppOtp(
        phoneNumber: fullPhoneNumber,
      );

      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _generatedOtpCode = session.code;
        _enteredOtp = '';
        _isLoading = false;
        _infoMessage = 'WhatsApp verification code generated for $fullPhoneNumber';
      });
      _startResendCountdown();

      if (launchChat) {
        await _openWhatsAppVerification(fullPhoneNumber, session.code);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll(RegExp(r'\[.*\]'), '').trim();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openWhatsAppVerification(String userPhone, String code) async {
    final businessInfo = ref.read(businessInfoProvider).valueOrNull;
    final storeWhatsApp = (businessInfo != null && businessInfo.whatsappNumber.isNotEmpty)
        ? businessInfo.whatsappNumber
        : '919656978468';

    final message = 'Hello Izzfah Noobi, my account verification code is: $code for $userPhone. Please verify my account.';

    await launchWhatsApp(
      context: context,
      phone: storeWhatsApp,
      message: message,
    );
  }

  Future<void> _verifyWhatsAppOtp() async {
    if (_enteredOtp.length < 6) {
      setState(() {
        _errorMessage = 'Please enter the complete 6-digit OTP code.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      final fullPhoneNumber = _formatPhoneNumber(_phoneController.text.trim());
      final userModel = await ref.read(authRepoProvider).verifyWhatsAppOtpAndSignIn(
        phoneNumber: fullPhoneNumber,
        enteredCode: _enteredOtp,
        defaultName: _nameController.text.trim(),
      );

      await _handleSuccessfulAuth(userModel);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll(RegExp(r'\[.*\]'), '').trim();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loginWithEmail() async {
    if (!_emailFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      final userModel = await ref.read(authRepoProvider).signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      await _handleSuccessfulAuth(userModel);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll(RegExp(r'\[.*\]'), '').trim();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _launchWhatsApp(String number) async {
    await launchWhatsApp(
      context: context,
      phone: number,
      message: 'Hello Izzfah Noobi, I need help with login.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final businessInfoAsync = ref.watch(businessInfoProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                businessInfoAsync.when(
                  data: (info) => info.companyLogoUrl.isNotEmpty
                      ? AppNetworkImage(
                          imageUrl: info.companyLogoUrl,
                          height: 90,
                          cacheHeight: 180,
                          fit: BoxFit.contain,
                          fallbackAsset: 'assets/logo/logo.png',
                        )
                      : Image.asset('assets/logo/logo.png', height: 90, fit: BoxFit.contain),
                  loading: () => Image.asset('assets/logo/logo.png', height: 90, fit: BoxFit.contain),
                  error: (_, _) => Image.asset('assets/logo/logo.png', height: 90, fit: BoxFit.contain),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Welcome to Izzfah Noobi',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sign in to access your orders, wishlist, and rewards.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Tab Switcher: WhatsApp OTP vs Email & Password
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTabButton(
                          title: 'WhatsApp OTP',
                          icon: Icons.chat,
                          isSelected: _authMethod == AuthMethod.whatsapp,
                          selectedColor: const Color(0xFF1E60D5),
                          onTap: () {
                            setState(() {
                              _authMethod = AuthMethod.whatsapp;
                              _errorMessage = null;
                              _infoMessage = null;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: _buildTabButton(
                          title: 'Email & Password',
                          icon: Icons.email_outlined,
                          isSelected: _authMethod == AuthMethod.email,
                          selectedColor: const Color(0xFF1E60D5),
                          onTap: () {
                            setState(() {
                              _authMethod = AuthMethod.email;
                              _errorMessage = null;
                              _infoMessage = null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Error alert
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 13, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Info banner
                if (_infoMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: primaryColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle_outline, color: primaryColor, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _infoMessage!,
                            style: TextStyle(color: primaryColor, fontSize: 13, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Form Body based on Tab
                if (_authMethod == AuthMethod.whatsapp)
                  _buildWhatsAppOtpSection(primaryColor)
                else
                  _buildEmailSection(primaryColor),

                const SizedBox(height: 20),

                // Register Link (for email users)
                if (_authMethod == AuthMethod.email) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      TextButton(
                        onPressed: () => context.push('/register'),
                        style: TextButton.styleFrom(
                          foregroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        child: const Text('Register with Email', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],

                // Guest option
                TextButton(
                  onPressed: () => context.go('/home'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                  ),
                  child: const Text('Continue as Guest'),
                ),

                const SizedBox(height: 12),

                // Support WhatsApp
                businessInfoAsync.when(
                  data: (info) => Center(
                    child: TextButton.icon(
                      onPressed: () => _launchWhatsApp(info.whatsappNumber),
                      icon: const Icon(Icons.chat, color: Color(0xFF25D366), size: 18),
                      label: const Text(
                        'Need help? Chat with Support',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    Color? selectedColor,
  }) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final activeColor = selectedColor ?? primaryColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WhatsApp OTP Section ---
  Widget _buildWhatsAppOtpSection(Color primaryColor) {
    if (!_otpSent) {
      return Form(
        key: _phoneFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // WhatsApp Number Input
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 16, letterSpacing: 0.5),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
              ],
              decoration: InputDecoration(
                hintText: 'Enter 10-digit WhatsApp number',
                prefixIcon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  margin: const EdgeInsets.only(right: 8),
                  alignment: Alignment.center,
                  width: 70,
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                  ),
                  child: const Text(
                    '+91',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                suffixIcon: const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.chat_bubble, color: Color(0xFF1E60D5), size: 20),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your WhatsApp number';
                }
                final clean = value.replaceAll(RegExp(r'[^0-9]'), '');
                if (clean.length < 10) {
                  return 'Please enter a valid 10-digit WhatsApp number';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Optional Name (for quick auto-registration)
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(color: Color(0xFF0F172A)),
              decoration: const InputDecoration(
                hintText: 'Your Name (Optional)',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),

            // Free WhatsApp verification feature card
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified, color: Color(0xFF1E60D5), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Free & secure OTP verification via WhatsApp.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF1E60D5), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _sendWhatsAppOtp(launchChat: true),
              icon: _isLoading
                  ? const SizedBox.shrink()
                  : const Icon(Icons.chat, size: 18, color: Colors.white),
              label: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                    )
                  : const Text('Continue with WhatsApp OTP'),
            ),
          ],
        ),
      );
    }

    // OTP Verification View
    final fullNumber = _formatPhoneNumber(_phoneController.text.trim());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Number badge & Change action
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.chat, color: Color(0xFF1E60D5), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('WhatsApp Number:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    Text(
                      fullNumber,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _otpSent = false;
                          _errorMessage = null;
                          _infoMessage = null;
                          _resendTimer?.cancel();
                        });
                      },
                style: TextButton.styleFrom(
                  foregroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('Change', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Prominent WhatsApp Handshake Button
        OutlinedButton.icon(
          onPressed: () {
            if (_generatedOtpCode != null) {
              _openWhatsAppVerification(fullNumber, _generatedOtpCode!);
            }
          },
          icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF25D366), size: 18),
          label: const Text(
            'Open WhatsApp to Verify',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF25D366)),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF25D366), width: 1.2),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 14),

        // Quick Code Display Card with 1-Tap Auto-Fill
        if (_generatedOtpCode != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.key, color: Color(0xFF1E60D5), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Verification OTP:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      Text(
                        _generatedOtpCode!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                          color: Color(0xFF1E60D5),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    if (_generatedOtpCode != null) {
                      _otpWidgetKey.currentState?.setCode(_generatedOtpCode!);
                      setState(() {
                        _enteredOtp = _generatedOtpCode!;
                      });
                    }
                  },
                  icon: const Icon(Icons.touch_app, size: 15),
                  label: const Text('Auto-Fill', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1E60D5),
                    backgroundColor: const Color(0xFFDBEAFE),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // 6-digit OTP Input Widget
        OtpInputWidget(
          key: _otpWidgetKey,
          length: 6,
          autoFocus: true,
          onChanged: (val) {
            _enteredOtp = val;
            if (_errorMessage != null) {
              setState(() => _errorMessage = null);
            }
          },
          onCompleted: (val) {
            _enteredOtp = val;
            _verifyWhatsAppOtp();
          },
        ),
        const SizedBox(height: 16),

        // Resend countdown or button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Didn't get or need new code?",
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
            if (_resendSeconds > 0)
              Text(
                'Resend in 00:${_resendSeconds.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: Color(0xFF1E60D5),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              )
            else
              TextButton(
                onPressed: _isLoading ? null : () => _sendWhatsAppOtp(launchChat: false),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF1E60D5),
                  padding: EdgeInsets.zero,
                ),
                child: const Text(
                  'Resend WhatsApp OTP',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),

        ElevatedButton(
          onPressed: _isLoading ? null : _verifyWhatsAppOtp,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                )
              : const Text('Verify & Sign In'),
        ),
      ],
    );
  }

  // --- Email & Password Section ---
  Widget _buildEmailSection(Color primaryColor) {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Color(0xFF0F172A)),
            decoration: const InputDecoration(
              hintText: 'Email Address',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter your email';
              if (!value.contains('@')) return 'Enter a valid email address';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            style: const TextStyle(color: Color(0xFF0F172A)),
            decoration: const InputDecoration(
              hintText: 'Password',
              prefixIcon: Icon(Icons.lock_outlined),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter your password';
              return null;
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push('/forgot-password'),
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
              ),
              child: const Text('Forgot Password?'),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : _loginWithEmail,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                  )
                : const Text('Sign In'),
          ),
        ],
      ),
    );
  }
}
