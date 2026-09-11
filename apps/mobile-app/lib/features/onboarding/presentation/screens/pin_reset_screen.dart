import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/routing.dart';
import '../../../../core/constants/onboarding_strings.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_notification.dart';
import '../../domain/models/pin_reset_result.dart';
import '../../domain/validators/onboarding_validator.dart';
import '../../providers/onboarding_notifier.dart';
import '../widgets/onboarding_back_handler.dart';
import '_onboarding_scaffold.dart';

String _t({required String en, required String sw}) =>
    LocalizationService.tr(en: en, sw: sw);

/// Target of the PIN-recovery magic link (`AppRoutes.resetPin`). Reachable in
/// any auth state — usually a cold start from an emailed link. Validates the
/// token with `validatePinResetToken`, collects a new PIN, then calls
/// `confirmPinReset` and hands the user to the PIN login screen.
class PinResetScreen extends ConsumerStatefulWidget {
  const PinResetScreen({super.key, required this.token});

  final String? token;

  @override
  ConsumerState<PinResetScreen> createState() => _PinResetScreenState();
}

class _PinResetScreenState extends ConsumerState<PinResetScreen> {
  final _pinCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _pinFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _loadingToken = true;
  PinResetTokenInfo? _tokenInfo;

  bool _showConfirm = false;
  bool _pinHasError = false;
  bool _confirmHasError = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _validateToken();
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    _confirmCtrl.dispose();
    _pinFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _validateToken() async {
    final token = widget.token?.trim() ?? '';
    if (token.isEmpty) {
      setState(() {
        _loadingToken = false;
        _tokenInfo =
            const PinResetTokenInfo.invalid(PinResetTokenProblem.invalid);
      });
      return;
    }
    final info = await ref
        .read(onboardingNotifierProvider.notifier)
        .validatePinResetToken(token);
    if (!mounted) return;
    setState(() {
      _loadingToken = false;
      _tokenInfo = info;
    });
  }

  void _backToPhone() => context.go(AppRoutes.phone);

