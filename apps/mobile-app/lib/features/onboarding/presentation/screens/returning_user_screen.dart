import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/onboarding_strings.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/onboarding_notifier.dart';
import '../../../onboarding/core/onboarding_colors.dart';
import '../../../../config/routing.dart';
import '_onboarding_scaffold.dart';

class ReturningUserScreen extends ConsumerWidget {
  const ReturningUserScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingNotifierProvider);
    final sw = state.isSwahili;
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    return OnboardingScaffold(
      currentStep: 3,
      totalSteps: 6,
      onBack: () => context.go(AppRoutes.otp),
      child: _ReturningUserBody(
        state: _BodyState(
          firstName: state.firstName,
          businessName: state.businessName,
          businessType: state.businessType,
          city: state.city,
          isLoading: state.isLoading,
          errorMessage: state.errorMessage,
          isSwahili: sw,
        ),
        onContinue: () => notifier.continueAsReturningUser(),
        onStartOver: () {
          notifier.startOverAsNewUser();
          context.go(AppRoutes.newUser);
        },
      ),
    );
  }
}

class _BodyState {
  const _BodyState({
    required this.firstName,
    required this.businessName,
    required this.businessType,
    required this.city,
    required this.isLoading,
    required this.errorMessage,
    required this.isSwahili,
  });
  final String firstName;
  final String businessName;
  final String businessType;
  final String city;
  final bool isLoading;
  final String? errorMessage;
  final bool isSwahili;
}

class _ReturningUserBody extends StatefulWidget {
  const _ReturningUserBody({
    required this.state,
    required this.onContinue,
    required this.onStartOver,
  });

  final _BodyState state;
  final VoidCallback onContinue;
  final VoidCallback onStartOver;

  @override
  State<_ReturningUserBody> createState() => _ReturningUserBodyState();
}

class _ReturningUserBodyState extends State<_ReturningUserBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 540),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = widget.state.isSwahili;
    final name = widget.state.firstName.isNotEmpty
        ? widget.state.firstName
        : LocalizationService.tr(en: 'there', sw: 'rafiki');

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // ── Greeting ──────────────────────────────────────────────────
            Text(
              OnboardingStrings.s(sw,
                  en: OnboardingStrings.returningGreetEn(name),
                  sw: OnboardingStrings.returningGreetSw(name)),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyPrimary,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              OnboardingStrings.s(sw,
                  en: OnboardingStrings.returningFoundEn,
                  sw: OnboardingStrings.returningFoundSw),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
            const SizedBox(height: 32),

            // ── Business card ─────────────────────────────────────────────
            _BusinessCard(
              businessName: widget.state.businessName,
              businessType: widget.state.businessType,
              city: widget.state.city,
              isSwahili: sw,
            ),
            const SizedBox(height: 12),
            Text(
              OnboardingStrings.s(sw,
                  en: OnboardingStrings.returningInfoNoteEn,
                  sw: OnboardingStrings.returningInfoNoteSw),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
            const SizedBox(height: 40),

            // ── Error ─────────────────────────────────────────────────────
            if (widget.state.errorMessage != null) ...[
              _ErrorBanner(message: widget.state.errorMessage!),
              const SizedBox(height: 16),
            ],

            // ── Primary CTA ───────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: widget.state.isLoading ? null : widget.onContinue,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.yellowBrand,
                  foregroundColor: AppColors.navyPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: widget.state.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.navyPrimary,
                        ),
                      )
                    : Text(
                        OnboardingStrings.s(sw,
                            en: OnboardingStrings.returningContinueCtaEn,
                            sw: OnboardingStrings.returningContinueCtaSw),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Secondary CTA — start over ────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed:
                    widget.state.isLoading ? null : widget.onStartOver,
                child: Text(
                  OnboardingStrings.s(sw,
                      en: OnboardingStrings.returningStartOverCtaEn,
                      sw: OnboardingStrings.returningStartOverCtaSw),
                  style: TextStyle(
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
        ),
      ),
    );
  }
}

// ─── Business card ────────────────────────────────────────────────────────────

class _BusinessCard extends StatelessWidget {
  const _BusinessCard({
    required this.businessName,
    required this.businessType,
    required this.city,
    required this.isSwahili,
  });

  final String businessName;
  final String businessType;
  final String city;
  final bool isSwahili;

  @override
  Widget build(BuildContext context) {
    final typeLabel = businessType.isNotEmpty
        ? (OnboardingStrings.businessTypes[businessType]?.let(
                (t) => isSwahili ? t.sw : t.en) ??
            businessType)
        : '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: OnboardingColors.lightGreen,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.yellowBrand.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.yellowBrand,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: AppColors.navyPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  businessName.isNotEmpty ? businessName : '—',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyPrimary,
                      ),
                ),
                if (typeLabel.isNotEmpty || city.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    [typeLabel, city]
                        .where((s) => s.isNotEmpty)
                        .join(' · '),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared sub-widgets ───────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension _Let<T> on T {
  R let<R>(R Function(T) block) => block(this);
}
