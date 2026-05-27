import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/validators/onboarding_validator.dart';
import '../../providers/onboarding_notifier.dart';
import '../../../../config/routing.dart';
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
      useRootNavigator: true,
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
    if (s.isComplete) context.go(AppRoutes.success);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);
    final sw = state.isSwahili;
    final name =
        state.firstName.isNotEmpty ? state.firstName : '';

    return OnboardingScaffold(
      onBack: () {
        _pinCtrl.clear();
        context.go(AppRoutes.phone);
      },
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // ── Avatar ─────────────────────────────────────────────────
              _UserAvatar(name: name),
              const SizedBox(height: 20),

              // ── Greeting ──────────────────────────────────────────────
              Text(
                name.isNotEmpty
                    ? (sw
                        ? 'Karibu tena, $name 👋'
                        : 'Welcome back, $name 👋')
                    : (sw ? 'Karibu tena 👋' : 'Welcome back 👋'),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navyPrimary,
                  height: 1.2,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                sw
                    ? 'Biashara yako inakungoja.'
                    : 'Your business is waiting for you.',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),

              // ── Business card ──────────────────────────────────────────
              if (state.businessName.isNotEmpty) ...[
                const SizedBox(height: 24),
                _BusinessCard(
                  businessName: state.businessName,
                  role: state.role,
                  isSwahili: sw,
                ),
              ],

              const SizedBox(height: 36),

              // ── PIN dots ───────────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Text(
                      sw ? 'Ingiza PIN yako' : 'Enter your PIN',
                      style: const TextStyle(
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
                      onComplete: _submit,
                      onChanged: (_) {
                        if (_hasError) setState(() => _hasError = false);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Error ─────────────────────────────────────────────────
              if (state.errorMessage != null) ...[
                OnboardingErrorBanner(message: state.errorMessage!),
                const SizedBox(height: 16),
              ],

              // ── CTA ───────────────────────────────────────────────────
              OnboardingPrimaryButton(
                label: sw ? 'Ingia' : 'Sign in',
                onPressed: state.isLoading ? null : _submit,
                isLoading: state.isLoading,
              ),
              const SizedBox(height: 16),

              // ── Forgot PIN ─────────────────────────────────────────────
              Center(
                child: TextButton(
                  onPressed: state.isLoading
                      ? null
                      : () => _showForgotPin(context, sw),
                  child: Text(
                    sw ? 'Umesahau PIN yako?' : 'Forgot your PIN?',
                    style: const TextStyle(
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
    );
  }
}

// ── User avatar ───────────────────────────────────────────────────────────────

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.navyPrimary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.navyPrimary.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: AppColors.yellowBrand,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
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
            // Success state
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
