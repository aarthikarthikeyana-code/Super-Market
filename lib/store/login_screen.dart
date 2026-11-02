import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'state.dart';
import 'widgets.dart';

class CustomerLoginScreen extends ConsumerStatefulWidget {
  const CustomerLoginScreen({super.key});

  @override
  ConsumerState<CustomerLoginScreen> createState() =>
      _CustomerLoginScreenState();
}

class _CustomerLoginScreenState extends ConsumerState<CustomerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  Map<String, dynamic>? _challenge;
  bool _busy = false;
  String? _error;
  int _resendCountdown = 30;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendCountdown = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        t.cancel();
      }
    });
  }

  Future<void> _continue() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final api = ref.read(storeApiProvider);
      if (_challenge == null) {
        final challenge = await api.requestCustomerCode(
          _phoneController.text.trim(),
        );
        if (mounted) {
          setState(() => _challenge = challenge);
          _startResendTimer();
        }
        return;
      }

      await api.verifyCustomerCode(
        _challenge!['challenge_id'],
        _codeController.text.trim(),
      );
      if (!mounted) return;
      ref.invalidate(customerAccountProvider);
      ref.invalidate(customerProfileProvider);
      ref.invalidate(myOrdersProvider);
      ref.invalidate(wishlistProvider);
      ref.invalidate(wishlistIdsProvider);
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resendCode() async {
    if (_busy || _resendCountdown > 0) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final challenge = await ref
          .read(storeApiProvider)
          .requestCustomerCode(_phoneController.text.trim());
      if (mounted) {
        setState(() {
          _challenge = challenge;
          _codeController.clear();
        });
        _startResendTimer();
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        backgroundColor: storeCream,
        body: SafeArea(
          child: Column(
            children: [
              // Top Bar with back arrow & Agaram Supermarket Logo
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: storeInk,
                        size: 22,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'AGARAM',
                            style: TextStyle(
                              color: storeForestGreen,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.2,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'SUPERMARKET',
                            style: TextStyle(
                              color: storeFreshGreen,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.5,
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48), // Balance spacing
                  ],
                ),
              ),

              // Form Area
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hero Grocery Illustration (~30% screen height)
                        Center(
                          child: Container(
                            height: 190,
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 6, bottom: 20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: storeForestGreen.withOpacity(0.08),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.asset(
                                    'assets/images/drawer_grocery_pantry.jpg',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      color: storeMint,
                                      child: const Icon(
                                        Icons.shopping_bag_outlined,
                                        size: 64,
                                        color: storeForestGreen,
                                      ),
                                    ),
                                  ),
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          storeDeepGreen.withOpacity(0.7),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 14,
                                    left: 16,
                                    right: 16,
                                    child: Row(
                                      children: const [
                                        Icon(
                                          Icons.verified_rounded,
                                          color: storeGold,
                                          size: 18,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          '100% Genuine Grocery Essentials',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Copy
                        Text(
                          _challenge == null
                              ? 'Welcome to Agaram'
                              : 'Verify your mobile',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: storeInk,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _challenge == null
                              ? 'Sign in to shop faster, track orders and save your favourites.'
                              : 'Enter the verification code sent to +91 ${_phoneController.text.trim()}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: storeGrey,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Error Banner
                        if (_error != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: storeRed.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: storeRed.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: storeRed,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(
                                      color: storeRed,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Phone Input Field (Height 54-58px)
                        if (_challenge == null)
                          Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: storeBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextFormField(
                              controller: _phoneController,
                              enabled: !_busy,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: storeInk,
                              ),
                              decoration: InputDecoration(
                                prefixIcon: Container(
                                  width: 72,
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Text(
                                        '+91',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: storeForestGreen,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      VerticalDivider(
                                        color: storeBorder,
                                        width: 1,
                                        thickness: 1,
                                        indent: 14,
                                        endIndent: 14,
                                      ),
                                    ],
                                  ),
                                ),
                                hintText: 'Enter 10-digit mobile number',
                                hintStyle: const TextStyle(
                                  color: storeGrey,
                                  fontSize: 13.5,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              validator: (v) {
                                final text = v?.trim() ?? '';
                                if (!RegExp(r'^[6-9][0-9]{9}$')
                                    .hasMatch(text)) {
                                  return 'Enter a valid 10-digit Indian mobile number';
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) => _continue(),
                            ),
                          )
                        else ...[
                          // Demo Code Banner if available in response
                          if (_challenge!['demo_code'] != null)
                            Container(
                              padding: const EdgeInsets.all(14),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: storeMint,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: storeForestGreen.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    color: storeForestGreen,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Demo Verification Code',
                                          style: TextStyle(
                                            color: storeForestGreen,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          'Enter: ${_challenge!['demo_code']}',
                                          style: const TextStyle(
                                            color: storeForestGreen,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 17,
                                            letterSpacing: 2.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // OTP Input Field
                          Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: storeBorder),
                            ),
                            child: TextFormField(
                              controller: _codeController,
                              enabled: !_busy,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 8,
                                color: storeForestGreen,
                              ),
                              decoration: const InputDecoration(
                                hintText: '• • • • •',
                                hintStyle: TextStyle(
                                  letterSpacing: 8,
                                  color: storeGrey,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              validator: (v) => (v?.trim().length ?? 0) < 4
                                  ? 'Enter the code'
                                  : null,
                              onFieldSubmitted: (_) => _continue(),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Resend OTP Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _challenge = null;
                                    _codeController.clear();
                                  });
                                },
                                child: const Text(
                                  'Change mobile number',
                                  style: TextStyle(
                                    color: storeGrey,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _resendCountdown == 0
                                    ? _resendCode
                                    : null,
                                child: Text(
                                  _resendCountdown > 0
                                      ? 'Resend OTP in ${_resendCountdown}s'
                                      : 'Resend OTP',
                                  style: TextStyle(
                                    color: _resendCountdown == 0
                                        ? storeForestGreen
                                        : storeGrey,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 24),

                        // Primary Action Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            onPressed: _busy ? null : _continue,
                            style: FilledButton.styleFrom(
                              backgroundColor: storeForestGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _busy
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _challenge == null
                                            ? 'Continue'
                                            : 'Verify & Continue',
                                        style: const TextStyle(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Three Compact Trust Items (Section 35)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: const [
                            _TrustBadge(
                              icon: Icons.bolt_rounded,
                              label: 'Fast Checkout',
                            ),
                            _TrustBadge(
                              icon: Icons.local_shipping_outlined,
                              label: 'Track Orders',
                            ),
                            _TrustBadge(
                              icon: Icons.favorite_border_rounded,
                              label: 'Save Wishlist',
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: storeMint,
          child: Icon(icon, color: storeForestGreen, size: 14),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: storeInk,
          ),
        ),
      ],
    );
  }
}
