import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/plan_service.dart';
import '../../core/theme/app_colors.dart';
import 'app_sheet.dart';
import 'mali_components.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Feature keys — lets the sheet show context-aware locked-feature header.
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
}

extension PlanFeatureKeyX on PlanFeatureKey {
  IconData get icon => switch (this) {
        PlanFeatureKey.teamMembers    => Icons.group_rounded,
        PlanFeatureKey.cashFlow       => Icons.waterfall_chart_rounded,
        PlanFeatureKey.expenseExports => Icons.download_rounded,
        PlanFeatureKey.expenseTracking => Icons.receipt_long_rounded,
        PlanFeatureKey.fullReports    => Icons.bar_chart_rounded,
        PlanFeatureKey.mpesaImport    => Icons.phone_android_rounded,
        PlanFeatureKey.smsReminders   => Icons.sms_rounded,
        PlanFeatureKey.allExports     => Icons.ios_share_rounded,
      };

  String get labelSw => switch (this) {
        PlanFeatureKey.teamMembers    => 'Wanachama wa Timu',
        PlanFeatureKey.cashFlow       => 'Mtiririko wa Fedha',
        PlanFeatureKey.expenseExports => 'Uhamishaji wa Matumizi',
        PlanFeatureKey.expenseTracking => 'Kufuatilia Matumizi',
        PlanFeatureKey.fullReports    => 'Ripoti Kamili',
        PlanFeatureKey.mpesaImport    => 'Kuingiza Data ya M-Pesa',
        PlanFeatureKey.smsReminders   => 'SMS za Ukumbusho',
        PlanFeatureKey.allExports     => 'Uhamishaji wa Data',
      };

  String get labelEn => switch (this) {
        PlanFeatureKey.teamMembers    => 'Team Members',
        PlanFeatureKey.cashFlow       => 'Cash Flow',
        PlanFeatureKey.expenseExports => 'Expense Exports',
        PlanFeatureKey.expenseTracking => 'Expense Tracking',
        PlanFeatureKey.fullReports    => 'Full Reports',
        PlanFeatureKey.mpesaImport    => 'M-Pesa Import',
        PlanFeatureKey.smsReminders   => 'SMS Reminders',
        PlanFeatureKey.allExports     => 'Data Exports',
      };

