import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/onboarding_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/onboarding_state.dart';
import '../../domain/validators/onboarding_validator.dart';
import '../../providers/onboarding_notifier.dart';
import '../../../../config/routing.dart';
import '_onboarding_scaffold.dart';

class OtpVerifyScreen extends ConsumerStatefulWidget {
  const OtpVerifyScreen({super.key});

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();

  late final AnimationController _animCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    await notifier.verifyOtp(_codeCtrl.text.trim());
    if (!mounted) return;

    final s = ref.read(onboardingNotifierProvider);
    if (s.currentStep == OnboardingStep.returningUser) {
      context.go(AppRoutes.returning);
    } else if (s.currentStep == OnboardingStep.newUserInfo) {
      context.go(AppRoutes.newUser);
    }
    // else: errorMessage is set; the screen stays so the user can retry.
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);
    final sw = state.isSwahili;
    // Mask the phone so only the last 4 digits are visible.
    final phone = state.phone;
    final masked = phone.length > 4
        ? '${phone.substring(0, phone.length - 4).replaceAll(RegExp(r'\d'), '*')}${phone.substring(phone.length - 4)}'
        : phone;

    return OnboardingScaffold(
      currentStep: 3,
      onBack: () => context.go(AppRoutes.phone),
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // ── Title ──────────────────────────────────────────────────
                Text(
                  OnboardingStrings.s(sw,
                      en: OnboardingStrings.otpTitleEn,
                      sw: OnboardingStrings.otpTitleSw),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.navyPrimary,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  OnboardingStrings.s(sw,
                      en: OnboardingStrings.otpSubEn(masked),
                      sw: OnboardingStrings.otpSubSw(masked)),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
                const SizedBox(height: 40),

                // ── 6-digit code field ─────────────────────────────────────
                _OtpCodeField(
                  controller: _codeCtrl,
                  isSwahili: sw,
                  isLocked: state.isOtpLocked,
                  onComplete: () => _submit(),
                  validator: (v) =>
                      OnboardingValidator.validateOtp(v ?? '', isSwahili: sw),
                ),
                const SizedBox(height: 32),

                // ── Resend link ────────────────────────────────────────────
                _ResendRow(
                  cooldown: state.resendCooldownSeconds,
                  isSwahili: sw,
                  isLocked: state.isLoading,
                  onResend: () =>
                      ref.read(onboardingNotifierProvider.notifier).resendOtp(),
                ),
                const SizedBox(height: 24),

                if (state.errorMessage != null) ...[
                  OnboardingErrorBanner(message: state.errorMessage!),
                  const SizedBox(height: 16),
                ],

                OnboardingPrimaryButton(
                  label: OnboardingStrings.s(sw,
                      en: OnboardingStrings.otpVerifyCtaEn,
                      sw: OnboardingStrings.otpVerifyCtaSw),
                  onPressed:
                      (state.isLoading || state.isOtpLocked) ? null : _submit,
                  isLoading: state.isLoading,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 6-digit OTP input ─────────────────────────────────────────────────────────

class _OtpCodeField extends StatelessWidget {
  const _OtpCodeField({
    required this.controller,
    required this.isSwahili,
    required this.isLocked,
    required this.onComplete,
    required this.validator,
  });

  final TextEditingController controller;
  final bool isSwahili;
  final bool isLocked;
  final VoidCallback onComplete;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          OnboardingStrings.s(isSwahili,
              en: OnboardingStrings.otpFieldLabelEn,
              sw: OnboardingStrings.otpFieldLabelSw),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.navyPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: !isLocked,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          maxLength: 6,
          autofocus: true,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onFieldSubmitted: (_) => onComplete(),
          onChanged: (v) {
            if (v.length == 6) onComplete();
          },
          validator: validator,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: 10,
            color: AppColors.navyPrimary,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: isLocked ? AppColors.disabled : AppColors.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.navyPrimary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.error, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Resend row ────────────────────────────────────────────────────────────────

class _ResendRow extends StatelessWidget {
  const _ResendRow({
    required this.cooldown,
    required this.isSwahili,
    required this.isLocked,
    required this.onResend,
  });

  final int cooldown;
  final bool isSwahili;
  final bool isLocked;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final canResend = cooldown == 0 && !isLocked;

    return GestureDetector(
      onTap: canResend ? onResend : null,
      child: Text(
        cooldown > 0
            ? OnboardingStrings.s(isSwahili,
                en: OnboardingStrings.otpResendCooldownEn(cooldown),
                sw: OnboardingStrings.otpResendCooldownSw(cooldown))
            : OnboardingStrings.s(isSwahili,
                en: OnboardingStrings.otpResendLinkEn,
                sw: OnboardingStrings.otpResendLinkSw),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: canResend ? AppColors.navyPrimary : AppColors.textDisabled,
          decoration: canResend ? TextDecoration.underline : null,
          decorationColor: AppColors.navyPrimary,
        ),
      ),
    );
  }
}
