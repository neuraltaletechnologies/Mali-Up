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
  late final AnimationController _ringCtrl;
  late final AnimationController _contentCtrl;

  late final Animation<double> _checkScale;
  late final Animation<double> _checkOpacity;
  late final Animation<double> _ringScale;
  late final Animation<double> _ringOpacity;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();

    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    );
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
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

    _ringScale = Tween<double>(begin: 0.6, end: 1.5).animate(
      CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut),
    );
    _ringOpacity = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut),
    );

    _contentFade =
        CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut);
    _contentSlide =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOutCubic),
    );

    // Stagger: check → ring pulse → content
    _checkCtrl.forward().whenComplete(() {
      if (mounted) {
        _ringCtrl.forward();
        _contentCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    _ringCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state       = ref.watch(onboardingNotifierProvider);
    final sw          = state.isSwahili;
    final firstName   = state.firstName;
    final bizName     = state.businessName;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Decorative background orbs ─────────────────────────────────
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.yellowBrand.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              left: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.tealAccent.withValues(alpha: 0.05),
                ),
              ),
            ),

            // ── Main content ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // ── Animated check + ring pulse ──────────────────────────
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Expanding ring
                        FadeTransition(
                          opacity: _ringOpacity,
                          child: ScaleTransition(
                            scale: _ringScale,
                            child: Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.yellowBrand,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Check circle
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
                                    color: AppColors.yellowBrand
                                        .withValues(alpha: 0.38),
                                    blurRadius: 32,
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  // ── Title + subtitle ─────────────────────────────────────
                  FadeTransition(
                    opacity: _contentFade,
                    child: SlideTransition(
                      position: _contentSlide,
                      child: Column(
                        children: [
                          Text(
                            firstName.isNotEmpty
                                ? OnboardingStrings.s(sw,
                                    en: OnboardingStrings
                                        .successTitleEn(firstName),
                                    sw: OnboardingStrings
                                        .successTitleSw(firstName))
                                : OnboardingStrings.s(sw,
                                    en: "You're all set! 🎉",
                                    sw: 'Umewekwa vizuri! 🎉'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navyPrimary,
                              height: 1.15,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            OnboardingStrings.s(sw,
                                en: OnboardingStrings.successBodyEn,
                                sw: OnboardingStrings.successBodySw),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textMuted,
                              height: 1.55,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ── Feature pills ──────────────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _FeaturePill(
                                icon: Icons.point_of_sale_rounded,
                                label: sw ? 'Mauzo' : 'Sales',
                              ),
                              const SizedBox(width: 8),
                              _FeaturePill(
                                icon: Icons.inventory_rounded,
                                label: sw ? 'Stoo' : 'Stock',
                              ),
                              const SizedBox(width: 8),
                              _FeaturePill(
                                icon: Icons.receipt_long_rounded,
                                label: sw ? 'Risiti' : 'Invoices',
                              ),
                            ],
                          ),

                          // ── Business name card ─────────────────────────────
                          if (bizName.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _BusinessReadyCard(
                              businessName: bizName,
                              isSwahili: sw,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),

                  // ── Welcome tag + CTA ────────────────────────────────────
                  FadeTransition(
                    opacity: _contentFade,
                    child: Column(
                      children: [
                        Text(
                          OnboardingStrings.s(sw,
                              en: OnboardingStrings.successWelcomeTagEn,
                              sw: OnboardingStrings.successWelcomeTagSw),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: _GoToDashboardButton(
                            label: OnboardingStrings.s(sw,
                                en: OnboardingStrings.successCtaEn,
                                sw: OnboardingStrings.successCtaSw),
                            onPressed: () => context.go(AppRoutes.dashboard),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Feature pill ──────────────────────────────────────────────────────────────

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.success),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.navyPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Business ready card ───────────────────────────────────────────────────────

class _BusinessReadyCard extends StatelessWidget {
  const _BusinessReadyCard({
    required this.businessName,
    required this.isSwahili,
  });

  final String businessName;
  final bool isSwahili;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowCard,
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.navyPrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.storefront_rounded,
                color: AppColors.yellowBrand, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  businessName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  isSwahili ? 'Eneo lako liko tayari' : 'Your workspace is ready',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              isSwahili ? 'Tayari ✓' : 'Ready ✓',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Go to Dashboard button with press animation ───────────────────────────────

class _GoToDashboardButton extends StatefulWidget {
  const _GoToDashboardButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  State<_GoToDashboardButton> createState() => _GoToDashboardButtonState();
}

class _GoToDashboardButtonState extends State<_GoToDashboardButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 180),
      lowerBound: 0.97,
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
          widget.onPressed();
        },
        onTapCancel: () => _pressCtrl.forward(),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.navyPrimary,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.navyPrimary.withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded,
                  color: AppColors.yellowBrand, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
