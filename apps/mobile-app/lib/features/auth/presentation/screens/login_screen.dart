import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/logo.dart';
import '../../../../shared/widgets/emotional_design.dart';
import '../../../../shared/widgets/pin_digit_box.dart';
import '../../../../config/routing.dart';
import '../../../../core/services/default_context_routing_service.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/services/motion_service.dart';
import '../utils/pin_auth_password.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

// Notification helper for success/error messages
class _NotificationHelper {
  static Future<void> showError(BuildContext context, String message) async {
    _showNotification(context, message, Colors.red, Icons.error_outline);
  }

  static void _showNotification(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  final String? initialPhone;

  const LoginScreen({super.key, this.initialPhone});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final VoidCallback _languageListener;
  AppLanguage _language = AppLanguage.english;

  bool _showPinEntry =
      false; // Flag to switch between phone and PIN entry views
  bool _isLoading = false;
  String? _normalizedPhone;
  String? _feedbackText;
  EmotionalStatusTone _feedbackTone = EmotionalStatusTone.neutral;
  int _successBurstTrigger = 0;
  bool _showHeroAnimation = false;

  final TextEditingController _phoneController = TextEditingController();
  final List<TextEditingController> _pinControllers = List.generate(
    4,
    (i) => TextEditingController(),
  );
  final FocusNode _phoneFocusNode = FocusNode();

  String _normalizeLocalPhone(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('255') && digits.length >= 12) {
      return digits.substring(3);
    }
    if (digits.startsWith('0') && digits.length >= 10) {
      return digits.substring(1);
    }
    return digits;
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initialPhone;
    if (initial != null && initial.trim().isNotEmpty) {
      _phoneController.text = _normalizeLocalPhone(initial);
    }
    _language = LocalizationService.languageNotifier.value;
    _languageListener = () {
      if (mounted) {
        setState(() => _language = LocalizationService.languageNotifier.value);
      }
    };
    LocalizationService.languageNotifier.addListener(_languageListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _showHeroAnimation = true);
    });
  }

  String _tr(String en, String sw) {
    return _language == AppLanguage.swahili ? sw : en;
  }

  void _setFeedback(String text, EmotionalStatusTone tone) {
    if (!mounted) return;
    setState(() {
      _feedbackText = text;
      _feedbackTone = tone;
    });
  }

  void _triggerSuccessBurst() {
    if (!mounted) return;
    setState(() => _successBurstTrigger++);
  }

  Future<void> _goToPostLoginLanding() async {
    final route = await DefaultContextRoutingService.resolveUserLandingPath(
      auth: _auth,
      firestore: _firestore,
    );
    if (!mounted) return;
    context.go(route);
  }

  Future<void> _openWhatsAppHelpDesk() async {
    final message = Uri.encodeComponent(
      _tr(
        'Hello Mali App Help Desk, I need emergency support with login.',
        'Habari Mali App Help Desk, nahitaji msaada wa dharura wa kuingia.',
      ),
    );
    final uri = Uri.parse('https://wa.me/255653520829?text=$message');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      await _NotificationHelper.showError(
        context,
        _tr(
          'We could not open WhatsApp right now.',
          'Hatukuweza kufungua WhatsApp sasa.',
        ),
      );
    }
  }

  Future<void> _handleLoginRequest() async {
    final rawPhone = _phoneController.text.trim();
    final digitsOnly = rawPhone.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.isEmpty) {
      await _NotificationHelper.showError(
        context,
        _tr(
          'Please enter your phone number.',
          'Tafadhali weka namba yako ya simu.',
        ),
      );
      return;
    }

    final localPhone = _normalizeLocalPhone(digitsOnly);
    if (localPhone.length < 9) {
      await _NotificationHelper.showError(
        context,
        _tr('Invalid phone number.', 'Namba ya simu si sahihi.'),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _normalizedPhone = localPhone;
    });

    try {
      // Check if user exists in Firestore
      final userSnapshot = await _firestore
          .collection('users')
          .where('phone', isEqualTo: localPhone)
          .limit(1)
          .get();

      if (userSnapshot.docs.isEmpty) {
        setState(() => _isLoading = false);
        if (!mounted) return;
        await _NotificationHelper.showError(
          context,
          _tr(
            'No account found with this number. Please register.',
            'Hakuna akaunti iliyopatikana kwa namba hii. Tafadhali jisajili.',
          ),
        );
        return;
      }

      setState(() {
        _showPinEntry = true;
        _isLoading = false;
      });
      _setFeedback(
        _tr(
          'Welcome back! Please enter your PIN.',
          'Karibu tena! Tafadhali weka PIN yako.',
        ),
        EmotionalStatusTone.neutral,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      await _NotificationHelper.showError(
        context,
        _tr(
          'Connection error. Please try again.',
          'Hitilafu ya muunganisho. Tafadhali jaribu tena.',
        ),
      );
    }
  }

  Future<void> _handlePINLogin() async {
    final pin = _pinControllers.map((c) => c.text).join();
    if (pin.length < 4) {
      await _NotificationHelper.showError(
        context,
        _tr(
          'Please enter your 4-digit PIN.',
          'Tafadhali weka PIN yako ya tarakimu 4.',
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final email = '$_normalizedPhone@mali.up';
    final authPassword = buildAuthPasswordFromPin(pin);

    try {
      try {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: authPassword,
        );
      } on FirebaseAuthException catch (e) {
        // Backward compatibility for any accounts created before auth-password derivation.
        if (e.code != 'wrong-password') rethrow;
        await _auth.signInWithEmailAndPassword(email: email, password: pin);
      }
      if (!mounted) return;

      _setFeedback(
        _tr('Login successful!', 'Umeingia kikamilifu!'),
        EmotionalStatusTone.success,
      );
      _triggerSuccessBurst();
      await Future.delayed(const Duration(milliseconds: 500));
      await _goToPostLoginLanding();
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      String message = switch (e.code) {
        'wrong-password' => _tr(
          'Incorrect PIN. Please try again.',
          'PIN si sahihi. Jaribu tena.',
        ),
        'user-not-found' => _tr('Account not found.', 'Akaunti haijapatikana.'),
        _ => _tr(
          'Login failed. Please check your PIN.',
          'Uingiaji umeshindikana. Hakiki PIN yako.',
        ),
      };
      if (!mounted) return;
      await _NotificationHelper.showError(context, message);
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      await _NotificationHelper.showError(
        context,
        _tr(
          'An unexpected error occurred.',
          'Hitilafu isiyotarajiwa imetokea.',
        ),
      );
    }
  }

  Future<void> _handleForgotPIN() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_tr('Forgot PIN?', 'Umesahau PIN?')),
        content: Text(
          _tr(
            'Please contact support at +255 653 520 829 to reset your PIN.',
            'Tafadhali wasiliana na huduma kwa wateja +255 653 520 829 ili kuweka PIN mpya.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_tr('Close', 'Funga')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openWhatsAppHelpDesk();
            },
            child: Text(_tr('WhatsApp Support', 'Msaada wa WhatsApp')),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    LocalizationService.languageNotifier.removeListener(_languageListener);
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    for (final controller in _pinControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const textPrimary = Color(0xFF1A1A1A);
    const textSecondary = Color(0xFF6B7280);
    const fieldBg = Color(0xFFEFF5F2);
    final mediaQuery = MediaQuery.of(context);
    final topHeight = mediaQuery.size.height * 0.25;
    final bottomInset = mediaQuery.viewInsets.bottom;

    InputDecoration fieldDecoration({
      required String hint,
      required IconData suffix,
      Widget? prefix,
      Widget? suffixWidget,
    }) {
      return InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: textSecondary),
        filled: true,
        fillColor: fieldBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
        ),
        prefixIcon: prefix,
        suffixIcon: suffixWidget ?? Icon(suffix, color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      );
    }

    final headingStyle = GoogleFonts.poppins(
      fontSize: 30,
      color: textPrimary,
      fontWeight: FontWeight.w700,
      height: 1.15,
    );
    final subtitleStyle = GoogleFonts.poppins(
      color: textSecondary,
      fontSize: 14,
      height: 1.45,
      fontWeight: FontWeight.w400,
    );
    final sectionTitleStyle = GoogleFonts.poppins(
      fontWeight: FontWeight.w600,
      color: textPrimary,
      fontSize: 15,
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: topHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: AppColors.primary,
                  child: Center(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: MotionService.reducedMotionNotifier,
                      builder: (context, reducedMotion, _) {
                        return RepaintBoundary(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: _showHeroAnimation && !reducedMotion
                                  ? Lottie.asset(
                                      'assets/lottie/Login.json',
                                      key: const ValueKey('login-hero-lottie'),
                                      fit: BoxFit.contain,
                                      repeat: false,
                                      animate: true,
                                    )
                                  : Center(
                                      key: const ValueKey(
                                        'login-hero-placeholder',
                                      ),
                                      child: Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.10,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            28,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.15,
                                            ),
                                          ),
                                        ),
                                        child: const Center(
                                          child: MaliUpLogo(size: 56),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.18),
                        Colors.black.withValues(alpha: 0.38),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Material(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  Row(
                    children: [
                      Material(
                        color: const Color(0xFF25D366).withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(999),
                        child: IconButton(
                          tooltip: _tr(
                            'Emergency WhatsApp support',
                            'Msaada wa dharura WhatsApp',
                          ),
                          icon: const Icon(
                            Icons.support_agent_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: _openWhatsAppHelpDesk,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.42),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.lock_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _tr('Secure', 'Salama'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.72,
            minChildSize: 0.72,
            maxChildSize: 0.96,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(24, 20, 24, bottomInset + 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(child: MaliUpLogo(size: 54)),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          _showPinEntry
                              ? _tr('Verify PIN', 'Thibitisha PIN')
                              : _tr('Login to Mali App', 'Ingia Mali App'),
                          textAlign: TextAlign.center,
                          style: headingStyle,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          _showPinEntry
                              ? _tr(
                                  'Enter your 4-digit PIN to secure your access.',
                                  'Weka PIN yako ya tarakimu 4 ili kulinda ufikiaji wako.',
                                )
                              : _tr(
                                  'Enter your phone number to continue securely.',
                                  'Weka namba yako ya simu ili kuendelea salama.',
                                ),
                          textAlign: TextAlign.center,
                          style: subtitleStyle,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            size: 16,
                            color: textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _tr(
                                'Your transactions are protected with secure encryption.',
                                'Miamala yako inalindwa kwa usimbaji salama.',
                              ),
                              style: GoogleFonts.poppins(
                                color: textSecondary,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (_feedbackText != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: EmotionalStatusChip(
                            visible: true,
                            text: _feedbackText!,
                            tone: _feedbackTone,
                          ),
                        ),
                      if (!_showPinEntry) ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline_rounded,
                              size: 18,
                              color: textPrimary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _tr('Account Details', 'Taarifa za Akaunti'),
                              style: sectionTitleStyle,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _phoneController,
                          focusNode: _phoneFocusNode,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(12),
                          ],
                          decoration: fieldDecoration(
                            hint: _tr('Phone number', 'Namba ya simu'),
                            suffix: Icons.phone_iphone_rounded,
                            prefix: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    '🇹🇿',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '+255',
                                    style: GoogleFonts.poppins(
                                      color: textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _isLoading ? null : _handleLoginRequest,
                            child: Text(
                              _isLoading
                                  ? _tr('Checking...', 'Inahakiki...')
                                  : _tr('Continue', 'Endelea'),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              final phone = _phoneController.text.trim();
                              context.push(
                                AppRouter.registerPath,
                                extra: {'phone': phone},
                              );
                            },
                            child: Text(
                              _tr(
                                "Don't have an account? Create one",
                                'Huna akaunti? Sajili',
                              ),
                              style: GoogleFonts.poppins(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.lock_outline_rounded,
                              size: 18,
                              color: textPrimary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _tr('Enter PIN', 'Weka PIN'),
                              style: sectionTitleStyle,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            4,
                            (i) => PinDigitBox(controller: _pinControllers[i]),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _handleForgotPIN,
                            child: Text(
                              _tr('Forgot PIN?', 'Umesahau PIN?'),
                              style: GoogleFonts.poppins(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _isLoading ? null : _handlePINLogin,
                            child: Text(
                              _isLoading
                                  ? _tr('Verifying...', 'Inathibitisha...')
                                  : _tr('Login', 'Ingia'),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton(
                            onPressed: () => setState(() {
                              _showPinEntry = false;
                              for (var c in _pinControllers) {
                                c.clear();
                              }
                            }),
                            child: Text(
                              _tr(
                                'Use different number',
                                'Tumia namba nyingine',
                              ),
                              style: GoogleFonts.poppins(color: textSecondary),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          if (_successBurstTrigger > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Lottie.asset(
                    'assets/lottie/success_burst.json',
                    repeat: false,
                    onLoaded: (composition) {},
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
