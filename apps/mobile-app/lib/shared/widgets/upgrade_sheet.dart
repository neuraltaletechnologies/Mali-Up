import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/plan_request_service.dart';
import '../../core/services/plan_service.dart';
import '../../core/services/localization_service.dart';
import '../../core/utils/online_guard.dart';
import '../../core/theme/app_colors.dart';
import 'app_sheet.dart';
import 'mali_components.dart';
import 'skeleton_widgets.dart';
import 'smart_skeleton.dart';

String _t(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

// ─────────────────────────────────────────────────────────────────────────────
// Feature keys — lets the sheet show context-aware locked-feature notice.
// ─────────────────────────────────────────────────────────────────────────────

enum PlanFeatureKey {
  teamMembers,
  cashFlow,
  expenseExports,
  expenseTracking,
  fullReports,
  mpesaImport,
  smsReminders,
  allExports,
  manualDebt,
  multiBusiness,
  customerLimit,
}

extension PlanFeatureKeyX on PlanFeatureKey {
  IconData get icon => switch (this) {
        PlanFeatureKey.teamMembers     => Icons.group_rounded,
        PlanFeatureKey.cashFlow        => Icons.waterfall_chart_rounded,
        PlanFeatureKey.expenseExports  => Icons.download_rounded,
        PlanFeatureKey.expenseTracking => Icons.receipt_long_rounded,
        PlanFeatureKey.fullReports     => Icons.bar_chart_rounded,
        PlanFeatureKey.mpesaImport     => Icons.phone_android_rounded,
        PlanFeatureKey.smsReminders    => Icons.sms_rounded,
        PlanFeatureKey.allExports      => Icons.ios_share_rounded,
        PlanFeatureKey.manualDebt      => Icons.edit_note_rounded,
        PlanFeatureKey.multiBusiness   => Icons.store_mall_directory_rounded,
        PlanFeatureKey.customerLimit   => Icons.people_alt_rounded,
      };

  String get labelSw => switch (this) {
        PlanFeatureKey.teamMembers     => 'Wanachama wa Timu',
        PlanFeatureKey.cashFlow        => 'Mtiririko wa Fedha',
        PlanFeatureKey.expenseExports  => 'Uhamishaji wa Matumizi',
        PlanFeatureKey.expenseTracking => 'Kufuatilia Matumizi',
        PlanFeatureKey.fullReports     => 'Ripoti Kamili',
        PlanFeatureKey.mpesaImport     => 'Kuingiza Data ya M-Pesa',
        PlanFeatureKey.smsReminders    => 'SMS za Ukumbusho',
        PlanFeatureKey.allExports      => 'Uhamishaji wa Data',
        PlanFeatureKey.manualDebt      => 'Kuongeza Deni/Dai Mkononi',
        PlanFeatureKey.multiBusiness   => 'Biashara Nyingi',
        PlanFeatureKey.customerLimit   => 'Kikomo cha Wateja',
      };

  String get labelEn => switch (this) {
        PlanFeatureKey.teamMembers     => 'Team Members',
        PlanFeatureKey.cashFlow        => 'Cash Flow',
        PlanFeatureKey.expenseExports  => 'Expense Exports',
        PlanFeatureKey.expenseTracking => 'Expense Tracking',
        PlanFeatureKey.fullReports     => 'Full Reports',
        PlanFeatureKey.mpesaImport     => 'M-Pesa Import',
        PlanFeatureKey.smsReminders    => 'SMS Reminders',
        PlanFeatureKey.allExports      => 'Data Exports',
        PlanFeatureKey.manualDebt      => 'Manual Debt Entry',
        PlanFeatureKey.multiBusiness   => 'Multiple Businesses',
        PlanFeatureKey.customerLimit   => 'Customer Limit',
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Public API
// ─────────────────────────────────────────────────────────────────────────────

/// Shows the upgrade / paywall bottom sheet.
/// Returns the selected [PlanTier] if the user proceeds to payment, or null.
Future<PlanTier?> showUpgradeSheet(
  BuildContext context, {
  PlanStatus? currentStatus,
  String? triggerReason,
  PlanFeatureKey? featureKey,
}) {
  return showAppSheet<PlanTier>(
    context,
    builder: (_) => _UpgradeSheetWrapper(
      currentStatus: currentStatus,
      triggerReason: triggerReason,
      featureKey: featureKey,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal wrapper (provides Riverpod to the sheet)
// ─────────────────────────────────────────────────────────────────────────────

class _UpgradeSheetWrapper extends ConsumerWidget {
  final PlanStatus? currentStatus;
  final String? triggerReason;
  final PlanFeatureKey? featureKey;

  const _UpgradeSheetWrapper({
    this.currentStatus,
    this.triggerReason,
    this.featureKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // One pending request per user at a time — a second submission (growth,
    // business, or enterprise) while the first is still awaiting admin review
    // would just create noise in the admin portal, so block the whole sheet
    // and point the user at the existing request instead.
    final pendingAsync = ref.watch(pendingPlanRequestProvider);
    if (pendingAsync.isLoading && !pendingAsync.hasValue) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    final pending = pendingAsync.valueOrNull;
    if (pending != null) {
      return _PendingRequestNotice(pending: pending);
    }

    final defsAsync = ref.watch(planDefinitionsProvider);
    return defsAsync.smartWhen(
      skeleton: () => const Padding(
        padding: EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonPlanCard(),
            SizedBox(height: 16),
            SkeletonCard(height: 56, padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
            SizedBox(height: 8),
            SkeletonCard(height: 56, padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
          ],
        ),
      ),
      onError: (e, _) => _UpgradeSheet(
        currentStatus: currentStatus,
        triggerReason: triggerReason,
        featureKey: featureKey,
      ),
      data: (defs) => _UpgradeSheet(
        currentStatus: currentStatus,
        triggerReason: triggerReason,
        featureKey: featureKey,
        defs: defs,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pending-request notice — shown instead of the paywall while a request
// (payment claim or enterprise inquiry) is already awaiting admin review.
// ─────────────────────────────────────────────────────────────────────────────

class _PendingRequestNotice extends StatelessWidget {
  final PlanRequestSummary pending;

  const _PendingRequestNotice({required this.pending});

  @override
  Widget build(BuildContext context) {
    final tierLabel = switch (pending.tier) {
      PlanTier.growth => 'Growth',
      PlanTier.business => 'Business',
      PlanTier.enterprise => 'Enterprise',
      PlanTier.lifetime => 'Lifetime',
      PlanTier.starter => 'Starter',
    };

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHandle(),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.tealAccent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.tealAccent.withValues(alpha: 0.25)),
            ),
            child: Column(
              children: [
                const Icon(Icons.hourglass_top_rounded,
                    color: AppColors.tealAccent, size: 36),
                const SizedBox(height: 10),
                Text(
                  _t('Your $tierLabel request is still being processed',
                      'Ombi lako la $tierLabel bado linashughulikiwa'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _t(
                      'Our team is verifying your request. You cannot submit '
                      'another request until this one is done.',
                      'Timu yetu inathibitisha ombi lako. Huwezi kutuma ombi jingine mpaka hili likamilike.'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navyPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _t('Got It', 'Nimeelewa'),
                      style: GoogleFonts.dmSans(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
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
// Main sheet widget
// ─────────────────────────────────────────────────────────────────────────────

class _UpgradeSheet extends StatefulWidget {
  final PlanStatus? currentStatus;
  final String? triggerReason;
  final PlanFeatureKey? featureKey;
  final PlanDefinitions? defs;

  const _UpgradeSheet({
    this.currentStatus,
    this.triggerReason,
    this.featureKey,
    this.defs,
  });

  @override
  State<_UpgradeSheet> createState() => _UpgradeSheetState();
}

class _UpgradeSheetState extends State<_UpgradeSheet> {
  PlanTier _selected = PlanTier.growth;
  bool _showPayment = false;
  bool _showEnterprise = false;
  bool _submittingClaim = false;
  bool _paymentSubmitted = false;
  String _paymentRef = '';

  static const _mpesaNumber = '+255 XXX XXX XXX';

  PlanLimits get _selLimits => limitsFor(_selected, widget.defs);
  int get _priceMonthly => _selLimits.pricePerMonth;
  int get _priceCycle   => _selLimits.pricePerCycle;

  Future<void> _openPayment() async {
    // The payment claim must reach Firestore (admin portal activates the
    // plan from it) — don't start the flow without a connection.
    if (!await OnlineGuard.ensureOnline(context)) return;
    if (!mounted) return;
    final tierName = _selected == PlanTier.growth ? 'GROWTH' : 'BUSINESS';
    setState(() {
      _paymentRef =
          'MALIUP-$tierName-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      _showPayment = true;
    });
  }

  /// Records the payment claim in Firestore (visible in the admin portal)
  /// before closing the sheet. Best-effort — activation is manual either way.
  Future<void> _finishPayment() async {
    // Without a connection PlanRequestService.submit would hang forever
    // (Firestore persistence is disabled) — bail out with the offline notice.
    if (!await OnlineGuard.ensureOnline(context)) return;
    if (!mounted) return;
    setState(() => _submittingClaim = true);
    try {
      await PlanRequestService.submit(
        tier: _selected,
        type: PlanRequestType.paymentClaim,
        paymentRef: _paymentRef,
      );
    } catch (_) {
      // Offline or rules failure — the M-Pesa reference still reaches the
      // team through the payment itself, so don't block the user here.
    }
    if (mounted) {
      setState(() {
        _submittingClaim = false;
        _paymentSubmitted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20, 12, 20, 20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHandle(),
              const SizedBox(height: 14),

              // ── Locked-feature notice ─────────────────────────────────────
              _LockedFeatureNotice(
                featureKey: widget.featureKey,
                triggerReason: widget.triggerReason,
              ),

              // ── Headline ─────────────────────────────────────────────────
              Text(
                _t('Grow Your Business', 'Inua Biashara Yako'),
                style: GoogleFonts.dmSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navyPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 3),
              Text(
                _t(
                    'Costs less than an hour of accountant fees — reach '
                    'further every day.',
                    'Lipa chini ya saa moja ya mhasibu — ufike zaidi kila siku.'),
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              // ── Plan cards ───────────────────────────────────────────────
              _TierCard(
                tier: PlanTier.growth,
                limits: limitsFor(PlanTier.growth, widget.defs),
                isSelected: !_showEnterprise && _selected == PlanTier.growth,
                onTap: () => setState(() {
                  _selected = PlanTier.growth;
                  _showPayment = false;
                  _showEnterprise = false;
                }),
              ),
              const SizedBox(height: 6),
              _TierCard(
                tier: PlanTier.business,
                limits: limitsFor(PlanTier.business, widget.defs),
                isSelected: !_showEnterprise && _selected == PlanTier.business,
                onTap: () => setState(() {
                  _selected = PlanTier.business;
                  _showPayment = false;
                  _showEnterprise = false;
                }),
              ),
              const SizedBox(height: 6),
              _EnterpriseCard(
                isSelected: _showEnterprise,
                onTap: () => setState(() {
                  _showEnterprise = true;
                  _showPayment = false;
                }),
              ),
              const SizedBox(height: 16),

              // ── CTA / Payment / Enterprise request ───────────────────────
              if (_paymentSubmitted) ...[
                _PaymentSubmittedCard(
                  tier: _selected,
                  paymentRef: _paymentRef,
                  onDone: () => Navigator.pop(context, _selected),
                ),
              ] else if (_showEnterprise) ...[
                _EnterpriseRequestForm(
                  onDone: () => Navigator.pop(context, PlanTier.enterprise),
                ),
              ] else if (!_showPayment) ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _openPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.yellowBrand,
                      foregroundColor: AppColors.navyPrimary,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.rocket_launch_rounded, size: 16),
                        SizedBox(width: 8),
                        Text(
                          '${_t("Upgrade to", "Panda")} '
                          '${_selected == PlanTier.growth ? "Growth" : "Business"}'
                          ' — ${_fmtPrice(_priceMonthly)}${_t("/mo", "/mwezi")}',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 6),
                Center(
                  child: Text(
                    '${_fmtPrice(_priceCycle)} ${_t("billed every ${_selLimits.cycleMonths} months upfront", "ulipwa kwa miezi ${_selLimits.cycleMonths} mbele")}',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ] else ...[
                _PaymentInstructions(
                  tier: _selected,
                  priceMonthly: _priceMonthly,
                  priceCycle: _priceCycle,
                  cycleMonths: _selLimits.cycleMonths,
                  mpesaNumber: _mpesaNumber,
                  paymentRef: _paymentRef,
                  busy: _submittingClaim,
                  onDone: _finishPayment,
                  onBack: () => setState(() => _showPayment = false),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Locked-feature notice — flat row, no gradient, brand colors only
// ─────────────────────────────────────────────────────────────────────────────

class _LockedFeatureNotice extends StatelessWidget {
  final PlanFeatureKey? featureKey;
  final String? triggerReason;

  const _LockedFeatureNotice({this.featureKey, this.triggerReason});

  @override
  Widget build(BuildContext context) {
    if (featureKey == null && triggerReason == null) return const SizedBox.shrink();

    final icon  = featureKey?.icon ?? Icons.lock_rounded;
    final label = LocalizationService.isSwahili
        ? featureKey?.labelSw
        : featureKey?.labelEn;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.navyPrimary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.navyPrimary, size: 17),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (label != null) ...[
                    Text(
                      label,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                  ],
                  Text(
                    triggerReason ??
                        _t('This feature requires a higher plan.',
                            'Kipengele hiki kinahitaji mpango wa juu.'),
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.navyPrimary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_rounded, size: 9, color: Colors.white),
                  SizedBox(width: 3),
                  Text(
                    'PREMIUM',
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tier card
// ─────────────────────────────────────────────────────────────────────────────

class _TierCard extends StatelessWidget {
  final PlanTier tier;
  final PlanLimits limits;
  final bool isSelected;
  final VoidCallback onTap;

  const _TierCard({
    required this.tier,
    required this.limits,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isGrowth = tier == PlanTier.growth;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navyPrimary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.navyPrimary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.yellowBrand : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.yellowBrand : AppColors.border,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, size: 10, color: AppColors.navyPrimary)
                  : null,
            ),
            const SizedBox(width: 10),

            // Name + badge
            Expanded(
              child: Row(
                children: [
                  Text(
                    isGrowth ? 'Growth' : 'Business',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppColors.navyPrimary,
                    ),
                  ),
                  if (isGrowth) ...[
                    SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.yellowBrand.withValues(
                          alpha: isSelected ? 0.2 : 0.12,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _t('Popular', 'Maarufu'),
                        style: GoogleFonts.dmSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? AppColors.yellowBrand : AppColors.navyPrimary,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(width: 6),
                  Text(
                    '${_fmtPrice(limits.pricePerCycle)} / '
                    '${_t("${limits.cycleMonths} mo", "miezi ${limits.cycleMonths}")}',
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.45)
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _fmtPrice(limits.pricePerMonth),
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? AppColors.yellowBrand : AppColors.navyPrimary,
                  ),
                ),
                Text(
                  _t('/mo', '/mwezi'),
                  style: GoogleFonts.dmSans(
                    fontSize: 9,
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.45)
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Enterprise card
// ─────────────────────────────────────────────────────────────────────────────

class _EnterpriseCard extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _EnterpriseCard({required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.navyPrimary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.yellowBrand.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.business_center_rounded,
                color: AppColors.yellowBrand,
                size: 16,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enterprise',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyPrimary,
                    ),
                  ),
                  Text(
                    _t('Chains, NGOs, distributors — custom pricing',
                        'Minyororo, NGO, wasambazaji — bei maalum'),
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Enterprise request form — writes to plan_requests, visible in admin portal
// ─────────────────────────────────────────────────────────────────────────────

enum _EnterpriseFormState { checking, form, submitting, sent, alreadyPending }

class _EnterpriseRequestForm extends StatefulWidget {
  final VoidCallback onDone;

  const _EnterpriseRequestForm({required this.onDone});

  @override
  State<_EnterpriseRequestForm> createState() => _EnterpriseRequestFormState();
}

class _EnterpriseRequestFormState extends State<_EnterpriseRequestForm> {
  final _noteController = TextEditingController();
  _EnterpriseFormState _state = _EnterpriseFormState.checking;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkPending();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _checkPending() async {
    final pending =
        await PlanRequestService.hasPending(PlanRequestType.enterpriseInquiry);
    if (!mounted) return;
    setState(() => _state = pending
        ? _EnterpriseFormState.alreadyPending
        : _EnterpriseFormState.form);
  }

  Future<void> _submit() async {
    // Enterprise inquiries write to Firestore — online-only.
    if (!await OnlineGuard.ensureOnline(context)) return;
    if (!mounted) return;
    setState(() {
      _state = _EnterpriseFormState.submitting;
      _error = null;
    });
    try {
      await PlanRequestService.submit(
        tier: PlanTier.enterprise,
        type: PlanRequestType.enterpriseInquiry,
        note: _noteController.text,
      );
      if (!mounted) return;
      setState(() => _state = _EnterpriseFormState.sent);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = _EnterpriseFormState.form;
        _error = _t(
            'Failed to send request. Check your internet connection and try again.',
            'Imeshindwa kutuma ombi. Hakikisha una intaneti kisha jaribu tena.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case _EnterpriseFormState.checking:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );

      case _EnterpriseFormState.sent:
      case _EnterpriseFormState.alreadyPending:
        final alreadyPending = _state == _EnterpriseFormState.alreadyPending;
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              const Icon(Icons.mark_email_read_rounded,
                  color: AppColors.success, size: 36),
              SizedBox(height: 10),
              Text(
                alreadyPending
                    ? _t('You already submitted an Enterprise request',
                        'Tayari umetuma ombi la Enterprise')
                    : _t('Request sent!', 'Ombi limetumwa!'),
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navyPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                _t(
                    'Our team will contact you within 24 hours about custom '
                    'pricing for your business.',
                    'Timu yetu itawasiliana nawe ndani ya masaa 24 kuhusu bei maalum ya biashara yako.'),
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: widget.onDone,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _t('OK', 'Sawa'),
                    style: GoogleFonts.dmSans(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );

      case _EnterpriseFormState.form:
      case _EnterpriseFormState.submitting:
        final busy = _state == _EnterpriseFormState.submitting;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _t('Tell us about your business (optional)',
                  'Tuambie kuhusu biashara yako (hiari)'),
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 3,
              maxLength: 500,
              enabled: !busy,
              style: GoogleFonts.dmSans(fontSize: 13),
              decoration: InputDecoration(
                hintText: _t(
                    'E.g. 5 branches, 30 staff, need API and custom reports…',
                    'Mf. matawi 5, wafanyakazi 30, tunahitaji API na ripoti maalum…'),
                hintStyle: GoogleFonts.dmSans(
                    fontSize: 12, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surface,
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.navyPrimary),
                ),
              ),
            ),
            if (_error != null) ...[
              SizedBox(height: 8),
              Text(
                _error!,
                style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.error),
              ),
            ],
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: busy ? null : _submit,
                icon: busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.navyPrimary),
                      )
                    : const Icon(Icons.send_rounded, size: 16),
                label: Text(
                  busy
                      ? _t('Sending…', 'Inatuma…')
                      : _t('Send Enterprise Request',
                          'Tuma Ombi la Enterprise'),
                  style: GoogleFonts.dmSans(
                      fontSize: 14, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.yellowBrand,
                  foregroundColor: AppColors.navyPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            SizedBox(height: 6),
            Center(
              child: Text(
                _t('Your request will reach our team immediately.',
                    'Ombi lako litaonekana na timu yetu mara moja.'),
                style: GoogleFonts.dmSans(
                    fontSize: 11, color: AppColors.textMuted),
              ),
            ),
          ],
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment claim submitted — "we're processing it" confirmation
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentSubmittedCard extends StatelessWidget {
  final PlanTier tier;
  final String paymentRef;
  final VoidCallback onDone;

  const _PaymentSubmittedCard({
    required this.tier,
    required this.paymentRef,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final tierName = tier == PlanTier.growth ? 'Growth' : 'Business';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          const Icon(Icons.hourglass_top_rounded,
              color: AppColors.success, size: 36),
          SizedBox(height: 10),
          Text(
            _t('We received your payment info!',
                'Tumepokea taarifa yako ya malipo!'),
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.navyPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            _t(
                'We are confirming your $tierName payment ($paymentRef) — '
                'your plan will be activated within 24 hours. You will see '
                'a notice here once it is active.',
                'Tunathibitisha malipo yako ya $tierName ($paymentRef) — mpango wako '
                'utawashwa ndani ya masaa 24. Utaona taarifa hapa mara ukiwashwa.'),
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _t('OK', 'Sawa'),
                style: GoogleFonts.dmSans(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment instructions
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentInstructions extends StatelessWidget {
  final PlanTier tier;
  final int priceMonthly;
  final int priceCycle;
  final int cycleMonths;
  final String mpesaNumber;
  final String paymentRef;
  final bool busy;
  final VoidCallback onDone;
  final VoidCallback onBack;

  const _PaymentInstructions({
    required this.tier,
    required this.priceMonthly,
    required this.priceCycle,
    required this.cycleMonths,
    required this.mpesaNumber,
    required this.paymentRef,
    required this.busy,
    required this.onDone,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final ref = paymentRef;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onBack,
          child: Row(
            children: [
              const Icon(Icons.arrow_back_rounded,
                  size: 16, color: AppColors.textSecondary),
              SizedBox(width: 4),
              Text(
                _t('Back', 'Rudi'),
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.tealAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.phone_android_rounded,
                        color: AppColors.tealAccent, size: 16),
                  ),
                  SizedBox(width: 10),
                  Text(
                    _t('M-Pesa Payment Steps', 'Hatua za Malipo ya M-Pesa'),
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navyPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _Step(
                  number: '1',
                  text: _t('Open M-Pesa on your phone',
                      'Fungua M-Pesa kwenye simu yako')),
              _Step(
                number: '2',
                text: _t('Select "Pay Bill" (Lipa Number)',
                    'Chagua "Lipa Biashara" (Lipa Number)'),
              ),
              _Step(
                number: '3',
                child: _CopyRow(
                  label: '${_t("Number", "Namba")}: $mpesaNumber',
                  copyValue: mpesaNumber,
                  snackLabel: _t('Number copied', 'Namba imenakiliwa'),
                  context: context,
                ),
              ),
              _Step(
                number: '4',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_t("Amount", "Kiasi")}: ${_fmtPrice(priceCycle)} '
                      '(${_t("$cycleMonths months", "miezi $cycleMonths")})',
                      style: GoogleFonts.dmSans(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '(${_fmtPrice(priceMonthly)}${_t("/mo", "/mwezi")} × $cycleMonths)',
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              _Step(
                number: '5',
                child: _CopyRow(
                  label: ref,
                  sublabel: _t('Reference:', 'Maelezo / Kumbukumbu:'),
                  copyValue: ref,
                  snackLabel: _t('Reference copied', 'Kumbukumbu imenakiliwa'),
                  context: context,
                  bold: true,
                ),
              ),
              SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 14, color: AppColors.warning),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _t(
                            'After paying, our team will confirm within 24 hours.',
                            'Baada ya kulipa, timu yetu itathibitisha ndani ya masaa 24.'),
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppColors.warning,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: busy ? null : onDone,
                  icon: busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: Text(busy
                      ? _t('Sending…', 'Inatuma…')
                      : _t('I Have Paid', 'Nimemaliza Kulipa')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CopyRow extends StatelessWidget {
  final String label;
  final String? sublabel;
  final String copyValue;
  final String snackLabel;
  final BuildContext context;
  final bool bold;

  const _CopyRow({
    required this.label,
    this.sublabel,
    required this.copyValue,
    required this.snackLabel,
    required this.context,
    this.bold = false,
  });

  @override
  Widget build(BuildContext _) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (sublabel != null)
                Text(
                  sublabel!,
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                  color: AppColors.navyPrimary,
                  letterSpacing: bold ? 0.5 : 0,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: copyValue));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(snackLabel),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ));
          },
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.tealAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.copy_rounded,
                size: 14, color: AppColors.tealAccent),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment step row
// ─────────────────────────────────────────────────────────────────────────────

class _Step extends StatelessWidget {
  final String number;
  final String? text;
  final Widget? child;

  const _Step({required this.number, this.text, this.child})
      : assert(text != null || child != null);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: AppColors.navyPrimary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: text != null
                ? Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      text!,
                      style: GoogleFonts.dmSans(fontSize: 13),
                    ),
                  )
                : child!,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

String _fmtPrice(int v) =>
    'TZS ${v.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';
