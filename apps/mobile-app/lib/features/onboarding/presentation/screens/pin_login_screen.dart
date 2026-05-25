import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/onboarding_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/emotional_design.dart';
import '../../domain/validators/onboarding_validator.dart';
import '../../providers/onboarding_notifier.dart';
import '../../../../config/routing.dart';
import '_onboarding_scaffold.dart';

/// Screen 4A — shown when an existing user (owner or activated team member)
/// enters their phone number and their account is found.
/// They sign in using their 4-digit PIN.
class PinLoginScreen extends ConsumerStatefulWidget {
  const PinLoginScreen({super.key});

  @override
  ConsumerState<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends ConsumerState<PinLoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _pinCtrl = TextEditingController();

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
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final pin = _pinCtrl.text.trim();
    await ref.read(onboardingNotifierProvider.notifier).loginWithPin(pin);
    if (!mounted) return;
    final s = ref.read(onboardingNotifierProvider);
    if (s.isComplete) context.go(AppRoutes.success);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);
    final sw = state.isSwahili;
    final name = state.firstName.isNotEmpty ? state.firstName : '';

    return OnboardingScaffold(
      currentStep: 4,
      lottieScene: EmotionalLottieScene.authWelcome,
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

                // ── Greeting ──────────────────────────────────────────────
                Text(
                  name.isNotEmpty
                      ? OnboardingStrings.s(sw,
                          en: OnboardingStrings.pinLoginGreetEn(name),
                          sw: OnboardingStrings.pinLoginGreetSw(name))
                      : OnboardingStrings.s(sw,
                          en: 'Welcome back!',
                          sw: 'Karibu tena!'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.navyPrimary,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  OnboardingStrings.s(sw,
                      en: OnboardingStrings.pinLoginSubEn,
                      sw: OnboardingStrings.pinLoginSubSw),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
                const SizedBox(height: 40),

                // ── Business card ─────────────────────────────────────────
                if (state.businessName.isNotEmpty) ...[
                  _BusinessBadge(
                    businessName: state.businessName,
                    role: state.role,
                  ),
                  const SizedBox(height: 32),
                ],

                // ── PIN field ─────────────────────────────────────────────
                _PinField(
                  controller: _pinCtrl,
                  isSwahili: sw,
                  onComplete: _submit,
                  validator: (v) =>
                      OnboardingValidator.validatePin(v ?? '', isSwahili: sw),
                ),
                const SizedBox(height: 32),

                if (state.errorMessage != null) ...[
                  OnboardingErrorBanner(message: state.errorMessage!),
                  const SizedBox(height: 16),
                ],

                OnboardingPrimaryButton(
                  label: OnboardingStrings.s(sw,
                      en: OnboardingStrings.pinLoginCtaEn,
                      sw: OnboardingStrings.pinLoginCtaSw),
                  onPressed: state.isLoading ? null : _submit,
                  isLoading: state.isLoading,
                ),
                const SizedBox(height: 12),

                // ── Forgot PIN hint ───────────────────────────────────────
                Center(
                  child: Text(
                    OnboardingStrings.s(sw,
                        en: OnboardingStrings.pinLoginForgotEn,
                        sw: OnboardingStrings.pinLoginForgotSw),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                    textAlign: TextAlign.center,
                  ),
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

// ─── PIN input field ──────────────────────────────────────────────────────────

class _PinField extends StatelessWidget {
  const _PinField({
    required this.controller,
    required this.isSwahili,
    required this.onComplete,
    required this.validator,
  });

  final TextEditingController controller;
  final bool isSwahili;
  final VoidCallback onComplete;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          OnboardingStrings.s(isSwahili,
              en: OnboardingStrings.pinLoginFieldLabelEn,
              sw: OnboardingStrings.pinLoginFieldLabelSw),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.navyPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          maxLength: 4,
          obscureText: true,
          autofocus: true,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onFieldSubmitted: (_) => onComplete(),
          onChanged: (v) {
            if (v.length == 4) onComplete();
          },
          validator: validator,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: 12,
            color: AppColors.navyPrimary,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: AppColors.surface,
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
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Business badge ───────────────────────────────────────────────────────────

class _BusinessBadge extends StatelessWidget {
  const _BusinessBadge({required this.businessName, required this.role});

  final String businessName;
  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.yellowBrand,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: AppColors.navyPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  businessName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyPrimary,
                      ),
                ),
                if (role.isNotEmpty)
                  Text(
                    role,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
