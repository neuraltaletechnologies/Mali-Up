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
        if (e.code != 'wrong-password' && e.code != 'invalid-credential') rethrow;
        try {
          await _auth.signInWithEmailAndPassword(email: email, password: pin);
        } catch (_) {
          rethrow; // Rethrow the original if fallback fails
        }
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
      debugPrint('FIREBASE AUTH ERROR: ${e.code} - ${e.message}');
      setState(() => _isLoading = false);
      String message = switch (e.code) {
        'wrong-password' || 'invalid-credential' => _tr(
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
    final theme = Theme.of(context);
    final textPrimary = AppColors.textPrimary;
    final textSecondary = AppColors.textSecondary;
    final fieldBg = AppColors.surface;
    final mediaQuery = MediaQuery.of(context);
    final topHeight = mediaQuery.size.height * 0.35;
    final bottomInset = mediaQuery.viewInsets.bottom;

    InputDecoration fieldDecoration({
      required String hint,
      required IconData suffix,
      Widget? prefix,
      Widget? suffixWidget,
    }) {
      return InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        filled: true,
        fillColor: fieldBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        prefixIcon: prefix != null
            ? Padding(
                padding: const EdgeInsets.only(left: 12),
                child: prefix,
              )
            : null,
        suffixIcon: suffixWidget ?? Icon(suffix, color: AppColors.textSecondary, size: 20),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      );
    }

    final headingStyle = GoogleFonts.poppins(
      fontSize: 28,
      color: textPrimary,
      fontWeight: FontWeight.w800,
      height: 1.15,
      letterSpacing: -0.5,
    );
    final subtitleStyle = GoogleFonts.poppins(
      color: textSecondary,
      fontSize: 14,
      height: 1.5,
      fontWeight: FontWeight.w400,
    );
    final sectionTitleStyle = GoogleFonts.poppins(
      fontWeight: FontWeight.w700,
      color: textPrimary,
      fontSize: 14,
      letterSpacing: 0.3,
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Premium gradient header with subtle overlay
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: topHeight,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primaryDark,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(48),
                  bottomRight: Radius.circular(48),
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Subtle pattern overlay
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.03,
                      child: Image.asset(
                        'assets/images/pattern.png',
                        repeat: ImageRepeat.repeat,
                      ),
                    ),
                  ),
                  Center(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: MotionService.reducedMotionNotifier,
                      builder: (context, reducedMotion, _) {
                        return RepaintBoundary(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
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
                                          color: Colors.white.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(28),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.2),
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
                ],
              ),
            ),
          ),

          // Top navigation bar with glass effect
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button with subtle glass effect
                  Material(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  // WhatsApp support and secure badge
                  Row(
                    children: [
                      // WhatsApp support button
                      Material(
                        color: const Color(0xFF25D366).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _openWhatsAppHelpDesk,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            child: const Icon(
                              Icons.support_agent_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Secure badge with glass effect
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
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
                                fontSize: 13,
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
          // Main content sheet
          DraggableScrollableSheet(
            initialChildSize: 0.68,
            minChildSize: 0.68,
            maxChildSize: 0.96,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset + 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      // Logo
                      const Center(child: MaliUpLogo(size: 48)),
                      const SizedBox(height: 16),
                      // Title
                      Center(
                        child: Text(
                          _showPinEntry
                              ? _tr('Verify PIN', 'Thibitisha PIN')
                              : _tr('Welcome Back', 'Karibu Tena'),
                          textAlign: TextAlign.center,
                          style: headingStyle,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Subtitle
                      Center(
                        child: Text(
                          _showPinEntry
                              ? _tr(
                                  'Enter your 4-digit PIN to access your account.',
                                  'Weka PIN yako ya tarakimu 4 ili kufikia akaunti yako.',
                                )
                              : _tr(
                                  'Enter your phone number to continue securely.',
                                  'Weka namba yako ya simu ili kuendelea salama.',
                                ),
                          textAlign: TextAlign.center,
                          style: subtitleStyle,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Security badge
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.shield_outlined,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _tr(
                                  'Your transactions are protected with bank-level encryption.',
                                  'Miamala yako inalindwa kwa usimbaji salama.',
                                ),
                                style: GoogleFonts.poppins(
                                  color: textSecondary,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Feedback message
                      if (_feedbackText != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: EmotionalStatusChip(
                            visible: true,
                            text: _feedbackText!,
                            tone: _feedbackTone,
                          ),
                        ),
                      // Phone entry section
                      if (!_showPinEntry) ...[
                        Row(
                          children: [
                            Icon(
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
                        const SizedBox(height: 12),
                        // Phone number field
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
                            prefix: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🇹🇿', style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 6),
                                Text(
                                  '+255',
                                  style: GoogleFonts.poppins(
                                    color: textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Continue button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: AppColors.primary.withValues(alpha: 0.3),
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
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Register link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _tr('Do not have an account? ', 'Huna akaunti? '),
                              style: GoogleFonts.poppins(
                                color: textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.push(AppRouter.registerPath),
                              style: TextButton.styleFrom(padding: EdgeInsets.zero),
                              child: Text(
                                _tr('Register', 'Jisajili'),
                                style: GoogleFonts.poppins(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // PIN entry section
                        Row(
                          children: [
                            Icon(
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
                        const SizedBox(height: 16),
                        // PIN digit boxes
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            4,
                            (i) => PinDigitBox(controller: _pinControllers[i]),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Forgot PIN link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _handleForgotPIN,
                            style: TextButton.styleFrom(padding: EdgeInsets.zero),
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
                        const SizedBox(height: 16),
                        // Login button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: AppColors.primary.withValues(alpha: 0.3),
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
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Change number link
                        Center(
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _showPinEntry = false;
                                for (var c in _pinControllers) {
                                  c.clear();
                                }
                              });
                            },
                            style: TextButton.styleFrom(padding: EdgeInsets.zero),
                            child: Text(
                              _tr('Use different number', 'Tumia namba nyingine'),
                              style: GoogleFonts.poppins(
                                color: textSecondary,
                                fontSize: 14,
                              ),
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
