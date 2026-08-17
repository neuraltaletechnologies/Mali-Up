import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/emotional_design.dart';
import '../../../../shared/widgets/pin_digit_box.dart';
import '../../../../config/routing.dart';
import '../../../../core/services/default_context_routing_service.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/services/pin_attempt_throttle.dart';
import '../../../../core/constants/onboarding_strings.dart';
import '../../../../core/utils/phone_number_utils.dart';
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
  static const _loginThrottle = PinAttemptThrottle('login_pin');
  late final VoidCallback _languageListener;
  AppLanguage _language = AppLanguage.english;

  bool _showPinEntry =
      false; // Flag to switch between phone and PIN entry views
  bool _isLoading = false;
  String? _normalizedPhone;
  List<String> _authEmailsForSignIn = const [];
  String? _recoveryEmail;
  String? _feedbackText;
  EmotionalStatusTone _feedbackTone = EmotionalStatusTone.neutral;
  int _successBurstTrigger = 0;

  final TextEditingController _phoneController = TextEditingController();
  final List<TextEditingController> _pinControllers = List.generate(
    4,
    (i) => TextEditingController(),
  );
  final List<FocusNode> _pinFocusNodes = List.generate(4, (_) => FocusNode());
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

  bool _isValidEmail(String value) {
    final normalized = value.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalized);
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
        'Hello Mali Up Help Desk, I need emergency support with login.',
        'Habari Mali Up Help Desk, nahitaji msaada wa dharura wa kuingia.',
      ),
    );
    final uri = Uri.parse('${OnboardingStrings.helpDeskUrl}$message');
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
      _normalizedPhone = PhoneNumberUtils.canonical(digitsOnly);
    });

    try {
      final userDoc = await _lookupUserByPhone(digitsOnly);

      if (userDoc == null) {
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

      final profile = userDoc.data();
      final recoveryEmail =
          ((profile['recoveryEmail'] ?? profile['email']) as String?)
              ?.trim()
              .toLowerCase();
      final authEmails = <String>{
        PhoneNumberUtils.authEmail(_normalizedPhone ?? digitsOnly),
        for (final field in ['authEmail', 'email', 'recoveryEmail'])
          if ((profile[field] as String?)?.trim().isNotEmpty == true)
            (profile[field] as String).trim().toLowerCase(),
      }.toList(growable: false);

      setState(() {
        _showPinEntry = true;
        _isLoading = false;
        _recoveryEmail = recoveryEmail;
        _authEmailsForSignIn = authEmails;
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
      final errorMessage = switch (e) {
        FirebaseException(code: 'permission-denied') => _tr(
          'Access denied by server rules. Please contact support or try again later.',
          'Ufikiaji umekataliwa na sheria za seva. Tafadhali wasiliana na msaada au jaribu tena baadaye.',
        ),
        FirebaseException(code: 'unavailable') => _tr(
          'Service is temporarily unavailable. Please try again shortly.',
          'Huduma haipatikani kwa sasa. Tafadhali jaribu tena muda mfupi ujao.',
        ),
        FirebaseException(code: 'network-request-failed') => _tr(
          'No internet connection. Please check your network and try again.',
          'Hakuna muunganisho wa intaneti. Tafadhali angalia mtandao wako na ujaribu tena.',
        ),
        _ => _tr(
          'Connection error. Please try again.',
          'Hitilafu ya muunganisho. Tafadhali jaribu tena.',
        ),
      };
      await _NotificationHelper.showError(context, errorMessage);
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

    final throttleKey = _normalizedPhone ?? '';
    final lockout = await _loginThrottle.lockoutRemaining(throttleKey);
    if (!mounted) return;
    if (lockout != null) {
      await _NotificationHelper.showError(
        context,
        _tr(
          'Too many attempts. Try again in ${_formatLockout(lockout)}.',
          'Majaribio mengi sana. Jaribu tena baada ya ${_formatLockout(lockout)}.',
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final authPassword = buildAuthPasswordFromPin(
      phone: _normalizedPhone ?? '',
      pin: pin,
    );

    try {
      FirebaseAuthException? lastError;
      final candidates = _authEmailsForSignIn.isNotEmpty
          ? _authEmailsForSignIn
          : [PhoneNumberUtils.authEmail(_normalizedPhone ?? '')];
      for (final email in candidates) {
        try {
          await _auth.signInWithEmailAndPassword(
            email: email,
            password: authPassword,
          );
          lastError = null;
          break;
        } on FirebaseAuthException catch (e) {
          lastError = e;
          if (e.code != 'user-not-found' &&
              e.code != 'invalid-credential' &&
              e.code != 'wrong-password') {
            rethrow;
          }
        }
      }
      if (lastError != null) throw lastError;
      await _loginThrottle.recordSuccess(throttleKey);
      if (!mounted) return;

      _setFeedback(
        _tr('Login successful!', 'Umeingia kikamilifu!'),
        EmotionalStatusTone.success,
      );
      _triggerSuccessBurst();
      await Future.delayed(const Duration(milliseconds: 500));
      await _goToPostLoginLanding();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        await _loginThrottle.recordFailure(throttleKey);
      }
      setState(() => _isLoading = false);
      final String message = switch (e.code) {
        'wrong-password' || 'invalid-credential' => _tr(
          'Incorrect PIN. Please try again.',
          'PIN si sahihi. Jaribu tena.',
        ),
        'user-not-found' => _tr(
          'Account not found. Please go back and check your phone number.',
          'Akaunti haijapatikana. Rudi nyuma na uangalie namba yako ya simu.',
        ),
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
          'Something went wrong. Please try again or contact support if it continues.',
          'Kuna tatizo. Tafadhali jaribu tena au wasiliana na msaada ikiwa litaendelea.',
        ),
      );
    }
  }

  String _formatLockout(Duration d) {
    if (d.inMinutes >= 1) return '${(d.inSeconds / 60).ceil()} min';
    return '${d.inSeconds}s';
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _lookupUserByPhone(
    String phone,
  ) async {
    final variants = PhoneNumberUtils.lookupVariants(phone);
    for (final field in ['phone', 'phoneNumber']) {
      for (final variant in variants) {
        final snapshot = await _firestore
            .collection('users')
            .where(field, isEqualTo: variant)
            .limit(1)
            .get();
        if (snapshot.docs.isNotEmpty) return snapshot.docs.first;
      }
    }
    return null;
  }

  Future<void> _handleForgotPIN() async {
    final emailController = TextEditingController(text: _recoveryEmail ?? '');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_tr('Recover PIN', 'Rejesha PIN')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _tr(
                'Enter your recovery email to receive a PIN reset email.',
                'Weka barua pepe ya urejeshaji ili upokee barua pepe ya kurejesha PIN.',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofocus: true,
              decoration: InputDecoration(
                hintText: _tr('you@example.com', 'wewe@example.com'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(_tr('Cancel', 'Ghairi')),
          ),
          ElevatedButton(
            onPressed: () async {
              final enteredEmail = emailController.text.trim().toLowerCase();
              if (!_isValidEmail(enteredEmail)) {
                await _NotificationHelper.showError(
                  dialogContext,
                  _tr(
                    'Please enter a valid email address.',
                    'Tafadhali weka barua pepe sahihi.',
                  ),
                );
                return;
              }

              try {
                await _auth.sendPasswordResetEmail(email: enteredEmail);
                if (!mounted || !dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _tr(
                          'Recovery email sent. Check your inbox.',
                          'Barua pepe ya urejeshaji imetumwa. Angalia kikasha chako.',
                        ),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } on FirebaseAuthException catch (e) {
                final message = switch (e.code) {
                  'user-not-found' => _tr(
                    'No account found for that email.',
                    'Hakuna akaunti iliyo na barua pepe hiyo.',
                  ),
                  'invalid-email' => _tr(
                    'Invalid email address.',
                    'Barua pepe si sahihi.',
                  ),
                  _ => _tr(
                    'Could not send recovery email right now.',
                    'Imeshindikana kutuma barua pepe ya urejeshaji kwa sasa.',
                  ),
                };
                if (dialogContext.mounted) {
                  await _NotificationHelper.showError(dialogContext, message);
                }
              } catch (_) {
                if (dialogContext.mounted) {
                  await _NotificationHelper.showError(
                    dialogContext,
                    _tr(
                      'Could not send recovery email right now.',
                      'Imeshindikana kutuma barua pepe ya urejeshaji kwa sasa.',
                    ),
                  );
                }
              }
            },
            child: Text(_tr('Send Email', 'Tuma Barua Pepe')),
          ),
        ],
      ),
    );

    emailController.dispose();
  }

  @override
  void dispose() {
    LocalizationService.languageNotifier.removeListener(_languageListener);
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    for (final controller in _pinControllers) {
      controller.dispose();
    }
    for (final node in _pinFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const textPrimary = AppColors.textPrimary;
    const textSecondary = AppColors.textSecondary;
    const fieldBg = AppColors.surface;
    final mediaQuery = MediaQuery.of(context);
    final topHeight = mediaQuery.size.height * 0.35;

    InputDecoration fieldDecoration({
      required String hint,
      required IconData suffix,
      Widget? prefix,
      Widget? suffixWidget,
    }) {
      return InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.dmSans(color: AppColors.textMuted),
        filled: true,
        fillColor: fieldBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        prefixIcon: prefix != null
            ? Padding(padding: const EdgeInsets.only(left: 12), child: prefix)
            : null,
        suffixIcon:
            suffixWidget ??
            Icon(suffix, color: AppColors.textSecondary, size: 20),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      );
    }

    final headingStyle = GoogleFonts.dmSans(
      fontSize: 28,
      color: textPrimary,
      fontWeight: FontWeight.w800,
      height: 1.15,
      letterSpacing: -0.5,
    );
    final subtitleStyle = GoogleFonts.dmSans(
      color: textSecondary,
      fontSize: 14,
      height: 1.5,
      fontWeight: FontWeight.w400,
    );
    final sectionTitleStyle = GoogleFonts.dmSans(
      fontWeight: FontWeight.w700,
      color: textPrimary,
      fontSize: 14,
      letterSpacing: 0.3,
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Header image
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: topHeight,
            child: ClipRect(
              child: Image.asset(
                'assets/Picture/sign_up.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),

          // Top navigation bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => context.go(AppRouter.registerPath),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      padding: const EdgeInsets.all(10),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _openWhatsAppHelpDesk,
                    icon: const Icon(
                      Icons.headset_mic_outlined,
                      color: Colors.white,
                      size: 15,
                    ),
                    label: Text(
                      _tr('Help', 'Msaada'),
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Main content sheet — "bottom content panel"
          DraggableScrollableSheet(
            initialChildSize: 0.68,
            minChildSize: 0.68,
            maxChildSize: 0.8,
            builder: (context, scrollController) {
              return Container(
                clipBehavior: Clip.hardEdge,
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
                child: NotificationListener<OverscrollIndicatorNotification>(
                  onNotification: (overscroll) {
                    overscroll.disallowIndicator();
                    return true;
                  },
                  child: SingleChildScrollView(
                    controller: scrollController,
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
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
                              const Icon(
                                Icons.person_outline_rounded,
                                size: 18,
                                color: textPrimary,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _tr('Account Details', 'Taarifa za Akaunti'),
                                  style: sectionTitleStyle,
                                ),
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
                                  Text(
                                    '🇹🇿',
                                    style: GoogleFonts.dmSans(fontSize: 18),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '+255',
                                    style: GoogleFonts.dmSans(
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
                                shadowColor: AppColors.primary.withValues(
                                  alpha: 0.3,
                                ),
                                minimumSize: const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _isLoading
                                  ? null
                                  : _handleLoginRequest,
                              child: Text(
                                _isLoading
                                    ? _tr('Checking...', 'Inahakiki...')
                                    : _tr('Continue', 'Endelea'),
                                style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Register link
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                _tr(
                                  'Do not have an account? ',
                                  'Huna akaunti? ',
                                ),
                                style: GoogleFonts.dmSans(
                                  color: textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    context.push(AppRouter.registerPath),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                ),
                                child: Text(
                                  _tr('Register', 'Jisajili'),
                                  style: GoogleFonts.dmSans(
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
                              const Icon(
                                Icons.lock_outline_rounded,
                                size: 18,
                                color: textPrimary,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _tr('Enter PIN', 'Weka PIN'),
                                  style: sectionTitleStyle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // PIN digit boxes — blocked + dimmed while verifying
                          IgnorePointer(
                            ignoring: _isLoading,
                            child: Opacity(
                              opacity: _isLoading ? 0.45 : 1.0,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: List.generate(
                                  4,
                                  (i) => PinDigitBox(
                                    controller: _pinControllers[i],
                                    previousController: i > 0
                                        ? _pinControllers[i - 1]
                                        : null,
                                    focusNode: _pinFocusNodes[i],
                                    previousFocusNode: i > 0
                                        ? _pinFocusNodes[i - 1]
                                        : null,
                                    nextFocusNode: i < 3
                                        ? _pinFocusNodes[i + 1]
                                        : null,
                                    autoFocus: i == 0,
                                    isLast: i == 3,
                                    readOnly: _isLoading,
                                    onComplete: i == 3
                                        ? () {
                                            if (!_isLoading) {
                                              _handlePINLogin();
                                            }
                                          }
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Verification progress indicator
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: _isLoading
                                ? Padding(
                                    key: const ValueKey('verifying'),
                                    padding: const EdgeInsets.only(top: 16),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Flexible(
                                          child: Text(
                                            _tr(
                                              'Verifying your PIN…',
                                              'Inathibitisha PIN yako…',
                                            ),
                                            style: GoogleFonts.dmSans(
                                              color: textSecondary,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : const SizedBox(
                                    key: ValueKey('idle'),
                                    height: 16,
                                  ),
                          ),
                          // Forgot PIN link (hidden while verifying)
                          if (!_isLoading)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _handleForgotPIN,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                ),
                                child: Text(
                                  _tr('Forgot PIN?', 'Umesahau PIN?'),
                                  style: GoogleFonts.dmSans(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
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
                                  for (final c in _pinControllers) {
                                    c.clear();
                                  }
                                });
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(
                                _tr(
                                  'Use different number',
                                  'Tumia namba nyingine',
                                ),
                                style: GoogleFonts.dmSans(
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
                ),
              );
            },
          ),
          if (_successBurstTrigger > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Lottie.asset(
                    'assets/lottie/DATA.json',
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
