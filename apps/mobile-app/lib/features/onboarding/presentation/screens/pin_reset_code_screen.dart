import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/routing.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../i18n/gen/strings.g.dart';
import '../../../../shared/widgets/app_notification.dart';
import '../../domain/models/pin_reset_result.dart';
import '../../domain/validators/onboarding_validator.dart';
import '../../providers/onboarding_notifier.dart';
import '../widgets/onboarding_back_handler.dart';
import '_onboarding_scaffold.dart';

/// Code-based PIN recovery (`AppRoutes.resetPinCode`), opened from the
/// "Forgot PIN" sheet on the PIN login screen once `requestPinResetOtp` has
/// sent a 6-digit code by SMS (and email, when one is on file). The reset
/// code, the new PIN and its confirmation are all entered on this one page;
/// `confirmPinResetOtp` then sets the new PIN-derived password and the user
/// lands back on the PIN login screen. The phone comes from onboarding state.
class PinResetCodeScreen extends ConsumerStatefulWidget {
  const PinResetCodeScreen({super.key, this.maskedPhone, this.maskedEmail});

  final String? maskedPhone;
  final String? maskedEmail;

  @override
  ConsumerState<PinResetCodeScreen> createState() => _PinResetCodeScreenState();
}

class _PinResetCodeScreenState extends ConsumerState<PinResetCodeScreen> {
  static const _resendCooldown = 60;

  final _codeCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _pinFocus = FocusNode();
  final _confirmFocus = FocusNode();

  String? _codeError;
  bool _pinHasError = false;
  String? _confirmError;
  bool _submitting = false;
  bool _resending = false;

