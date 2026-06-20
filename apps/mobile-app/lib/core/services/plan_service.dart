import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Tiers & limits
// ─────────────────────────────────────────────────────────────────────────────

enum PlanTier { starter, growth, business, enterprise }

class PlanLimits {
  final int monthlyInvoices; // -1 = unlimited
  final int maxUsers;
  final bool fullReports;
  final bool mpesaImport;
  final bool smsReminders;
  final bool multiLocation;
  final bool apiAccess;
  final bool allExports;
  final bool prioritySupport;

  const PlanLimits({
    required this.monthlyInvoices,
    required this.maxUsers,
    required this.fullReports,
    required this.mpesaImport,
    required this.smsReminders,
    required this.multiLocation,
    required this.apiAccess,
    required this.allExports,
    required this.prioritySupport,
  });
}

const _limits = <PlanTier, PlanLimits>{
  PlanTier.starter: PlanLimits(
    monthlyInvoices: 50,
    maxUsers: 1,
    fullReports: false,
    mpesaImport: false,
    smsReminders: false,
    multiLocation: false,
    apiAccess: false,
    allExports: false,
    prioritySupport: false,
  ),
  PlanTier.growth: PlanLimits(
    monthlyInvoices: -1,
    maxUsers: 3,
    fullReports: true,
    mpesaImport: true,
    smsReminders: true,
    multiLocation: false,
    apiAccess: false,
    allExports: false,
    prioritySupport: false,
  ),
  PlanTier.business: PlanLimits(
    monthlyInvoices: -1,
    maxUsers: 10,
    fullReports: true,
    mpesaImport: true,
    smsReminders: true,
    multiLocation: true,
    apiAccess: true,
    allExports: true,
    prioritySupport: true,
  ),
  PlanTier.enterprise: PlanLimits(
    monthlyInvoices: -1,
    maxUsers: -1,
    fullReports: true,
    mpesaImport: true,
    smsReminders: true,
    multiLocation: true,
    apiAccess: true,
    allExports: true,
    prioritySupport: true,
  ),
};

PlanLimits limitsFor(PlanTier tier) => _limits[tier]!;

// ─────────────────────────────────────────────────────────────────────────────
// PlanStatus — runtime snapshot
// ─────────────────────────────────────────────────────────────────────────────

class PlanStatus {
  final PlanTier tier;
  final int invoicesUsedThisMonth;
  final DateTime? expiresAt;

  const PlanStatus({
    required this.tier,
    required this.invoicesUsedThisMonth,
    this.expiresAt,
  });

  PlanLimits get limits => limitsFor(tier);

  bool get isStarter => tier == PlanTier.starter;
  bool get isPaid => tier != PlanTier.starter;

  bool get canCreateInvoice {
    final limit = limits.monthlyInvoices;
    if (limit == -1) return true;
    return invoicesUsedThisMonth < limit;
  }

  int get invoicesRemaining {
    final limit = limits.monthlyInvoices;
    if (limit == -1) return 999999;
    return (limit - invoicesUsedThisMonth).clamp(0, limit);
  }

  double get usagePercent {
    final limit = limits.monthlyInvoices;
    if (limit == -1) return 0;
    return (invoicesUsedThisMonth / limit).clamp(0.0, 1.0);
  }

  String get tierLabel {
    switch (tier) {
      case PlanTier.starter:    return 'Starter';
      case PlanTier.growth:     return 'Growth';
      case PlanTier.business:   return 'Business';
      case PlanTier.enterprise: return 'Enterprise';
    }
  }

  String get tierLabelSw {
    switch (tier) {
      case PlanTier.starter:    return 'Mpango wa Bure';
      case PlanTier.growth:     return 'Growth';
      case PlanTier.business:   return 'Business';
      case PlanTier.enterprise: return 'Enterprise';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PlanService
// ─────────────────────────────────────────────────────────────────────────────

class PlanService {
  static final _db = FirebaseFirestore.instance;

  static Future<PlanStatus> fetchStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const PlanStatus(tier: PlanTier.starter, invoicesUsedThisMonth: 0);
    }

    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      final data = doc.data() ?? {};

      final tierRaw = (data['plan'] as String?)?.toLowerCase();
      final PlanTier tier;
      switch (tierRaw) {
        case 'growth':     tier = PlanTier.growth;     break;
        case 'business':   tier = PlanTier.business;   break;
        case 'enterprise': tier = PlanTier.enterprise; break;
        default:           tier = PlanTier.starter;
      }

      final expiresRaw = data['planExpiresAt'] ?? data['premiumExpiresAt'];
      DateTime? expiresAt;
      if (expiresRaw is Timestamp) expiresAt = expiresRaw.toDate();

      // Revert to Starter if subscription has expired
      final effectiveTier =
          (tier != PlanTier.starter && expiresAt != null && expiresAt.isBefore(DateTime.now()))
              ? PlanTier.starter
              : tier;

      int invoiceCount = 0;
      if (effectiveTier == PlanTier.starter) {
        final selectedBusinessId = (data['selectedBusinessId'] as String?)?.trim() ?? '';
        if (selectedBusinessId.isNotEmpty) {
          final now = DateTime.now();
          final monthStart = Timestamp.fromDate(DateTime(now.year, now.month));
          final snap = await _db
              .collection('businesses')
              .doc(selectedBusinessId)
              .collection('sales_invoices')
              .where('createdAt', isGreaterThanOrEqualTo: monthStart)
              .count()
              .get();
          invoiceCount = snap.count ?? 0;
        }
      }

      return PlanStatus(
        tier: effectiveTier,
        invoicesUsedThisMonth: invoiceCount,
        expiresAt: expiresAt,
      );
    } catch (_) {
      return const PlanStatus(tier: PlanTier.starter, invoicesUsedThisMonth: 0);
    }
  }

