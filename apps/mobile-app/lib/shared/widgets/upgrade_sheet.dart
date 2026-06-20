import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/plan_service.dart';
import '../../core/theme/app_colors.dart';

/// Shows the upgrade/paywall bottom sheet comparing paid tiers.
/// Returns the selected [PlanTier] if the user taps a tier CTA, or null.
Future<PlanTier?> showUpgradeSheet(
  BuildContext context, {
  PlanStatus? currentStatus,
  String? triggerReason,
}) {
  return showModalBottomSheet<PlanTier>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) => _UpgradeSheet(
      currentStatus: currentStatus,
      triggerReason: triggerReason,
    ),
  );
}

class _UpgradeSheet extends StatefulWidget {
  final PlanStatus? currentStatus;
  final String? triggerReason;

  const _UpgradeSheet({this.currentStatus, this.triggerReason});

  @override
  State<_UpgradeSheet> createState() => _UpgradeSheetState();
}

class _UpgradeSheetState extends State<_UpgradeSheet> {
  PlanTier _selected = PlanTier.growth;
  bool _showPaymentInstructions = false;

  static const _mpesaNumber = '+255 XXX XXX XXX'; // Replace with actual M-Pesa number

  int get _selectedPriceMonthly =>
      _selected == PlanTier.growth ? 5000 : 10000;

  int get _selectedPriceSixMonths => _selectedPriceMonthly * 6;

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
              // Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header
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
                isSelected: _selected == PlanTier.growth,
                onTap: () => setState(() => _selected = PlanTier.growth),
              ),
              const SizedBox(height: 12),
              _TierCard(
                tier: PlanTier.business,
                isSelected: _selected == PlanTier.business,
                onTap: () => setState(() => _selected = PlanTier.business),
              ),
              const SizedBox(height: 12),

              // Enterprise
              _EnterpriseCard(),

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
                      ' — TZS ${_fmt(_selectedPriceMonthly)}/mwezi',
                      style: GoogleFonts.dmSans(
                          fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'TZS ${_fmt(_selectedPriceSixMonths)} ulipwa kwa miezi 6 mbele',
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: AppColors.textMuted),
                  ),
                ),
              ] else ...[
                _PaymentInstructions(
                  tier: _selected,
                  priceMonthly: _selectedPriceMonthly,
                  priceSixMonths: _selectedPriceSixMonths,
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

  static String _fmt(int v) =>
      v.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
}

// ─────────────────────────────────────────────────────────────────────────────

class _TierCard extends StatelessWidget {
  final PlanTier tier;
  final bool isSelected;
  final VoidCallback onTap;

  const _TierCard({
    required this.tier,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isGrowth = tier == PlanTier.growth;
    final limits = limitsFor(tier);
    final priceMonthly = isGrowth ? 5000 : 10000;

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
                              color: isSelected
                                  ? AppColors.tealAccent
                                  : AppColors.tealAccent,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'TZS ${_fmt(priceMonthly)} / mwezi',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _Feature(
                      text: 'Ankara zisizo na kikomo', ok: true, sel: isSelected),
                  _Feature(
                      text: '${limits.maxUsers} watumiaji', ok: true, sel: isSelected),
                  _Feature(text: 'Ripoti kamili', ok: true, sel: isSelected),
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
                        text: 'Stoo nyingi', ok: limits.multiLocation, sel: isSelected),
                    _Feature(
                        text: 'Ufikiaji wa API', ok: limits.apiAccess, sel: isSelected),
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

  static String _fmt(int v) =>
      v.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
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
  final int priceSixMonths;
  final String mpesaNumber;
  final VoidCallback onDone;

  const _PaymentInstructions({
    required this.tier,
    required this.priceMonthly,
    required this.priceSixMonths,
    required this.mpesaNumber,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final tierName = tier == PlanTier.growth ? 'Growth' : 'Business';
    final ref = 'MALIUP-${tierName.toUpperCase()}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

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
          const _Step(
            number: '1',
            text: 'Fungua M-Pesa kwenye simu yako',
          ),
          const _Step(
            number: '2',
            text: 'Chagua "Lipa Biashara" (Lipa Number)',
          ),
          _Step(
            number: '3',
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Namba: $mpesaNumber',
                    style: GoogleFonts.dmSans(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: mpesaNumber));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Namba imenakiliwa'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
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
                  'Kiasi: TZS ${_fmt(priceSixMonths)} (miezi 6)',
                  style: GoogleFonts.dmSans(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  '(TZS ${_fmt(priceMonthly)}/mwezi × 6)',
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
                      Text(
                        'Maelezo / Kumbukumbu:',
                        style: GoogleFonts.dmSans(fontSize: 12,
                            color: AppColors.textSecondary),
                      ),
                      Text(
                        ref,
                        style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: AppColors.navyPrimary),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: ref));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Kumbukumbu imenakiliwa'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
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

  static String _fmt(int v) =>
      v.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
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
                ? Text(
                    text!,
                    style: GoogleFonts.dmSans(fontSize: 13),
                  )
                : child!,
          ),
        ],
      ),
    );
  }
}
