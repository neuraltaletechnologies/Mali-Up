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
      currentStep: 4,
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
                child: Text(
                  sw
                      ? 'Umesahau PIN? Wasiliana na msaada.'
                      : 'Forgot your PIN? Contact support.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
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
