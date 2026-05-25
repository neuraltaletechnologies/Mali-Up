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

/// Screen 6 — PIN setup for new owner users.
/// The user sets a 4-digit PIN and confirms it. On submit a Firebase Auth
/// account is created and user/business profiles are written to Firestore.
class SecuritySetupScreen extends ConsumerStatefulWidget {
  const SecuritySetupScreen({super.key});

  @override
  ConsumerState<SecuritySetupScreen> createState() =>
      _SecuritySetupScreenState();
}

class _SecuritySetupScreenState extends ConsumerState<SecuritySetupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _pinCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

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
    _pinCtrl.text = s.pin;
    _confirmCtrl.text = s.confirmPin;
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _pinCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    notifier.setPin(_pinCtrl.text);
    notifier.setConfirmPin(_confirmCtrl.text);
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
                      en: OnboardingStrings.pinSetupTitleEn,
                      sw: OnboardingStrings.pinSetupTitleSw),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.navyPrimary,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  OnboardingStrings.s(sw,
                      en: OnboardingStrings.pinSetupSubEn,
                      sw: OnboardingStrings.pinSetupSubSw),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
                const SizedBox(height: 32),

                // ── PIN ───────────────────────────────────────────────────
                OnboardingField(
                  controller: _pinCtrl,
                  label: OnboardingStrings.s(sw,
                      en: OnboardingStrings.pinSetupEnterLabelEn,
                      sw: OnboardingStrings.pinSetupEnterLabelSw),
                  hint: '••••',
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  autofocus: true,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) =>
                      OnboardingValidator.validatePin(v ?? '', isSwahili: sw),
                ),
                const SizedBox(height: 16),

                // ── Confirm PIN ───────────────────────────────────────────
                OnboardingField(
                  controller: _confirmCtrl,
                  label: OnboardingStrings.s(sw,
                      en: OnboardingStrings.pinSetupConfirmLabelEn,
                      sw: OnboardingStrings.pinSetupConfirmLabelSw),
                  hint: '••••',
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  obscureText: true,
                  maxLength: 4,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onFieldSubmitted: (_) => _submit(),
                  validator: (v) {
                    final base = OnboardingValidator.validatePin(
                        v ?? '', isSwahili: sw);
                    if (base != null) return base;
                    if (v != _pinCtrl.text) {
                      return OnboardingStrings.s(sw,
                          en: OnboardingStrings.pinSetupMismatchEn,
                          sw: OnboardingStrings.pinSetupMismatchSw);
                    }
                    return null;
                  },
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
                          en: OnboardingStrings.pinSetupSavingEn,
                          sw: OnboardingStrings.pinSetupSavingSw)
                      : OnboardingStrings.s(sw,
                          en: OnboardingStrings.pinSetupCtaEn,
                          sw: OnboardingStrings.pinSetupCtaSw),
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
