import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/onboarding_strings.dart';
import '../../domain/validators/onboarding_validator.dart';
import '../../providers/onboarding_notifier.dart';
import '../../../../config/routing.dart';
import '../../../rbac/data/rbac_providers.dart' show permissionsLoadedProvider;
import '_onboarding_scaffold.dart';

/// Screen 4A — shown when an existing owner/activated team member
/// enters their phone and the account is found. They sign in with their PIN.
class PinLoginScreen extends ConsumerStatefulWidget {
  const PinLoginScreen({super.key});

  @override
  ConsumerState<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends ConsumerState<PinLoginScreen>
    with SingleTickerProviderStateMixin {
  final _pinCtrl = TextEditingController();
  bool _hasError = false;

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
    super.dispose();
  }

  void _showForgotPin(BuildContext ctx, bool sw) {
    showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ForgotPinSheet(sw: sw),
    );
  }

  Future<void> _submit() async {
    final pin = _pinCtrl.text.trim();
    final isSwahili = ref.read(onboardingNotifierProvider).isSwahili;
    final err = OnboardingValidator.validatePin(pin, isSwahili: isSwahili);
    if (err != null) {
      setState(() => _hasError = true);
      return;
    }
    setState(() => _hasError = false);
    await ref.read(onboardingNotifierProvider.notifier).loginWithPin(pin);
    if (!mounted) return;
    final s = ref.read(onboardingNotifierProvider);
    if (s.errorMessage != null) setState(() => _hasError = true);
    // Navigation is handled by the router redirect: when isComplete = true AND
    // permissionsLoadedProvider = true, _RouterNotifier redirects to dashboard.
    // Do NOT call context.go() here — it would bypass the RBAC loading gate and
    // render the dashboard with denied() permissions on the first frame.
  }

  Future<void> _openWhatsAppHelp(bool sw) async {
    final message = Uri.encodeComponent(
      sw
          ? 'Habari Mali Up Help Desk, nahitaji msaada wa kuingia.'
          : 'Hello Mali Up Help Desk, I need help with login.',
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
    final permissionsLoaded = ref.watch(permissionsLoadedProvider);
    // Keep showing the loading indicator after loginWithPin() completes while
    // the RBAC providers are settling (Firestore snap in-flight).  Once both
    // isComplete and permissionsLoaded are true, the router redirects to /.
    final isLoading = state.isLoading || (state.isComplete && !permissionsLoaded);
    final sw = state.isSwahili;
    final name = state.firstName.isNotEmpty ? state.firstName : '';
    final topHeight = MediaQuery.of(context).size.height * 0.35;

    final headingStyle = GoogleFonts.poppins(
      fontSize: 26,
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w800,
      height: 1.2,
      letterSpacing: -0.4,
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
                    onPressed: () {
                      _pinCtrl.clear();
                      context.go(AppRoutes.phone);
                    },
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
                            // Greeting heading
                            Center(
                              child: Text(
                                name.isNotEmpty
                                    ? (sw
                                        ? 'Karibu tena, $name 👋'
                                        : 'Welcome back, $name 👋')
                                    : (sw
                                        ? 'Karibu tena 👋'
                                        : 'Welcome back 👋'),
                                textAlign: TextAlign.center,
                                style: headingStyle,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Center(
                              child: Text(
                                sw
                                    ? 'Biashara yako inakungoja.'
                                    : 'Your business is waiting for you.',
                                textAlign: TextAlign.center,
                                style: subtitleStyle,
                              ),
                            ),

                            // Business card
                            if (state.businessName.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              _BusinessCard(
                                businessName: state.businessName,
                                role: state.role,
                                isSwahili: sw,
                              ),
                            ],

                            const SizedBox(height: 36),

                            // PIN dots
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    sw ? 'Ingiza PIN yako' : 'Enter your PIN',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textMuted,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  PinDotsInput(
                                    controller: _pinCtrl,
                                    hasError: _hasError,
                                    enabled: !isLoading,
                                    onComplete: _submit,
                                    onChanged: (_) {
                                      if (_hasError) {
                                        setState(() => _hasError = false);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

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
                                  shadowColor:
                                      AppColors.primary.withValues(alpha: 0.3),
                                  minimumSize: const Size.fromHeight(52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed:
                                    isLoading ? null : _submit,
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
                                        sw ? 'Ingia' : 'Sign in',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Loading status label
                            if (isLoading)
                              Center(
                                child: Text(
                                  sw
                                      ? 'Inakuingia, subiri kidogo…'
                                      : 'Signing you in, please wait…',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),

                            // Forgot PIN
                            Center(
                              child: TextButton(
                                onPressed: isLoading
                                    ? null
                                    : () => _showForgotPin(context, sw),
                                child: Text(
                                  sw
                                      ? 'Umesahau PIN yako?'
                                      : 'Forgot your PIN?',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.navySecondary,
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

// ── Business info card ────────────────────────────────────────────────────────

class _BusinessCard extends StatelessWidget {
  const _BusinessCard({
    required this.businessName,
    required this.role,
    required this.isSwahili,
  });

  final String businessName;
  final String role;
  final bool isSwahili;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
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
                  businessName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (role.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.navySecondary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      role,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navySecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.verified_rounded,
              color: AppColors.success, size: 18),
        ],
      ),
    );
  }
}

// ── Forgot PIN recovery sheet ─────────────────────────────────────────────────

class _ForgotPinSheet extends ConsumerStatefulWidget {
  const _ForgotPinSheet({required this.sw});
  final bool sw;

  @override
  ConsumerState<_ForgotPinSheet> createState() => _ForgotPinSheetState();
}

class _ForgotPinSheetState extends ConsumerState<_ForgotPinSheet> {
  bool _isSending = false;
  bool _sent = false;

  Future<void> _sendRecovery() async {
    setState(() => _isSending = true);
    await ref.read(onboardingNotifierProvider.notifier).sendPinRecovery();
    if (mounted) setState(() { _isSending = false; _sent = true; });
  }

  @override
  Widget build(BuildContext context) {
    final sw = widget.sw;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 20, 24,
        MediaQuery.of(context).viewInsets.bottom + 40,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Icon
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: AppColors.navyPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.lock_reset_rounded,
                color: AppColors.navyPrimary, size: 28),
          ),
          const SizedBox(height: 20),

          Text(
            sw ? 'Msaada wa PIN 🔐' : 'PIN Recovery 🔐',
            style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.w800,
              color: AppColors.navyPrimary, letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),

          if (!_sent) ...[
            Text(
              sw
                  ? 'Tutakutumia maelekezo ya kurejesha PIN yako. '
                    'Hakikisha unaweza kufikia barua pepe au simu yako.'
                  : 'We\'ll send recovery instructions so you can reset your PIN. '
                    'Make sure you have access to your registered contact.',
              style: const TextStyle(
                fontSize: 14, color: AppColors.textMuted, height: 1.55,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.infoBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.tealAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.tealAccent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      sw
                          ? 'Baada ya kupokea ujumbe, fuata maelekezo '
                            'kurejesha ufikiaji wako salama.'
                          : 'After receiving the message, follow the link '
                            'to securely restore your account access.',
                      style: const TextStyle(
                        fontSize: 12, color: AppColors.tealAccent, height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _isSending ? null : _sendRecovery,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyPrimary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.navyPrimary.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isSending
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(
                        sw ? 'Tuma Maelekezo' : 'Send Recovery Link',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    sw ? 'Imetumwa! ✓' : 'Sent! ✓',
                    style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sw
                        ? 'Maelekezo ya kurejesha PIN yametumwa. '
                          'Angalia barua pepe yako na ufuate hatua zilizotolewa.'
                        : 'Recovery instructions have been sent. '
                          'Check your email and follow the steps provided.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13, color: AppColors.success, height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  sw ? 'Sawa, nimepokea' : 'Got it, close',
                  style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: AppColors.navyPrimary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
