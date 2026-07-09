import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/customer_picker_field.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../../customer/domain/models/customer.dart';
import '../../data/customer_debt_sync_service.dart';
import '../../data/debt_providers.dart';
import '../../domain/models/debt.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

String _fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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

  final _amountCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _invoiceCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _isReceivable = widget.initialIsReceivable;
    _dueDate = DateTime.now().add(const Duration(days: 30));

    final e = widget.debtToEdit;
    if (e != null) {
      _isReceivable = e.type == 'receivable';
      _amountCtrl.text = e.originalAmount.toStringAsFixed(0);
      _nameCtrl.text = e.partyName;
      _phoneCtrl.text = e.partyPhone;
      _invoiceCtrl.text = e.invoiceRef;
      _noteCtrl.text = e.note;
      _dueDate = DateTime.tryParse(e.dueDate) ?? _dueDate;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _invoiceCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _selectCustomer(Customer? c) {
    setState(() {
      _linkedCustomer = c;
      if (c != null) {
        _nameCtrl.text = c.name;
        _phoneCtrl.text = c.phone;
      }
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final repo = ref.read(debtRepositoryProvider);
      final amount = double.tryParse(
              _amountCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ??
          0;
      final now = DateTime.now().toIso8601String();

      // Enforce credit limit for new receivables linked to a customer with a limit.
      final isNew = widget.debtToEdit == null;
      if (isNew && _isReceivable && _linkedCustomer != null && _linkedCustomer!.creditLimit > 0) {
        final projectedBalance = _linkedCustomer!.balanceAmount + amount;
        if (projectedBalance > _linkedCustomer!.creditLimit) {
          final available = _linkedCustomer!.availableCredit;
          if (mounted) {
            setState(() => _saving = false);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(_tr(
                'Credit limit exceeded. ${_linkedCustomer!.name} can only borrow TZS ${available.toStringAsFixed(0)} more.',
                'Kikomo cha mkopo kimezidiwa. ${_linkedCustomer!.name} anaweza kukopa TZS ${available.toStringAsFixed(0)} tu zaidi.',
              )),
              backgroundColor: AppColors.error,
            ));
          }
          return;
        }
      }

      final debt = Debt(
        id: widget.debtToEdit?.id ?? '',
        partyName: _nameCtrl.text.trim(),
        partyPhone: _phoneCtrl.text.trim(),
        partyId: _linkedCustomer?.id ?? widget.debtToEdit?.partyId ?? '',
        type: _isReceivable ? 'receivable' : 'payable',
        originalAmount: amount,
        paidAmount: widget.debtToEdit?.paidAmount ?? 0,
        dueDate: _fmtDate(_dueDate),
        status: widget.debtToEdit?.status ?? 'current',
        invoiceRef: _invoiceCtrl.text.trim(),
        note: _noteCtrl.text.trim(),
        createdBy: widget.debtToEdit?.createdBy ?? user.uid,
        createdAt: widget.debtToEdit?.createdAt ?? now,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_tr(
                'Failed to save. Please try again.',
                'Imeshindwa kuhifadhi. Jaribu tena.')),
            backgroundColor: AppColors.error,
          ),
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
            _Header(
              isEdit: isEdit,
              isReceivable: _isReceivable,
              accentColor: accentColor,
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!isEdit) ...[
                        _TypeToggle(
                          isReceivable: _isReceivable,
                          onChanged: (v) => setState(() => _isReceivable = v),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _AmountCard(
                        controller: _amountCtrl,
                        isReceivable: _isReceivable,
                      ),
                      const SizedBox(height: 16),
                      if (_isReceivable) ...[
                        CustomerPickerField(
                          selected: _linkedCustomer,
                          onSelected: _selectCustomer,
                          labelEn: 'Link to Customer (optional)',
                          labelSw: 'Unganisha na Mteja (si lazima)',
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextFormField(
                        controller: _nameCtrl,
                        style: GoogleFonts.dmSans(
                            fontSize: 14, color: AppColors.textPrimary),
                        decoration: _fieldDec(
                          label: _isReceivable
                              ? _tr('Customer Name', 'Jina la Mteja')
                              : _tr('Supplier Name', 'Jina la Muuzaji'),
                          prefix: Icons.person_outline_rounded,
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? _tr('Name is required', 'Jina linahitajika')
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneCtrl,
                        style: GoogleFonts.dmSans(
                            fontSize: 14, color: AppColors.textPrimary),
                        decoration: _fieldDec(
                          label: _tr('Phone Number', 'Namba ya Simu'),
                          prefix: Icons.phone_outlined,
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      _DueDateRow(dueDate: _dueDate, onTap: _pickDate),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _invoiceCtrl,
                        style: GoogleFonts.dmSans(
                            fontSize: 14, color: AppColors.textPrimary),
                        decoration: _fieldDec(
                          label: _tr('Invoice / Ref # (optional)',
                              'Nambari ya Ankara (hiari)'),
                          prefix: Icons.tag_rounded,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _noteCtrl,
                        style: GoogleFonts.dmSans(
                            fontSize: 14, color: AppColors.textPrimary),
                        decoration: _fieldDec(
                          label: _tr('Note (optional)', 'Maelezo (hiari)'),
                          prefix: Icons.notes_outlined,
                        ),
                        maxLines: 3,
                        minLines: 1,
                      ),
                      const SizedBox(height: 24),
                      _SaveButton(
                        saving: _saving,
                        isEdit: isEdit,
                        isReceivable: _isReceivable,
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

InputDecoration _fieldDec({
  required String label,
  required IconData prefix,
  String? hint,
}) =>
    InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle:
          GoogleFonts.dmSans(fontSize: 14, color: AppColors.textDisabled),
      labelStyle: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textMuted),
      floatingLabelStyle:
          GoogleFonts.dmSans(fontSize: 12, color: AppColors.navyPrimary),
      prefixIcon: Icon(prefix, size: 20, color: AppColors.textSecondary),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: AppColors.navyPrimary, width: 1.5),
      ),
    );

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final bool isEdit;
  final bool isReceivable;
  final Color accentColor;

  const _Header({
    required this.isEdit,
    required this.isReceivable,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final label = isEdit
        ? _tr('Edit Entry', 'Hariri Rekodi')
        : isReceivable
            ? _tr('Add Receivable', 'Ongeza Dai')
            : _tr('Add Payable', 'Ongeza Deni');
    final pillLabel =
        isReceivable ? _tr('Owed to you', 'Unadai') : _tr('You owe', 'Unadaiwa');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.navyPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              pillLabel,
              style: GoogleFonts.dmSans(
                color: accentColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.border.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  size: 18, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Type Toggle ───────────────────────────────────────────────────────────────

class _TypeToggle extends StatelessWidget {
  final bool isReceivable;
  final ValueChanged<bool> onChanged;

  const _TypeToggle({required this.isReceivable, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _ToggleChip(
            label: _tr('Receivable', 'Dai'),
            subtitle: _tr('Money owed to you', 'Unastahili kulipwa'),
            icon: Icons.arrow_downward_rounded,
            active: isReceivable,
            activeColor: AppColors.success,
            onTap: () => onChanged(true),
          ),
          const SizedBox(width: 4),
          _ToggleChip(
            label: _tr('Payable', 'Deni'),
            subtitle: _tr('Money you owe', 'Unadaiwa'),
            icon: Icons.arrow_upward_rounded,
            active: !isReceivable,
            activeColor: AppColors.error,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: active ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 18,
                  color: active ? Colors.white : AppColors.textMuted),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: active ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: active
                            ? Colors.white70
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Amount Card ───────────────────────────────────────────────────────────────

class _AmountCard extends StatelessWidget {
  final TextEditingController controller;
  final bool isReceivable;

  const _AmountCard({
    required this.controller,
    required this.isReceivable,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navyPrimary, Color(0xFF003153)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isReceivable
                ? _tr('Amount Owed to You', 'Kiasi Unachostahili')
                : _tr('Amount You Owe', 'Kiasi Unachoadaiwa'),
            style: GoogleFonts.dmSans(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Text(
                'TZS',
                style: GoogleFonts.dmSans(
                    color: Colors.white54,
                    fontSize: 18,
                    fontWeight: FontWeight.w500),
              ),
              SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    filled: false,
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: GoogleFonts.jetBrainsMono(
                        color: Colors.white30,
                        fontSize: 32,
                        fontWeight: FontWeight.w700),
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
        ],
      ),
    );
  }
}

// ── Due Date Row ─────────────────────────────────────────────────────────────

class _DueDateRow extends StatelessWidget {
  final DateTime dueDate;
  final VoidCallback onTap;

  const _DueDateRow({required this.dueDate, required this.onTap});

  String _daysLabel() {
    final diff = dueDate.difference(DateTime.now()).inDays;
    if (diff == 0) return _tr('today', 'leo');
    if (diff > 0) {
      return '${_tr('in', 'baada ya')} $diff ${_tr('days', 'siku')}';
    }
    return '${diff.abs()} ${_tr('days ago', 'siku zilizopita')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 18, color: AppColors.textSecondary),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _tr('Due Date', 'Tarehe ya Mwisho'),
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: AppColors.textMuted),
                  ),
                  Text(
                    _fmtDate(dueDate),
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navyPrimary),
                  ),
                ],
              ),
            ),
            Text(
              _daysLabel(),
              style: GoogleFonts.dmSans(
                  fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Save Button ───────────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  final bool saving;
  final bool isEdit;
  final bool isReceivable;
  final VoidCallback onTap;

  const _SaveButton({
    required this.saving,
    required this.isEdit,
    required this.isReceivable,
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
            borderRadius: BorderRadius.circular(16),
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
