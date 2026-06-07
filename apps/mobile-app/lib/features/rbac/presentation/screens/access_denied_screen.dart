import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/routing.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/rbac_providers.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

/// Shown when a user navigates to a route they don't have permission for.
/// Uses friendly language — never "Access Denied" or "Unauthorized".
class AccessDeniedScreen extends ConsumerWidget {
  const AccessDeniedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(currentMemberProvider);
    final member = memberAsync.valueOrNull;

    final roleLabel = member?.role.label ?? _tr('Team Member', 'Mwanachama');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Illustration
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

              // Headline
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

              // Explanation
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

              // Role badge
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

              // Go to Dashboard
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => context.go(AppRoutes.dashboard),
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

              // Contact owner hint
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
