import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers/business_id_provider.dart';
import '../../core/theme/app_colors.dart';
import 'plan_request_service.dart';

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
  final int maxBusinesses;   // -1 = unlimited
  final int maxCustomers;    // -1 = unlimited
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
    this.maxBusinesses = -1,
    this.maxCustomers = -1,
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
      maxBusinesses:       asInt('maxBusinesses',       fallback.maxBusinesses),
      maxCustomers:        asInt('maxCustomers',        fallback.maxCustomers),
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

  Map<String, dynamic> toCacheJson() => {
        'monthlyInvoices': monthlyInvoices,
        'maxUsers': maxUsers,
        'maxBusinesses': maxBusinesses,
        'maxCustomers': maxCustomers,
        'pricePerCycle': pricePerCycle,
        'cycleMonths': cycleMonths,
        'fullReports': fullReports,
        'mpesaImport': mpesaImport,
        'smsReminders': smsReminders,
        'multiLocation': multiLocation,
        'apiAccess': apiAccess,
        'allExports': allExports,
        'prioritySupport': prioritySupport,
        'customIntegrations': customIntegrations,
        'whiteLabel': whiteLabel,
        'dedicatedOnboarding': dedicatedOnboarding,
        'cashFlow': cashFlow,
        'expenseTracking': expenseTracking,
        'manualDebt': manualDebt,
      };

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
    maxBusinesses: 1,
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
    maxBusinesses: 1,
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

/// Keeps the last plan catalog received from the admin-managed Firestore
/// document. The comparison page can therefore show the real configured
/// prices, limits, and features during an offline launch instead of silently
/// reverting to stale compile-time defaults.
class PlanDefinitionsCache {
  static const _key = 'plan_definitions_v1';

  static Future<void> save(PlanDefinitions definitions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode({
          for (final tier in PlanTier.values)
            tier.name: (definitions[tier] ?? _fallbackLimits[tier]!)
                .toCacheJson(),
        }),
      );
    } catch (_) {
      // A cache failure must never prevent the live catalog from loading.
    }
  }

  static Future<PlanDefinitions?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(_key);
      if (encoded == null || encoded.isEmpty) return null;
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) return null;

      final result = Map<PlanTier, PlanLimits>.from(_fallbackLimits);
      for (final tier in PlanTier.values) {
        final raw = decoded[tier.name];
        if (raw is Map) {
          result[tier] = PlanLimits.fromFirestore(
            Map<String, dynamic>.from(raw),
            _fallbackLimits[tier]!,
          );
        }
      }
      return result;
    } catch (_) {
      return null;
    }
  }
}

Future<PlanDefinitions> _fetchPlanDefinitions() async {
  final cached = await PlanDefinitionsCache.load();
  try {
    final snap = await _db
        .collection('platform_config')
        .doc('plans')
        .get();

    if (!snap.exists) return cached ?? Map.from(_fallbackLimits);

    final data = snap.data() ?? {};
    final result = Map<PlanTier, PlanLimits>.from(_fallbackLimits);
    for (final tier in PlanTier.values) {
      final raw = data[tier.name];
      if (raw is Map<String, dynamic>) {
        result[tier] = PlanLimits.fromFirestore(raw, _fallbackLimits[tier]!);
      }
    }
    await PlanDefinitionsCache.save(result);
    return result;
  } catch (_) {
    return cached ?? Map.from(_fallbackLimits);
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

  /// Per-business negotiated Enterprise terms (admin-set), overriding
  /// specific fields of the shared Enterprise definition. Null for every
  /// tier except Enterprise businesses with a deal on file.
  final PlanLimits? overrideLimits;

  const PlanStatus({
    required this.tier,
    required this.invoicesUsedThisMonth,
    this.expiresAt,
    this.definitions,
    this.overrideLimits,
  });

  PlanLimits get limits => overrideLimits ?? limitsFor(tier, definitions);

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

/// Persists the last plan status successfully verified with Firestore.
/// Firestore persistence is disabled app-wide, so this small,
/// business-scoped cache keeps paid entitlements available during an
/// offline launch. Keyed by businessId (not uid) — the plan belongs to the
/// business, not to whichever account happens to be signed in, so a team
/// member and the owner of the same business share one cached entry.
class PlanStatusCache {
  // v2: keyed by businessId instead of uid (plan moved from users/{uid} to
  // businesses/{businessId}) — a distinct prefix avoids ever misreading a
  // pre-migration, uid-keyed v1 entry as if it were business-scoped.
  static const _keyPrefix = 'verified_plan_status_v2_';

  static String _key(String businessId) => '$_keyPrefix$businessId';

  static String _usageMonth(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}';

  static Future<void> save(String businessId, PlanStatus status) async {
    if (businessId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key(businessId),
        jsonEncode({
          'tier': status.tier.name,
          'invoicesUsedThisMonth': status.invoicesUsedThisMonth,
          'usageMonth': _usageMonth(DateTime.now()),
          if (status.expiresAt != null)
            'expiresAt': status.expiresAt!.millisecondsSinceEpoch,
          if (status.overrideLimits != null)
            'overrideLimits': status.overrideLimits!.toCacheJson(),
        }),
      );
    } catch (_) {
      // Entitlement refresh remains authoritative even if local persistence
      // is temporarily unavailable.
    }
  }

  static Future<PlanStatus?> load(
    String businessId, {
    PlanDefinitions? definitions,
  }) async {
    if (businessId.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(businessId));
    if (raw == null || raw.isEmpty) return null;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final storedTier = PlanTierX.fromString(data['tier'] as String?);
      final expiresMs = (data['expiresAt'] as num?)?.toInt();
      final expiresAt = expiresMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(expiresMs);
      final tier = storedTier != PlanTier.starter &&
              expiresAt != null &&
              expiresAt.isBefore(DateTime.now())
          ? PlanTier.starter
          : storedTier;

      final invoiceCount = data['usageMonth'] == _usageMonth(DateTime.now())
          ? ((data['invoicesUsedThisMonth'] as num?)?.toInt() ?? 0)
          : 0;

      PlanLimits? overrideLimits;
      final overrideRaw = data['overrideLimits'];
      if (tier == PlanTier.enterprise && overrideRaw is Map) {
        overrideLimits = PlanLimits.fromFirestore(
          Map<String, dynamic>.from(overrideRaw),
          limitsFor(tier, definitions),
        );
      }

      return PlanStatus(
        tier: tier,
        invoicesUsedThisMonth: invoiceCount,
        expiresAt: expiresAt,
        definitions: definitions,
        overrideLimits: overrideLimits,
      );
    } catch (_) {
      await prefs.remove(_key(businessId));
      return null;
    }
  }
}