  int _cooldown = _resendCooldown;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeCtrl.dispose();
    _pinCtrl.dispose();
    _confirmCtrl.dispose();
    _pinFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = _resendCooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _cooldown--);
      if (_cooldown <= 0) timer.cancel();
    });
  }

  void _backToLogin() => context.go(AppRoutes.pinLogin);

  Future<void> _resend() async {
    setState(() => _resending = true);
    final result = await ref
        .read(onboardingNotifierProvider.notifier)
        .requestPinResetCode();
    if (!mounted) return;
    setState(() => _resending = false);
    if (result.status == PinResetCodeRequestStatus.sent) {
      _codeCtrl.clear();
      _startCooldown();
      AppNotification.success(context, t.pinResetCode.resent);
    } else {
      AppNotification.error(context, t.pinResetCode.sendFailed);
    }
  }

  Future<void> _submit() async {
    final code = _codeCtrl.text.trim();
    final codeOk = RegExp(r'^\d{6}$').hasMatch(code);
    final pinOk =
        OnboardingValidator.validatePin(
          _pinCtrl.text,
          isSwahili: LocalizationService.isSwahili,
        ) ==
        null;
    final matches = _confirmCtrl.text == _pinCtrl.text;

    setState(() {
      _codeError = codeOk ? null : t.pinResetCode.codeError;
      _pinHasError = !pinOk;
      _confirmError = pinOk && !matches ? t.pinResetCode.pinMismatch : null;
    });
    if (!codeOk || !pinOk || !matches) return;

    setState(() => _submitting = true);
    final result = await ref
        .read(onboardingNotifierProvider.notifier)
        .confirmPinResetCode(code: code, newPin: _pinCtrl.text);
    if (!mounted) return;

    if (result.status == PinResetCodeConfirmStatus.ok) {
      // confirmPinResetCode set pinJustReset, so /pin-login shows the toast.
      context.go(AppRoutes.pinLogin);
      return;
    }

    setState(() => _submitting = false);
    switch (result.status) {
      case PinResetCodeConfirmStatus.wrongCode:
        final left = result.remainingAttempts;
        setState(() {
          _codeError = left == null
              ? t.pinResetCode.wrongCodeNoCount
              : t.pinResetCode.wrongCode(count: left);
        });
      case PinResetCodeConfirmStatus.expired:
        setState(() => _codeError = t.pinResetCode.expired);
      case PinResetCodeConfirmStatus.tooManyAttempts:
        setState(() => _codeError = t.pinResetCode.tooManyAttempts);
      case PinResetCodeConfirmStatus.failed:
      case PinResetCodeConfirmStatus.ok:
        AppNotification.error(context, t.pinResetCode.failed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = ref.watch(onboardingNotifierProvider.select((s) => s.phone));
    return OnboardingBackHandler(
      onBack: _backToLogin,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: phone.isEmpty ? _missingPhone() : _form(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Reached without a phone in state (e.g. the app was restarted mid-flow).
  Widget _missingPhone() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(t.pinResetCode.title, style: _titleStyle),
      const SizedBox(height: 24),
      _primaryButton(label: t.pinResetCode.backToLogin, onPressed: _backToLogin),
    ],
  );

  Widget _form() {
    final phone = widget.maskedPhone;
    final email = widget.maskedEmail;
    final subtitle = phone == null
        ? t.pinResetCode.sentGeneric
        : email == null
        ? t.pinResetCode.sentTo(phone: phone)
        : t.pinResetCode.sentToBoth(phone: phone, email: email);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.pinResetCode.title, style: _titleStyle),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: AppColors.textMuted,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),

        _label(t.pinResetCode.codeLabel),
        TextField(
          controller: _codeCtrl,
          autofocus: true,
          enabled: !_submitting,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: GoogleFonts.dmSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: 10,
            color: AppColors.navyPrimary,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '••••••',
            errorText: _codeError,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onChanged: (value) {
            if (_codeError != null) setState(() => _codeError = null);
            if (value.length == 6) _pinFocus.requestFocus();
          },
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _cooldown > 0 || _resending || _submitting
                ? null
                : _resend,
            child: Text(
              _cooldown > 0
                  ? t.pinResetCode.resendIn(seconds: _cooldown)
                  : t.pinResetCode.resend,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        _label(t.pinResetCode.newPinLabel),
        Center(
          child: PinDotsInput(
            controller: _pinCtrl,
            focusNode: _pinFocus,
            autofocus: false,
            hasError: _pinHasError,
            enabled: !_submitting,
            onComplete: _confirmFocus.requestFocus,
            onChanged: (_) {
              if (_pinHasError) setState(() => _pinHasError = false);
            },
          ),
        ),
        const SizedBox(height: 28),

        _label(t.pinResetCode.confirmPinLabel),
        Center(
          child: PinDotsInput(
            controller: _confirmCtrl,
            focusNode: _confirmFocus,
            autofocus: false,
            hasError: _confirmError != null,
            enabled: !_submitting,
            onComplete: _submit,
            onChanged: (_) {
              if (_confirmError != null) setState(() => _confirmError = null);
            },
          ),
        ),
        if (_confirmError != null) ...[
          const SizedBox(height: 10),
          Text(
            _confirmError!,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.error),
          ),
        ],
        const SizedBox(height: 36),

        _primaryButton(
          label: t.pinResetCode.submit,
          onPressed: _submitting ? null : _submit,
          loading: _submitting,
        ),
        TextButton(
          onPressed: _submitting ? null : _backToLogin,
          child: Text(
            t.pinResetCode.backToLogin,
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

  TextStyle get _titleStyle => GoogleFonts.dmSans(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.navyPrimary,
    letterSpacing: -0.4,
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.navyPrimary,
      ),
    ),
  );

  Widget _primaryButton({
    required String label,
    required VoidCallback? onPressed,
    bool loading = false,
  }) => SizedBox(
    height: 52,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.navyPrimary,
        elevation: 4,
        shadowColor: AppColors.primary.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.navyPrimary,
              ),
            )
          : Text(
              label,
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 16),
            ),
    ),
  );
}
