import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_notification.dart';
import '../../../../shared/widgets/customer_picker_field.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../../customer/data/customer_providers.dart';
import '../../../customer/domain/models/customer.dart';
import '../../data/customer_debt_sync_service.dart';
import '../../data/debt_providers.dart';
import '../../domain/models/debt.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

String _fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _fmtAmt(double v) {
  final s = v.toStringAsFixed(0);
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return 'TZS $buf';
}

const List<String> _interestPeriods = ['daily', 'weekly', 'monthly'];
const List<String> _interestTypes = ['simple', 'compound'];

String _periodLabel(String p) => switch (p) {
      'daily' => _tr('Daily', 'Kila siku'),
      'weekly' => _tr('Weekly', 'Kila wiki'),
      _ => _tr('Monthly', 'Kila mwezi'),
    };

String _typeLabel(String t) =>
    t == 'compound' ? _tr('Compound', 'Riba mchanganyiko') : _tr('Simple', 'Riba rahisi');

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class AddDebtScreen extends ConsumerStatefulWidget {
  final bool initialIsReceivable;
  final Debt? debtToEdit;

  const AddDebtScreen({
    super.key,
    this.initialIsReceivable = true,
    this.debtToEdit,
  });

  @override
  ConsumerState<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends ConsumerState<AddDebtScreen> {
  late bool _isReceivable;
  late DateTime _dueDate;
  bool _saving = false;
  Customer? _linkedCustomer;
  String? _customerError;

  // Interest / money-lender terms.
  bool _chargeInterest = false;
  late DateTime _loanDate;
  String _interestPeriod = 'monthly';
  String _interestType = 'simple';

  final _amountCtrl = TextEditingController();
  final _interestRateCtrl = TextEditingController();
  final _invoiceCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _isReceivable = widget.initialIsReceivable;
    _dueDate = DateTime.now().add(const Duration(days: 30));
    _loanDate = DateTime.now();

    final e = widget.debtToEdit;
    if (e != null) {
      _isReceivable = e.type == 'receivable';
      _amountCtrl.text = e.originalAmount.toStringAsFixed(0);
      _invoiceCtrl.text = e.invoiceRef;
      _noteCtrl.text = e.note;
      _dueDate = DateTime.tryParse(e.dueDate) ?? _dueDate;
      _chargeInterest = e.hasInterest;
      _interestPeriod = e.interestPeriod;
      _interestType = e.interestType;
      _loanDate = DateTime.tryParse(
              e.loanDate.isNotEmpty ? e.loanDate : e.createdAt) ??
          _loanDate;
      if (e.interestRatePercent > 0) {
        _interestRateCtrl.text = _trimZeros(e.interestRatePercent);
      }
      // Pre-select the linked customer, if any, from whatever the list
      // provider has already loaded. Best-effort — if the list hasn't
      // loaded yet the field simply starts empty and the user re-picks.
      if (e.partyId.isNotEmpty) {
        final customers = ref
            .read(customerListProvider)
            .maybeWhen(data: (d) => d, orElse: () => <Customer>[]);
        for (final c in customers) {
          if (c.id == e.partyId) {
            _linkedCustomer = c;
            break;
          }
        }
      }
    }
  }

  String _trimZeros(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _interestRateCtrl.dispose();
    _invoiceCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _selectCustomer(Customer? c) {
    setState(() {
      _linkedCustomer = c;
      if (c != null) _customerError = null;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.navyPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _pickLoanDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _loanDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.navyPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _loanDate = picked);
  }

  /// A throwaway Debt built from the form's current values, used only to
  /// reuse [Debt.accruedInterest]'s math for the live preview below.
  double _previewAccrued() {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    final rate = double.tryParse(_interestRateCtrl.text) ?? 0;
    if (amount <= 0 || rate <= 0) return 0;
    final preview = Debt(
      id: '',
      partyName: '',
      type: 'receivable',
      originalAmount: amount,
      dueDate: '',
      createdAt: _fmtDate(_loanDate),
      interestRatePercent: rate,
      interestPeriod: _interestPeriod,
      interestType: _interestType,
      loanDate: _fmtDate(_loanDate),
    );
    return preview.accruedInterest;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_linkedCustomer == null) {
      setState(() => _customerError = _isReceivable
          ? _tr('Select who owes you', 'Chagua anayekudai')
          : _tr('Select who you owe', 'Chagua unayemdai'));
      return;
    }
    setState(() => _saving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final repo = ref.read(debtRepositoryProvider);
      final amount = double.tryParse(
              _amountCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ??
          0;
      final now = DateTime.now().toIso8601String();
      final rate = _chargeInterest
          ? (double.tryParse(_interestRateCtrl.text) ?? 0)
          : 0.0;

      // Enforce credit limit for new receivables linked to a customer with a limit.
      final isNew = widget.debtToEdit == null;
      if (isNew && _isReceivable && _linkedCustomer!.creditLimit > 0) {
        final projectedBalance = _linkedCustomer!.balanceAmount + amount;
        if (projectedBalance > _linkedCustomer!.creditLimit) {
          final available = _linkedCustomer!.availableCredit;
          if (mounted) {
            setState(() => _saving = false);
            AppNotification.error(
              context,
              _tr(
                'Credit limit exceeded. ${_linkedCustomer!.name} can only borrow TZS ${available.toStringAsFixed(0)} more.',
                'Kikomo cha mkopo kimezidiwa. ${_linkedCustomer!.name} anaweza kukopa TZS ${available.toStringAsFixed(0)} tu zaidi.',
              ),
            );
          }
          return;
        }
      }

      final debt = Debt(
        id: widget.debtToEdit?.id ?? '',
        partyName: _linkedCustomer!.name,
        partyPhone: _linkedCustomer!.phone,
        partyId: _linkedCustomer!.id,
        type: _isReceivable ? 'receivable' : 'payable',
        originalAmount: amount,
        paidAmount: widget.debtToEdit?.paidAmount ?? 0,
        dueDate: _fmtDate(_dueDate),
        status: widget.debtToEdit?.status ?? 'current',
        invoiceRef: _invoiceCtrl.text.trim(),
        note: _noteCtrl.text.trim(),
        createdBy: widget.debtToEdit?.createdBy ?? user.uid,
        createdAt: widget.debtToEdit?.createdAt ?? now,
        interestRatePercent: rate,
        interestPeriod: _interestPeriod,
        interestType: _interestType,
        loanDate: rate > 0 ? _fmtDate(_loanDate) : '',
      );

      await repo.save(debt);

      // Mirror the change into the linked customer's balance so the
      // customer page shows the same debt.
      await adjustCustomerBalanceForDebtChange(
        ref,
        before: widget.debtToEdit,
        after: debt,
      );

      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        AppNotification.error(
          context,
          _tr('Failed to save. Please try again.', 'Imeshindwa kuhifadhi. Jaribu tena.'),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.debtToEdit != null;
    final accentColor = _isReceivable ? AppColors.success : AppColors.error;
    final size = MediaQuery.sizeOf(context);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: size.height * 0.95),
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            const SheetHandle(),
            _Header(isEdit: isEdit, isReceivable: _isReceivable),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!isEdit) ...[
                        _TypeToggle(
                          isReceivable: _isReceivable,
                          onChanged: (v) => setState(() => _isReceivable = v),
                        ),
                        const SizedBox(height: 20),
                      ],
                      _AmountEntry(
                        controller: _amountCtrl,
                        isReceivable: _isReceivable,
                        onChanged: () => setState(() {}),
                      ),
                      const SizedBox(height: 24),

                      _SectionLabel(
                        _isReceivable
                            ? _tr('Who owes you', 'Nani anakudai')
                            : _tr('Who you owe', 'Unamdaiwa nani'),
                      ),
                      const SizedBox(height: 8),
                      CustomerPickerField(
                        selected: _linkedCustomer,
                        onSelected: _selectCustomer,
                      ),
                      if (_customerError != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _customerError!,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      _SectionLabel(_tr('Details', 'Taarifa')),
                      const SizedBox(height: 8),
                      _GroupCard(
                        children: [
                          _TapRow(
                            icon: Icons.calendar_today_outlined,
                            label: _tr('Due Date', 'Tarehe ya Mwisho'),
                            value: _fmtDate(_dueDate),
                            onTap: _pickDate,
                          ),
                          _TextRow(
                            icon: Icons.tag_rounded,
                            label:
                                _tr('Invoice / Ref # (optional)', 'Nambari ya Ankara (hiari)'),
                            controller: _invoiceCtrl,
                          ),
                          _TextRow(
                            icon: Icons.notes_outlined,
                            label: _tr('Note (optional)', 'Maelezo (hiari)'),
                            controller: _noteCtrl,
                            maxLines: 3,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      _SectionLabel(_tr('Interest', 'Riba')),
                      const SizedBox(height: 8),
                      _InterestCard(
                        enabled: _chargeInterest,
                        onEnabledChanged: (v) =>
                            setState(() => _chargeInterest = v),
                        rateController: _interestRateCtrl,
                        period: _interestPeriod,
                        onPeriodChanged: (v) =>
                            setState(() => _interestPeriod = v),
                        type: _interestType,
                        onTypeChanged: (v) => setState(() => _interestType = v),
                        loanDate: _loanDate,
                        onLoanDateTap: _pickLoanDate,
                        previewAccrued: _previewAccrued(),
                        onRateChanged: () => setState(() {}),
                      ),
                      const SizedBox(height: 28),

                      _SaveButton(
                        saving: _saving,
                        isEdit: isEdit,
                        isReceivable: _isReceivable,
                        accentColor: accentColor,
                        onTap: _save,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
// Minimal: a plain title + a small muted caption instead of a loud colour
// pill — Apple-style forms lean on typography/whitespace, not colour blocks.

class _Header extends StatelessWidget {
  final bool isEdit;
  final bool isReceivable;

  const _Header({required this.isEdit, required this.isReceivable});

  @override
  Widget build(BuildContext context) {
    final label = isEdit
        ? _tr('Edit Entry', 'Hariri Rekodi')
        : isReceivable
            ? _tr('Add Receivable', 'Ongeza Dai')
            : _tr('Add Payable', 'Ongeza Deni');
    final caption =
        isReceivable ? _tr('Owed to you', 'Unadai') : _tr('You owe', 'Unadaiwa');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 12, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  caption,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  size: 16, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Type Toggle — monochrome segmented control ─────────────────────────────

class _TypeToggle extends StatelessWidget {
  final bool isReceivable;
  final ValueChanged<bool> onChanged;

  const _TypeToggle({required this.isReceivable, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _ToggleChip(
            label: _tr('Receivable', 'Dai'),
            active: isReceivable,
            accentColor: AppColors.success,
            onTap: () => onChanged(true),
          ),
          _ToggleChip(
            label: _tr('Payable', 'Deni'),
            active: !isReceivable,
            accentColor: AppColors.error,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color accentColor;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.active,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: active
                ? const [
                    BoxShadow(
                      color: AppColors.shadowCard,
                      blurRadius: 6,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 7),
                decoration: BoxDecoration(
                  color: active ? accentColor : AppColors.textDisabled,
                  shape: BoxShape.circle,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: active ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Amount Entry — plain, generous whitespace, no gradient ─────────────────

class _AmountEntry extends StatelessWidget {
  final TextEditingController controller;
  final bool isReceivable;
  final VoidCallback onChanged;

  const _AmountEntry({
    required this.controller,
    required this.isReceivable,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isReceivable
                ? _tr('Amount Owed to You', 'Kiasi Unachostahili')
                : _tr('Amount You Owe', 'Kiasi Unachoadaiwa'),
            style: GoogleFonts.dmSans(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'TZS',
                  style: GoogleFonts.dmSans(
                      color: AppColors.textDisabled,
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => onChanged(),
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textPrimary,
                    fontSize: 40,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                  ),
                  decoration: InputDecoration(
                    filled: false,
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: GoogleFonts.jetBrainsMono(
                        color: AppColors.textDisabled,
                        fontSize: 40,
                        fontWeight: FontWeight.w600),
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return _tr('Amount required', 'Kiasi kinahitajika');
                    }
                    if ((double.tryParse(v) ?? 0) <= 0) {
                      return _tr(
                          'Enter a valid amount', 'Ingiza kiasi halali');
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(height: 1.5, color: AppColors.border),
        ],
      ),
    );
  }
}

// ── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Text(
          text.toUpperCase(),
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 0.6,
          ),
        ),
      );
}

// ── Grouped card — iOS-settings-style rows with hairline dividers ──────────

class _GroupCard extends StatelessWidget {
  final List<Widget> children;
  const _GroupCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              const Padding(
                padding: EdgeInsets.only(left: 48),
                child: Divider(height: 1, color: AppColors.border),
              ),
          ],
        ],
      ),
    );
  }
}

class _TapRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _TapRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                    fontSize: 14, color: AppColors.textPrimary),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                size: 16, color: AppColors.textDisabled),
          ],
        ),
      ),
    );
  }
}

