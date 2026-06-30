import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/services/plan_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/skeleton_widgets.dart';
import '../../../../shared/widgets/smart_skeleton.dart';
import '../../../../shared/widgets/upgrade_sheet.dart';

String _fmtPrice(int v) =>
    'TZS ${v.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';

String _fmtPriceCompact(int v) => v == 0 ? 'Bure' : _fmtPrice(v);

String _t(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

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
        title: Text(
          _t('My Plan', 'Mpango Wangu'),
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.navyPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navyPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: planAsync.smartWhen(
        skeleton: () => const SkeletonSubscriptionBody(),
        onError: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text(_t('Could not load plan info', 'Imeshindwa kupakia mpango'),
                  style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
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
          final growthLimits   = limitsFor(PlanTier.growth,   defs);
          final businessLimits = limitsFor(PlanTier.business, defs);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              // ── Current plan card ──────────────────────────────
              PlanInfoCard(
                status: status,
                onUpgradeTap: () => _openUpgrade(context, ref, status),
              ),
              const SizedBox(height: 28),

              // ── Usage meters (Starter only) ────────────────────
              if (status.isStarter) ...[
                _SectionHeader(_t('Usage this month', 'Matumizi mwezi huu')),
                const SizedBox(height: 12),
                _UsageMeter(
                  label: _t('Invoices', 'Ankara'),
                  used: status.invoicesUsedThisMonth,
                  limit: status.limits.monthlyInvoices,
                ),
                const SizedBox(height: 28),
              ],

              // ── All tiers comparison ───────────────────────────
              _SectionHeader(_t('Compare plans', 'Linganisha mipango')),
              const SizedBox(height: 12),
              _ComparisonTable(currentTier: status.tier, defs: defs),
              const SizedBox(height: 28),

              // ── FAQ ────────────────────────────────────────────
              _SectionHeader(_t('Common questions', 'Maswali ya kawaida')),
              const SizedBox(height: 12),
              _Faq(
                q: _t('How do I pay?', 'Ninalipaje?'),
                a: _t(
                  'Send ${_fmtPrice(growthLimits.pricePerCycle)} (${growthLimits.cycleMonths} months × Growth) or ${_fmtPrice(businessLimits.pricePerCycle)} (${businessLimits.cycleMonths} months × Business) via M-Pesa to our business number. Our team activates your plan within 24 hours.',
                  'Tuma ${_fmtPrice(growthLimits.pricePerCycle)} (miezi ${growthLimits.cycleMonths} × Growth) au ${_fmtPrice(businessLimits.pricePerCycle)} (miezi ${businessLimits.cycleMonths} × Business) kwa M-Pesa kwenye namba yetu ya biashara. Timu yetu itawasha mpango wako ndani ya masaa 24.',
                ),
              ),
            _Faq(
              q: _t('Can I cancel?', 'Ninaweza kughairi?'),
              a: _t(
                'Yes. When your paid period ends it simply reverts to Starter — no automatic charges.',
                'Ndiyo. Wakati kipindi chako cha malipo kinapoisha, moja kwa moja inarudi Starter — hakuna malipo ya moja kwa moja.',
              ),
            ),
            _Faq(
              q: _t('What happens to my data if I downgrade?',
                  'Nini kinatokea kwa data yangu nikienda chini?'),
              a: _t(
                'All your data stays safe. You can only create new invoices up to the Starter limit; everything already recorded remains accessible.',
                'Data yako yote inabaki salama. Unaweza tu kuunda ankara mpya hadi kikomo cha Starter; kila kitu kilichorekodiwa tayari kinabaki kinaweza kufikiwa.',
              ),
            ),
            const SizedBox(height: 24),

            // ── Upgrade CTA (Starter only) ─────────────────────
            if (status.isStarter)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _openUpgrade(context, ref, status),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.yellowBrand,
                    foregroundColor: AppColors.navyPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    _t('Upgrade my plan', 'Boresha mpango wangu'),
                    style: GoogleFonts.dmSans(
                        fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
          ],
        );
        },
      ),
    );
  }

  Future<void> _openUpgrade(
      BuildContext context, WidgetRef ref, PlanStatus status) async {
    await showUpgradeSheet(context, currentStatus: status);
    // Refresh plan status after user dismisses the sheet
    ref.invalidate(planStatusProvider);
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 0.5,
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────

class _UsageMeter extends StatelessWidget {
  final String label;
  final int used;
  final int limit;

  const _UsageMeter(
      {required this.label, required this.used, required this.limit});

  @override
  Widget build(BuildContext context) {
    final pct = (used / limit).clamp(0.0, 1.0);
    final barColor = pct >= 1.0
        ? AppColors.error
        : pct >= 0.8
            ? AppColors.warning
            : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: GoogleFonts.dmSans(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              Text(
                '$used / $limit',
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          if (pct >= 0.8) ...[
            const SizedBox(height: 8),
            Text(
              pct >= 1.0
                  ? _t('Limit reached — upgrade to continue', 'Kikomo kimefikiwa — boresha kuendelea')
                  : _t('${limit - used} remaining this month', '${limit - used} zimebaki mwezi huu'),
              style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: pct >= 1.0 ? AppColors.error : AppColors.warning),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ComparisonTable extends StatelessWidget {
  final PlanTier currentTier;
  final PlanDefinitions? defs;
  const _ComparisonTable({required this.currentTier, this.defs});

  @override
  Widget build(BuildContext context) {
    final tiers = [PlanTier.starter, PlanTier.growth, PlanTier.business];
    final tierNames = ['Starter', 'Growth', 'Business'];

    final starterL  = limitsFor(PlanTier.starter,  defs);
    final growthL   = limitsFor(PlanTier.growth,   defs);
    final businessL = limitsFor(PlanTier.business, defs);

    String priceLabel(PlanLimits l) =>
        l.pricePerMonth > 0 ? '${_fmtPriceCompact(l.pricePerMonth)}/mwezi' : 'Bure';

    final prices = [
      priceLabel(starterL),
      priceLabel(growthL),
      priceLabel(businessL),
    ];

    final allLimits = [starterL, growthL, businessL];

    final features = <(String, List<bool>)>[
      (_t('Monthly invoices', 'Ankara / mwezi'), [false, true, true]),
      (_t('Users', 'Watumiaji'), [false, false, true]),
      (_t('Full reports', 'Ripoti kamili'),
          allLimits.map((l) => l.fullReports).toList()),
      (_t('M-Pesa import', 'Kuingiza M-Pesa'),
          allLimits.map((l) => l.mpesaImport).toList()),
      (_t('SMS reminders', 'Ukumbusho wa SMS'),
          allLimits.map((l) => l.smsReminders).toList()),
      (_t('Multi-location stock', 'Stoo nyingi'),
          allLimits.map((l) => l.multiLocation).toList()),
      (_t('API access', 'Ufikiaji wa API'),
          allLimits.map((l) => l.apiAccess).toList()),
      (_t('Priority support', 'Msaada wa kipaumbele'),
          allLimits.map((l) => l.prioritySupport).toList()),
    ];

    String invoiceLabel(PlanLimits l) =>
        l.monthlyInvoices == -1 ? '∞' : '${l.monthlyInvoices}/mwezi';
    String userLabel(PlanLimits l) =>
        l.maxUsers == -1 ? '∞' : '${l.maxUsers}';

    final limitLabels = allLimits.map(invoiceLabel).toList();
    final userLabels  = allLimits.map(userLabel).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header row
          Container(
            color: AppColors.surface,
            child: Row(
              children: [
                const Expanded(flex: 3, child: SizedBox()),
                ...List.generate(
                  tiers.length,
                  (i) => Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: tiers[i] == currentTier
                          ? const BoxDecoration(
                              color: AppColors.navyPrimary,
                            )
                          : null,
                      child: Column(
                        children: [
                          Text(
                            tierNames[i],
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: tiers[i] == currentTier
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            prices[i],
                            style: GoogleFonts.dmSans(
                              fontSize: 9,
                              color: tiers[i] == currentTier
                                  ? Colors.white.withValues(alpha: 0.65)
                                  : AppColors.textMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Feature rows
          ...features.asMap().entries.map((entry) {
            final idx = entry.key;
            final (label, values) = entry.value;
            final isLast = idx == features.length - 1;

            return Container(
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : const Border(
                        bottom: BorderSide(color: AppColors.border, width: 0.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                      child: Text(
                        label,
                        style: GoogleFonts.dmSans(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  ...List.generate(tiers.length, (i) {
                    final isCurrent = tiers[i] == currentTier;
                    // Special handling for invoices (index 0) and users (index 1)
                    if (idx == 0) {
                      return Expanded(
                        flex: 2,
                        child: Container(
                          color: isCurrent
                              ? AppColors.navyPrimary.withValues(alpha: 0.04)
                              : null,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Center(
                            child: Text(
                              limitLabels[i],
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isCurrent
                                    ? AppColors.navyPrimary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    if (idx == 1) {
                      return Expanded(
                        flex: 2,
                        child: Container(
                          color: isCurrent
                              ? AppColors.navyPrimary.withValues(alpha: 0.04)
                              : null,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Center(
                            child: Text(
                              userLabels[i],
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isCurrent
                                    ? AppColors.navyPrimary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    return Expanded(
                      flex: 2,
                      child: Container(
                        color: isCurrent
                            ? AppColors.navyPrimary.withValues(alpha: 0.04)
                            : null,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Center(
                          child: Icon(
                            values[i]
                                ? Icons.check_circle_rounded
                                : Icons.remove_rounded,
                            size: 16,
                            color: values[i]
                                ? AppColors.success
                                : AppColors.textDisabled,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Faq extends StatefulWidget {
  final String q;
  final String a;
  const _Faq({required this.q, required this.a});

  @override
  State<_Faq> createState() => _FaqState();
}

class _FaqState extends State<_Faq> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            widget.q,
            style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
          ),
          trailing: Icon(
            _open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
            color: AppColors.textMuted,
            size: 20,
          ),
          onExpansionChanged: (v) => setState(() => _open = v),
          childrenPadding:
              const EdgeInsets.fromLTRB(16, 0, 16, 14),
          children: [
            Text(
              widget.a,
              style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
