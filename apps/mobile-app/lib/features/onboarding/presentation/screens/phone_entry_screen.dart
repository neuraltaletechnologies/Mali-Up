import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/onboarding_strings.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
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
        vsync: this, duration: const Duration(milliseconds: 480));
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();

    _phoneCtrl.text = ref.read(onboardingNotifierProvider).phone;

    // Sync language after frame — modifying providers during build is forbidden.
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
    final phone = OnboardingValidator.normalisePhone(_phoneCtrl.text.trim());
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    notifier.setPhone(phone);
    await notifier.lookupPhone();
    if (!mounted) return;

    final s = ref.read(onboardingNotifierProvider);
    if (s.errorMessage != null) return;

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
                const SizedBox(height: 20),

                // ── Icon ──────────────────────────────────────────────────
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.yellowBrand,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.yellowBrand.withValues(alpha: 0.30),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.phone_iphone_rounded,
                      color: AppColors.navyPrimary, size: 26),
                ),
                const SizedBox(height: 20),

                // ── Title ─────────────────────────────────────────────────
                Text(
                  OnboardingStrings.s(sw,
                      en: OnboardingStrings.phoneTitleEn,
                      sw: OnboardingStrings.phoneTitleSw),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyPrimary,
                    height: 1.2,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  OnboardingStrings.s(sw,
                      en: OnboardingStrings.phoneSubEn,
                      sw: OnboardingStrings.phoneSubSw),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 36),

                // ── Country selector ──────────────────────────────────────
                _CountrySelector(isSwahili: sw),
                const SizedBox(height: 14),

                // ── Phone field ───────────────────────────────────────────
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
                  validator: (v) => OnboardingValidator.validatePhone(
                      v ?? '', isSwahili: sw),
                ),
                const SizedBox(height: 8),
                Text(
                  OnboardingStrings.s(sw,
                      en: OnboardingStrings.phoneHelperEn,
                      sw: OnboardingStrings.phoneHelperSw),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 32),

                // ── Error ─────────────────────────────────────────────────
                if (state.errorMessage != null) ...[
                  OnboardingErrorBanner(message: state.errorMessage!),
                  const SizedBox(height: 16),
                ],

                // ── CTA ───────────────────────────────────────────────────
                OnboardingPrimaryButton(
                  label: OnboardingStrings.s(sw,
                      en: OnboardingStrings.phoneSendCtaEn,
                      sw: OnboardingStrings.phoneSendCtaSw),
                  onPressed: state.isLoading ? null : _submit,
                  isLoading: state.isLoading,
                ),
                const SizedBox(height: 16),

                // ── Privacy note ──────────────────────────────────────────
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline_rounded,
                          size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 5),
                      Text(
                        sw
                            ? 'Nambari yako ni salama'
                            : 'Your number is kept private',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Country selector ──────────────────────────────────────────────────────────

class _CountrySelector extends StatelessWidget {
  const _CountrySelector({required this.isSwahili});
  final bool isSwahili;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Text('🇹🇿', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSwahili ? 'Tanzania' : 'Tanzania',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyPrimary,
                  ),
                ),
                const Text(
                  '+255',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 18),
        ],
      ),
    );
  }
}
