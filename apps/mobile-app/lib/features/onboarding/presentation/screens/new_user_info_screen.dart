import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Future<void> _openWhatsAppHelp(bool sw) async {
    final message = Uri.encodeComponent(
      sw
          ? 'Habari Mali Up Help Desk, nahitaji msaada wa kusajili.'
          : 'Hello Mali Up Help Desk, I need help with registration.',
    );
    final uri = Uri.parse('https://wa.me/255653520829?text=$message');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sw
              ? 'Hatukuweza kufungua WhatsApp sasa.'
              : 'We could not open WhatsApp right now.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);
    final sw    = state.isSwahili;
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
          // Header image
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

          // Top navigation bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => context.go(AppRoutes.phone),
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

          // Main content sheet
          DraggableScrollableSheet(
            initialChildSize: 0.68,
            minChildSize: 0.68,
            maxChildSize: 0.96,
            builder: (context, scrollController) {
              return Container(
                clipBehavior: Clip.hardEdge,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(28)),
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
                    opacity: _fade,
                    child: SlideTransition(
                      position: _slide,
                      child: Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          controller: scrollController,
                          physics: const ClampingScrollPhysics(),
                          padding:
                              const EdgeInsets.fromLTRB(24, 24, 24, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Handle bar
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

                              // Title
                              Center(
                                child: Text(
                                  OnboardingStrings.s(sw,
                                      en: OnboardingStrings.newUserTitleEn,
                                      sw: OnboardingStrings.newUserTitleSw),
                                  textAlign: TextAlign.center,
                                  style: headingStyle,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: Text(
                                  OnboardingStrings.s(sw,
                                      en: OnboardingStrings.newUserSubEn,
                                      sw: OnboardingStrings.newUserSubSw),
                                  textAlign: TextAlign.center,
                                  style: subtitleStyle,
                                ),
                              ),
                              const SizedBox(height: 28),

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
                                prefix: const Icon(Icons.badge_outlined,
                                    size: 18, color: AppColors.textMuted),
                                validator: (v) =>
                                    OnboardingValidator.validateName(
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
                                prefix: const Icon(Icons.badge_outlined,
                                    size: 18, color: AppColors.textMuted),
                                validator: (v) =>
                                    OnboardingValidator.validateName(
                                        v ?? '', isSwahili: sw),
                              ),
                              const SizedBox(height: 16),

                              // Email (optional)
                              OnboardingField(
                                controller: _emailCtrl,
                                label: sw
                                    ? 'BARUA PEPE (HIARI)'
                                    : 'EMAIL (OPTIONAL)',
                                hint: sw ? 'jina@mfano.com' : 'you@example.com',
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.done,
                                prefix: const Icon(
                                    Icons.alternate_email_rounded,
                                    size: 18,
                                    color: AppColors.textMuted),
                                validator: (v) => OnboardingValidator.validateEmail(
                                    v ?? '', isSwahili: sw, optional: true),
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
                                        fontSize: 12,
                                        color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),

                              // Error
                              if (state.errorMessage != null) ...[
                                OnboardingErrorBanner(
                                    message: state.errorMessage!),
                                const SizedBox(height: 16),
                              ],

                              // CTA button
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.navyPrimary,
                                    elevation: 4,
                                    shadowColor: AppColors.primary
                                        .withValues(alpha: 0.3),
                                    minimumSize: const Size.fromHeight(52),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: _submit,
                                  child: Text(
                                    OnboardingStrings.s(sw,
                                        en: OnboardingStrings.newUserCtaEn,
                                        sw: OnboardingStrings.newUserCtaSw),
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
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
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
