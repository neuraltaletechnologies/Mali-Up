import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_notification.dart';
import '../../data/reports_providers.dart';
import '../../services/report_export_service.dart';
import 'reports_hub_screen.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

class BalanceSheetScreen extends ConsumerWidget {
  const BalanceSheetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(balanceSheetProvider);
    final range = ref.watch(reportDateRangeProvider);
    final isSwahili = LocalizationService.isSwahili;
    final now = DateTime.now();
    final dateLabel = '${now.day}/${now.month}/${now.year}';
    final periodLabel = isSwahili ? range.labelSw : range.label;

    final isBalanced =
        (report.totalAssets - report.totalLiabilities - report.ownersEquity)
            .abs() <
        1.0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.secondary),
        title: Text(
          _tr('Balance Sheet', 'Karatasi ya Mizania'),
          style: GoogleFonts.dmSans(
            color: AppColors.secondary,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Text(
                _tr('As of $dateLabel', 'Hadi $dateLabel'),
                style: GoogleFonts.dmSans(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Balance equation banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _EquationTerm(
                  label: _tr('Assets', 'Rasilimali'),
                  value: formatCurrency(report.totalAssets),
                ),
                Text(
                  '=',
                  style: GoogleFonts.dmSans(
                    color: Colors.white60,
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                _EquationTerm(
                  label: _tr('Liabilities', 'Madeni'),
                  value: formatCurrency(report.totalLiabilities),
                ),
                Text(
                  '+',
                  style: GoogleFonts.dmSans(
                    color: Colors.white60,
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                _EquationTerm(
                  label: _tr('Equity', 'Hisa'),
                  value: formatCurrency(report.ownersEquity),
                ),
              ],
            ),
          ),
          if (!isBalanced) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                _tr(
                  'Note: Some transactions may not be recorded. Totals are approximate.',
                  'Kumbuka: Baadhi ya miamala huenda haikurekodiwa. Jumla ni takriban.',
                ),
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // ASSETS section
          _BalanceSection(
            title: _tr('ASSETS', 'RASILIMALI'),
            color: AppColors.success,
            total: formatCurrency(report.totalAssets),
            totalLabel: _tr('TOTAL ASSETS', 'JUMLA YA RASILIMALI'),
            children: [
              _BSGroup(
                title: _tr('Current Assets', 'Rasilimali za Sasa'),
                subtotal: formatCurrency(report.totalCurrentAssets),
                children: [
                  _BSRow(
                    label: _tr(
                      'Cash & Bank Accounts',
                      'Pesa & Akaunti za Benki',
                    ),
                    value: formatCurrency(report.cashAndEquivalents),
                  ),
                  _BSRow(
                    label: _tr('Accounts Receivable', 'Madai ya Wateja'),
                    value: formatCurrency(report.accountsReceivable),
                  ),
                  _BSRow(
                    label: _tr('Inventory (at cost)', 'Hisa (kwa gharama)'),
                    value: formatCurrency(report.inventoryValue),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // LIABILITIES section
          _BalanceSection(
            title: _tr('LIABILITIES', 'MADENI'),
            color: AppColors.error,
            total: formatCurrency(report.totalLiabilities),
            totalLabel: _tr('TOTAL LIABILITIES', 'JUMLA YA MADENI'),
            children: [
              _BSGroup(
                title: _tr('Current Liabilities', 'Madeni ya Sasa'),
                subtotal: formatCurrency(report.totalCurrentLiabilities),
                children: [
                  _BSRow(
                    label: _tr(
                      'Accounts Payable (pending expenses)',
                      'Madeni ya Wasambazaji (gharama zinazosimama)',
                    ),
                    value: formatCurrency(report.accountsPayable),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // EQUITY section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _tr("OWNER'S EQUITY", 'HISA YA MMILIKI'),
                      style: GoogleFonts.dmSans(
                        color: AppColors.secondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _BSRow(
                  label: _tr(
                    "Total Owner's Equity",
                    'Jumla ya Hisa ya Mmiliki',
                  ),
                  value: formatCurrency(report.ownersEquity),
                  bold: true,
                  valueColor: report.ownersEquity >= 0
                      ? AppColors.success
                      : AppColors.error,
                ),
                const Divider(height: 16, color: AppColors.border),
                _BSRow(
                  label: _tr('Assets − Liabilities', 'Rasilimali − Madeni'),
                  value: formatCurrency(
                    report.totalAssets - report.totalLiabilities,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          ReportExportRow(
            onPdf: () => exportReportPdf(
              context,
              () =>
                  ReportExportService.shareBalanceSheetPdf(report, periodLabel),
            ),
            onCsv: () async {
              await ReportExportService.copyToClipboard(
                ReportExportService.balanceSheetCsv(report),
              );
              if (context.mounted) {
                AppNotification.success(context, _tr('CSV copied to clipboard', 'CSV imenakiliwa'));
              }
            },
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

// ─── Equation term ────────────────────────────────────────────────────────────

class _EquationTerm extends StatelessWidget {
  final String label;
  final String value;
  const _EquationTerm({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(color: Colors.white60, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ─── Balance section ──────────────────────────────────────────────────────────

class _BalanceSection extends StatelessWidget {
  final String title;
  final Color color;
  final List<Widget> children;
  final String total;
  final String totalLabel;

  const _BalanceSection({
    required this.title,
    required this.color,
    required this.children,
    required this.total,
    required this.totalLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.dmSans(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
          const Divider(height: 16, color: AppColors.border),
          _BSRow(label: totalLabel, value: total, bold: true),
        ],
      ),
    );
  }
}

class _BSGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final String subtotal;

  const _BSGroup({
    required this.title,
    required this.children,
    required this.subtotal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.dmSans(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        ...children,
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '  Subtotal',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                subtotal,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _BSRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _BSRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: bold ? AppColors.secondary : AppColors.textSecondary,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color:
                  valueColor ??
                  (bold ? AppColors.secondary : AppColors.textPrimary),
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
