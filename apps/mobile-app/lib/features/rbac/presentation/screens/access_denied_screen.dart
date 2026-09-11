import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/routing.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/rbac_providers.dart';
import '../../data/role_cache_service.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

/// Shown when a user navigates to a route they don't have permission for,
/// OR when their member record cannot be found after profile loading.
/// Uses friendly language — never "Access Denied" or "Unauthorized".
class AccessDeniedScreen extends ConsumerStatefulWidget {
  const AccessDeniedScreen({super.key});

  @override
  ConsumerState<AccessDeniedScreen> createState() => _AccessDeniedScreenState();
}

class _AccessDeniedScreenState extends ConsumerState<AccessDeniedScreen> {
  bool _isRetrying = false;

  Future<void> _retrySession() async {
    setState(() => _isRetrying = true);
    // Give Riverpod a moment to re-evaluate the providers.
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _isRetrying = false);
    // If session recovered, the router will redirect away automatically.
  }

  Future<void> _signOut() async {
    await RoleCacheService.clear();
    await FirebaseAuth.instance.signOut();
    if (mounted) context.go(AppRoutes.welcome);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionStateProvider);
    final memberAsync = ref.watch(currentMemberProvider);
    final member = memberAsync.valueOrNull;

    // Member record missing — show recovery flow.
    if (session == SessionState.memberNotFound) {
      return _RecoveryView(
        isRetrying: _isRetrying,
        onRetry: _retrySession,
        onSignOut: _signOut,
      );
    }

    // Standard "no permission for this route" screen.
    final roleLabel = member?.role.label ?? _tr('Team Member', 'Mwanachama');
    return _AccessView(
      member: member,
      roleLabel: roleLabel,
      onBack: () => context.go(AppRoutes.dashboard),
    );
  }
}

// ── Recovery view — member record not found ────────────────────────────────────

class _RecoveryView extends StatelessWidget {
  final bool isRetrying;
  final VoidCallback onRetry;
  final VoidCallback onSignOut;

  const _RecoveryView({
    required this.isRetrying,
    required this.onRetry,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sync_problem_rounded,
                  size: 48,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(height: 28),

              Text(
                _tr(
                  'Your permissions need to be refreshed',
                  'Ruhusa zako zinahitaji kusasishwa',
                ),
                style: GoogleFonts.dmSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navyPrimary,
                  height: 1.25,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              Text(
                _tr(
                  'We found your account but could not load your role assignment. '
                  'This usually resolves in a few seconds. '
                  'Please tap "Try again" — if the problem persists, contact your business owner.',
                  'Tumepata akaunti yako lakini hatukuweza kupakia jukumu lako. '
                  'Hii kawaida hutatuliwa kwa sekunde chache. '
                  'Tafadhali bonyeza "Jaribu tena" — ikiwa tatizo linaendelea, '
                  'wasiliana na mmiliki wa biashara.',
                ),
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: AppColors.textMuted,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Recovery info card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.infoBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.tealAccent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.tealAccent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _tr(
                          'Your account is active — only your permission data '
                          'needs to be refreshed.',
                          'Akaunti yako iko hai — data ya ruhusa tu inahitaji '
                          'kusasishwa.',
                        ),
                        style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AppColors.tealAccent,
                            height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              const Spacer(flex: 3),

              // Try again
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: isRetrying ? null : onRetry,
                  icon: isRetrying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.navyPrimary),
                        )
                      : const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(
                    isRetrying
                        ? _tr('Checking…', 'Inakagua…')
                        : _tr('Try again', 'Jaribu tena'),
                    style: GoogleFonts.dmSans(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.navyPrimary,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Sign out
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: onSignOut,
                  icon: const Icon(Icons.logout_rounded, size: 16),
                  label: Text(
                    _tr('Sign out and try again', 'Toka na ujaribu tena'),
                    style: GoogleFonts.dmSans(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navyPrimary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Standard "no permission" view ─────────────────────────────────────────────

class _AccessView extends StatelessWidget {
  final dynamic member;
  final String roleLabel;
  final VoidCallback onBack;

  const _AccessView({
    required this.member,
    required this.roleLabel,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 48,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 28),

              Text(
                _tr(
                  'You don\'t have access to this feature',
                  'Huna ruhusa ya kutumia kipengele hiki',
                ),
                style: GoogleFonts.dmSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navyPrimary,
                  height: 1.25,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              Text(
                _tr(
                  'This feature is only available to users with the required permissions. '
                  'Your current role ($roleLabel) does not include access to this area. '
                  'Please contact your business owner if you believe this is a mistake.',
                  'Kipengele hiki kinapatikana tu kwa watumiaji wenye ruhusa zinazohitajika. '
                  'Jukumu lako la sasa ($roleLabel) halijumuishi ufikiaji wa sehemu hii. '
                  'Wasiliana na mmiliki wa biashara ikiwa unaamini hii ni kosa.',
                ),
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: AppColors.textMuted,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              if (member != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.badge_outlined,
                          size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      Text(
                        _tr('Your role: ', 'Jukumu lako: '),
                        style: GoogleFonts.dmSans(
                            fontSize: 13, color: AppColors.textMuted),
                      ),
                      Text(
                        roleLabel,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],

              const Spacer(flex: 3),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.grid_view_rounded, size: 18),
                  label: Text(
                    _tr('Go to Dashboard', 'Rudi kwenye Dashibodi'),
                    style: GoogleFonts.dmSans(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.navyPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Text(
                _tr(
                  'Need more access? Ask your business owner to update your role.',
                  'Unahitaji ufikiaji zaidi? Mwambie mmiliki wa biashara akusasishe jukumu lako.',
                ),
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: AppColors.textDisabled),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