  /// Activate a paid tier for [months] months.
  static Future<void> activatePlan({
    required String uid,
    required PlanTier tier,
    required int months,
  }) async {
    final expiresAt = DateTime.now().add(Duration(days: 30 * months));
    await _db.collection('users').doc(uid).set({
      'plan': tier.name,
      'planExpiresAt': Timestamp.fromDate(expiresAt),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Riverpod provider
// ─────────────────────────────────────────────────────────────────────────────

final planStatusProvider = FutureProvider.autoDispose<PlanStatus>((ref) {
  return PlanService.fetchStatus();
});

// ─────────────────────────────────────────────────────────────────────────────
// PlanUpgradeCard — inline warning when approaching or at the limit
// ─────────────────────────────────────────────────────────────────────────────

class PlanUpgradeCard extends StatelessWidget {
  final PlanStatus status;
  final VoidCallback? onUpgradeTap;

  const PlanUpgradeCard({super.key, required this.status, this.onUpgradeTap});

  @override
  Widget build(BuildContext context) {
    if (!status.isStarter) return const SizedBox.shrink();

    final atLimit  = !status.canCreateInvoice;
    final nearLimit = status.usagePercent >= 0.8;
    if (!nearLimit && !atLimit) return const SizedBox.shrink();

    final limitLabel = limitsFor(PlanTier.starter).monthlyInvoices;
    final accent = atLimit ? AppColors.error : AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withValues(alpha: 0.08), accent.withValues(alpha: 0.03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              atLimit ? Icons.lock_rounded : Icons.warning_amber_rounded,
              color: accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  atLimit
                      ? 'Umefika kikomo — $limitLabel invoices kwa mwezi'
                      : '${status.invoicesUsedThisMonth}/$limitLabel invoices mwezi huu',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Growth: TZS 5,000/mwezi — ankara zisizo na kikomo',
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
          GestureDetector(
            onTap: onUpgradeTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.yellowBrand,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Panda',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PlanInfoCard — shown in settings / subscription screen
// ─────────────────────────────────────────────────────────────────────────────

class PlanInfoCard extends StatelessWidget {
  final PlanStatus status;
  final VoidCallback? onUpgradeTap;

  const PlanInfoCard({super.key, required this.status, this.onUpgradeTap});

  @override
  Widget build(BuildContext context) {
    final isPaid = status.isPaid;
    final limit = limitsFor(PlanTier.starter).monthlyInvoices;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isPaid
            ? const LinearGradient(
                colors: [AppColors.navyPrimary, AppColors.navySecondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isPaid ? null : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: isPaid ? null : Border.all(color: AppColors.border),
        boxShadow: isPaid
            ? [
                BoxShadow(
                  color: AppColors.navyPrimary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPaid ? Icons.stars_rounded : Icons.workspace_premium_outlined,
                color: isPaid ? AppColors.yellowBrand : AppColors.textMuted,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                status.tierLabel,
                style: GoogleFonts.dmSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isPaid ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (status.expiresAt != null)
                Text(
                  'Hadi ${_fmt(status.expiresAt!)}',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: isPaid
                        ? Colors.white.withValues(alpha: 0.55)
                        : AppColors.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (status.isStarter) ...[
            _UsageBar(status: status),
            const SizedBox(height: 8),
            Text(
              '${status.invoicesUsedThisMonth} / $limit invoices mwezi huu',
              style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            _FeatureRow(text: 'Hadi $limit invoices / mwezi', ok: true),
            const _FeatureRow(text: 'Ankara zisizo na kikomo', ok: false),
            const _FeatureRow(text: 'Ripoti kamili', ok: false),
            const _FeatureRow(text: 'Kuingiza data ya M-Pesa', ok: false),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onUpgradeTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.yellowBrand,
                  foregroundColor: AppColors.navyPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Angalia Mipango ya Malipo',
                  style: GoogleFonts.dmSans(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ] else ...[
            const _FeatureRow(text: 'Ankara zisizo na kikomo', ok: true, light: true),
            const _FeatureRow(text: 'Ripoti kamili', ok: true, light: true),
            const _FeatureRow(text: 'Kuingiza data ya M-Pesa', ok: true, light: true),
            if (status.tier == PlanTier.business || status == status)
              const _FeatureRow(text: 'Stoo nyingi', ok: true, light: true),
          ],
        ],
      ),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _UsageBar extends StatelessWidget {
  final PlanStatus status;
  const _UsageBar({required this.status});

  @override
  Widget build(BuildContext context) {
    final pct = status.usagePercent;
    final barColor = pct >= 1.0
        ? AppColors.error
        : pct >= 0.8
            ? AppColors.warning
            : AppColors.success;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: pct,
        minHeight: 6,
        backgroundColor: AppColors.border,
        valueColor: AlwaysStoppedAnimation<Color>(barColor),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String text;
  final bool ok;
  final bool light;

  const _FeatureRow({required this.text, required this.ok, this.light = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: ok
                ? (light ? AppColors.yellowBrand : AppColors.success)
                : AppColors.textDisabled,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: ok
                  ? (light ? Colors.white : AppColors.textPrimary)
                  : AppColors.textDisabled,
              fontWeight: ok ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
