import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/onboarding_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/onboarding_notifier.dart';
import '../../../../config/routing.dart';

class OnboardingSuccessScreen extends ConsumerStatefulWidget {
  const OnboardingSuccessScreen({super.key});

  @override
  ConsumerState<OnboardingSuccessScreen> createState() =>
      _OnboardingSuccessScreenState();
}

class _OnboardingSuccessScreenState
    extends ConsumerState<OnboardingSuccessScreen>
    with TickerProviderStateMixin {
  late final AnimationController _checkCtrl;
  late final AnimationController _contentCtrl;
  late final Animation<double> _checkScale;
  late final Animation<double> _checkOpacity;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();

    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    );
    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _checkScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut),
    );
    _checkOpacity =
        CurvedAnimation(parent: _checkCtrl, curve: const Interval(0, 0.4));

    _contentFade =
        CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut);
    _contentSlide =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOutCubic),
    );

    // Stagger: check mark animates first, then content slides in.
    _checkCtrl.forward().whenComplete(() {
      if (mounted) _contentCtrl.forward();
    });
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);
    final sw = state.isSwahili;
    final firstName = state.firstName;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Animated checkmark ─────────────────────────────────────────
              ScaleTransition(
                scale: _checkScale,
                child: FadeTransition(
                  opacity: _checkOpacity,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.yellowBrand,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.yellowBrand.withValues(alpha: 0.35),
                          blurRadius: 28,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 52,
                      color: AppColors.navyPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // ── Title + body ───────────────────────────────────────────────
              FadeTransition(
                opacity: _contentFade,
                child: SlideTransition(
                  position: _contentSlide,
                  child: Column(
                    children: [
                      Text(
                        firstName.isNotEmpty
                            ? OnboardingStrings.s(sw,
                                en: OnboardingStrings.successTitleEn(firstName),
                                sw: OnboardingStrings.successTitleSw(firstName))
                            : OnboardingStrings.s(sw,
                                en: "You're all set!",
                                sw: 'Umewekwa vizuri!'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.navyPrimary,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        OnboardingStrings.s(sw,
                            en: OnboardingStrings.successBodyEn,
                            sw: OnboardingStrings.successBodySw),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textMuted,
                              height: 1.5,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        OnboardingStrings.s(sw,
                            en: OnboardingStrings.successWelcomeTagEn,
                            sw: OnboardingStrings.successWelcomeTagSw),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // ── CTA — Go to Dashboard ──────────────────────────────────────
              FadeTransition(
                opacity: _contentFade,
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => context.go(AppRoutes.dashboard),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.navyPrimary,
                      foregroundColor: AppColors.inverseText,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      OnboardingStrings.s(sw,
                          en: OnboardingStrings.successCtaEn,
                          sw: OnboardingStrings.successCtaSw),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
