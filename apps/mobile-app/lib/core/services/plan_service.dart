import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Tiers
// ─────────────────────────────────────────────────────────────────────────────

enum PlanTier { starter, growth, business, enterprise, lifetime }

extension PlanTierX on PlanTier {
  String get name {
    switch (this) {
      case PlanTier.starter:    return 'starter';
      case PlanTier.growth:     return 'growth';
      case PlanTier.business:   return 'business';
      case PlanTier.enterprise: return 'enterprise';
      case PlanTier.lifetime:   return 'lifetime';
    }
  }

  static PlanTier fromString(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'growth':     return PlanTier.growth;
      case 'business':   return PlanTier.business;
      case 'enterprise': return PlanTier.enterprise;
      case 'lifetime':   return PlanTier.lifetime;
      default:           return PlanTier.starter;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PlanLimits — runtime limits for a tier, sourced from Firestore or hardcoded
// ─────────────────────────────────────────────────────────────────────────────

class PlanLimits {
  final int monthlyInvoices; // -1 = unlimited
  final int maxUsers;        // -1 = unlimited
  final int pricePerCycle;   // TZS total for the billing cycle
  final int cycleMonths;
  final bool fullReports;
  final bool mpesaImport;
  final bool smsReminders;
  final bool multiLocation;
  final bool apiAccess;
  final bool allExports;
  final bool prioritySupport;
  final bool customIntegrations;
  final bool whiteLabel;
  final bool dedicatedOnboarding;
  final bool cashFlow;
  final bool expenseTracking;
  final bool manualDebt;

  const PlanLimits({
    required this.monthlyInvoices,
    required this.maxUsers,
    this.pricePerCycle = 0,
    this.cycleMonths = 6,
    required this.fullReports,
    required this.mpesaImport,
    required this.smsReminders,
    required this.multiLocation,
    required this.apiAccess,
    required this.allExports,
    required this.prioritySupport,
    this.customIntegrations = false,
    this.whiteLabel = false,
    this.dedicatedOnboarding = false,
    this.cashFlow = false,
    this.expenseTracking = false,
    this.manualDebt = false,
  });

  factory PlanLimits.fromFirestore(Map<String, dynamic> data, PlanLimits fallback) {
    int asInt(String k, int def) {
      final v = data[k];
      if (v is int) return v;
      if (v is num) return v.toInt();
      return def;
    }
    bool asBool(String k, bool def) {
      final v = data[k];
      if (v is bool) return v;
      return def;
    }
    return PlanLimits(
      monthlyInvoices:     asInt('monthlyInvoices',    fallback.monthlyInvoices),
      maxUsers:            asInt('maxUsers',            fallback.maxUsers),
      pricePerCycle:       asInt('pricePerCycle',       fallback.pricePerCycle),
      cycleMonths:         asInt('cycleMonths',         fallback.cycleMonths),
      fullReports:         asBool('fullReports',        fallback.fullReports),
      mpesaImport:         asBool('mpesaImport',        fallback.mpesaImport),
      smsReminders:        asBool('smsReminders',       fallback.smsReminders),
      multiLocation:       asBool('multiLocation',      fallback.multiLocation),
      apiAccess:           asBool('apiAccess',          fallback.apiAccess),
      allExports:          asBool('allExports',         fallback.allExports),
      prioritySupport:     asBool('prioritySupport',    fallback.prioritySupport),
      customIntegrations:  asBool('customIntegrations', fallback.customIntegrations),
      whiteLabel:          asBool('whiteLabel',         fallback.whiteLabel),
      dedicatedOnboarding: asBool('dedicatedOnboarding', fallback.dedicatedOnboarding),
      cashFlow:            asBool('cashFlow',           fallback.cashFlow),
      expenseTracking:     asBool('expenseTracking',    fallback.expenseTracking),
      manualDebt:          asBool('manualDebt',         fallback.manualDebt),
    );
  }

  int get pricePerMonth =>
      pricePerCycle > 0 && cycleMonths > 0
          ? (pricePerCycle / cycleMonths).round()
          : 0;
}

// Hardcoded fallbacks — used when Firestore is unreachable
const _fallbackLimits = <PlanTier, PlanLimits>{
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
    pricePerCycle: 30000,
    fullReports: true,
    mpesaImport: true,
    smsReminders: true,
    multiLocation: false,
    apiAccess: false,
    allExports: false,
    prioritySupport: false,
    cashFlow: true,
    expenseTracking: true,
    manualDebt: true,
  ),
  PlanTier.business: PlanLimits(
    monthlyInvoices: -1,
    maxUsers: 10,
    pricePerCycle: 40000,
    fullReports: true,
    mpesaImport: true,
    smsReminders: true,
    multiLocation: true,
    apiAccess: true,
    allExports: true,
    prioritySupport: true,
    cashFlow: true,
    expenseTracking: true,
    manualDebt: true,
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
    customIntegrations: true,
    whiteLabel: true,
    dedicatedOnboarding: true,
    cashFlow: true,
    expenseTracking: true,
    manualDebt: true,
  ),
  PlanTier.lifetime: PlanLimits(
    monthlyInvoices: -1,
    maxUsers: -1,
    cycleMonths: 0,
    fullReports: true,
    mpesaImport: true,
    smsReminders: true,
    multiLocation: true,
    apiAccess: true,
    allExports: true,
    prioritySupport: true,
    customIntegrations: true,
    whiteLabel: true,
    dedicatedOnboarding: true,
    cashFlow: true,
    expenseTracking: true,
    manualDebt: true,
  ),
};

// ─────────────────────────────────────────────────────────────────────────────
// Dynamic plan definitions — loaded from Firestore /platform_config/plans
// ─────────────────────────────────────────────────────────────────────────────

typedef PlanDefinitions = Map<PlanTier, PlanLimits>;

final _db = FirebaseFirestore.instance;

Future<PlanDefinitions> _fetchPlanDefinitions() async {
  try {
    final snap = await _db
        .collection('platform_config')
        .doc('plans')
        .get();

    if (!snap.exists) return Map.from(_fallbackLimits);

    final data = snap.data() ?? {};
    final result = Map<PlanTier, PlanLimits>.from(_fallbackLimits);
    for (final tier in PlanTier.values) {
      final raw = data[tier.name];
      if (raw is Map<String, dynamic>) {
        result[tier] = PlanLimits.fromFirestore(raw, _fallbackLimits[tier]!);
      }
    }
    return result;
  } catch (_) {
    return Map.from(_fallbackLimits);
  }
}

/// Cached plan definitions provider — auto-refreshed per session.
final planDefinitionsProvider = FutureProvider.autoDispose<PlanDefinitions>((ref) {
  return _fetchPlanDefinitions();
});

/// Convenience: get limits for a specific tier (synchronous, uses fallbacks).
PlanLimits limitsFor(PlanTier tier, [PlanDefinitions? defs]) =>
    defs?[tier] ?? _fallbackLimits[tier]!;

// ─────────────────────────────────────────────────────────────────────────────
// PlanStatus — runtime snapshot for the current user
// ─────────────────────────────────────────────────────────────────────────────

class PlanStatus {
  final PlanTier tier;
  final int invoicesUsedThisMonth;
  final DateTime? expiresAt;
  final PlanDefinitions? definitions;

