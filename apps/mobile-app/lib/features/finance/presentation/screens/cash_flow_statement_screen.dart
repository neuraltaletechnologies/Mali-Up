import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/cash_flow_providers.dart';
import '../../domain/models/cash_transaction.dart';

String _t(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

final _numFmt = NumberFormat('#,###', 'en_US');
String _fmtAmt(double v) => 'TZS ${_numFmt.format(v.abs())}';

class CashFlowStatementScreen extends ConsumerWidget {
  const CashFlowStatementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(cfMonthProvider);
    final txns = ref.watch(cfTransactionsByMonthProvider);
    final byActivity = ref.watch(cfByActivityProvider);
    final netFlow = ref.watch(netCashFlowProvider);

    final monthLabel = DateFormat.yMMMM().format(month);

    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Cash Flow Statement', 'Taarifa ya Mtiririko wa Pesa')),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month + net banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          monthLabel,
                          style: GoogleFonts.dmSans(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _t('Net Cash Flow', 'Mtiririko Halisi wa Pesa'),
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${netFlow >= 0 ? '+' : '-'}${_fmtAmt(netFlow)}',
                    style: GoogleFonts.dmSans(
                      color: netFlow >= 0 ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Operating activities
            _ActivitySection(
              title: _t('Operating Activities', 'Shughuli za Uendeshaji'),
              subtitle: _t(
                'Day-to-day business cash flows',
                'Mtiririko wa pesa za kila siku',
              ),
              icon: Icons.store_outlined,
              color: AppColors.tealAccent,
              data: byActivity['operating'] ?? (inflow: 0.0, outflow: 0.0),
              transactions: txns
                  .where((t) => t.activityCategory == 'operating' && !t.isTransfer)
                  .toList(),
            ),
            const SizedBox(height: 16),

            // Investing activities
            _ActivitySection(
              title: _t('Investing Activities', 'Shughuli za Uwekezaji'),
              subtitle: _t(
                'Asset purchases and sales',
                'Ununuzi na mauzo ya mali',
              ),
              icon: Icons.trending_up_rounded,
              color: AppColors.purpleAccent,
              data: byActivity['investing'] ?? (inflow: 0.0, outflow: 0.0),
              transactions: txns
                  .where((t) => t.activityCategory == 'investing' && !t.isTransfer)
                  .toList(),
            ),
            const SizedBox(height: 16),

            // Financing activities
            _ActivitySection(
              title: _t('Financing Activities', 'Shughuli za Ufadhili'),
              subtitle: _t(
                'Loans, owner contributions, dividends',
                'Mikopo, michango ya mmiliki, gawio',
              ),
              icon: Icons.account_balance_outlined,
              color: AppColors.warning,
              data: byActivity['financing'] ?? (inflow: 0.0, outflow: 0.0),
              transactions: txns
                  .where((t) => t.activityCategory == 'financing' && !t.isTransfer)
                  .toList(),
            ),
            const SizedBox(height: 24),

            // Totals summary table
            _SummaryTable(byActivity: byActivity, netFlow: netFlow),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ActivitySection extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final ({double inflow, double outflow}) data;
  final List<CashTransaction> transactions;

  const _ActivitySection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.data,
    required this.transactions,
  });

  @override
  State<_ActivitySection> createState() => _ActivitySectionState();
}

class _ActivitySectionState extends State<_ActivitySection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final net = widget.data.inflow - widget.data.outflow;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        Text(
                          widget.subtitle,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${net >= 0 ? '+' : '-'}${_fmtAmt(net)}',
                        style: GoogleFonts.dmSans(
                          color: net >= 0 ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: AppColors.textMuted,
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Details
          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.borderLight),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _InOutRow(
                    label: _t('Total Inflow', 'Jumla ya Mapato'),
                    amount: widget.data.inflow,
                    color: AppColors.success,
                    icon: Icons.south_west_rounded,
                  ),
                  const SizedBox(height: 8),
                  _InOutRow(
                    label: _t('Total Outflow', 'Jumla ya Matumizi'),
                    amount: widget.data.outflow,
                    color: AppColors.error,
                    icon: Icons.north_east_rounded,
                  ),
                  if (widget.transactions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: AppColors.borderLight),
                    const SizedBox(height: 12),
                    ...widget.transactions.map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(
                              t.isDeposit
                                  ? Icons.add_circle_outline
                                  : Icons.remove_circle_outline,
                              size: 14,
                              color: t.isDeposit ? AppColors.success : AppColors.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                t.description,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${t.isDeposit ? '+' : '-'}${_fmtAmt(t.amount)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: t.isDeposit ? AppColors.success : AppColors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InOutRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _InOutRow({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ),
        Text(
          _fmtAmt(amount),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SummaryTable extends StatelessWidget {
  final Map<String, ({double inflow, double outflow})> byActivity;
  final double netFlow;

  const _SummaryTable({required this.byActivity, required this.netFlow});

  @override
  Widget build(BuildContext context) {
    final totalIn = byActivity.values.fold(0.0, (s, v) => s + v.inflow);
    final totalOut = byActivity.values.fold(0.0, (s, v) => s + v.outflow);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('Summary', 'Muhtasari'),
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          _SummaryRow(
            label: _t('Total Cash In', 'Jumla ya Pesa Zilizoingia'),
            value: totalIn,
            color: const Color(0xFF6EE7B7),
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            label: _t('Total Cash Out', 'Jumla ya Pesa Zilizotoka'),
            value: totalOut,
            color: const Color(0xFFFCA5A5),
          ),
          const Divider(color: Colors.white24, height: 24),
          _SummaryRow(
            label: _t('Net Cash Flow', 'Mtiririko Halisi'),
            value: netFlow,
            color: netFlow >= 0 ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
            bold: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool bold;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            color: Colors.white70,
            fontSize: bold ? 14 : 12,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        Text(
          '${value < 0 ? '-' : ''}${_fmtAmt(value)}',
          style: GoogleFonts.dmSans(
            color: color,
            fontSize: bold ? 16 : 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
