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

/// Screen 4B — shown when the phone number matches a team member record
/// that was added by an owner but has not yet activated their account.
///
/// Flow:
/// 1. Shows the member's name, role, and business (read from onboarding state).
/// 2. "Set Up My PIN" → shows PIN entry + confirm, creates account, marks done.
/// 3. "That's not me" → resets and goes to /new-user.
class TeamMemberSetupScreen extends ConsumerStatefulWidget {
  const TeamMemberSetupScreen({super.key});

  @override
  ConsumerState<TeamMemberSetupScreen> createState() =>
      _TeamMemberSetupScreenState();
}

class _TeamMemberSetupScreenState
    extends ConsumerState<TeamMemberSetupScreen>
    with SingleTickerProviderStateMixin {
  bool _showPinEntry = false;

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
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _pinCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _continueAsTeamMember() {
    setState(() => _showPinEntry = true);
    ref.read(onboardingNotifierProvider.notifier).continueAsTeamMember();
  }

  void _startOver() {
    ref.read(onboardingNotifierProvider.notifier).startOverFromTeamMember();
    context.go(AppRoutes.newUser);
  }

  Future<void> _savePin() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(onboardingNotifierProvider.notifier)
        .saveTeamMemberPin(_pinCtrl.text.trim());
    if (!mounted) return;
    final s = ref.read(onboardingNotifierProvider);
    if (s.isComplete) context.go(AppRoutes.success);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);
    final sw = state.isSwahili;
    final name = state.firstName.isNotEmpty ? state.firstName : state.fullName;

    return OnboardingScaffold(
      currentStep: 4,
      lottieScene: EmotionalLottieScene.onboarding,
      onBack: () {
        if (_showPinEntry) {
          setState(() => _showPinEntry = false);
        } else {
          context.go(AppRoutes.phone);
        }
      },
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: _showPinEntry
              ? _PinSetupBody(
                  sw: sw,
                  formKey: _formKey,
                  pinCtrl: _pinCtrl,
                  confirmCtrl: _confirmCtrl,
                  isLoading: state.isLoading,
                  errorMessage: state.errorMessage,
                  onSave: _savePin,
                )
              : _ProfileBody(
                  sw: sw,
                  name: name,
                  role: state.role,
                  businessName: state.businessName,
                  isLoading: state.isLoading,
                  errorMessage: state.errorMessage,
                  onContinue: _continueAsTeamMember,
                  onStartOver: _startOver,
                ),
        ),
      ),
    );
  }
}