  const PlanStatus({
    required this.tier,
    required this.invoicesUsedThisMonth,
    this.expiresAt,
    this.definitions,
  });

  PlanLimits get limits => limitsFor(tier, definitions);

  bool get isStarter => tier == PlanTier.starter;
  bool get isPaid    => tier != PlanTier.starter;

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
      case PlanTier.lifetime:   return 'Lifetime';
    }
  }

  String get tierLabelSw {
    switch (tier) {
      case PlanTier.starter:    return 'Mpango wa Bure';
      case PlanTier.growth:     return 'Growth';
      case PlanTier.business:   return 'Business';
      case PlanTier.enterprise: return 'Enterprise';
      case PlanTier.lifetime:   return 'Lifetime';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PlanService
// ─────────────────────────────────────────────────────────────────────────────

class PlanService {
  static Future<PlanStatus> fetchStatus({PlanDefinitions? defs}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return PlanStatus(
          tier: PlanTier.starter, invoicesUsedThisMonth: 0, definitions: defs);
    }

    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      final data = doc.data() ?? {};

      final tier = PlanTierX.fromString(data['plan'] as String?);

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
        final selectedBusinessId =
            (data['selectedBusinessId'] as String?)?.trim() ?? '';
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
        definitions: defs,
      );
    } catch (_) {
      return PlanStatus(
          tier: PlanTier.starter, invoicesUsedThisMonth: 0, definitions: defs);
    }
  }

  /// Activate a paid tier for [months] months (admin-side only, kept for completeness).
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
// Riverpod providers
// ─────────────────────────────────────────────────────────────────────────────

