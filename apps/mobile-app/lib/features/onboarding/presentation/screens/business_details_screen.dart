import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/onboarding_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/validators/onboarding_validator.dart';
import '../../providers/onboarding_notifier.dart';
import '../../../../config/routing.dart';
import '_onboarding_scaffold.dart';

class BusinessDetailsScreen extends ConsumerStatefulWidget {
  const BusinessDetailsScreen({super.key});

  @override
  ConsumerState<BusinessDetailsScreen> createState() =>
      _BusinessDetailsScreenState();
}

class _BusinessDetailsScreenState extends ConsumerState<BusinessDetailsScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _bizNameCtrl = TextEditingController();
  String? _selectedType;

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
    _bizNameCtrl.text = s.businessName;
    _selectedType = s.businessType.isNotEmpty ? s.businessType : null;
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _bizNameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null) {
      // Trigger form rebuild so dropdown shows error.
      _formKey.currentState!.validate();
      return;
    }
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    notifier.setBusinessName(_bizNameCtrl.text.trim());
    notifier.setBusinessType(_selectedType!);
    notifier.advanceFromBusinessDetails();
    context.go(AppRoutes.security);
  }

  String? _validateType(String? value) {
    if (value == null || value.isEmpty) {
      final sw = ref.read(onboardingNotifierProvider).isSwahili;
      return OnboardingStrings.s(sw,
          en: OnboardingStrings.bizTypeRequiredEn,
          sw: OnboardingStrings.bizTypeRequiredSw);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);
    final sw = state.isSwahili;
    final firstName = state.firstName.isNotEmpty ? state.firstName : 'there';

    return OnboardingScaffold(
      currentStep: 4,
      onBack: () => state.isReturningUser
          ? context.go(AppRoutes.returning)
          : context.go(AppRoutes.newUser),
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

                // ── Personalised greeting ──────────────────────────────────
                Text(
                  OnboardingStrings.s(sw,
                      en: OnboardingStrings.bizGreetEn(firstName),
                      sw: OnboardingStrings.bizGreetSw(firstName)),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.navyPrimary,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  OnboardingStrings.s(sw,
                      en: OnboardingStrings.bizSubEn,
                      sw: OnboardingStrings.bizSubSw),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
                const SizedBox(height: 32),

                // ── Business name ─────────────────────────────────────────
                OnboardingField(
                  controller: _bizNameCtrl,
                  label: OnboardingStrings.s(sw,
                      en: OnboardingStrings.bizNameLabelEn,
                      sw: OnboardingStrings.bizNameLabelSw),
                  hint: OnboardingStrings.s(sw,
                      en: OnboardingStrings.bizNameHintEn,
                      sw: OnboardingStrings.bizNameHintSw),
                  autofocus: true,
                  validator: (v) => OnboardingValidator.validateBusinessName(
                      v ?? '', isSwahili: sw),
                ),
                const SizedBox(height: 20),

                // ── Business type dropdown ────────────────────────────────
                _BusinessTypeDropdown(
                  value: _selectedType,
                  isSwahili: sw,
                  validator: _validateType,
                  onChanged: (val) => setState(() => _selectedType = val),
                ),
                const SizedBox(height: 32),

                if (state.errorMessage != null) ...[
                  OnboardingErrorBanner(message: state.errorMessage!),
                  const SizedBox(height: 16),
                ],

                OnboardingPrimaryButton(
                  label: OnboardingStrings.s(sw,
                      en: OnboardingStrings.bizCtaEn,
                      sw: OnboardingStrings.bizCtaSw),
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

// ─── Business type dropdown ────────────────────────────────────────────────────

class _BusinessTypeDropdown extends StatelessWidget {
  const _BusinessTypeDropdown({
    required this.value,
    required this.isSwahili,
    required this.validator,
    required this.onChanged,
  });

  final String? value;
  final bool isSwahili;
  final FormFieldValidator<String?> validator;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = OnboardingStrings.businessTypes.entries
        .map(
          (e) => DropdownMenuItem<String>(
            value: e.key,
            child: Text(
              isSwahili ? e.value.sw : e.value.en,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.navyPrimary,
              ),
            ),
          ),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          OnboardingStrings.s(isSwahili,
              en: OnboardingStrings.bizTypeLabelEn,
              sw: OnboardingStrings.bizTypeLabelSw),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.navyPrimary,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: items,
          validator: validator,
          onChanged: onChanged,
          isExpanded: true,
          hint: Text(
            OnboardingStrings.s(isSwahili,
                en: OnboardingStrings.bizTypeSelectPromptEn,
                sw: OnboardingStrings.bizTypeSelectPromptSw),
            style: const TextStyle(
              color: AppColors.textDisabled,
              fontSize: 14,
            ),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          ),
        ),
      ],
    );
  }
}