// ─── Profile view (step 1 of 2) ──────────────────────────────────────────────

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.sw,
    required this.name,
    required this.role,
    required this.businessName,
    required this.isLoading,
    required this.errorMessage,
    required this.onContinue,
    required this.onStartOver,
  });

  final bool sw;
  final String name;
  final String role;
  final String businessName;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onContinue;
  final VoidCallback onStartOver;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),

        Text(
          OnboardingStrings.s(sw,
              en: OnboardingStrings.teamGreetEn(name),
              sw: OnboardingStrings.teamGreetSw(name)),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.navyPrimary,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          OnboardingStrings.s(sw,
              en: OnboardingStrings.teamSubEn,
              sw: OnboardingStrings.teamSubSw),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
        ),
        const SizedBox(height: 32),

        // ── Business info card ────────────────────────────────────────────
        _TeamInfoCard(
          sw: sw,
          businessName: businessName,
          role: role,
        ),
        const SizedBox(height: 40),

        if (errorMessage != null) ...[
          OnboardingErrorBanner(message: errorMessage!),
          const SizedBox(height: 16),
        ],

        // ── Primary CTA ───────────────────────────────────────────────────
        OnboardingPrimaryButton(
          label: OnboardingStrings.s(sw,
              en: OnboardingStrings.teamContinueCtaEn,
              sw: OnboardingStrings.teamContinueCtaSw),
          onPressed: isLoading ? null : onContinue,
          isLoading: isLoading,
        ),
        const SizedBox(height: 12),

        // ── Start over ────────────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: isLoading ? null : onStartOver,
            child: Text(
              OnboardingStrings.s(sw,
                  en: OnboardingStrings.teamStartOverCtaEn,
                  sw: OnboardingStrings.teamStartOverCtaSw),
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.textMuted,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ─── PIN setup view (step 2 of 2) ────────────────────────────────────────────

class _PinSetupBody extends StatelessWidget {
  const _PinSetupBody({
    required this.sw,
    required this.formKey,
    required this.pinCtrl,
    required this.confirmCtrl,
    required this.isLoading,
    required this.errorMessage,
    required this.onSave,
  });

  final bool sw;
  final GlobalKey<FormState> formKey;
  final TextEditingController pinCtrl;
  final TextEditingController confirmCtrl;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
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

          _PinInputField(
            controller: pinCtrl,
            label: OnboardingStrings.s(sw,
                en: OnboardingStrings.pinSetupEnterLabelEn,
                sw: OnboardingStrings.pinSetupEnterLabelSw),
            autofocus: true,
            validator: (v) =>
                OnboardingValidator.validatePin(v ?? '', isSwahili: sw),
          ),
          const SizedBox(height: 16),

          _PinInputField(
            controller: confirmCtrl,
            label: OnboardingStrings.s(sw,
                en: OnboardingStrings.pinSetupConfirmLabelEn,
                sw: OnboardingStrings.pinSetupConfirmLabelSw),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSave(),
            validator: (v) {
              final base = OnboardingValidator.validatePin(v ?? '',
                  isSwahili: sw);
              if (base != null) return base;
              if (v != pinCtrl.text) {
                return OnboardingStrings.s(sw,
                    en: OnboardingStrings.pinSetupMismatchEn,
                    sw: OnboardingStrings.pinSetupMismatchSw);
              }
              return null;
            },
          ),
          const SizedBox(height: 32),

          if (errorMessage != null) ...[
            OnboardingErrorBanner(message: errorMessage!),
            const SizedBox(height: 16),
          ],

          OnboardingPrimaryButton(
            label: isLoading
                ? OnboardingStrings.s(sw,
                    en: OnboardingStrings.pinSetupSavingEn,
                    sw: OnboardingStrings.pinSetupSavingSw)
                : OnboardingStrings.s(sw,
                    en: OnboardingStrings.pinSetupCtaEn,
                    sw: OnboardingStrings.pinSetupCtaSw),
            onPressed: isLoading ? null : onSave,
            isLoading: isLoading,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Shared PIN text field ────────────────────────────────────────────────────

class _PinInputField extends StatelessWidget {
  const _PinInputField({
    required this.controller,
    required this.label,
    required this.validator,
    this.autofocus = false,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String> validator;
  final bool autofocus;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
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
          textInputAction: textInputAction,
          maxLength: 4,
          obscureText: true,
          autofocus: autofocus,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onFieldSubmitted: onSubmitted,
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

// ─── Team info card ───────────────────────────────────────────────────────────

class _TeamInfoCard extends StatelessWidget {
  const _TeamInfoCard({
    required this.sw,
    required this.businessName,
    required this.role,
  });

  final bool sw;
  final String businessName;
  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.yellowBrand,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: AppColors.navyPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      OnboardingStrings.s(sw,
                          en: OnboardingStrings.teamBusinessLabelEn,
                          sw: OnboardingStrings.teamBusinessLabelSw),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                    Text(
                      businessName.isNotEmpty ? businessName : '—',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.navyPrimary,
                              ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (role.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.badge_outlined,
                    size: 16, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Text(
                  OnboardingStrings.s(sw,
                      en: OnboardingStrings.teamRoleLabelEn,
                      sw: OnboardingStrings.teamRoleLabelSw),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
                const SizedBox(width: 4),
                Text(
                  role,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyPrimary,
                      ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
