import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/plan_service.dart';
import '../../core/theme/app_colors.dart';
import 'app_sheet.dart';
import 'mali_components.dart';

/// Shows the upgrade/paywall bottom sheet comparing paid tiers.
/// Returns the selected [PlanTier] if the user taps a tier CTA, or null.
Future<PlanTier?> showUpgradeSheet(
  BuildContext context, {
  PlanStatus? currentStatus,
  String? triggerReason,
}) {
  return showAppSheet<PlanTier>(
    context,
    builder: (_) => _UpgradeSheetWrapper(
      currentStatus: currentStatus,
      triggerReason: triggerReason,
    ),
  );
}

// Wraps with Riverpod so the sheet can read planDefinitionsProvider.
class _UpgradeSheetWrapper extends ConsumerWidget {
  final PlanStatus? currentStatus;
  final String? triggerReason;

  const _UpgradeSheetWrapper({this.currentStatus, this.triggerReason});

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
      ),
      data: (defs) => _UpgradeSheet(
        currentStatus: currentStatus,
        triggerReason: triggerReason,
        defs: defs,
      ),
    );
  }
}

class _UpgradeSheet extends StatefulWidget {
  final PlanStatus? currentStatus;
  final String? triggerReason;
  final PlanDefinitions? defs;

  const _UpgradeSheet({this.currentStatus, this.triggerReason, this.defs});

  @override
  State<_UpgradeSheet> createState() => _UpgradeSheetState();
}

class _UpgradeSheetState extends State<_UpgradeSheet> {
  PlanTier _selected = PlanTier.growth;
  bool _showPaymentInstructions = false;

  static const _mpesaNumber = '+255 XXX XXX XXX'; // Replace with actual M-Pesa number

  PlanLimits get _selectedLimits => limitsFor(_selected, widget.defs);

  int get _selectedPriceSixMonths => _selectedLimits.pricePerCycle;
  int get _selectedPriceMonthly   => _selectedLimits.pricePerMonth;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              24, 12, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHandle(),
              const SizedBox(height: 12),

              // Trigger reason banner
              if (widget.triggerReason != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_rounded,
                          color: AppColors.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.triggerReason!,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Text(
                'Chagua Mpango Wako',
                style: GoogleFonts.dmSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navyPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Lipa chini ya saa moja ya mhasibu — ufike zaidi.',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Tier cards
              _TierCard(
                tier: PlanTier.growth,
                limits: limitsFor(PlanTier.growth, widget.defs),
                isSelected: _selected == PlanTier.growth,
                onTap: () => setState(() {
                  _selected = PlanTier.growth;
                  _showPaymentInstructions = false;
                }),
              ),
              const SizedBox(height: 12),
              _TierCard(
                tier: PlanTier.business,
                limits: limitsFor(PlanTier.business, widget.defs),
                isSelected: _selected == PlanTier.business,
                onTap: () => setState(() {
                  _selected = PlanTier.business;
                  _showPaymentInstructions = false;
                }),
              ),
              const SizedBox(height: 12),

              // Enterprise
              const _EnterpriseCard(),

              const SizedBox(height: 24),

              // Payment instructions toggle
              if (!_showPaymentInstructions) ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () =>
                        setState(() => _showPaymentInstructions = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.yellowBrand,
                      foregroundColor: AppColors.navyPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      'Panda ${_selected == PlanTier.growth ? "Growth" : "Business"}'
                      ' — ${_fmtPrice(_selectedPriceMonthly)}/mwezi',
                      style: GoogleFonts.dmSans(
                          fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '${_fmtPrice(_selectedPriceSixMonths)} ulipwa kwa miezi ${_selectedLimits.cycleMonths} mbele',
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: AppColors.textMuted),
                  ),
                ),
              ] else ...[
                _PaymentInstructions(
                  tier: _selected,
                  priceMonthly: _selectedPriceMonthly,
                  priceCycle: _selectedPriceSixMonths,
                  cycleMonths: _selectedLimits.cycleMonths,
                  mpesaNumber: _mpesaNumber,
                  onDone: () => Navigator.pop(context, _selected),
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
        padding: const EdgeInsets.all(18),
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
                    color: AppColors.navyPrimary.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Radio
            Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.yellowBrand : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.yellowBrand : AppColors.border,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: AppColors.navyPrimary)
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
                          color: isSelected
                              ? Colors.white
                              : AppColors.navyPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isGrowth)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.tealAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Maarufu',
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.tealAccent,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_fmtPrice(limits.pricePerMonth)} / mwezi',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppColors.textSecondary,
                    ),
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
                  _Feature(
                      text: 'Ankara zisizo na kikomo', ok: true, sel: isSelected),
                  _Feature(
                      text: '${limits.maxUsers == -1 ? "Wasio na kikomo" : limits.maxUsers} watumiaji',
                      ok: true,
                      sel: isSelected),
                  _Feature(text: 'Ripoti kamili', ok: limits.fullReports, sel: isSelected),
                  _Feature(
                      text: 'Kuingiza data ya M-Pesa',
                      ok: limits.mpesaImport,
                      sel: isSelected),
                  _Feature(
                      text: 'Ujumbe wa SMS',
                      ok: limits.smsReminders,
                      sel: isSelected),
                  if (!isGrowth) ...[
                    _Feature(
                        text: 'Stoo nyingi',
                        ok: limits.multiLocation,
                        sel: isSelected),
                    _Feature(
                        text: 'Ufikiaji wa API',
                        ok: limits.apiAccess,
                        sel: isSelected),
                    _Feature(
                        text: 'Msaada wa kipaumbele',
                        ok: limits.prioritySupport,
                        sel: isSelected),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 14,
            color: ok
                ? (sel ? AppColors.yellowBrand : AppColors.success)
                : (sel
                    ? Colors.white.withValues(alpha: 0.25)
                    : AppColors.textDisabled),
          ),
          const SizedBox(width: 6),
          Text(
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
        ],
      ),
    );
  }
}

