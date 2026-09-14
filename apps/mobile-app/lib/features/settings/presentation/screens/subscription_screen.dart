import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/providers/plan_usage_provider.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/services/plan_request_service.dart';
import '../../../../core/services/plan_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/skeleton_widgets.dart';
import '../../../../shared/widgets/smart_skeleton.dart';
import '../../../../shared/widgets/upgrade_sheet.dart';

String _fmtPrice(int v) =>
    'TZS ${v.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';

String _t(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

String _fmtPriceCompact(int v) => v == 0 ? _t('Free', 'Bure') : _fmtPrice(v);

/// One-line differentiator shown next to each tier in the plan list.
String _blurbFor(PlanTier tier, PlanLimits limits) {
  switch (tier) {
    case PlanTier.starter:
      // maxUsers=1 on Starter means the owner only — phrased as "no team
      // members" rather than "1 user" so it doesn't read as if the owner
      // counts as a team member seat.
      final productBlurb = limits.maxProducts == -1
          ? ''
          : _t(' · ${limits.maxProducts} products',
              ' · Bidhaa ${limits.maxProducts}');
      final salesBlurb = limits.maxSalesPerDay == -1
          ? ''
          : _t(' · ${limits.maxSalesPerDay} sales/day',
              ' · Mauzo ${limits.maxSalesPerDay}/siku');
      final customerBlurb = limits.maxCustomers == -1
          ? ''
          : _t(' · ${limits.maxCustomers} customers',
              ' · Wateja ${limits.maxCustomers}');
      return _t(
        '${limits.monthlyInvoices} invoices/mo$salesBlurb$customerBlurb$productBlurb · No team members',
        'Ankara ${limits.monthlyInvoices}/mwezi$salesBlurb$customerBlurb$productBlurb · Hakuna wanachama wa timu',
      );
    case PlanTier.growth:
      return _t(
        'Unlimited invoices · Full reports · M-Pesa import',
        'Ankara zisizo na kikomo · Ripoti kamili · Kuingiza M-Pesa',
      );
    case PlanTier.business:
      return _t(
        'Multi-location stock · API access · Priority support',
        'Stoo za maeneo mengi · API · Msaada wa kipaumbele',
      );
    case PlanTier.enterprise:
      return _t(
        'Custom integrations · White-label · Dedicated onboarding',
        'Miunganisho maalum · Chapa binafsi · Msaada maalum',
      );
    case PlanTier.lifetime:
      return _t(
        'One-time payment · Full access forever',
        'Malipo mara moja · Ufikiaji kamili milele',
      );
  }
}

String _priceLabel(PlanTier tier, PlanLimits limits) {
  if (limits.pricePerMonth > 0) {
    return '${_fmtPriceCompact(limits.pricePerMonth)}${_t("/mo", "/mwezi")}';
  }
  if (tier == PlanTier.enterprise) return _t('Custom', 'Maalum');
  if (tier == PlanTier.lifetime) return _t('Lifetime', 'Maisha yote');
  return _t('Free', 'Bure');
}

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(planStatusProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        title: Text(
          _t('My Plan', 'Mpango Wangu'),
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.navyPrimary,
            letterSpacing: -0.3,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            size: 18,
            color: AppColors.navyPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: planAsync.smartWhen(
        skeleton: () => const SkeletonSubscriptionBody(),
        onError: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                _t('Could not load plan info', 'Imeshindwa kupakia mpango'),
                style: GoogleFonts.dmSans(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(planStatusProvider),
                child: Text(_t('Retry', 'Jaribu tena')),
              ),
            ],
          ),
        ),
        data: (status) {
          final defs = status.definitions;
          final bottomInset = MediaQuery.paddingOf(context).bottom;
          final tiers = [
            PlanTier.starter,
            PlanTier.growth,
            PlanTier.business,
            PlanTier.enterprise,
            if (status.tier == PlanTier.lifetime) PlanTier.lifetime,
          ];

          return ListView(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 32 + bottomInset),
            children: [
              // ── Pending request notice ─────────────────────────
              const _PendingBanner(),

              // ── Current plan ────────────────────────────────────
              _CurrentPlanBlock(
                status: status,
                onUpgradeTap: () => _openUpgrade(context, ref, status),
              ),

              // ── Usage against free-plan limits ─────────────────
              // Free plan only — paid tiers are effectively unlimited on
              // every metered dimension, so a usage panel there is just noise.
              if (status.isStarter) ...[
                const SizedBox(height: 16),
                _UsagePanel(status: status),
              ],
              const SizedBox(height: 32),

              // ── Plans ────────────────────────────────────────────
              _SectionLabel(_t('Plans', 'Mipango')),
              const SizedBox(height: 10),
              _PlanList(
                tiers: tiers,
                currentTier: status.tier,
                defs: defs,
                onTap: (tier) {
                  if (tier == status.tier) return;
                  _openUpgrade(context, ref, status);
                },
              ),
              const SizedBox(height: 32),

              // ── FAQ ────────────────────────────────────────────
              _SectionLabel(_t('Common questions', 'Maswali ya kawaida')),
              const SizedBox(height: 10),
              _FaqList(defs: defs),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openUpgrade(
    BuildContext context,
    WidgetRef ref,
    PlanStatus status,
  ) async {
    await showUpgradeSheet(context, currentStatus: status);
    // Refresh plan status after user dismisses the sheet
    ref.invalidate(planStatusProvider);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label — small muted caps heading
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) => Text(
    label.toUpperCase(),
    style: GoogleFonts.dmSans(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: AppColors.textMuted,
      letterSpacing: 1.1,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Pending request notice — flat, single line
// ─────────────────────────────────────────────────────────────────────────────

class _PendingBanner extends ConsumerWidget {
  const _PendingBanner();

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
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.tealAccent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.tealAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.hourglass_top_rounded,
            color: AppColors.tealAccent,
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _t(
                'Your $tierLabel request is being reviewed',
                'Ombi lako la $tierLabel linashughulikiwa',
              ),
              style: GoogleFonts.dmSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.navyPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Current plan — flat card, no gradient/shadow
// ─────────────────────────────────────────────────────────────────────────────

class _CurrentPlanBlock extends StatelessWidget {
  final PlanStatus status;
  final VoidCallback onUpgradeTap;

  const _CurrentPlanBlock({required this.status, required this.onUpgradeTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('CURRENT PLAN', 'MPANGO WA SASA'),
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      status.tierLabel,
                      style: GoogleFonts.dmSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navyPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (status.expiresAt != null)
                Text(
                  _t(
                    'Until ${_fmtDate(status.expiresAt!)}',
                    'Hadi ${_fmtDate(status.expiresAt!)}',
                  ),
                  style: GoogleFonts.dmSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                )
              else if (status.tier == PlanTier.lifetime)
                Row(
                  children: [
                    const Icon(
                      Icons.all_inclusive_rounded,
                      size: 14,
                      color: AppColors.tealAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _t('Lifetime', 'Maisha yote'),
                      style: GoogleFonts.dmSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.tealAccent,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          if (status.isStarter) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onUpgradeTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _t('Upgrade my plan', 'Boresha mpango wangu'),
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 15,
                    color: AppColors.navyPrimary,
                  ),
                ],
              ),
            ),
          ] else if (status.tier == PlanTier.growth) ...[
            // No usage bar here — Growth already has unlimited invoices.
            // Business is the natural next step up, so still surface a
            // direct path to it instead of leaving Growth subscribers with
            // no upgrade affordance on their own plan card.
            const SizedBox(height: 14),
            GestureDetector(
              onTap: onUpgradeTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _t('Upgrade to Business', 'Panda hadi Business'),
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 15,
                    color: AppColors.navyPrimary,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Usage panel — a bar per metered free-plan limit. Only rendered for Starter
// (see the call site); the counts come from planUsageProvider, which reads the
// offline-first Drift streams so this matches exactly what the "add" gates in
// Sales, Customers and Inventory enforce.
// ─────────────────────────────────────────────────────────────────────────────

class _UsagePanel extends ConsumerWidget {
  final PlanStatus status;
  const _UsagePanel({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usage = ref.watch(planUsageProvider);
    final limits = status.limits;

    final rows = <Widget>[];
    void add(String en, String sw, int used, int limit) {
      if (limit < 0) return; // unlimited on this plan — nothing to meter
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 14));
      rows.add(_UsageRow(label: _t(en, sw), used: used, limit: limit));
    }

    add('Sales today', 'Mauzo leo', usage.salesToday, limits.maxSalesPerDay);
    add('Invoices this month', 'Ankara mwezi huu',
        status.invoicesUsedThisMonth, limits.monthlyInvoices);
    add('Customers', 'Wateja', usage.customers, limits.maxCustomers);
    add('Products', 'Bidhaa', usage.products, limits.maxProducts);
    add('Services', 'Huduma', usage.serviceProducts, limits.maxServiceProducts);
    add('Accounts', 'Akaunti', usage.accounts, limits.maxAccounts);

    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('YOUR USAGE', 'MATUMIZI YAKO'),
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _t(
              'Free-plan limits reset as shown — daily or monthly. Upgrade to lift them.',
              'Vikomo vya mpango wa bure vinaanza upya kama inavyoonyeshwa — kila siku au mwezi. Boresha kuviondoa.',
            ),
            style: GoogleFonts.dmSans(
              fontSize: 11.5,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          ...rows,
        ],
      ),
    );
  }
}

class _UsageRow extends StatelessWidget {
  final String label;
  final int used;
  final int limit;

  const _UsageRow({required this.label, required this.used, required this.limit});

  @override
  Widget build(BuildContext context) {
    final pct = limit <= 0 ? 0.0 : (used / limit).clamp(0.0, 1.0);
    final color = pct >= 1.0
        ? AppColors.error
        : pct >= 0.8
            ? AppColors.warning
            : AppColors.tealAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '$used / $limit',
              style: GoogleFonts.dmSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: pct >= 0.8 ? color : AppColors.navyPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 5,
            backgroundColor: AppColors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Plan list — vertical, single column (replaces the wide comparison table)
// ─────────────────────────────────────────────────────────────────────────────

class _PlanList extends StatelessWidget {
  final List<PlanTier> tiers;
  final PlanTier currentTier;
  final PlanDefinitions? defs;
  final ValueChanged<PlanTier> onTap;

  const _PlanList({
    required this.tiers,
    required this.currentTier,
    required this.defs,
    required this.onTap,
  });

  static const _tierNames = {
    PlanTier.starter: 'Starter',
    PlanTier.growth: 'Growth',
    PlanTier.business: 'Business',
    PlanTier.enterprise: 'Enterprise',
    PlanTier.lifetime: 'Lifetime',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < tiers.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.borderLight),
            _PlanRow(
              tier: tiers[i],
              limits: limitsFor(tiers[i], defs),
              isCurrent: tiers[i] == currentTier,
              onTap: () => onTap(tiers[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  final PlanTier tier;
  final PlanLimits limits;
  final bool isCurrent;
  final VoidCallback onTap;

  const _PlanRow({
    required this.tier,
    required this.limits,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isCurrent ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCurrent ? AppColors.navyPrimary : Colors.transparent,
                border: Border.all(
                  color: isCurrent ? AppColors.navyPrimary : AppColors.border,
                  width: 1.4,
                ),
              ),
              child: isCurrent
                  ? const Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _PlanList._tierNames[tier]!,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _priceLabel(tier, limits),
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _blurbFor(tier, limits),
                    style: GoogleFonts.dmSans(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            if (!isCurrent) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textDisabled,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FAQ — flat list, hairline dividers, no per-item card shadow
// ─────────────────────────────────────────────────────────────────────────────

class _FaqList extends StatelessWidget {
  final PlanDefinitions? defs;
  const _FaqList({required this.defs});

  @override
  Widget build(BuildContext context) {
    final starterLimits = limitsFor(PlanTier.starter, defs);

    final items = [
      (
        _t('How do I pay?', 'Ninalipaje?'),
        _t(
          'Open My Plan, pick Growth or Business, and enter your mobile money '
              'number. We send a payment prompt to that phone — enter your PIN '
              'to confirm and your plan activates on the spot. No forms, no '
              'waiting for our team.',
          'Fungua Mpango Wangu, chagua Growth au Business, kisha weka namba '
              'yako ya pesa ya simu. Tutatuma ombi la malipo kwenye simu hiyo '
              '— weka PIN yako kuthibitisha na mpango wako unaanza papo hapo. '
              'Hakuna fomu, hakuna kusubiri timu yetu.',
        ),
      ),
      (
        _t(
          'Which mobile money can I use?',
          'Naweza kutumia pesa ya simu gani?',
        ),
        _t(
          'M-Pesa, Tigo Pesa (Mixx by Yas), Airtel Money, and HaloPesa all '
              "work. The number you pay from doesn't have to be the same as "
              'your account number.',
          'M-Pesa, Tigo Pesa (Mixx by Yas), Airtel Money, na HaloPesa zote '
              'zinafanya kazi. Namba unayolipia haihitaji kufanana na namba '
              'ya akaunti yako.',
        ),
      ),
      (
        _t(
          'Does it renew automatically?',
          'Je, inajilipa yenyewe kila mwezi?',
        ),
        _t(
          'No. Each payment covers one cycle. When it ends, your plan simply '
              'drops back to Starter — we never auto-charge your phone. Pay '
              "again whenever you're ready to continue, nothing to cancel.",
          'Hapana. Kila malipo hufunika mzunguko mmoja. Ukiisha, mpango wako '
              'unarudi Starter tu — hatutozi simu yako kiotomatiki. Lipa tena '
              'wakati wowote ukiwa tayari kuendelea, hakuna cha kughairi.',
        ),
      ),
      (
        _t(
          'What happens to my data if I go back to Starter?',
          'Nini kinatokea kwa data yangu nikirudi Starter?',
        ),
        _t(
          "Everything you've recorded stays and stays visible. You just "
              "can't create new invoices past the Starter limit of "
              '${starterLimits.monthlyInvoices}/month until you upgrade again.',
          'Kila ulichorekodi kinabaki na kinaonekana. Utashindwa tu '
              'kutengeneza ankara mpya zaidi ya kikomo cha Starter cha '
              '${starterLimits.monthlyInvoices}/mwezi mpaka upande tena.',
        ),
      ),
      (
        _t(
          'Is each business billed separately?',
          'Je, kila biashara hulipiwa peke yake?',
        ),
        _t(
          "Yes. Plans are per business — upgrading one business doesn't "
              'upgrade the others. Switch business at the top of the '
              'dashboard, then open My Plan for that one.',
          'Ndiyo. Mipango ni kwa kila biashara — kupandisha biashara moja '
              'hakupandishi nyingine. Badilisha biashara juu ya dashibodi, '
              'kisha fungua Mpango Wangu kwa hiyo.',
        ),
      ),
      (
        _t('Do I need internet to pay?', 'Nahitaji intaneti kulipa?'),
        _t(
          'Only for the payment itself — the prompt and confirmation need a '
              'connection. Everything else in Mali Up keeps working offline.',
          'Kwa malipo yenyewe tu — ombi na uthibitisho vinahitaji mtandao. '
              'Kila kitu kingine katika Mali Up kinaendelea kufanya kazi bila '
              'intaneti.',
        ),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.borderLight),
            _FaqTile(q: items[i].$1, a: items[i].$2),
          ],
        ],
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String q;
  final String a;
  const _FaqTile({required this.q, required this.a});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          widget.q,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.navyPrimary,
          ),
        ),
        trailing: Icon(
          _open ? Icons.remove_rounded : Icons.add_rounded,
          color: AppColors.textMuted,
          size: 18,
        ),
        onExpansionChanged: (v) => setState(() => _open = v),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.a,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
