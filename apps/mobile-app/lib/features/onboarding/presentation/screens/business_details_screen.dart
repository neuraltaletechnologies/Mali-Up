import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/onboarding_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/validators/onboarding_validator.dart';
import '../../providers/onboarding_notifier.dart';
import '../../../../config/routing.dart';
import '_onboarding_scaffold.dart';

// Icon for each Firestore businessType key
const Map<String, IconData> _typeIcons = {
  'retail':          Icons.storefront_rounded,
  'wholesale':       Icons.inventory_2_rounded,
  'food_beverages':  Icons.lunch_dining_rounded,
  'restaurant':      Icons.restaurant_rounded,
  'salon':           Icons.content_cut_rounded,
  'tailoring':       Icons.checkroom_rounded,
  'electronics':     Icons.devices_rounded,
  'hardware':        Icons.hardware_rounded,
  'pharmacy':        Icons.local_pharmacy_rounded,
  'agriculture':     Icons.grass_rounded,
  'transport':       Icons.local_shipping_rounded,
  'health':          Icons.favorite_rounded,
  'education':       Icons.school_rounded,
  'construction':    Icons.construction_rounded,
  'real_estate':     Icons.home_work_rounded,
  'printing':        Icons.print_rounded,
  'cleaning':        Icons.cleaning_services_rounded,
  'tech_services':   Icons.computer_rounded,
  'events':          Icons.celebration_rounded,
  'freelance':       Icons.work_rounded,
  'consultancy':     Icons.business_center_rounded,
  'banking_finance': Icons.account_balance_rounded,
  'insurance':       Icons.verified_user_rounded,
  'mobile_money':    Icons.mobile_friendly_rounded,
  'photography':     Icons.camera_alt_rounded,
  'media':           Icons.campaign_rounded,
  'legal':           Icons.gavel_rounded,
  'security_guard':  Icons.shield_rounded,
  'travel':          Icons.flight_rounded,
  'other':           Icons.more_horiz_rounded,
};

class BusinessDetailsScreen extends ConsumerStatefulWidget {
  const BusinessDetailsScreen({super.key});

  @override
  ConsumerState<BusinessDetailsScreen> createState() =>
      _BusinessDetailsScreenState();
}

class _BusinessDetailsScreenState extends ConsumerState<BusinessDetailsScreen>
    with SingleTickerProviderStateMixin {
  final _formKey    = GlobalKey<FormState>();
  final _bizNameCtrl = TextEditingController();
  String? _selectedType;
  bool _typeError = false;

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
    final formValid = _formKey.currentState!.validate();
    if (_selectedType == null) setState(() => _typeError = true);
    if (!formValid || _selectedType == null) return;

    final notifier = ref.read(onboardingNotifierProvider.notifier);
    notifier.setBusinessName(_bizNameCtrl.text.trim());
    notifier.setBusinessType(_selectedType!);
    notifier.advanceFromBusinessDetails();
    context.go(AppRoutes.security);
  }

  @override
  Widget build(BuildContext context) {
    final state     = ref.watch(onboardingNotifierProvider);
    final sw        = state.isSwahili;
    final firstName = state.firstName.isNotEmpty
        ? state.firstName
        : (sw ? 'wewe' : 'there');

    return OnboardingScaffold(
      currentStep: 5,
      onBack: () => context.go(AppRoutes.newUser),
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
                  child: const Icon(Icons.storefront_rounded,
                      color: AppColors.navyPrimary, size: 26),
                ),
                const SizedBox(height: 20),

                // ── Heading ───────────────────────────────────────────────
                Text(
                  OnboardingStrings.s(sw,
                      en: OnboardingStrings.bizGreetEn(firstName),
                      sw: OnboardingStrings.bizGreetSw(firstName)),
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
                      en: OnboardingStrings.bizSubEn,
                      sw: OnboardingStrings.bizSubSw),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                    height: 1.5,
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
                  prefix: const Icon(Icons.storefront_outlined,
                      size: 18, color: AppColors.textMuted),
                  validator: (v) => OnboardingValidator.validateBusinessName(
                      v ?? '', isSwahili: sw),
                ),
                const SizedBox(height: 28),

                // ── Business type heading ─────────────────────────────────
                Text(
                  OnboardingStrings.s(sw,
                      en: OnboardingStrings.bizTypeLabelEn,
                      sw: OnboardingStrings.bizTypeLabelSw),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navyPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  sw
                      ? 'Chagua inayofaa zaidi biashara yako.'
                      : 'Select the one that best fits your business.',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 14),

                // ── Type chips ────────────────────────────────────────────
                _BusinessTypeChips(
                  selected: _selectedType,
                  isSwahili: sw,
                  hasError: _typeError,
                  onSelect: (key) =>
                      setState(() {
                        _selectedType = key;
                        _typeError = false;
                      }),
                ),

                if (_typeError) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 13, color: AppColors.error),
                      const SizedBox(width: 5),
                      Text(
                        OnboardingStrings.s(sw,
                            en: OnboardingStrings.bizTypeRequiredEn,
                            sw: OnboardingStrings.bizTypeRequiredSw),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.error),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 32),

                if (state.errorMessage != null) ...[
                  OnboardingErrorBanner(message: state.errorMessage!),
                  const SizedBox(height: 16),
                ],

                // ── CTA ───────────────────────────────────────────────────
                OnboardingPrimaryButton(
                  label: OnboardingStrings.s(sw,
                      en: OnboardingStrings.bizCtaEn,
                      sw: OnboardingStrings.bizCtaSw),
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

// ── Business type chip grid ───────────────────────────────────────────────────

class _BusinessTypeChips extends StatelessWidget {
  const _BusinessTypeChips({
    required this.selected,
    required this.isSwahili,
    required this.hasError,
    required this.onSelect,
  });

  final String? selected;
  final bool isSwahili;
  final bool hasError;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: hasError ? const EdgeInsets.all(10) : EdgeInsets.zero,
      decoration: hasError
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.35), width: 1.5),
            )
          : null,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: OnboardingStrings.businessTypes.entries.map((e) {
          return _TypeChip(
            label: isSwahili ? e.value.sw : e.value.en,
            icon: _typeIcons[e.key] ?? Icons.category_rounded,
            isSelected: selected == e.key,
            onTap: () => onSelect(e.key),
          );
        }).toList(),
      ),
    );
  }
}

// ── Individual chip with press animation ─────────────────────────────────────

class _TypeChip extends StatefulWidget {
  const _TypeChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_TypeChip> createState() => _TypeChipState();
}

class _TypeChipState extends State<_TypeChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 160),
      lowerBound: 0.94,
      upperBound: 1.0,
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pressCtrl,
      child: GestureDetector(
        onTapDown: (_) => _pressCtrl.reverse(),
        onTapUp: (_) {
          _pressCtrl.forward();
          widget.onTap();
        },
        onTapCancel: () => _pressCtrl.forward(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.navyPrimary
                : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.navyPrimary
                  : AppColors.border,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: AppColors.navyPrimary.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: widget.isSelected
                    ? AppColors.yellowBrand
                    : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: widget.isSelected
                      ? FontWeight.w600
                      : FontWeight.w500,
                  color: widget.isSelected
                      ? Colors.white
                      : AppColors.navyPrimary,
                ),
              ),
              if (widget.isSelected) ...[
                const SizedBox(width: 5),
                const Icon(
                  Icons.check_rounded,
                  size: 13,
                  color: AppColors.yellowBrand,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