  Color get accentColor => switch (this) {
        PlanFeatureKey.teamMembers    => AppColors.tealAccent,
        PlanFeatureKey.cashFlow       => const Color(0xFF1A6E8A),
        PlanFeatureKey.expenseExports => const Color(0xFF7C3AED),
        PlanFeatureKey.expenseTracking => const Color(0xFF7C3AED),
        PlanFeatureKey.fullReports    => AppColors.tealAccent,
        PlanFeatureKey.mpesaImport    => const Color(0xFF16A34A),
        PlanFeatureKey.smsReminders   => AppColors.warning,
        PlanFeatureKey.allExports     => const Color(0xFF7C3AED),
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
    final defsAsync = ref.watch(planDefinitionsProvider);
    return defsAsync.when(
      loading: () => const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => _UpgradeSheet(
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

class _UpgradeSheetState extends State<_UpgradeSheet>
    with SingleTickerProviderStateMixin {
  PlanTier _selected = PlanTier.growth;
  bool _showPayment = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  static const _mpesaNumber = '+255 XXX XXX XXX';

  PlanLimits get _selLimits => limitsFor(_selected, widget.defs);
  int get _priceMonthly => _selLimits.pricePerMonth;
  int get _priceCycle   => _selLimits.pricePerCycle;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20, 12, 20, 24 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHandle(),
              const SizedBox(height: 16),

              // ── Locked-feature hero ───────────────────────────────────────
              _LockedFeatureHero(
                featureKey: widget.featureKey,
                triggerReason: widget.triggerReason,
              ),
              const SizedBox(height: 20),

              // ── Headline ─────────────────────────────────────────────────
              Text(
                'Inua Biashara Yako',
                style: GoogleFonts.dmSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navyPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Lipa chini ya saa moja ya mhasibu — ufike zaidi kila siku.',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // ── Plan cards ───────────────────────────────────────────────
              _TierCard(
                tier: PlanTier.growth,
                limits: limitsFor(PlanTier.growth, widget.defs),
                isSelected: _selected == PlanTier.growth,
                onTap: () => setState(() {
                  _selected = PlanTier.growth;
                  _showPayment = false;
                }),
              ),
              const SizedBox(height: 10),
              _TierCard(
                tier: PlanTier.business,
                limits: limitsFor(PlanTier.business, widget.defs),
                isSelected: _selected == PlanTier.business,
                onTap: () => setState(() {
                  _selected = PlanTier.business;
                  _showPayment = false;
                }),
              ),
              const SizedBox(height: 10),
              const _EnterpriseCard(),
              const SizedBox(height: 24),

              // ── CTA / Payment ─────────────────────────────────────────
              if (!_showPayment) ...[
                ScaleTransition(
                  scale: _pulseAnim,
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => setState(() => _showPayment = true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.yellowBrand,
                        foregroundColor: AppColors.navyPrimary,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.rocket_launch_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Panda ${_selected == PlanTier.growth ? "Growth" : "Business"}'
                            ' — ${_fmtPrice(_priceMonthly)}/mwezi',
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '${_fmtPrice(_priceCycle)} ulipwa kwa miezi ${_selLimits.cycleMonths} mbele',
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
                  onDone: () => Navigator.pop(context, _selected),
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
// Locked-feature hero banner
// ─────────────────────────────────────────────────────────────────────────────

class _LockedFeatureHero extends StatelessWidget {
  final PlanFeatureKey? featureKey;
  final String? triggerReason;

  const _LockedFeatureHero({this.featureKey, this.triggerReason});

  @override
  Widget build(BuildContext context) {
    if (featureKey == null && triggerReason == null) return const SizedBox.shrink();

    final accent = featureKey?.accentColor ?? AppColors.navyPrimary;
    final icon   = featureKey?.icon ?? Icons.lock_rounded;
    final label  = featureKey?.labelSw;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.navyPrimary,
            accent.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyPrimary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Lock badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppColors.yellowBrand,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      size: 9,
                      color: AppColors.navyPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label != null)
                  Text(
                    label,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                const SizedBox(height: 3),
                Text(
                  triggerReason ??
                      'Kipengele hiki kinahitaji mpango wa juu.',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
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
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navyPrimary : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.navyPrimary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.navyPrimary.withValues(alpha: 0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Radio indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.yellowBrand : Colors.transparent,
                border: Border.all(
                  color:
                      isSelected ? AppColors.yellowBrand : AppColors.border,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: AppColors.navyPrimary,
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isGrowth ? 'Growth' : 'Business',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color:
                              isSelected ? Colors.white : AppColors.navyPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isGrowth)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.yellowBrand.withValues(alpha: 0.25)
                                : AppColors.yellowBrand.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Maarufu',
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? AppColors.yellowBrand
                                  : AppColors.navyPrimary,
                            ),
                          ),
                        ),
                      const Spacer(),
                      // Price on the right
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _fmtPrice(limits.pricePerMonth),
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? AppColors.yellowBrand
                                  : AppColors.navyPrimary,
                            ),
                          ),
                          Text(
                            '/mwezi',
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.6)
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_fmtPrice(limits.pricePerCycle)} kwa miezi ${limits.cycleMonths}',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.5)
                          : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    children: [
                      _Feature(
                        text: 'Ankara zisizo na kikomo',
                        ok: true,
                        sel: isSelected,
                      ),
                      _Feature(
                        text: limits.maxUsers == -1
                            ? 'Watumiaji wasio na kikomo'
                            : 'Hadi watumiaji ${limits.maxUsers}',
                        ok: true,
                        sel: isSelected,
                      ),
                      _Feature(
                        text: 'Ripoti kamili',
                        ok: limits.fullReports,
                        sel: isSelected,
                      ),
                      _Feature(
                        text: 'Kuingiza data ya M-Pesa',
                        ok: limits.mpesaImport,
                        sel: isSelected,
                      ),
                      _Feature(
                        text: 'Ujumbe wa SMS',
                        ok: limits.smsReminders,
                        sel: isSelected,
                      ),
                      if (!isGrowth) ...[
                        _Feature(
                          text: 'Stoo nyingi',
                          ok: limits.multiLocation,
                          sel: isSelected,
                        ),
                        _Feature(
                          text: 'Ufikiaji wa API',
                          ok: limits.apiAccess,
                          sel: isSelected,
                        ),
                        _Feature(
                          text: 'Msaada wa kipaumbele',
                          ok: limits.prioritySupport,
                          sel: isSelected,
                        ),
                      ],
                    ],
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
// Feature row inside tier card
// ─────────────────────────────────────────────────────────────────────────────

class _Feature extends StatelessWidget {
  final String text;
  final bool ok;
  final bool sel;

  const _Feature({required this.text, required this.ok, required this.sel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.remove_circle_outline_rounded,
            size: 13,
            color: ok
                ? (sel ? AppColors.yellowBrand : AppColors.success)
                : (sel
                    ? Colors.white.withValues(alpha: 0.25)
                    : AppColors.textDisabled),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: ok
                    ? (sel ? Colors.white : AppColors.textPrimary)
                    : (sel
                        ? Colors.white.withValues(alpha: 0.35)
                        : AppColors.textDisabled),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Enterprise card
// ─────────────────────────────────────────────────────────────────────────────

class _EnterpriseCard extends StatelessWidget {
  const _EnterpriseCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wasiliana nasi kwa ajili ya bei ya Enterprise'),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.yellowBrand.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.business_center_rounded,
                color: AppColors.yellowBrand,
                size: 18,
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
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navyPrimary,
                    ),
                  ),
                  Text(
                    'Minyororo, NGO, wasambazaji — bei maalum',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 18,
            ),
          ],
        ),
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
  final VoidCallback onDone;
  final VoidCallback onBack;

  const _PaymentInstructions({
    required this.tier,
    required this.priceMonthly,
    required this.priceCycle,
    required this.cycleMonths,
    required this.mpesaNumber,
    required this.onDone,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final tierName = tier == PlanTier.growth ? 'Growth' : 'Business';
    final ref =
        'MALIUP-${tierName.toUpperCase()}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back row
        GestureDetector(
          onTap: onBack,
          child: Row(
            children: [
              const Icon(Icons.arrow_back_rounded,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Rudi',
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.navyPrimary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.navyPrimary.withValues(alpha: 0.1),
            ),
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
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.phone_android_rounded,
                        color: AppColors.tealAccent, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Hatua za Malipo ya M-Pesa',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navyPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const _Step(number: '1', text: 'Fungua M-Pesa kwenye simu yako'),
              const _Step(
                number: '2',
                text: 'Chagua "Lipa Biashara" (Lipa Number)',
              ),
              _Step(
                number: '3',
                child: _CopyRow(
                  label: 'Namba: $mpesaNumber',
                  copyValue: mpesaNumber,
                  snackLabel: 'Namba imenakiliwa',
                  context: context,
                ),
              ),
              _Step(
                number: '4',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kiasi: ${_fmtPrice(priceCycle)} (miezi $cycleMonths)',
                      style: GoogleFonts.dmSans(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '(${_fmtPrice(priceMonthly)}/mwezi × $cycleMonths)',
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
                  sublabel: 'Maelezo / Kumbukumbu:',
                  copyValue: ref,
                  snackLabel: 'Kumbukumbu imenakiliwa',
                  context: context,
                  bold: true,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 14, color: AppColors.warning),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Baada ya kulipa, timu yetu itathibitisha ndani ya masaa 24.',
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
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: onDone,
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: const Text('Nimemaliza Kulipa'),
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
                  fontWeight:
                      bold ? FontWeight.w700 : FontWeight.w600,
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
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: AppColors.navyPrimary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: text != null
                ? Padding(
                    padding: const EdgeInsets.only(top: 3),
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
