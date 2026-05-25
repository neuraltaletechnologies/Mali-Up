import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/onboarding_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/validators/onboarding_validator.dart';
import '../../providers/onboarding_notifier.dart';
import '../../../../config/routing.dart';
import '_onboarding_scaffold.dart';

class NewUserInfoScreen extends ConsumerStatefulWidget {
  const NewUserInfoScreen({super.key});

  @override
  ConsumerState<NewUserInfoScreen> createState() => _NewUserInfoScreenState();
}

class _NewUserInfoScreenState extends ConsumerState<NewUserInfoScreen>
    with SingleTickerProviderStateMixin {
  final _formKey       = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();

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
        .animate(
            CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();

    final s = ref.read(onboardingNotifierProvider);
    _firstNameCtrl.text = s.firstName;
    _lastNameCtrl.text  = s.lastName;
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    notifier.setFirstName(_firstNameCtrl.text.trim());
    notifier.setLastName(_lastNameCtrl.text.trim());
    notifier.advanceFromPersonalInfo();
    context.go(AppRoutes.business);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);
    final sw    = state.isSwahili;

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
                const SizedBox(height: 20),

                // ── Icon ──────────────────────────────────────────────────
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.tealAccent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.tealAccent.withValues(alpha: 0.28),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(height: 20),

                // ── Heading ───────────────────────────────────────────────
                Text(
                  OnboardingStrings.s(sw,
                      en: OnboardingStrings.newUserTitleEn,
                      sw: OnboardingStrings.newUserTitleSw),
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
                      en: OnboardingStrings.newUserSubEn,
                      sw: OnboardingStrings.newUserSubSw),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 36),

                // ── First name ────────────────────────────────────────────
                OnboardingField(
                  controller: _firstNameCtrl,
                  label: OnboardingStrings.s(sw,
                      en: OnboardingStrings.firstNameLabelEn,
                      sw: OnboardingStrings.firstNameLabelSw),
                  hint: OnboardingStrings.s(sw,
                      en: OnboardingStrings.firstNameHintEn,
                      sw: OnboardingStrings.firstNameHintSw),
                  autofocus: true,
                  prefix: const Icon(Icons.badge_outlined,
                      size: 18, color: AppColors.textMuted),
                  validator: (v) => OnboardingValidator.validateName(
                      v ?? '', isSwahili: sw),
                ),
                const SizedBox(height: 16),

                // ── Last name ─────────────────────────────────────────────
                OnboardingField(
                  controller: _lastNameCtrl,
                  label: OnboardingStrings.s(sw,
                      en: OnboardingStrings.lastNameLabelEn,
                      sw: OnboardingStrings.lastNameLabelSw),
                  hint: OnboardingStrings.s(sw,
                      en: OnboardingStrings.lastNameHintEn,
                      sw: OnboardingStrings.lastNameHintSw),
                  prefix: const Icon(Icons.badge_outlined,
                      size: 18, color: AppColors.textMuted),
                  validator: (v) => OnboardingValidator.validateName(
                      v ?? '', isSwahili: sw),
                ),
                const SizedBox(height: 16),

                // ── Email (optional) ──────────────────────────────────────
                OnboardingField(
                  controller: _emailCtrl,
                  label: sw ? 'BARUA PEPE (HIARI)' : 'EMAIL (OPTIONAL)',
                  hint: sw
                      ? 'jina@mfano.com'
                      : 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  prefix: const Icon(Icons.alternate_email_rounded,
                      size: 18, color: AppColors.textMuted),
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 5),
                    Text(
                      sw
                          ? 'Barua pepe inatumika kwa arifa tu.'
                          : 'Email is used for notifications only.',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),

                const SizedBox(height: 36),

                // ── Error ─────────────────────────────────────────────────
                if (state.errorMessage != null) ...[
                  OnboardingErrorBanner(message: state.errorMessage!),
                  const SizedBox(height: 16),
                ],

                // ── CTA ───────────────────────────────────────────────────
                OnboardingPrimaryButton(
                  label: OnboardingStrings.s(sw,
                      en: OnboardingStrings.newUserCtaEn,
                      sw: OnboardingStrings.newUserCtaSw),
                  onPressed: _submit,
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