/// Full plan status with dynamic limits baked in.
final planStatusProvider = FutureProvider.autoDispose<PlanStatus>((ref) async {
  final defs = await ref.watch(planDefinitionsProvider.future);
  return PlanService.fetchStatus(defs: defs);
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

    final atLimit   = !status.canCreateInvoice;
    final nearLimit = status.usagePercent >= 0.8;
    if (!nearLimit && !atLimit) return const SizedBox.shrink();

    final limitLabel = status.limits.monthlyInvoices;
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
          SizedBox(width: 12),
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
                SizedBox(height: 2),
                Text(
                  'Growth: ${_fmtPrice(status.definitions?[PlanTier.growth]?.pricePerMonth ?? 5000)}/mwezi — ankara zisizo na kikomo',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
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
    final isPaid  = status.isPaid;
    final limit   = status.limits.monthlyInvoices;
    final growthPrice = status.definitions?[PlanTier.growth]?.pricePerMonth ?? 5000;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: isPaid
            ? const LinearGradient(
                colors: [AppColors.navyPrimary, AppColors.navySecondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isPaid ? null : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: isPaid ? null : Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: isPaid
                ? AppColors.navyPrimary.withValues(alpha: 0.28)
                : AppColors.shadowCard,
            blurRadius: isPaid ? 24 : 14,
            offset: Offset(0, isPaid ? 10 : 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (isPaid)
            Positioned(
              right: -18,
              top: -28,
              child: Icon(
                Icons.stars_rounded,
                size: 130,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPaid ? Colors.white.withValues(alpha: 0.14) : null,
                      gradient: isPaid
                          ? null
                          : const LinearGradient(
                              colors: [AppColors.tealAccent, AppColors.navySecondary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      boxShadow: isPaid
                          ? null
                          : [
                              BoxShadow(
                                color: AppColors.tealAccent.withValues(alpha: 0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Icon(
                      isPaid ? Icons.stars_rounded : Icons.workspace_premium_rounded,
                      color: isPaid ? AppColors.yellowBrand : Colors.white,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CURRENT PLAN',
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: isPaid
                                ? Colors.white.withValues(alpha: 0.55)
                                : AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          status.tierLabel,
                          style: GoogleFonts.dmSans(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: isPaid ? Colors.white : AppColors.navyPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (status.expiresAt != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isPaid
                            ? Colors.white.withValues(alpha: 0.12)
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Hadi ${_fmt(status.expiresAt!)}',
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isPaid
                              ? Colors.white.withValues(alpha: 0.75)
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
          if (status.isStarter) ...[
            _UsageBar(status: status),
            SizedBox(height: 8),
            Text(
              '${status.invoicesUsedThisMonth} / $limit invoices mwezi huu',
              style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            _FeatureRow(text: 'Hadi $limit invoices / mwezi', ok: true),
            const _FeatureRow(text: 'Ankara zisizo na kikomo', ok: false),
            const _FeatureRow(text: 'Ripoti kamili', ok: false),
            const _FeatureRow(text: 'Kuingiza data ya M-Pesa', ok: false),
            SizedBox(height: 16),
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
                  'Angalia Mipango ya Malipo — ${_fmtPrice(growthPrice)}/mwezi',
                  style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ] else ...[
            const _FeatureRow(text: 'Ankara zisizo na kikomo', ok: true, light: true),
            const _FeatureRow(text: 'Ripoti kamili', ok: true, light: true),
            const _FeatureRow(text: 'Kuingiza data ya M-Pesa', ok: true, light: true),
            if (status.tier == PlanTier.business || status.tier == PlanTier.enterprise)
              const _FeatureRow(text: 'Stoo nyingi', ok: true, light: true),
          ],
        ],
      ),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal helpers
// ─────────────────────────────────────────────────────────────────────────────

String _fmtPrice(int v) =>
    'TZS ${v.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';

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
          SizedBox(width: 8),
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