class PlanService {
  /// Derives entitlements from a `businesses/{businessId}` document. The
  /// plan belongs to the business, not to whichever account is signed in —
  /// this is what makes a team member automatically inherit their business's
  /// real tier instead of defaulting to Starter on their own bare account.
  static Future<PlanStatus> _statusFromBusinessData(
    Map<String, dynamic> data, {
    required String businessId,
    PlanDefinitions? defs,
    int fallbackInvoiceCount = 0,
  }) async {
    final tier = PlanTierX.fromString(data['plan'] as String?);

    final expiresRaw = data['planExpiresAt'];
    DateTime? expiresAt;
    if (expiresRaw is Timestamp) expiresAt = expiresRaw.toDate();

    // Revert to Starter if subscription has expired
    final effectiveTier =
        (tier != PlanTier.starter && expiresAt != null && expiresAt.isBefore(DateTime.now()))
            ? PlanTier.starter
            : tier;

    // Negotiated Enterprise deal terms for this specific business
    // (admin-set), partially overriding the shared Enterprise definition —
    // same merge semantics as PlanLimits.fromFirestore already uses for
    // tier-wide definitions.
    PlanLimits? overrideLimits;
    if (effectiveTier == PlanTier.enterprise) {
      final overrideRaw = data['enterpriseOverrides'];
      if (overrideRaw is Map<String, dynamic>) {
        overrideLimits = PlanLimits.fromFirestore(
          overrideRaw,
          limitsFor(effectiveTier, defs),
        );
      }
    }

    // Counted for whichever tier actually has a finite cap (admin-editable
    // per tier, not just Starter) — scoped to this business only, never
    // summed across other businesses the same owner might have.
    var invoiceCount = fallbackInvoiceCount;
    if ((overrideLimits ?? limitsFor(effectiveTier, defs)).monthlyInvoices != -1 &&
        businessId.isNotEmpty) {
      try {
        final now = DateTime.now();
        final monthStart = Timestamp.fromDate(DateTime(now.year, now.month));
        final snap = await _db
            .collection('businesses')
            .doc(businessId)
            .collection('sales_invoices')
            .where('createdAt', isGreaterThanOrEqualTo: monthStart)
            .count()
            .get();
        invoiceCount = snap.count ?? 0;
      } catch (_) {
        // A usage-count failure must not downgrade an otherwise valid paid
        // package. Keep the last server-verified monthly count instead.
      }
    }

    return PlanStatus(
      tier: effectiveTier,
      invoicesUsedThisMonth: invoiceCount,
      expiresAt: expiresAt,
      definitions: defs,
      overrideLimits: overrideLimits,
    );
  }

