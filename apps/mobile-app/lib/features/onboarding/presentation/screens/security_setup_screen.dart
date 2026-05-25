import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/onboarding_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/validators/onboarding_validator.dart';
import '../../providers/onboarding_notifier.dart';
import '../../../../config/routing.dart';
import '_onboarding_scaffold.dart';

class SecuritySetupScreen extends ConsumerStatefulWidget {
  const SecuritySetupScreen({super.key});

  @override
  ConsumerState<SecuritySetupScreen> createState() =>
      _SecuritySetupScreenState();
}

class _SecuritySetupScreenState extends ConsumerState<SecuritySetupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  bool _obscurePassword = true;

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

    final s = ref.read(onboardingNotifierProvider);
    _passwordCtrl.text = s.password;
    _pinCtrl.text = s.pin;
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _passwordCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    notifier.setPassword(_passwordCtrl.text);
    notifier.setPin(_pinCtrl.text);
    await notifier.saveAndComplete();
    if (mounted && ref.read(onboardingNotifierProvider).isComplete) {
      context.go(AppRoutes.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);
    final sw = state.isSwahili;

    return OnboardingScaffold(
      currentStep: 6,
      onBack: () => context.go(AppRoutes.business),
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

                // ── Title ─────────────────────────────────────────────────
                Text(
                  OnboardingStrings.s(sw,
                      en: OnboardingStrings.securityTitleEn,
                      sw: OnboardingStrings.securityTitleSw),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.navyPrimary,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  OnboardingStrings.s(sw,
                      en: OnboardingStrings.securitySubEn,
                      sw: OnboardingStrings.securitySubSw),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
                const SizedBox(height: 32),

                // ── Password ──────────────────────────────────────────────
                OnboardingField(
                  controller: _passwordCtrl,
                  label: OnboardingStrings.s(sw,
                      en: OnboardingStrings.passwordLabelEn,
                      sw: OnboardingStrings.passwordLabelSw),
                  hint: OnboardingStrings.s(sw,
                      en: OnboardingStrings.passwordHintEn,
                      sw: OnboardingStrings.passwordHintSw),
                  autofocus: true,
                  obscureText: _obscurePassword,
                  suffix: _PasswordToggle(
                    isObscured: _obscurePassword,
                    isSwahili: sw,
                    onToggle: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) =>
                      OnboardingValidator.validatePassword(v ?? '',
                          isSwahili: sw),
                ),
                const SizedBox(height: 20),

                // ── PIN ───────────────────────────────────────────────────
                OnboardingField(
                  controller: _pinCtrl,
                  label: OnboardingStrings.s(sw,
                      en: OnboardingStrings.pinLabelEn,
                      sw: OnboardingStrings.pinLabelSw),
                  hint: OnboardingStrings.s(sw,
                      en: OnboardingStrings.pinHintEn,
                      sw: OnboardingStrings.pinHintSw),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  obscureText: true,
                  maxLength: 4,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onFieldSubmitted: (_) => _submit(),
                  validator: (v) =>
                      OnboardingValidator.validatePin(v ?? '', isSwahili: sw),
                ),
                const SizedBox(height: 8),
                Text(
                  OnboardingStrings.s(sw,
                      en: OnboardingStrings.pinHelperEn,
                      sw: OnboardingStrings.pinHelperSw),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
                const SizedBox(height: 32),

                if (state.errorMessage != null) ...[
                  OnboardingErrorBanner(message: state.errorMessage!),
                  const SizedBox(height: 16),
                ],

                OnboardingPrimaryButton(
                  label: state.isLoading
                      ? OnboardingStrings.s(sw,
                          en: OnboardingStrings.securitySavingEn,
                          sw: OnboardingStrings.securitySavingSw)
                      : OnboardingStrings.s(sw,
                          en: OnboardingStrings.securityCreateCtaEn,
                          sw: OnboardingStrings.securityCreateCtaSw),
                  onPressed: state.isLoading ? null : _submit,
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

// ─── Password visibility toggle ───────────────────────────────────────────────

class _PasswordToggle extends StatelessWidget {
  const _PasswordToggle({
    required this.isObscured,
    required this.isSwahili,
    required this.onToggle,
  });

  final bool isObscured;
  final bool isSwahili;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          isObscured
              ? OnboardingStrings.s(isSwahili,
                  en: OnboardingStrings.passwordToggleShowEn,
                  sw: OnboardingStrings.passwordToggleShowSw)
              : OnboardingStrings.s(isSwahili,
                  en: OnboardingStrings.passwordToggleHideEn,
                  sw: OnboardingStrings.passwordToggleHideSw),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.navyPrimary,
          ),
        ),
      ),
    );
  }
}