class _TextRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final int maxLines;

  const _TextRow({
    required this.icon,
    required this.label,
    required this.controller,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Icon(icon, size: 18, color: AppColors.textMuted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: controller,
              maxLines: maxLines,
              minLines: 1,
              style: GoogleFonts.dmSans(
                  fontSize: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: label,
                border: InputBorder.none,
                isCollapsed: false,
                labelStyle:
                    GoogleFonts.dmSans(fontSize: 13, color: AppColors.textMuted),
                floatingLabelStyle: GoogleFonts.dmSans(
                    fontSize: 11, color: AppColors.navyPrimary),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Interest card ─────────────────────────────────────────────────────────
// Built for lenders: a rate + period + simple/compound + start date, with a
// live "accrued so far" preview so the numbers are never a surprise later.

class _InterestCard extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onEnabledChanged;
  final TextEditingController rateController;
  final String period;
  final ValueChanged<String> onPeriodChanged;
  final String type;
  final ValueChanged<String> onTypeChanged;
  final DateTime loanDate;
  final VoidCallback onLoanDateTap;
  final double previewAccrued;
  final VoidCallback onRateChanged;

  const _InterestCard({
    required this.enabled,
    required this.onEnabledChanged,
    required this.rateController,
    required this.period,
    required this.onPeriodChanged,
    required this.type,
    required this.onTypeChanged,
    required this.loanDate,
    required this.onLoanDateTap,
    required this.previewAccrued,
    required this.onRateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.percent_rounded,
                    size: 18, color: AppColors.textMuted),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tr('Charge Interest', 'Tumia Riba'),
                        style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary),
                      ),
                      Text(
                        _tr('For money lenders — grows the balance over time',
                            'Kwa watoa mikopo — huongeza salio kadri muda unavyopita'),
                        style: GoogleFonts.dmSans(
                            fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: enabled,
                  onChanged: onEnabledChanged,
                  activeTrackColor: AppColors.navyPrimary,
                ),
              ],
            ),
          ),
          if (enabled) ...[
            const Padding(
              padding: EdgeInsets.only(left: 16),
              child: Divider(height: 1, color: AppColors.border),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: rateController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => onRateChanged(),
                          style: GoogleFonts.jetBrainsMono(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            labelText: _tr('Interest Rate', 'Kiwango cha Riba'),
                            suffixText: '%  / ${_periodLabel(period).toLowerCase()}',
                            suffixStyle: GoogleFonts.dmSans(
                                fontSize: 12, color: AppColors.textMuted),
                            labelStyle: GoogleFonts.dmSans(
                                fontSize: 12, color: AppColors.textMuted),
                            border: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12)),
                              borderSide:
                                  BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12)),
                              borderSide:
                                  BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12)),
                              borderSide: BorderSide(
                                  color: AppColors.navyPrimary, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                          ),
                          validator: (v) {
                            if (!enabled) return null;
                            final n = double.tryParse(v ?? '');
                            if (n == null || n <= 0) {
                              return _tr('Enter a rate', 'Ingiza kiwango');
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SmallLabel(_tr('Charged every', 'Inatozwa kila')),
                  const SizedBox(height: 6),
                  _SegmentedControl<String>(
                    options: _interestPeriods,
                    value: period,
                    labelBuilder: _periodLabel,
                    onChanged: onPeriodChanged,
                  ),
                  const SizedBox(height: 14),
                  _SmallLabel(_tr('Interest type', 'Aina ya riba')),
                  const SizedBox(height: 6),
                  _SegmentedControl<String>(
                    options: _interestTypes,
                    value: type,
                    labelBuilder: _typeLabel,
                    onChanged: onTypeChanged,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    type == 'compound'
                        ? _tr(
                            'Interest is added to the balance each period, so the next period’s interest is charged on top of it.',
                            'Riba huongezwa kwenye salio kila kipindi, hivyo riba ya kipindi kinachofuata hutozwa juu yake.',
                          )
                        : _tr(
                            'Interest is charged on the original amount only, every period.',
                            'Riba hutozwa kwenye kiasi cha asili pekee, kila kipindi.',
                          ),
                    style: GoogleFonts.dmSans(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                        height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  _SmallLabel(_tr('Interest starts from', 'Riba inaanza tarehe')),
                  const SizedBox(height: 6),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onLoanDateTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 16, color: AppColors.textMuted),
                          const SizedBox(width: 10),
                          Text(
                            _fmtDate(loanDate),
                            style: GoogleFonts.jetBrainsMono(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.navyPrimary),
                          ),
                          const Spacer(),
                          const Icon(Icons.chevron_right_rounded,
                              size: 16, color: AppColors.textDisabled),
                        ],
                      ),
                    ),
                  ),
                  if (previewAccrued > 0) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.navyPrimary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.trending_up_rounded,
                              size: 16, color: AppColors.navyPrimary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _tr('Accrued so far', 'Imekusanya hadi sasa'),
                              style: GoogleFonts.dmSans(
                                  fontSize: 12.5, color: AppColors.textSecondary),
                            ),
                          ),
                          Text(
                            _fmtAmt(previewAccrued),
                            style: GoogleFonts.jetBrainsMono(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navyPrimary),
                          ),
                        ],
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

class _SmallLabel extends StatelessWidget {
  final String text;
  const _SmallLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 0.3,
        ),
      );
}

// ── Generic segmented control ───────────────────────────────────────────────

class _SegmentedControl<T> extends StatelessWidget {
  final List<T> options;
  final T value;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onChanged;

  const _SegmentedControl({
    required this.options,
    required this.value,
    required this.labelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: options.map((o) {
          final active = o == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(o),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: active
                      ? const [
                          BoxShadow(
                            color: AppColors.shadowCard,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  labelBuilder(o),
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color:
                        active ? AppColors.navyPrimary : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Save Button ───────────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  final bool saving;
  final bool isEdit;
  final bool isReceivable;
  final Color accentColor;
  final VoidCallback onTap;

  const _SaveButton({
    required this.saving,
    required this.isEdit,
    required this.isReceivable,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: saving ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navyPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.navyPrimary.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : Text(
                isEdit
                    ? _tr('Save Changes', 'Hifadhi Mabadiliko')
                    : isReceivable
                        ? _tr('Add Receivable', 'Ongeza Dai')
                        : _tr('Add Payable', 'Ongeza Deni'),
                style: GoogleFonts.dmSans(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}