class _EnterpriseCard extends StatelessWidget {
  const _EnterpriseCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _contactEnterprise(context),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.yellowBrand.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.business_center_rounded,
                  color: AppColors.yellowBrand, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enterprise',
                    style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navyPrimary),
                  ),
                  Text(
                    'Minyororo, NGO, wasambazaji — bei maalum',
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  void _contactEnterprise(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Wasiliana nasi kwa ajili ya bei ya Enterprise'),
        behavior: SnackBarBehavior.floating,
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

  const _PaymentInstructions({
    required this.tier,
    required this.priceMonthly,
    required this.priceCycle,
    required this.cycleMonths,
    required this.mpesaNumber,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final tierName = tier == PlanTier.growth ? 'Growth' : 'Business';
    final ref =
        'MALIUP-${tierName.toUpperCase()}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.navyPrimary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.navyPrimary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.phone_android_rounded,
                  color: AppColors.tealAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Hatua za Malipo ya M-Pesa',
                style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _Step(number: '1', text: 'Fungua M-Pesa kwenye simu yako'),
          const _Step(number: '2', text: 'Chagua "Lipa Biashara" (Lipa Number)'),
          _Step(
            number: '3',
            child: Row(
              children: [
                Expanded(
                  child: Text('Namba: $mpesaNumber',
                      style: GoogleFonts.dmSans(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: mpesaNumber));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Namba imenakiliwa'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ));
                  },
                  child: const Icon(Icons.copy_rounded,
                      size: 16, color: AppColors.tealAccent),
                ),
              ],
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
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Maelezo / Kumbukumbu:',
                          style: GoogleFonts.dmSans(
                              fontSize: 12, color: AppColors.textSecondary)),
                      Text(ref,
                          style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: AppColors.navyPrimary)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: ref));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Kumbukumbu imenakiliwa'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ));
                  },
                  child: const Icon(Icons.copy_rounded,
                      size: 16, color: AppColors.tealAccent),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Baada ya kulipa, timu yetu itathibitisha ndani ya masaa 24 na mpango wako utawashwa.',
            style: GoogleFonts.dmSans(
                fontSize: 11, color: AppColors.textMuted, height: 1.5),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onDone,
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: const Text('Nimemaliza Kulipa'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
              child: Text(number,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: text != null
                ? Text(text!, style: GoogleFonts.dmSans(fontSize: 13))
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
