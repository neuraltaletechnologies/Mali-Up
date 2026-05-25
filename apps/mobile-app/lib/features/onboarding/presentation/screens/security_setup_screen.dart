import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
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

  // ── Step 1: validate PIN and advance to confirm step ───────────────────────
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
    // Slight delay so the UI rebuilds before requesting focus
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) FocusScope.of(context).requestFocus(_confirmFocus);
    });
  }

  // ── Step 2: confirm PIN matches, then save ─────────────────────────────────
  Future<void> _submitConfirm() async {
    final sw = ref.read(onboardingNotifierProvider).isSwahili;
    final err = OnboardingValidator.validatePin(_confirmCtrl.text, isSwahili: sw);
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);
    final sw = state.isSwahili;

    return OnboardingScaffold(
      currentStep: 6,
      onBack: _showConfirm
          ? _backToPin
          : () => context.go(AppRoutes.business),
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => FadeTransition(
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
                    errorMessage: state.errorMessage,
                    onChanged: (_) {
                      if (_confirmHasError) {
                        setState(() => _confirmHasError = false);
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
                    onChanged: (_) {
                      if (_pinHasError) setState(() => _pinHasError = false);
                    },
                    onComplete: _advanceToConfirm,
                    onSubmit: _advanceToConfirm,
                  ),
          ),
        ),
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
    required this.onChanged,
    required this.onComplete,
    required this.onSubmit,
  });

  final bool sw;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final VoidCallback onComplete;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        // Icon
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
          child: const Icon(Icons.lock_rounded,
              color: AppColors.yellowBrand, size: 26),
        ),
        const SizedBox(height: 20),

        Text(
          sw ? 'Linda akaunti yako 🔐' : 'Secure your account 🔐',
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
          sw
              ? 'Tengeneza PIN ya tarakimu 4 utakayotumia kufikia Mali Up.'
              : 'Create a 4-digit PIN you\'ll use to access Mali Up.',
          style: const TextStyle(
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
                style: const TextStyle(
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
                onChanged: onChanged,
                onComplete: onComplete,
              ),
            ],
          ),
        ),

        if (hasError) ...[
          const SizedBox(height: 16),
          const OnboardingErrorBanner(
              message: 'PIN must be 4 digits.'),
        ],

        const SizedBox(height: 36),

        OnboardingPrimaryButton(
          label: sw ? 'Endelea' : 'Continue',
          onPressed: onSubmit,
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
  final String? errorMessage;
  final ValueChanged<String> onChanged;
  final VoidCallback onComplete;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        // Icon
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.success,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.verified_user_rounded,
              color: Colors.white, size: 26),
        ),
        const SizedBox(height: 20),

        Text(
          sw ? 'Thibitisha PIN yako ✓' : 'Confirm your PIN ✓',
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
          sw
              ? 'Ingiza tena PIN yako ili ithibitishwe.'
              : 'Enter your PIN once more to confirm it.',
          style: const TextStyle(
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
                style: const TextStyle(
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

        const SizedBox(height: 36),

        OnboardingPrimaryButton(
          label: isLoading
              ? (sw ? 'Inahifadhi...' : 'Saving...')
              : (sw ? 'Hifadhi & Endelea' : 'Save & Continue'),
          onPressed: isLoading ? null : onSubmit,
          isLoading: isLoading,
          color: AppColors.navyPrimary,
          textColor: Colors.white,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
