import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/providers/business_id_provider.dart';
import '../../core/services/plan_request_service.dart';
import '../../core/services/plan_service.dart';
import '../../core/services/clickpesa_service.dart';
import '../../core/services/localization_service.dart';
import '../../core/utils/online_guard.dart';
import '../../core/theme/app_colors.dart';
import 'app_sheet.dart';
import 'mali_components.dart';
import 'payment_pos_animation.dart';
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
  productLimit,
  serviceProductLimit,
}

extension PlanFeatureKeyX on PlanFeatureKey {
  IconData get icon => switch (this) {
    PlanFeatureKey.teamMembers => Icons.group_rounded,
    PlanFeatureKey.cashFlow => Icons.waterfall_chart_rounded,
    PlanFeatureKey.expenseExports => Icons.download_rounded,
    PlanFeatureKey.expenseTracking => Icons.receipt_long_rounded,
    PlanFeatureKey.fullReports => Icons.bar_chart_rounded,
    PlanFeatureKey.mpesaImport => Icons.phone_android_rounded,
    PlanFeatureKey.smsReminders => Icons.sms_rounded,
    PlanFeatureKey.allExports => Icons.ios_share_rounded,
    PlanFeatureKey.manualDebt => Icons.edit_note_rounded,
    PlanFeatureKey.multiBusiness => Icons.store_mall_directory_rounded,
    PlanFeatureKey.customerLimit => Icons.people_alt_rounded,
    PlanFeatureKey.productLimit => Icons.inventory_2_rounded,
    PlanFeatureKey.serviceProductLimit => Icons.design_services_rounded,
  };

  String get labelSw => switch (this) {
    PlanFeatureKey.teamMembers => 'Wanachama wa Timu',
    PlanFeatureKey.cashFlow => 'Mtiririko wa Fedha',
    PlanFeatureKey.expenseExports => 'Uhamishaji wa Matumizi',
    PlanFeatureKey.expenseTracking => 'Kufuatilia Matumizi',
    PlanFeatureKey.fullReports => 'Ripoti Kamili',
    PlanFeatureKey.mpesaImport => 'Kuingiza Data ya M-Pesa',
    PlanFeatureKey.smsReminders => 'SMS za Ukumbusho',
    PlanFeatureKey.allExports => 'Uhamishaji wa Data',
    PlanFeatureKey.manualDebt => 'Kuongeza Deni/Dai Mkononi',
    PlanFeatureKey.multiBusiness => 'Biashara Nyingi',
    PlanFeatureKey.customerLimit => 'Kikomo cha Wateja',
    PlanFeatureKey.productLimit => 'Kikomo cha Bidhaa',
    PlanFeatureKey.serviceProductLimit => 'Kikomo cha Huduma',
  };

