import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/routing.dart';
import '../../../../core/constants/onboarding_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../rbac/data/rbac_providers.dart' show permissionsLoadedProvider;
import '../../providers/onboarding_notifier.dart';

class OnboardingSuccessScreen extends ConsumerStatefulWidget {
  const OnboardingSuccessScreen({super.key});

  @override
  ConsumerState<OnboardingSuccessScreen> createState() =>
      _OnboardingSuccessScreenState();
}

class _OnboardingSuccessScreenState
    extends ConsumerState<OnboardingSuccessScreen>
    with TickerProviderStateMixin {
  late final AnimationController _contentCtrl;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _contentFade = CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut);
    _contentSlide =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
          CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOutCubic),
        );

    _contentCtrl.forward();
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _openWhatsAppHelp(bool sw) async {
    final message = Uri.encodeComponent(
      sw
          ? 'Habari Mali Up Help Desk, nimekamilisha usajili wangu.'
          : 'Hello Mali Up Help Desk, I have completed onboarding.',
    );
    final uri = Uri.parse('${OnboardingStrings.helpDeskUrl}$message');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _goBack() {
    final state = ref.read(onboardingNotifierProvider);
    if (state.isTeamMember) {
      context.go(AppRoutes.teamSetup);
      return;
    }
    if (state.isReturningUser) {
      context.go(AppRoutes.pinLogin);
      return;
    }
    context.go(AppRoutes.security);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);
    final sw = state.isSwahili;

    // For brand-new owners the users/{uid} Firestore doc is written just
    // before this screen appears.  Wait for it to be reflected in the RBAC
    // providers before allowing navigation to the dashboard — otherwise the
    // dashboard can render with denied() permissions on the first frame.
    final isNewOwner = !state.isReturningUser && !state.isTeamMember;
    final permissionsReady = ref.watch(permissionsLoadedProvider);
    final canNavigate = !isNewOwner || permissionsReady;

    if (kDebugMode && isNewOwner) {
      debugPrint('[SuccessScreen] permissionsReady=$permissionsReady canNavigate=$canNavigate');
    }
    final firstName = state.firstName;
    final bizName = state.businessName;
    final topHeight = MediaQuery.of(context).size.height * 0.35;

    final headingStyle = GoogleFonts.poppins(
      fontSize: 28,
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w800,
      height: 1.15,
      letterSpacing: -0.5,
    );
    final subtitleStyle = GoogleFonts.poppins(
      color: AppColors.textSecondary,
      fontSize: 14,
      height: 1.5,
      fontWeight: FontWeight.w400,
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: topHeight,
            child: ClipRect(
              child: Image.asset(
                'assets/Picture/sign_up.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _goBack,
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      padding: const EdgeInsets.all(10),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _openWhatsAppHelp(sw),
                    icon: const Icon(
                      Icons.headset_mic_outlined,
                      color: Colors.white,
                      size: 15,
                    ),
                    label: Text(
                      sw ? 'Msaada' : 'Help',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.68,
            minChildSize: 0.68,
            maxChildSize: 0.8,
            builder: (context, scrollController) {
              return Container(
                clipBehavior: Clip.hardEdge,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: NotificationListener<OverscrollIndicatorNotification>(
                  onNotification: (overscroll) {
                    overscroll.disallowIndicator();
                    return true;
                  },
                  child: FadeTransition(
                    opacity: _contentFade,
                    child: SlideTransition(
                      position: _contentSlide,
                      child: SingleChildScrollView(
                        controller: scrollController,
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: AppColors.border,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            Center(
                              child: Text(
                                firstName.isNotEmpty
                                    ? OnboardingStrings.s(
                                        sw,
                                        en: OnboardingStrings.successTitleEn(
                                          firstName,
                                        ),
                                        sw: OnboardingStrings.successTitleSw(
                                          firstName,
                                        ),
                                      )
                                    : OnboardingStrings.s(
                                        sw,
                                        en: "You're all set! 🎉",
                                        sw: 'Umewekwa vizuri! 🎉',
                                      ),
                                textAlign: TextAlign.center,
                                style: headingStyle,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                OnboardingStrings.s(
                                  sw,
                                  en: OnboardingStrings.successBodyEn,
                                  sw: OnboardingStrings.successBodySw,
                                ),
                                textAlign: TextAlign.center,
                                style: subtitleStyle,
                              ),
                            ),
                            const SizedBox(height: 28),
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _RoundFeatureCard(
                                    icon: Icons.point_of_sale_rounded,
                                    label: sw ? 'Mauzo' : 'Sales',
                                  ),
                                  const SizedBox(width: 10),
                                  _RoundFeatureCard(
                                    icon: Icons.inventory_rounded,
                                    label: sw ? 'Stoo' : 'Stock',
                                  ),
                                  const SizedBox(width: 10),
                                  _RoundFeatureCard(
                                    icon: Icons.receipt_long_rounded,
                                    label: sw ? 'Risiti' : 'Invoices',
                                  ),
                                ],
                              ),
                            ),
                            if (bizName.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              _BusinessReadyCard(
                                businessName: bizName,
                                isSwahili: sw,
                              ),
                            ],
                            const SizedBox(height: 32),
                            Text(
                              OnboardingStrings.s(
                                sw,
                                en: OnboardingStrings.successWelcomeTagEn,
                                sw: OnboardingStrings.successWelcomeTagSw,
                              ),
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
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.navyPrimary,
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  shadowColor: AppColors.navyPrimary.withValues(
                                    alpha: 0.3,
                                  ),
                                  minimumSize: const Size.fromHeight(52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: canNavigate
                                    ? () => context.go(AppRoutes.dashboard)
                                    : null,
                                child: canNavigate
                                    ? Text(
                                        OnboardingStrings.s(
                                          sw,
                                          en: OnboardingStrings.successCtaEn,
                                          sw: OnboardingStrings.successCtaSw,
                                        ),
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      )
                                    : const SizedBox.square(
                                        dimension: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RoundFeatureCard extends StatelessWidget {
  const _RoundFeatureCard({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowCard,
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 24, color: AppColors.success),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.navyPrimary,
          ),
        ),
      ],
    );
  }
}

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
            child: const Icon(
              Icons.storefront_rounded,
              color: AppColors.yellowBrand,
              size: 22,
            ),
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
                  isSwahili
                      ? 'Eneo lako liko tayari'
                      : 'Your workspace is ready',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
