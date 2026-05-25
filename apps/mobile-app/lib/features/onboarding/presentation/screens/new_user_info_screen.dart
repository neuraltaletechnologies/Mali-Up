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
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();

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

    // Pre-fill if returning from business screen (unlikely but safe).
    final s = ref.read(onboardingNotifierProvider);
    _firstNameCtrl.text = s.firstName;
    _lastNameCtrl.text = s.lastName;
    _cityCtrl.text = s.city;
    _roleCtrl.text = s.role;
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _cityCtrl.dispose();
    _roleCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    notifier.setFirstName(_firstNameCtrl.text.trim());
    notifier.setLastName(_lastNameCtrl.text.trim());
    notifier.setCity(_cityCtrl.text.trim());
    notifier.setRole(_roleCtrl.text.trim());
    notifier.advanceFromPersonalInfo();
    context.go(AppRoutes.business);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);
    final sw = state.isSwahili;

    return OnboardingScaffold(
      currentStep: 3,
      totalSteps: 6,
      onBack: () => context.go(AppRoutes.otp),
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
                Text(
                  OnboardingStrings.s(sw,
                      en: OnboardingStrings.newUserTitleEn,
                      sw: OnboardingStrings.newUserTitleSw),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.navyPrimary,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  OnboardingStrings.s(sw,
                      en: OnboardingStrings.newUserSubEn,
                      sw: OnboardingStrings.newUserSubSw),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
                const SizedBox(height: 32),

                // First name
                OnboardingField(
                  controller: _firstNameCtrl,
                  label: OnboardingStrings.s(sw,
                      en: OnboardingStrings.firstNameLabelEn,
                      sw: OnboardingStrings.firstNameLabelSw),
                  hint: OnboardingStrings.s(sw,
                      en: OnboardingStrings.firstNameHintEn,
                      sw: OnboardingStrings.firstNameHintSw),
                  autofocus: true,
                  validator: (v) => OnboardingValidator.validateName(
                      v ?? '', isSwahili: sw),
                ),
                const SizedBox(height: 16),

                // Last name
                OnboardingField(
                  controller: _lastNameCtrl,
                  label: OnboardingStrings.s(sw,
                      en: OnboardingStrings.lastNameLabelEn,
                      sw: OnboardingStrings.lastNameLabelSw),
                  hint: OnboardingStrings.s(sw,
                      en: OnboardingStrings.lastNameHintEn,
                      sw: OnboardingStrings.lastNameHintSw),
                  validator: (v) => OnboardingValidator.validateName(
                      v ?? '', isSwahili: sw),
                ),
                const SizedBox(height: 16),

                // City (optional — no validator)
                OnboardingField(
                  controller: _cityCtrl,
                  label: OnboardingStrings.s(sw,
                      en: OnboardingStrings.cityLabelEn,
                      sw: OnboardingStrings.cityLabelSw),
                  hint: OnboardingStrings.s(sw,
                      en: OnboardingStrings.cityHintEn,
                      sw: OnboardingStrings.cityHintSw),
                ),
                const SizedBox(height: 16),

                // Role (optional)
                OnboardingField(
                  controller: _roleCtrl,
                  label: OnboardingStrings.s(sw,
                      en: OnboardingStrings.roleLabelEn,
                      sw: OnboardingStrings.roleLabelSw),
                  hint: OnboardingStrings.s(sw,
                      en: OnboardingStrings.roleHintEn,
                      sw: OnboardingStrings.roleHintSw),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 32),

                if (state.errorMessage != null) ...[
                  OnboardingErrorBanner(message: state.errorMessage!),
                  const SizedBox(height: 16),
                ],

                OnboardingPrimaryButton(
                  label: OnboardingStrings.s(sw,
                      en: OnboardingStrings.newUserCtaEn,
                      sw: OnboardingStrings.newUserCtaSw),
                  onPressed: _submit,
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