  String get labelEn => switch (this) {
    PlanFeatureKey.teamMembers => 'Team Members',
    PlanFeatureKey.cashFlow => 'Cash Flow',
    PlanFeatureKey.expenseExports => 'Expense Exports',
    PlanFeatureKey.expenseTracking => 'Expense Tracking',
    PlanFeatureKey.fullReports => 'Full Reports',
    PlanFeatureKey.mpesaImport => 'M-Pesa Import',
    PlanFeatureKey.smsReminders => 'SMS Reminders',
    PlanFeatureKey.allExports => 'Data Exports',
    PlanFeatureKey.manualDebt => 'Manual Debt Entry',
    PlanFeatureKey.multiBusiness => 'Multiple Businesses',
    PlanFeatureKey.customerLimit => 'Customer Limit',
    PlanFeatureKey.productLimit => 'Product Limit',
    PlanFeatureKey.serviceProductLimit => 'Service Limit',
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Public API
// ─────────────────────────────────────────────────────────────────────────────

/// Shows the upgrade / paywall bottom sheet.
/// Returns the selected [PlanTier] if the user proceeds to payment, or null.
///
/// This is two separate bottom sheets chained together, not one: the plan
/// picker + phone-number form pops with a [_PaymentHandoff] once the user
/// submits a number, and only then does a second, independent sheet
/// ([_ClickPesaPaymentSheet]) open to run the actual ClickPesa request and
/// show its POS animation. Keeping them separate means the payment sheet's
/// AnimationController/Lottie composition is created fresh for that one
/// request instead of living inside (and being torn down by) the plan
/// sheet's own rebuilds.
Future<PlanTier?> showUpgradeSheet(
  BuildContext context, {
  PlanStatus? currentStatus,
  String? triggerReason,
  PlanFeatureKey? featureKey,
}) async {
  final result = await showAppSheet<Object>(
    context,
    builder: (_) => _UpgradeSheetWrapper(
      currentStatus: currentStatus,
      triggerReason: triggerReason,
      featureKey: featureKey,
    ),
  );
  if (result is! _PaymentHandoff) {
    return result as PlanTier?;
  }
  if (!context.mounted) return null;
  return showAppSheet<PlanTier>(
    context,
    builder: (_) => _ClickPesaPaymentSheet(
      tier: result.tier,
      phoneNumber: result.phoneNumber,
    ),
  );
}

/// Carries the plan + phone number chosen in the first sheet across to the
/// second, payment-processing sheet. See [showUpgradeSheet].
class _PaymentHandoff {
  final PlanTier tier;
  final String phoneNumber;

  const _PaymentHandoff({required this.tier, required this.phoneNumber});
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
            SkeletonCard(
              height: 56,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            SizedBox(height: 8),
            SkeletonCard(
              height: 56,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
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
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
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
              border: Border.all(
                color: AppColors.tealAccent.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.hourglass_top_rounded,
                  color: AppColors.tealAccent,
                  size: 36,
                ),
                const SizedBox(height: 10),
                Text(
                  _t(
                    'Your $tierLabel request is still being processed',
                    'Ombi lako la $tierLabel bado linashughulikiwa',
                  ),
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
                    'Timu yetu inathibitisha ombi lako. Huwezi kutuma ombi jingine mpaka hili likamilike.',
                  ),
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _t('Got It', 'Nimeelewa'),
                      style: GoogleFonts.dmSans(
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
  late PlanTier _selected;
  bool _showEnterprise = false;
  bool _showPhoneConfirm = false;
  String? _prefillPhone;

  bool get _isMultiBusiness =>
      widget.featureKey == PlanFeatureKey.multiBusiness;

  /// Whether [_selected] is the tier the user is already on — happens when
  /// they're already on Business (there's no higher standard tier to
  /// preselect) or when they tap their own current tier's card. The CTA
  /// swaps to an Enterprise nudge instead of a "pay again" button in this
  /// case; see [_selectedIsCurrentTier] usage in build().
  bool get _selectedIsCurrentTier => widget.currentStatus?.tier == _selected;

  @override
  void initState() {
    super.initState();
    final currentTier = widget.currentStatus?.tier;
    if (_isMultiBusiness) {
      _selected = PlanTier.business;
    } else if (currentTier == PlanTier.growth) {
      // Already on Growth — the natural next step is Business, not Growth
      // again (defaulting back to Growth here was the sheet's main "stuck"
      // bug: an existing subscriber would see "Upgrade to Growth" for the
      // plan they already had).
      _selected = PlanTier.business;
    } else {
      _selected = PlanTier.growth;
    }
    _loadProfilePhone();
  }

  Future<void> _loadProfilePhone() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final phone = (doc.data()?['phone'] as String?)?.trim();
      if (phone != null && phone.isNotEmpty && mounted) {
        setState(() => _prefillPhone = phone);
      }
    } catch (_) {
      // Best-effort prefill only — the user can always type their number.
    }
  }

  PlanLimits get _selLimits => limitsFor(_selected, widget.defs);
  int get _priceMonthly => _selLimits.pricePerMonth;
  int get _priceCycle => _selLimits.pricePerCycle;

  /// The phone form only collects a number here — actually sending the USSD
  /// push and watching for confirmation happens in a separate sheet (see
  /// [_ClickPesaPaymentSheet]) so that sheet's Lottie animation isn't torn
  /// down and rebuilt every time this plan-selection sheet's own state
  /// changes. Popping with a [_PaymentHandoff] tells [showUpgradeSheet] to
  /// open that second sheet next.
  Future<void> _sendPaymentRequest(String phoneNumber) async {
    if (!await OnlineGuard.ensureOnline(context)) return;
    if (!mounted) return;
    Navigator.pop(
      context,
      _PaymentHandoff(tier: _selected, phoneNumber: phoneNumber),
    );
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
            20,
            12,
            20,
            20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHandle(),
              const SizedBox(height: 14),

              // ── Headline ─────────────────────────────────────────────────
              // When opened because a specific feature is locked, the
              // headline itself becomes that feature's name (instead of the
              // generic "Grow Your Business") with a PREMIUM tag beside it —
              // replaces the old separate locked-feature notice box.
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.featureKey != null
                          ? (LocalizationService.isSwahili
                                ? widget.featureKey!.labelSw
                                : widget.featureKey!.labelEn)
                          : _t('Grow Your Business', 'Inua Biashara Yako'),
                      style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navyPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  if (widget.featureKey != null) ...[
                    const SizedBox(width: 10),
                    const _PremiumTag(),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Text(
                widget.triggerReason ??
                    _t(
                      'Costs less than an hour of accountant fees — reach '
                          'further every day.',
                      'Lipa chini ya saa moja ya mhasibu — ufike zaidi kila siku.',
                    ),
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              // ── Plan cards ───────────────────────────────────────────────
              if (!_isMultiBusiness) ...[
                _TierCard(
                  tier: PlanTier.growth,
                  limits: limitsFor(PlanTier.growth, widget.defs),
                  isSelected: !_showEnterprise && _selected == PlanTier.growth,
                  isCurrent: widget.currentStatus?.tier == PlanTier.growth,
                  onTap: () => setState(() {
                    _selected = PlanTier.growth;
                    _showEnterprise = false;
                    _showPhoneConfirm = false;
                  }),
                ),
                const SizedBox(height: 6),
              ],
              _TierCard(
                tier: PlanTier.business,
                limits: limitsFor(PlanTier.business, widget.defs),
                isSelected: !_showEnterprise && _selected == PlanTier.business,
                isCurrent: widget.currentStatus?.tier == PlanTier.business,
                onTap: () => setState(() {
                  _selected = PlanTier.business;
                  _showEnterprise = false;
                  _showPhoneConfirm = false;
                }),
              ),
              const SizedBox(height: 6),
              _EnterpriseCard(
                isSelected: _showEnterprise,
                onTap: () => setState(() {
                  _showEnterprise = true;
                }),
              ),
              const SizedBox(height: 16),

              // ── CTA / Payment / Enterprise request ───────────────────────
              if (_showEnterprise) ...[
                _EnterpriseRequestForm(
                  onDone: () => Navigator.pop(context, PlanTier.enterprise),
                ),
              ] else if (_showPhoneConfirm) ...[
                _PhonePaymentForm(
                  initialPhone: _prefillPhone,
                  onBack: () => setState(() => _showPhoneConfirm = false),
                  onSubmit: _sendPaymentRequest,
                ),
              ] else if (_selectedIsCurrentTier) ...[
                _AlreadyOnThisPlanNotice(
                  tier: _selected,
                  onSeeEnterprise: () => setState(() => _showEnterprise = true),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 52),
                    child: ElevatedButton(
                      onPressed: () => setState(() => _showPhoneConfirm = true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.yellowBrand,
                        foregroundColor: AppColors.navyPrimary,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.rocket_launch_rounded, size: 16),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '${_t("Upgrade to", "Panda")} '
                              '${_selected == PlanTier.growth ? "Growth" : "Business"}'
                              ' — ${_fmtPrice(_priceMonthly)}${_t("/mo", "/mwezi")}',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    '${_fmtPrice(_priceCycle)} ${_t("billed every ${_selLimits.cycleMonths} months upfront", "ulipwa kwa miezi ${_selLimits.cycleMonths} mbele")}',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
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
// Premium tag — small navy pill shown beside the headline when the sheet was
// opened because a specific feature is locked (see [_UpgradeSheet.build]).
// ─────────────────────────────────────────────────────────────────────────────

class _PremiumTag extends StatelessWidget {
  const _PremiumTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.navyPrimary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_rounded, size: 9, color: Colors.white),
          const SizedBox(width: 3),
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
  final bool isCurrent;
  final VoidCallback onTap;

  const _TierCard({
    required this.tier,
    required this.limits,
    required this.isSelected,
    this.isCurrent = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isGrowth = tier == PlanTier.growth;
    // "Current Plan" always wins over the generic "Popular" badge — knowing
    // which plan you're already on matters more here than a marketing tag.
    final showBadge = isCurrent || isGrowth;
    final badgeLabel = isCurrent
        ? _t('Current Plan', 'Mpango wa Sasa')
        : _t('Popular', 'Maarufu');

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
                  ? const Icon(
                      Icons.check_rounded,
                      size: 10,
                      color: AppColors.navyPrimary,
                    )
                  : null,
            ),
            const SizedBox(width: 10),

            // Name + badge on their own line, cycle price on the line below —
            // stacked instead of crammed into one row so neither ever needs
            // to ellipsize, without widening the card itself.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          isGrowth ? 'Growth' : 'Business',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : AppColors.navyPrimary,
                          ),
                        ),
                      ),
                      if (showBadge) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.yellowBrand.withValues(
                              alpha: isSelected ? 0.2 : 0.12,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badgeLabel,
                            style: GoogleFonts.dmSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? AppColors.yellowBrand
                                  : AppColors.navyPrimary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
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

            const SizedBox(width: 6),
            // Price
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _fmtPrice(limits.pricePerMonth),
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? AppColors.yellowBrand
                          : AppColors.navyPrimary,
                    ),
                  ),
                  Text(
                    _t('/mo', '/mwezi'),
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.45)
                          : AppColors.textMuted,
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
            const SizedBox(width: 12),
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
                    _t(
                      'Chains, NGOs, distributors — custom pricing',
                      'Minyororo, NGO, wasambazaji — bei maalum',
                    ),
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
    final pending = await PlanRequestService.hasPending(
      PlanRequestType.enterpriseInquiry,
    );
    if (!mounted) return;
    setState(
      () => _state = pending
          ? _EnterpriseFormState.alreadyPending
          : _EnterpriseFormState.form,
    );
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
          'Imeshindwa kutuma ombi. Hakikisha una intaneti kisha jaribu tena.',
        );
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
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.mark_email_read_rounded,
                color: AppColors.success,
                size: 36,
              ),
              const SizedBox(height: 10),
              Text(
                alreadyPending
                    ? _t(
                        'You already submitted an Enterprise request',
                        'Tayari umetuma ombi la Enterprise',
                      )
                    : _t('Request sent!', 'Ombi limetumwa!'),
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navyPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _t(
                  'Our team will contact you within 24 hours about custom '
                      'pricing for your business.',
                  'Timu yetu itawasiliana nawe ndani ya masaa 24 kuhusu bei maalum ya biashara yako.',
                ),
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
                  onPressed: widget.onDone,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _t('OK', 'Sawa'),
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
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
              _t(
                'Tell us about your business (optional)',
                'Tuambie kuhusu biashara yako (hiari)',
              ),
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 3,
              maxLength: 500,
              enabled: !busy,
              style: GoogleFonts.dmSans(fontSize: 13),
              decoration: InputDecoration(
                hintText: _t(
                  'E.g. 5 branches, 30 staff, need API and custom reports…',
                  'Mf. matawi 5, wafanyakazi 30, tunahitaji API na ripoti maalum…',
                ),
                hintStyle: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
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
              const SizedBox(height: 8),
              Text(
                _error!,
                style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.error),
              ),
            ],
            const SizedBox(height: 12),
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
                          strokeWidth: 2,
                          color: AppColors.navyPrimary,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 16),
                label: Text(
                  busy
                      ? _t('Sending…', 'Inatuma…')
                      : _t(
                          'Send Enterprise Request',
                          'Tuma Ombi la Enterprise',
                        ),
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.yellowBrand,
                  foregroundColor: AppColors.navyPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                _t(
                  'Your request will reach our team immediately.',
                  'Ombi lako litaonekana na timu yetu mara moja.',
                ),
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Already-on-this-plan notice — shown instead of a "pay again" button when
// the selected tier is the user's current plan (only reachable when they're
// already on Business, the top standard tier).
// ─────────────────────────────────────────────────────────────────────────────

class _AlreadyOnThisPlanNotice extends StatelessWidget {
  final PlanTier tier;
  final VoidCallback onSeeEnterprise;

  const _AlreadyOnThisPlanNotice({required this.tier, required this.onSeeEnterprise});

  @override
  Widget build(BuildContext context) {
    final tierName = tier == PlanTier.growth ? 'Growth' : 'Business';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_rounded,
            color: AppColors.tealAccent,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _t(
                "You're already on $tierName — our top standard plan. "
                    'Need more? See Enterprise above.',
                'Tayari upo kwenye $tierName — mpango wetu wa juu zaidi wa kawaida. '
                    'Unahitaji zaidi? Angalia Enterprise juu.',
              ),
              style: GoogleFonts.dmSans(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSeeEnterprise,
            child: const Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.navyPrimary,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Phone confirmation — the number ClickPesa pushes the mobile-money PIN
// prompt to. Prefilled from the user's profile when available and editable,
// since the mobile money line isn't always the same as the account phone.
// ─────────────────────────────────────────────────────────────────────────────

class _PhonePaymentForm extends StatefulWidget {
  final String? initialPhone;
  final VoidCallback onBack;
  final ValueChanged<String> onSubmit;

  const _PhonePaymentForm({
    this.initialPhone,
    required this.onBack,
    required this.onSubmit,
  });

  @override
  State<_PhonePaymentForm> createState() => _PhonePaymentFormState();
}

class _PhonePaymentFormState extends State<_PhonePaymentForm> {
  late final TextEditingController _phoneController =
      TextEditingController(text: widget.initialPhone ?? '');
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  bool _looksLikePhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 9 && digits.length <= 12;
  }

  void _submit() {
    final phone = _phoneController.text.trim();
    if (!_looksLikePhone(phone)) {
      setState(() => _error = _t(
            'Enter a valid mobile money number, e.g. 0712 345 678',
            'Weka namba sahihi ya pesa ya simu, mf. 0712 345 678',
          ));
      return;
    }
    setState(() => _error = null);
    widget.onSubmit(phone);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: widget.onBack,
          child: Row(
            children: [
              const Icon(
                Icons.arrow_back_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
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
        const SizedBox(height: 12),
        Text(
          _t(
            'Which number should receive the payment request?',
            'Ni namba gani ipokee ombi la malipo?',
          ),
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _t(
            "We'll send a payment prompt to this number — enter your M-Pesa, "
                'Tigo Pesa, Airtel Money, or HaloPesa PIN there to confirm.',
            'Tutatuma ombi la malipo kwenye namba hii — weka PIN yako ya M-Pesa, '
                'Tigo Pesa, Airtel Money, au HaloPesa hapo kuthibitisha.',
          ),
          style: GoogleFonts.dmSans(
            fontSize: 11.5,
            color: AppColors.textMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          autofocus: widget.initialPhone == null,
          style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: '0712 345 678',
            hintStyle: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textMuted),
            prefixIcon: const Icon(Icons.phone_android_rounded, size: 18),
            filled: true,
            fillColor: AppColors.surface,
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
          const SizedBox(height: 6),
          Text(
            _error!,
            style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.error),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.send_to_mobile_rounded, size: 16),
            label: Text(
              _t('Send Payment Request', 'Tuma Ombi la Malipo'),
              style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.yellowBrand,
              foregroundColor: AppColors.navyPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ClickPesa payment sheet — its own bottom sheet (see showUpgradeSheet), so
// its AnimationController/Lottie composition has a clean lifecycle: created
// when this sheet opens, torn down when it closes, never shared with the
// plan-picker sheet underneath it.
// ─────────────────────────────────────────────────────────────────────────────

class _ClickPesaPaymentSheet extends ConsumerStatefulWidget {
  final PlanTier tier;
  final String phoneNumber;

  const _ClickPesaPaymentSheet({required this.tier, required this.phoneNumber});

  @override
  ConsumerState<_ClickPesaPaymentSheet> createState() => _ClickPesaPaymentSheetState();
}

class _ClickPesaPaymentSheetState extends ConsumerState<_ClickPesaPaymentSheet>
    with SingleTickerProviderStateMixin {
  late final PaymentPosAnimationController _paymentAnim =
      PaymentPosAnimationController(vsync: this);

  bool _succeeded = false;
  bool _failed = false;
  String? _failureMessage;

  // Flipped in dispose() so an in-flight ClickPesaService.waitForPayment
  // poll loop notices (via isCancelled) and stops calling the server the
  // moment this sheet is closed, instead of continuing to fire requests in
  // the background for up to its full timeout.
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_runPayment());
  }

  @override
  void dispose() {
    _disposed = true;
    _paymentAnim.dispose();
    super.dispose();
  }

  Future<void> _runPayment() async {
    if (!mounted) return;
    setState(() {
      _failed = false;
      _failureMessage = null;
    });
    // Reset in case this is a retry after a previous failure (the
    // controller would otherwise still be sitting frozen mid wait-loop),
    // then play the card-into-POS intro and settle into the indefinitely
    // looping waiting animation — driven by this real request, not a timer.
    _paymentAnim.reset();
    unawaited(_paymentAnim.startPayment());

    try {
      final businessId = ref.read(currentBusinessIdProvider).valueOrNull ?? '';
      if (businessId.isEmpty) {
        throw StateError('No active business to upgrade.');
      }
      // Push a USSD payment prompt to the user's phone. The amount is
      // decided server-side (from the admin-configured price), not by the
      // client — see functions/src/clickpesa.ts. Activates the plan on
      // businessId specifically — plans are independent per business now.
      final initiated = await ClickPesaService.initiatePayment(
        tier: widget.tier,
        phoneNumber: widget.phoneNumber,
        businessId: businessId,
      );
      if (_disposed) return;

      // Poll the server while the user confirms the PIN prompt on their
      // phone. Plan activation happens server-side the moment this reports
      // "completed" — there is nothing left for the client to write. This
      // watches the payment doc in Firestore rather than polling ClickPesa
      // (see ClickPesaService.waitForPayment), capped at a 3-minute overall
      // timeout, and stops immediately — rather than continuing in the
      // background up to that cap — if this sheet is dismissed before then,
      // via isCancelled.
      await ClickPesaService.waitForPayment(
        orderReference: initiated.orderReference,
        isCancelled: () => _disposed,
      );
      if (_disposed || !mounted) return;

      debugPrint('[ClickPesaPaymentSheet] payment confirmed: ${initiated.orderReference}');
      setState(() => _succeeded = true);
      // Wait for the checkmark to actually be on screen, hold a beat so
      // it registers, then close on its own — there's nothing else on
      // this sheet to tap.
      await _paymentAnim.setSuccess();
      if (_disposed || !mounted) return;
      await Future.delayed(const Duration(milliseconds: 700));
      if (_disposed || !mounted) return;
      Navigator.pop(context, widget.tier);
    } on ClickPesaCancelledException {
      // The sheet was dismissed mid-poll — nothing to show, nothing to log.
    } catch (e) {
      if (_disposed) return;
      debugPrint('[ClickPesaPaymentSheet] payment error: $e');
      // Freezes wherever the wait loop currently is — the green checkmark
      // frames are never reached on failure.
      _paymentAnim.setFailed();
      if (!mounted) return;
      setState(() {
        _failed = true;
        _failureMessage = _friendlyClickPesaFailureMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Transparent, not the white Material card the plan-picker sheet below
    // uses — the failed state still needs a readable surface behind its
    // text/buttons, but the normal processing/success state is nothing but
    // the animation, so there's no card to paint a background on.
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            32 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetHandle(),
              if (_failed) ...[
                const SizedBox(height: 14),
                _PaymentFailedCard(
                  message: _failureMessage ??
                      _t('Something went wrong.', 'Hitilafu imetokea.'),
                  onRetry: () => unawaited(_runPayment()),
                  onCancel: () => Navigator.pop(context),
                ),
              ] else ...[
                const SizedBox(height: 8),
                _ClickPesaPaymentCard(
                  animController: _paymentAnim,
                  succeeded: _succeeded,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// ClickPesa/network exceptions are technical (`Exception: Payment failed`,
/// `FirebaseFunctionsException(...)`) — show something a shopkeeper can
/// actually act on instead of the raw error string.
String _friendlyClickPesaFailureMessage(Object e) {
  final raw = e.toString();
  if (raw.contains('Payment verification timeout')) {
    return _t(
      "We didn't get a confirmation in time. If you entered your PIN, "
          'check your balance before retrying — you may already have been '
          'charged.',
      'Hatujapokea uthibitisho kwa wakati. Kama uliweka PIN yako, kagua '
          'salio lako kabla ya kujaribu tena — huenda tayari umetozwa.',
    );
  }
  return _t(
    'The payment was declined or not completed on your phone. No charge '
        'was made — you can try again.',
    'Malipo yamekataliwa au hayakukamilika kwenye simu yako. Hukutozwa — '
        'unaweza kujaribu tena.',
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ClickPesa payment card — no box, no description copy, nothing to read.
// A single small status word up top and the POS Lottie animation doing all
// the actual communicating below it. Stays one mounted widget across the
// waiting -> success handoff (only [succeeded] flips) so PaymentPosAnimation
// and its AnimationController are never disposed/recreated mid-flow; see
// PaymentPosAnimationController for how the animation itself is driven off
// real ClickPesa status rather than a timer. There's no button here — the
// sheet closes itself a beat after the checkmark lands (_runPayment).
// ─────────────────────────────────────────────────────────────────────────────

class _ClickPesaPaymentCard extends StatelessWidget {
  final PaymentPosAnimationController animController;
  final bool succeeded;

  const _ClickPesaPaymentCard({
    required this.animController,
    required this.succeeded,
  });

  @override
  Widget build(BuildContext context) {
    // 80% of screen width, not a fixed pixel size, so the animation reads
    // as the dominant thing on the sheet on every phone size rather than
    // looking small on larger screens or cramped on small ones.
    final animSize = MediaQuery.sizeOf(context).width * 0.8;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            succeeded
                ? _t('Payment successful', 'Malipo Yamefanikiwa')
                : _t('Check Your Phone', 'Angalia Simu Yako'),
            key: ValueKey(succeeded),
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.1,
            ),
          ),
        ),
        PaymentPosAnimation(controller: animController, size: animSize),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment failed — shown when the USSD push was declined, timed out, or
// otherwise didn't complete. No charge was made in any of these cases (the
// server only activates a plan after ClickPesa confirms success), so the
// copy is reassuring rather than alarming, with a direct way to retry.
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentFailedCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  const _PaymentFailedCard({
    required this.message,
    required this.onRetry,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          const _BounceInIcon(
            icon: Icons.close_rounded,
            color: AppColors.error,
          ),
          const SizedBox(height: 10),
          Text(
            _t('Payment not completed', 'Malipo Hayakukamilika'),
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.navyPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _t('Cancel', 'Ghairi'),
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navyPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _t('Try Again', 'Jaribu Tena'),
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bounce-in icon — a filled circle + icon that pops in with an elastic
// overshoot. Used for the one-shot failure moment at the end of a payment
// attempt (the success moment now uses PaymentPosAnimation's checkmark
// instead, via _ClickPesaPaymentCard).
// ─────────────────────────────────────────────────────────────────────────────

class _BounceInIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _BounceInIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    // Curves.easeOutBack gives one restrained overshoot (~8%) and settles —
    // Curves.elasticOut (the previous curve) oscillates several times before
    // settling, which reads as playful/toy-like rather than premium.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.scale(scale: value, child: child),
      ),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.12),
        ),
        child: Icon(icon, color: color, size: 32),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

String _fmtPrice(int v) =>
    'TZS ${v.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';
