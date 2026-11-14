import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/plan_service.dart';
import '../../core/services/trial_service.dart';
import '../../core/theme/app_colors.dart';
import '../../i18n/gen/strings.g.dart';
import 'emotional_design.dart';
import 'upgrade_sheet.dart';

/// "We've gifted you N days of Growth" popup, shown once per trial when the
/// owner reaches the dashboard after the server grants it (see
/// MainShellPage's plan listener and [TrialGiftTracker]). The wording comes
/// from the admin portal's Free Trial page ([trialMessagesProvider]).
class TrialGiftDialog extends ConsumerWidget {
  final PlanStatus status;
  final String businessName;

  const TrialGiftDialog({
    super.key,
    required this.status,
    this.businessName = '',
  });

  static Future<void> show(
    BuildContext context,
    PlanStatus status, {
    String businessName = '',
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          TrialGiftDialog(status: status, businessName: businessName),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages =
        ref.watch(trialMessagesProvider).valueOrNull ?? const TrialMessages();
    final endsAt = status.expiresAt;
    final daysLeft = status.trialDaysLeft;
    final totalDays = status.trialStartedAt != null && endsAt != null
        ? (endsAt.difference(status.trialStartedAt!).inHours / 24).round()
        : daysLeft;
    final endDate = endsAt != null ? formatTrialDate(endsAt) : '';
    final vars = <String, Object>{
      'name': messages.ownerName.isNotEmpty ? messages.ownerName : 'Mteja',
      'businessName': businessName,
      'days': totalDays,
      'daysLeft': daysLeft,
      'endDate': endDate,
    };

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const EmotionalLottieSpot(
                scene: EmotionalLottieScene.celebrate,
                size: 130,
                repeat: false,
              ),
              Text(
                fillTrialTemplate(messages.title, vars),
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navyPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                fillTrialTemplate(messages.body, vars),
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              if (endsAt != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.tealAccent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.tealAccent.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.event_rounded,
                        color: AppColors.tealAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          t.trial.endsOn(date: endDate),
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navyPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.yellowBrand,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          daysLeft <= 1
                              ? t.trial.lastDayChip
                              : t.trial.daysLeftChip(days: daysLeft),
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navyPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.yellowBrand,
                    foregroundColor: AppColors.navyPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    t.trial.giftCta,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
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

/// Dashboard banner counting down the trial — the always-visible nudge
/// between the welcome popup and the reminder push. Owner-only (staff
/// can't pay); hidden when not on a trial.
class TrialCountdownBanner extends ConsumerWidget {
  const TrialCountdownBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(planStatusProvider).valueOrNull;
    if (status == null || !status.isTrial || status.expiresAt == null) {
      return const SizedBox.shrink();
    }
    final daysLeft = status.trialDaysLeft;
    if (daysLeft <= 0) return const SizedBox.shrink();
    final urgent = daysLeft <= 2;
    final accent = urgent ? AppColors.warning : AppColors.tealAccent;
    final tier = status.tierLabel;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.card_giftcard_rounded, color: accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  daysLeft <= 1
                      ? t.trial.bannerTitleLastDay(tier: tier)
                      : t.trial.bannerTitle(tier: tier, days: daysLeft),
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  t.trial.bannerBody(date: formatTrialDate(status.expiresAt!)),
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => showUpgradeSheet(context, currentStatus: status),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.yellowBrand,
              foregroundColor: AppColors.navyPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              t.trial.bannerCta,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