  static Future<PlanStatus> fetchStatus({
    required String businessId,
    PlanDefinitions? defs,
  }) async {
    if (businessId.isEmpty) {
      return PlanStatus(
          tier: PlanTier.starter, invoicesUsedThisMonth: 0, definitions: defs);
    }

    final cached = await PlanStatusCache.load(businessId, definitions: defs);
    try {
      final doc = await _db.collection('businesses').doc(businessId).get();
      final status = await _statusFromBusinessData(
        doc.data() ?? {},
        businessId: businessId,
        defs: defs,
        fallbackInvoiceCount: cached?.invoicesUsedThisMonth ?? 0,
      );
      await PlanStatusCache.save(businessId, status);
      return status;
    } catch (_) {
      return cached ??
          PlanStatus(
            tier: PlanTier.starter,
            invoicesUsedThisMonth: 0,
            definitions: defs,
          );
    }
  }

  /// Live plan status — re-derived whenever the business's Firestore doc
  /// changes, so an admin approving a plan request reflects in the app
  /// immediately for the owner and every team member of that business.
  static Stream<PlanStatus> watchStatus({
    required String businessId,
    PlanDefinitions? defs,
  }) async* {
    if (businessId.isEmpty) {
      yield PlanStatus(
        tier: PlanTier.starter,
        invoicesUsedThisMonth: 0,
        definitions: defs,
      );
      return;
    }

    final cached = await PlanStatusCache.load(businessId, definitions: defs);
    await for (final doc
        in _db.collection('businesses').doc(businessId).snapshots()) {
      // An offline listener can emit an empty cache snapshot even though
      // Firestore persistence is disabled. It is not authoritative.
      if (doc.metadata.isFromCache && !doc.exists) continue;
      try {
        final status = await _statusFromBusinessData(
          doc.data() ?? {},
          businessId: businessId,
          defs: defs,
          fallbackInvoiceCount: cached?.invoicesUsedThisMonth ?? 0,
        );
        await PlanStatusCache.save(businessId, status);
        yield status;
      } catch (_) {
        if (cached != null) yield cached;
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Riverpod providers
// ─────────────────────────────────────────────────────────────────────────────

/// Full plan status with dynamic limits baked in. Live — updates automatically
/// when an admin approves/activates a plan change in Firestore.
///
/// Resolved against the *active business* (via [currentBusinessIdProvider]),
/// not the signed-in account — the plan belongs to the business, so this
/// re-subscribes whenever the active business changes (a switch, or a team
/// member's businessId resolving after sign-in), and a team member sees the
/// same entitlements as the business owner automatically.
///
/// Emits immediately from the last server-verified local entitlement. Offline
/// entry points such as Add Sale can therefore open without waiting for
/// Firestore. A first-time user without a cache gets the Starter fallback
/// immediately while the live server listener starts in the background.
final planStatusProvider = StreamProvider.autoDispose<PlanStatus>((ref) async* {
  final businessId = ref.watch(currentBusinessIdProvider).valueOrNull ?? '';

  final initialCached = await PlanStatusCache.load(businessId);
  yield initialCached ??
      const PlanStatus(
        tier: PlanTier.starter,
        invoicesUsedThisMonth: 0,
      );

  if (businessId.isEmpty) return;

  PlanDefinitions? defs;
  try {
    defs = await ref.watch(planDefinitionsProvider.future).timeout(
          const Duration(seconds: 6),
        );
  } catch (_) {
    defs = null;
  }

  yield* PlanService.watchStatus(businessId: businessId, defs: defs);
});

// ─────────────────────────────────────────────────────────────────────────────
// PlanPendingBanner — "your upgrade request is being processed"
// ─────────────────────────────────────────────────────────────────────────────

class PlanPendingBanner extends ConsumerWidget {
  const PlanPendingBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingPlanRequestProvider).valueOrNull;
    if (pending == null) return const SizedBox.shrink();

    final tierLabel = switch (pending.tier) {
      PlanTier.growth => 'Growth',
      PlanTier.business => 'Business',
      PlanTier.enterprise => 'Enterprise',
      PlanTier.lifetime => 'Lifetime',
      PlanTier.starter => 'Starter',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.tealAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.tealAccent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.tealAccent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.hourglass_top_rounded,
              color: AppColors.tealAccent,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ombi lako la $tierLabel linashughulikiwa',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Timu yetu inathibitisha malipo yako — utapata taarifa mara mpango ukiwashwa.',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
                  const SizedBox(width: 14),
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
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.yellowBrand.withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
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
        minHeight: 7,
        backgroundColor: AppColors.surfaceVariant,
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
            size: 16,
            color: ok
                ? (light ? AppColors.yellowBrand : AppColors.success)
                : AppColors.textDisabled,
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: ok
                  ? (light ? Colors.white.withValues(alpha: 0.92) : AppColors.textPrimary)
                  : AppColors.textDisabled,
              fontWeight: ok ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
