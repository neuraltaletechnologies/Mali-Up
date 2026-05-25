import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/onboarding_strings.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/emotional_design.dart';
import '../../domain/validators/onboarding_validator.dart';
import '../../providers/onboarding_notifier.dart';
import '../../../../config/routing.dart';
import '_onboarding_scaffold.dart';

class PhoneEntryScreen extends ConsumerStatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();

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

    // Pre-fill if navigating back.
    _phoneCtrl.text = ref.read(onboardingNotifierProvider).phone;

    // Sync language — deferred because modifying a provider during initState
    // (inside the build phase) is forbidden by Riverpod.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final lang = LocalizationService.languageNotifier.value;
      ref.read(onboardingNotifierProvider.notifier).selectLanguage(lang);
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final phone =
        OnboardingValidator.normalisePhone(_phoneCtrl.text.trim());
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    notifier.setPhone(phone);
    await notifier.lookupPhone();
    if (!mounted) return;

    final s = ref.read(onboardingNotifierProvider);
    if (s.errorMessage != null) return; // stay on screen, error is displayed

    if (s.isReturningUser) {
      context.go(AppRoutes.pinLogin);
    } else if (s.isTeamMember) {
      context.go(AppRoutes.teamSetup);
    } else {
      context.go(AppRoutes.newUser);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);
    final sw = state.isSwahili;

    return OnboardingScaffold(
      currentStep: 3,
      lottieScene: EmotionalLottieScene.authVerify,
      onBack: () => context.go(AppRoutes.intro),
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
                      en: OnboardingStrings.phoneTitleEn,
                      sw: OnboardingStrings.phoneTitleSw),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.navyPrimary,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  OnboardingStrings.s(sw,
                      en: OnboardingStrings.phoneSubEn,
                      sw: OnboardingStrings.phoneSubSw),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
                const SizedBox(height: 32),

                // ── Tanzania country chip ──────────────────────────────────
                _CountryChip(isSwahili: sw),
                const SizedBox(height: 12),

                // ── Phone number field ─────────────────────────────────────
                OnboardingField(
                  controller: _phoneCtrl,
                  label: OnboardingStrings.s(sw,
                      en: OnboardingStrings.phoneLabelEn,
                      sw: OnboardingStrings.phoneLabelSw),
                  hint: OnboardingStrings.s(sw,
                      en: OnboardingStrings.phoneHintEn,
                      sw: OnboardingStrings.phoneHintSw),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  autofocus: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s]')),
                  ],
                  onFieldSubmitted: (_) => _submit(),
                  validator: (v) =>
                      OnboardingValidator.validatePhone(v ?? '',
                          isSwahili: sw),
                ),
                const SizedBox(height: 10),
                Text(
                  OnboardingStrings.s(sw,
                      en: OnboardingStrings.phoneHelperEn,
                      sw: OnboardingStrings.phoneHelperSw),
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
                  label: OnboardingStrings.s(sw,
                      en: OnboardingStrings.phoneSendCtaEn,
                      sw: OnboardingStrings.phoneSendCtaSw),
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

// ─── Tanzania country chip ─────────────────────────────────────────────────────

class _CountryChip extends StatelessWidget {
  const _CountryChip({required this.isSwahili});

  final bool isSwahili;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🇹🇿', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Text(
            OnboardingStrings.s(isSwahili,
                en: OnboardingStrings.phoneCountryChipEn,
                sw: OnboardingStrings.phoneCountryChipSw),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.navyPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
