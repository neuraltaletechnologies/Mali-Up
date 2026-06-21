import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/providers/connectivity_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/onboarding_strings.dart';
import '../../domain/validators/onboarding_validator.dart';
import '../../providers/onboarding_notifier.dart';
import '../../../../config/routing.dart';
import '_onboarding_scaffold.dart';

/// Screen 6 — PIN creation for new owner accounts.
/// Two-step: set PIN → confirm PIN → save & complete.
class SecuritySetupScreen extends ConsumerStatefulWidget {
  const SecuritySetupScreen({super.key});

  @override
  ConsumerState<SecuritySetupScreen> createState() =>
      _SecuritySetupScreenState();
}

class _SecuritySetupScreenState extends ConsumerState<SecuritySetupScreen>
    with SingleTickerProviderStateMixin {
  final _pinCtrl     = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _pinFocus    = FocusNode();
  final _confirmFocus = FocusNode();

  bool _showConfirm = false;
  bool _pinHasError = false;
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

    final s = ref.read(onboardingNotifierProvider);
    _pinCtrl.text = s.pin;
    _confirmCtrl.text = s.confirmPin;
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

  void _advanceToConfirm() {
    final sw = ref.read(onboardingNotifierProvider).isSwahili;
    final err = OnboardingValidator.validatePin(_pinCtrl.text, isSwahili: sw);
    if (err != null) {
      setState(() => _pinHasError = true);
      return;
    }
    setState(() {
      _pinHasError = false;
      _showConfirm = true;
    });
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) FocusScope.of(context).requestFocus(_confirmFocus);
    });
  }

  Future<void> _submitConfirm() async {
    if (!ref.read(isOnlineProvider)) return;
    final sw = ref.read(onboardingNotifierProvider).isSwahili;
    final err =
        OnboardingValidator.validatePin(_confirmCtrl.text, isSwahili: sw);
    if (err != null || _confirmCtrl.text != _pinCtrl.text) {
      setState(() => _confirmHasError = true);
      return;
    }
    setState(() => _confirmHasError = false);
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    notifier.setPin(_pinCtrl.text);
    notifier.setConfirmPin(_confirmCtrl.text);
    await notifier.saveAndComplete();
    if (!mounted) return;
    if (ref.read(onboardingNotifierProvider).isComplete) {
      context.go(AppRoutes.success);
    }
  }

  void _backToPin() {
    _confirmCtrl.clear();
    setState(() {
      _showConfirm = false;
      _confirmHasError = false;
    });
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) FocusScope.of(context).requestFocus(_pinFocus);
    });
  }

  Future<void> _openWhatsAppHelp(bool sw) async {
    final message = Uri.encodeComponent(
      sw
          ? 'Habari Mali Up Help Desk, nahitaji msaada wa kuweka PIN.'
          : 'Hello Mali Up Help Desk, I need help setting up my PIN.',
    );
    final uri = Uri.parse('${OnboardingStrings.helpDeskUrl}$message');
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
    final isOnline = ref.watch(isOnlineProvider);
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
                    onPressed:
                        _showConfirm ? _backToPin : () => context.go(AppRoutes.business),
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
            maxChildSize: 0.8,
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
                              child: _showConfirm
                                  ? _ConfirmPinBody(
                                      key: const ValueKey('confirm'),
                                      sw: sw,
                                      controller: _confirmCtrl,
                                      focusNode: _confirmFocus,
                                      hasError: _confirmHasError,
                                      isLoading: state.isLoading,
                                      isOnline: isOnline,
                                      errorMessage: state.errorMessage,
                                      onChanged: (_) {
                                        if (_confirmHasError) {
                                          setState(
                                              () => _confirmHasError = false);
                                        }
                                      },
                                      onComplete: _submitConfirm,
                                      onSubmit: _submitConfirm,
                                    )
                                  : _SetPinBody(
                                      key: const ValueKey('set'),
                                      sw: sw,
                                      controller: _pinCtrl,
                                      focusNode: _pinFocus,
                                      hasError: _pinHasError,
                                      isLoading: state.isLoading,
                                      onChanged: (_) {
                                        if (_pinHasError) {
                                          setState(() => _pinHasError = false);
                                        }
                                      },
                                      onComplete: _advanceToConfirm,
                                      onSubmit: _advanceToConfirm,
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

// ── Step 1: Set PIN ────────────────────────────────────────────────────────────

class _SetPinBody extends StatelessWidget {
  const _SetPinBody({
    super.key,
    required this.sw,
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.isLoading,
    required this.onChanged,
    required this.onComplete,
    required this.onSubmit,
  });

  final bool sw;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final bool isLoading;
  final ValueChanged<String> onChanged;
  final VoidCallback onComplete;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sw ? 'Linda akaunti yako 🔐' : 'Secure your account 🔐',
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
              ? 'Tengeneza PIN ya tarakimu 4 utakayotumia kufikia Mali Up.'
              : 'Create a 4-digit PIN you\'ll use to access Mali Up.',
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
                sw ? 'Ingiza PIN mpya' : 'Enter new PIN',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 18),
              PinDotsInput(
                controller: controller,
                focusNode: focusNode,
                hasError: hasError,
                enabled: !isLoading,
                onChanged: onChanged,
                onComplete: onComplete,
              ),
            ],
          ),
        ),

        if (hasError) ...[
          const SizedBox(height: 16),
          const OnboardingErrorBanner(message: 'PIN must be 4 digits.'),
        ],

        const SizedBox(height: 36),

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
            onPressed: onSubmit,
            child: Text(
              sw ? 'Endelea' : 'Continue',
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

// ── Step 2: Confirm PIN ────────────────────────────────────────────────────────

class _ConfirmPinBody extends StatelessWidget {
  const _ConfirmPinBody({
    super.key,
    required this.sw,
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.isLoading,
    required this.isOnline,
    required this.errorMessage,
    required this.onChanged,
    required this.onComplete,
    required this.onSubmit,
  });

  final bool sw;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final bool isLoading;
  final bool isOnline;
  final String? errorMessage;
  final ValueChanged<String> onChanged;
  final VoidCallback onComplete;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sw ? 'Thibitisha PIN yako ✓' : 'Confirm your PIN ✓',
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
              ? 'Ingiza tena PIN yako ili ithibitishwe.'
              : 'Enter your PIN once more to confirm it.',
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
                sw ? 'Thibitisha PIN' : 'Confirm PIN',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 18),
              PinDotsInput(
                controller: controller,
                focusNode: focusNode,
                hasError: hasError,
                enabled: !isLoading,
                onChanged: onChanged,
                onComplete: onComplete,
              ),
            ],
          ),
        ),

        if (hasError) ...[
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

        if (!isOnline) ...[
          const SizedBox(height: 16),
          _OnboardingOfflineBanner(sw: sw),
        ],

        const SizedBox(height: 36),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navyPrimary,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: AppColors.navyPrimary.withValues(alpha: 0.3),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: (isLoading || !isOnline) ? null : onSubmit,
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    sw ? 'Hifadhi & Endelea' : 'Save & Continue',
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

// ── Shared offline banner for onboarding screens ──────────────────────────────

class _OnboardingOfflineBanner extends StatelessWidget {
  final bool sw;
  const _OnboardingOfflineBanner({required this.sw});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFFFD60A).withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.wifi_off_rounded,
              size: 18, color: Color(0xFF856404)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sw ? 'Hakuna mtandao' : 'No internet connection',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF856404),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sw
                      ? 'Tafadhali unganisha mtandao na ujaribu tena.'
                      : 'Please connect to the internet and try again.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF856404),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