  Future<void> _openWhatsAppHelp() async {
    final sw = LocalizationService.isSwahili;
    final message = Uri.encodeComponent(
      sw
          ? 'Habari Mali Up Help Desk, nahitaji msaada wa kurejesha PIN yangu.'
          : 'Hello Mali Up Help Desk, I need help recovering my PIN.',
    );
    final uri = Uri.parse('${OnboardingStrings.helpDeskUrl}$message');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      AppNotification.error(
        context,
        _t(
          en: 'We could not open WhatsApp right now.',
          sw: 'Hatukuweza kufungua WhatsApp sasa.',
        ),
      );
    }
  }

  Future<void> _submit() async {
    final sw = LocalizationService.isSwahili;

    final pinErr =
        OnboardingValidator.validatePin(_pinCtrl.text, isSwahili: sw);
    if (pinErr != null) {
      setState(() => _pinHasError = true);
      return;
    }

    if (!_showConfirm) {
      setState(() {
        _pinHasError = false;
        _showConfirm = true;
      });
      Future.delayed(const Duration(milliseconds: 80), () {
        if (mounted) FocusScope.of(context).requestFocus(_confirmFocus);
      });
      return;
    }

    if (_confirmCtrl.text != _pinCtrl.text) {
      setState(() => _confirmHasError = true);
      return;
    }

    setState(() {
      _confirmHasError = false;
      _submitting = true;
    });

    final result = await ref
        .read(onboardingNotifierProvider.notifier)
        .confirmPinReset(
          token: widget.token!.trim(),
          phone: _tokenInfo!.phone!,
          newPin: _pinCtrl.text,
        );
    if (!mounted) return;

    switch (result) {
      case PinResetConfirmResult.ok:
        // confirmPinReset seeded the onboarding state + set pinJustReset, so
        // the router lets /pin-login through and it shows the confirmation.
        context.go(AppRoutes.pinLogin);
      case PinResetConfirmResult.linkNoLongerValid:
        setState(() {
          _submitting = false;
          _tokenInfo =
              const PinResetTokenInfo.invalid(PinResetTokenProblem.expired);
        });
      case PinResetConfirmResult.tooManyAttempts:
        setState(() => _submitting = false);
        AppNotification.error(
          context,
          _t(
            en: 'Too many attempts. Request a new recovery link.',
            sw: 'Umejaribu mara nyingi sana. Omba kiungo kipya cha kurejesha.',
          ),
        );
      case PinResetConfirmResult.failed:
        setState(() => _submitting = false);
        AppNotification.error(
          context,
          _t(
            en: 'Could not reset your PIN. Check your connection and try again.',
            sw: 'Imeshindikana kuweka upya PIN. Angalia mtandao na ujaribu tena.',
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingBackHandler(
      onBack: _backToPhone,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _content(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content() {
    if (_loadingToken) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.navyPrimary),
        ),
      );
    }
    final info = _tokenInfo!;
    if (!info.isValid) return _invalidCard(info.problem!);
    return _form(info);
  }

  // ── Invalid / expired token ────────────────────────────────────────────────

  Widget _invalidCard(PinResetTokenProblem problem) {
    final sw = LocalizationService.isSwahili;
    final (title, body) = switch (problem) {
      PinResetTokenProblem.expired => (
        _t(en: 'Link expired', sw: 'Kiungo kimekwisha muda'),
        _t(
          en: 'This recovery link has expired. Open the app and request a new '
              'one from the PIN screen.',
          sw: 'Kiungo hiki kimekwisha muda wake. Fungua programu na uombe '
              'kiungo kipya kwenye skrini ya PIN.',
        ),
      ),
      PinResetTokenProblem.used => (
        _t(en: 'Link already used', sw: 'Kiungo kimetumika'),
        _t(
          en: 'This recovery link has already been used. Request a new one if '
              'you still need to reset your PIN.',
          sw: 'Kiungo hiki tayari kimetumika. Omba kiungo kipya kama bado '
              'unahitaji kuweka upya PIN.',
        ),
      ),
      _ => (
        _t(en: 'Invalid link', sw: 'Kiungo si sahihi'),
        _t(
          en: 'We could not read this recovery link. Open the app and request '
              'a new one.',
          sw: 'Hatukuweza kusoma kiungo hiki. Fungua programu na uombe kiungo '
              'kipya.',
        ),
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          sw ? 'Msaada wa PIN 🔐' : 'PIN Recovery 🔐',
          style: GoogleFonts.dmSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.navyPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3CD),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFFD60A).withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF856404),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: const Color(0xFF856404),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _backToPhone,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navyPrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              sw ? 'Rudi kuanza' : 'Back to start',
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        TextButton(
          onPressed: _openWhatsAppHelp,
          child: Text(
            sw ? 'Wasiliana na Msaada' : 'Contact Support',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.navySecondary,
            ),
          ),
        ),
      ],
    );
  }

  // ── New PIN form ───────────────────────────────────────────────────────────

  Widget _form(PinResetTokenInfo info) {
    final sw = LocalizationService.isSwahili;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          sw ? 'Weka PIN mpya' : 'Set a new PIN',
          style: GoogleFonts.dmSans(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.navyPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _showConfirm
              ? (sw
                    ? 'Rudia PIN yako mpya ili kuithibitisha.'
                    : 'Re-enter your new PIN to confirm it.')
              : (sw
                    ? 'Chagua PIN mpya ya tarakimu 4 kwa akaunti ya '
                          '${info.maskedEmail}.'
                    : 'Choose a new 4-digit PIN for the account '
                          '${info.maskedEmail}.'),
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: AppColors.textMuted,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 40),
        Center(
          child: _showConfirm
              ? PinDotsInput(
                  key: const ValueKey('confirm'),
                  controller: _confirmCtrl,
                  focusNode: _confirmFocus,
                  hasError: _confirmHasError,
                  enabled: !_submitting,
                  onComplete: _submit,
                  onChanged: (_) {
                    if (_confirmHasError) {
                      setState(() => _confirmHasError = false);
                    }
                  },
                )
              : PinDotsInput(
                  key: const ValueKey('pin'),
                  controller: _pinCtrl,
                  focusNode: _pinFocus,
                  hasError: _pinHasError,
                  enabled: !_submitting,
                  onComplete: _submit,
                  onChanged: (_) {
                    if (_pinHasError) setState(() => _pinHasError = false);
                  },
                ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.navyPrimary,
              elevation: 4,
              shadowColor: AppColors.primary.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.navyPrimary,
                    ),
                  )
                : Text(
                    _showConfirm
                        ? (sw ? 'Weka upya PIN' : 'Reset PIN')
                        : (sw ? 'Endelea' : 'Continue'),
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
        if (_showConfirm && !_submitting)
          TextButton(
            onPressed: () {
              _confirmCtrl.clear();
              setState(() {
                _showConfirm = false;
                _confirmHasError = false;
              });
              Future.delayed(const Duration(milliseconds: 80), () {
                if (mounted) FocusScope.of(context).requestFocus(_pinFocus);
              });
            },
            child: Text(
              sw ? 'Rudi nyuma' : 'Go back',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.navySecondary,
              ),
            ),
          ),
      ],
    );
  }
}
