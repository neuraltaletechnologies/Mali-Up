import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../domain/models/cash_account.dart';
import '../../domain/models/cash_transaction.dart';
import '../../domain/models/daily_reconciliation.dart';
import '../../data/cash_flow_providers.dart';
import '../../data/finance_providers.dart';

String _t(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

final _fmt = NumberFormat('#,###', 'en_US');
String _fmtAmt(double v) => 'TZS ${_fmt.format(v)}';

class ReconciliationScreen extends ConsumerStatefulWidget {
  final CashAccount account;
  const ReconciliationScreen({super.key, required this.account});

  @override
  ConsumerState<ReconciliationScreen> createState() =>
      _ReconciliationScreenState();
}

class _ReconciliationScreenState extends ConsumerState<ReconciliationScreen> {
  late String _selectedDate;
  final _notesController = TextEditingController();
  double _openingBalance = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().toIso8601String().split('T').first;
    _openingBalance = widget.account.balance;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allTxns = ref.watch(accountTransactionsProvider(widget.account.id));
    final dayTxns = allTxns.where((t) => t.date == _selectedDate).toList();

    final deposits = dayTxns
        .where((t) => t.isDeposit || (t.isTransfer && t.toAccountId == widget.account.id))
        .fold(0.0, (s, t) => s + t.amount);
    final withdrawals = dayTxns
        .where((t) => t.isWithdrawal || (t.isTransfer && t.fromAccountId == widget.account.id))
        .fold(0.0, (s, t) => s + t.amount);
    final closingBalance = _openingBalance + deposits - withdrawals;

    final reconciliations = ref.watch(accountReconciliationsProvider(widget.account.id));
    final existing = reconciliations
        .where((r) => r.date == _selectedDate)
        .firstOrNull;

    if (existing != null && _notesController.text.isEmpty && existing.notes.isNotEmpty) {
      _notesController.text = existing.notes;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Daily Reconciliation', 'Ulinganisho wa Kila Siku')),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account + date selector
            _SectionCard(
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
                              widget.account.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            Text(
                              widget.account.type,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      if (existing?.isReconciled == true)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.successBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle,
                                  color: AppColors.success, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                _t('Reconciled', 'Imelinganishwa'),
                                style: const TextStyle(
                                  color: AppColors.success,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 16, color: AppColors.textMuted),
                          const SizedBox(width: 10),
                          Text(
                            _selectedDate,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.secondary),
                          ),
                          const Spacer(),
                          const Icon(Icons.chevron_right,
                              size: 18, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Opening balance
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t('Opening Balance', 'Salio la Awali'),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: _openingBalance.toStringAsFixed(0),
                    decoration: InputDecoration(
                      prefixText: 'TZS ',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final parsed = double.tryParse(v);
                      if (parsed != null) setState(() => _openingBalance = parsed);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Day transactions
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t('Transactions on $_selectedDate', 'Miamala ya $_selectedDate'),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (dayTxns.isEmpty)
                    EmptyState(
                      icon: Icons.check_circle_outline_rounded,
                      title: _t('All clear for this day',
                          'Hakuna shughuli siku hii'),
                      subtitle: _t(
                        'No transactions recorded for this date.',
                        'Hakuna miamala iliyorekodiwa kwa tarehe hii.',
                      ),
                    )
                  else
                    ...dayTxns
                        .map((t) => _ReconTxnRow(txn: t, accountId: widget.account.id)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Closing balance summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _BalanceLine(
                    label: _t('Opening Balance', 'Salio la Awali'),
                    value: _openingBalance,
                    color: Colors.white70,
                  ),
                  const SizedBox(height: 8),
                  _BalanceLine(
                    label: _t('+ Total Deposits', '+ Jumla ya Amana'),
                    value: deposits,
                    color: const Color(0xFF6EE7B7),
                  ),
                  _BalanceLine(
                    label: _t('- Total Withdrawals', '- Jumla ya Kutoa'),
                    value: withdrawals,
                    color: const Color(0xFFFCA5A5),
                  ),
                  const Divider(color: Colors.white24, height: 24),
                  _BalanceLine(
                    label: _t('Closing Balance', 'Salio la Mwisho'),
                    value: closingBalance,
                    color: Colors.white,
                    bold: true,
                    large: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t('Notes (Optional)', 'Maelezo (Hiari)'),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      hintText: _t(
                        'Any notes about today\'s cash position...',
                        'Maelezo yoyote kuhusu fedha za leo...',
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2),
                      ),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () => _saveReconciliation(
                          deposits: deposits,
                          withdrawals: withdrawals,
                          closingBalance: closingBalance,
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(_t(
                  'Mark as Reconciled',
                  'Thibitisha Ulinganisho',
                )),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked.toIso8601String().split('T').first;
      });
    }
  }

  Future<void> _saveReconciliation({
    required double deposits,
    required double withdrawals,
    required double closingBalance,
  }) async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      final reconciliation = DailyReconciliation(
        id: '',
        accountId: widget.account.id,
        date: _selectedDate,
        openingBalance: _openingBalance,
        closingBalance: closingBalance,
        totalDeposits: deposits,
        totalWithdrawals: withdrawals,
        notes: _notesController.text.trim(),
        reconciledBy: user.uid,
        isReconciled: true,
      );

      // Saves locally (incl. account lastReconciled) and queues the sync.
      await ref.read(cashRepositoryProvider).saveReconciliation(reconciliation);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_t(
              'Reconciliation saved',
              'Ulinganisho umehifadhiwa',
            )),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_t('Error: ${e.toString()}', 'Kosa: ${e.toString()}')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// ── Private helpers ───────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: child,
    );
  }
}

class _ReconTxnRow extends StatelessWidget {
  final CashTransaction txn;
  final String accountId;
  const _ReconTxnRow({required this.txn, required this.accountId});

  @override
  Widget build(BuildContext context) {
    final isIncoming =
        txn.isDeposit || (txn.isTransfer && txn.toAccountId == accountId);
    final color = txn.isTransfer
        ? AppColors.tealAccent
        : isIncoming
            ? AppColors.success
            : AppColors.error;
    final prefix = txn.isTransfer ? '' : isIncoming ? '+' : '-';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            txn.isTransfer
                ? Icons.swap_horiz_rounded
                : isIncoming
                    ? Icons.south_west_rounded
                    : Icons.north_east_rounded,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              txn.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.secondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$prefix${_fmtAmt(txn.amount)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceLine extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool bold;
  final bool large;

  const _BalanceLine({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: large ? 14 : 12,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          _fmtAmt(value),
          style: TextStyle(
            color: color,
            fontSize: large ? 18 : 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
