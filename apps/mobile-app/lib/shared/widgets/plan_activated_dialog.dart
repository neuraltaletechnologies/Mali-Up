import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/localization_service.dart';
import '../../core/services/plan_service.dart';
import '../../core/theme/app_colors.dart';
import 'emotional_design.dart';

/// Celebration popup shown once when an admin activates a plan upgrade for
/// the signed-in user (detected via [MainShellPage]'s live plan listener).
class PlanActivatedDialog extends StatelessWidget {
  final PlanTier tier;
  final PlanDefinitions? defs;

  const PlanActivatedDialog({super.key, required this.tier, this.defs});

  static Future<void> show(
    BuildContext context, {
    required PlanTier tier,
    PlanDefinitions? defs,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PlanActivatedDialog(tier: tier, defs: defs),
    );
  }

  String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

  List<String> _unlockedFeatures() {
    final limits = limitsFor(tier, defs);
    final features = <String>[];
    if (limits.monthlyInvoices == -1) {
      features.add(_tr('Unlimited invoices', 'Ankara zisizo na kikomo'));
    }
    if (limits.fullReports) {
      features.add(_tr('Full financial reports', 'Ripoti kamili za fedha'));
    }
    if (limits.mpesaImport) {
      features.add(_tr('M-Pesa statement import', 'Kuingiza data ya M-Pesa'));
    }
    if (limits.multiLocation) {
      features.add(_tr('Multi-location stock', 'Stoo nyingi'));
    }
    if (limits.prioritySupport) {
      features.add(_tr('Priority support', 'Msaada wa kipaumbele'));
    }
    return features.take(3).toList();
  }

  String get _tierName {
    switch (tier) {
      case PlanTier.starter:
        return 'Starter';
      case PlanTier.growth:
        return 'Growth';
      case PlanTier.business:
        return 'Business';
      case PlanTier.enterprise:
        return 'Enterprise';
      case PlanTier.lifetime:
        return 'Lifetime';
    }
  }

  @override
  Widget build(BuildContext context) {
    final features = _unlockedFeatures();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const EmotionalLottieSpot(
              scene: EmotionalLottieScene.celebrate,
              size: 140,
              repeat: false,
            ),
            Text(
              _tr('Hongera!', 'Hongera! 🎉'),
              style: GoogleFonts.dmSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.navyPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _tr(
                'Your $_tierName plan is now active',
                'Mpango wako wa $_tierName umewashwa',
              ),
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            if (features.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: features
                      .map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.success,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  f,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
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
                  _tr('Continue', 'Endelea'),
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
    );
  }
}
