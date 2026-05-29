import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/validators/onboarding_validator.dart';
import '../../providers/onboarding_notifier.dart';
import '../../../../config/routing.dart';
import '_onboarding_scaffold.dart';

/// Screen 4B — shown when the phone number matches a pending team-member
/// invitation. The member can continue with this account or start fresh.
class TeamMemberSetupScreen extends ConsumerStatefulWidget {
  const TeamMemberSetupScreen({super.key});

  @override
  ConsumerState<TeamMemberSetupScreen> createState() =>
      _TeamMemberSetupScreenState();
}

class _TeamMemberSetupScreenState
    extends ConsumerState<TeamMemberSetupScreen>
    with SingleTickerProviderStateMixin {
  bool _showPinSetup = false;

  final _pinCtrl     = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _pinFocus    = FocusNode();
  final _confirmFocus = FocusNode();
  bool _onConfirmStep = false;
  bool _pinHasError     = false;
  bool _confirmHasError = false;

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
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _pinCtrl.dispose();
    _confirmCtrl.dispose();
    _pinFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _continueAsTeamMember() {
    ref.read(onboardingNotifierProvider.notifier).continueAsTeamMember();
    setState(() => _showPinSetup = true);
  }

  Future<void> _startOver() async {
    final state = ref.read(onboardingNotifierProvider);
    final sw = state.isSwahili;
    final businessName = state.businessName;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StartFreshWarningSheet(
        sw: sw,
        businessName: businessName,
      ),
    );

    if (confirmed == true && mounted) {
      ref.read(onboardingNotifierProvider.notifier).startOverFromTeamMember();
      context.go(AppRoutes.newUser);
    }
  }

  void _advanceToConfirm() {
    final sw = ref.read(onboardingNotifierProvider).isSwahili;
    final err = OnboardingValidator.validatePin(_pinCtrl.text, isSwahili: sw);
    if (err != null) { setState(() => _pinHasError = true); return; }
    setState(() { _pinHasError = false; _onConfirmStep = true; });
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) FocusScope.of(context).requestFocus(_confirmFocus);
    });
  }

  Future<void> _savePin() async {
    final sw = ref.read(onboardingNotifierProvider).isSwahili;
    final err =
        OnboardingValidator.validatePin(_confirmCtrl.text, isSwahili: sw);
    if (err != null || _confirmCtrl.text != _pinCtrl.text) {
      setState(() => _confirmHasError = true);
      return;
    }
    setState(() => _confirmHasError = false);
    await ref
        .read(onboardingNotifierProvider.notifier)
        .saveTeamMemberPin(_pinCtrl.text.trim());
    if (!mounted) return;
    if (ref.read(onboardingNotifierProvider).isComplete) {
      context.go(AppRoutes.success);
    }
  }

  VoidCallback get _onBack {
    if (_showPinSetup && _onConfirmStep) {
      return () {
        _confirmCtrl.clear();
        setState(() { _onConfirmStep = false; _confirmHasError = false; });
        Future.delayed(const Duration(milliseconds: 80), () {
          if (mounted) FocusScope.of(context).requestFocus(_pinFocus);
        });
      };
    }
    if (_showPinSetup) return () => setState(() => _showPinSetup = false);
    return () => context.go(AppRoutes.phone);
  }

  Future<void> _openWhatsAppHelp(bool sw) async {
    final message = Uri.encodeComponent(
      sw
          ? 'Habari Mali Up Help Desk, nahitaji msaada wa mwaliko wa timu.'
          : 'Hello Mali Up Help Desk, I need help with my team invitation.',
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
    final sw = state.isSwahili;
    final name = state.firstName.isNotEmpty ? state.firstName : state.fullName;
    final topHeight = MediaQuery.of(context).size.height * 0.35;

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
                    onPressed: _onBack,
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

                            // Animated content switcher
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 320),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeIn,
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.08, 0),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              ),
                              child: _showPinSetup
                                  ? _PinSetupBody(
                                      key: ValueKey('pin_$_onConfirmStep'),
                                      sw: sw,
                                      pinCtrl: _pinCtrl,
                                      confirmCtrl: _confirmCtrl,
                                      pinFocus: _pinFocus,
                                      confirmFocus: _confirmFocus,
                                      onConfirmStep: _onConfirmStep,
                                      pinHasError: _pinHasError,
                                      confirmHasError: _confirmHasError,
                                      isLoading: state.isLoading,
                                      errorMessage: state.errorMessage,
                                      onPinChanged: (_) {
                                        if (_pinHasError) {
                                          setState(() => _pinHasError = false);
                                        }
                                      },
                                      onConfirmChanged: (_) {
                                        if (_confirmHasError) {
                                          setState(
                                              () => _confirmHasError = false);
                                        }
                                      },
                                      onPinComplete: _advanceToConfirm,
                                      onConfirmComplete: _savePin,
                                      onPinSubmit: _advanceToConfirm,
                                      onConfirmSubmit: _savePin,
                                    )
                                  : _InvitationBody(
                                      key: const ValueKey('invite'),
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

// ── Invitation card body ──────────────────────────────────────────────────────

class _InvitationBody extends StatelessWidget {
  const _InvitationBody({
    super.key,
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
        Text(
          sw ? 'Tumepata mwaliko wako 🎉' : 'We found your invitation 🎉',
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.navyPrimary,
            height: 1.2,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          sw
              ? 'Uliombwa kujiunga na biashara hii kama mwanachama wa timu.'
              : 'You\'ve been invited to join this business as a team member.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.textMuted,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),

        // Invitation card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.navyPrimary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.navyPrimary.withValues(alpha: 0.20),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
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
                    child: const Icon(Icons.storefront_rounded,
                        color: AppColors.navyPrimary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sw ? 'Biashara' : 'Business',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.55),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          businessName.isNotEmpty ? businessName : '—',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (role.isNotEmpty) ...[
                const SizedBox(height: 16),
                Divider(height: 1, color: Colors.white.withValues(alpha: 0.12)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.badge_outlined,
                        size: 16, color: Colors.white54),
                    const SizedBox(width: 8),
                    Text(
                      sw ? 'Jukumu lako: ' : 'Your role: ',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.60),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.yellowBrand,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        role,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              if (name.isNotEmpty) ...[
                const SizedBox(height: 16),
                Divider(height: 1, color: Colors.white.withValues(alpha: 0.12)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded,
                        size: 16, color: Colors.white54),
                    const SizedBox(width: 8),
                    Text(
                      sw ? 'Jina lako: ' : 'Your name: ',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.60),
                      ),
                    ),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 32),

        if (errorMessage != null) ...[
          OnboardingErrorBanner(message: errorMessage!),
          const SizedBox(height: 16),
        ],

        // Primary CTA
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.navyPrimary,
              elevation: 4,
              shadowColor: AppColors.primary.withValues(alpha: 0.3),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: isLoading ? null : onContinue,
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.navyPrimary,
                    ),
                  )
                : Text(
                    sw
                        ? 'Endelea na akaunti hii'
                        : 'Continue with this account',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),

        // Secondary — start fresh
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: isLoading ? null : onStartOver,
            child: Text(
              sw ? 'Anza upya badala yake' : 'Start fresh instead',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── PIN setup body ────────────────────────────────────────────────────────────

class _PinSetupBody extends StatelessWidget {
  const _PinSetupBody({
    super.key,
    required this.sw,
    required this.pinCtrl,
    required this.confirmCtrl,
    required this.pinFocus,
    required this.confirmFocus,
    required this.onConfirmStep,
    required this.pinHasError,
    required this.confirmHasError,
    required this.isLoading,
    required this.errorMessage,
    required this.onPinChanged,
    required this.onConfirmChanged,
    required this.onPinComplete,
    required this.onConfirmComplete,
    required this.onPinSubmit,
    required this.onConfirmSubmit,
  });

  final bool sw;
  final TextEditingController pinCtrl;
  final TextEditingController confirmCtrl;
  final FocusNode pinFocus;
  final FocusNode confirmFocus;
  final bool onConfirmStep;
  final bool pinHasError;
  final bool confirmHasError;
  final bool isLoading;
  final String? errorMessage;
  final ValueChanged<String> onPinChanged;
  final ValueChanged<String> onConfirmChanged;
  final VoidCallback onPinComplete;
  final VoidCallback onConfirmComplete;
  final VoidCallback onPinSubmit;
  final VoidCallback onConfirmSubmit;

  @override
  Widget build(BuildContext context) {
    final isConfirm = onConfirmStep;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.navyPrimary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.navyPrimary.withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.lock_rounded,
            color: AppColors.yellowBrand,
            size: 26,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          isConfirm
              ? (sw ? 'Thibitisha PIN yako ✓' : 'Confirm your PIN ✓')
              : (sw ? 'Weka PIN yako 🔐' : 'Set your PIN 🔐'),
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.navyPrimary,
            height: 1.2,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isConfirm
              ? (sw
                  ? 'Ingiza tena PIN yako ili ithibitishwe.'
                  : 'Enter your PIN once more to confirm.')
              : (sw
                  ? 'Tengeneza PIN ya tarakimu 4 utakayotumia kuingia.'
                  : 'Create a 4-digit PIN to access your account.'),
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.textMuted,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 40),

        Center(
          child: Column(
            children: [
              Text(
                isConfirm
                    ? (sw ? 'Thibitisha PIN' : 'Confirm PIN')
                    : (sw ? 'Ingiza PIN mpya' : 'Enter new PIN'),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 18),
              PinDotsInput(
                controller: isConfirm ? confirmCtrl : pinCtrl,
                focusNode: isConfirm ? confirmFocus : pinFocus,
                hasError: isConfirm ? confirmHasError : pinHasError,
                enabled: !isLoading,
                onChanged: isConfirm ? onConfirmChanged : onPinChanged,
                onComplete: isConfirm ? onConfirmComplete : onPinComplete,
              ),
            ],
          ),
        ),

        if (pinHasError && !isConfirm) ...[
          const SizedBox(height: 16),
          OnboardingErrorBanner(
              message: sw
                  ? 'PIN lazima iwe tarakimu 4.'
                  : 'PIN must be 4 digits.'),
        ],
        if (confirmHasError && isConfirm) ...[
          const SizedBox(height: 16),
          OnboardingErrorBanner(
            message: sw
                ? 'PIN hazifanani. Jaribu tena.'
                : 'PINs do not match. Please try again.',
          ),
        ],
        if (errorMessage != null) ...[
          const SizedBox(height: 16),
          OnboardingErrorBanner(message: errorMessage!),
        ],

        const SizedBox(height: 36),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isConfirm ? AppColors.navyPrimary : AppColors.primary,
              foregroundColor:
                  isConfirm ? Colors.white : AppColors.navyPrimary,
              elevation: 4,
              shadowColor: isConfirm
                  ? AppColors.navyPrimary.withValues(alpha: 0.3)
                  : AppColors.primary.withValues(alpha: 0.3),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed:
                isLoading ? null : (isConfirm ? onConfirmSubmit : onPinSubmit),
            child: isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: isConfirm ? Colors.white : AppColors.navyPrimary,
                    ),
                  )
                : Text(
                    isConfirm
                        ? (sw ? 'Hifadhi & Endelea' : 'Save & Continue')
                        : (sw ? 'Endelea' : 'Continue'),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── "Start fresh" security warning sheet ──────────────────────────────────────

class _StartFreshWarningSheet extends StatelessWidget {
  const _StartFreshWarningSheet({
    required this.sw,
    required this.businessName,
  });

  final bool sw;
  final String businessName;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Warning icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.warningBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: AppColors.warning, size: 28),
          ),
          const SizedBox(height: 20),

          Text(
            sw
                ? 'Nambari hii tayari imeunganishwa na akaunti'
                : 'This number is already linked to an account',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.navyPrimary,
              height: 1.25,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),

          Text(
            sw
                ? 'Nambari hii ilipewa mwaliko kujiunga na '
                    '${businessName.isNotEmpty ? businessName : "biashara hii"}. '
                    'Kuanzisha akaunti mpya kutaunda wasifu tofauti — '
                    'mwaliko utabaki wazi ukitaka kuudai baadaye.'
                : 'This number has a pending invitation to join '
                    '${businessName.isNotEmpty ? businessName : "a business"}. '
                    'Creating a new account will build a separate profile — '
                    'the invitation stays open if you want to claim it later.',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 28),

          // Confirm
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                sw
                    ? 'Ndiyo, anza akaunti mpya'
                    : 'Yes, create a new account',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Cancel
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                sw
                    ? 'Rudi kudai mwaliko wangu'
                    : 'Go back and claim my invitation',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
