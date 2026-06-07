import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/customer_picker_field.dart';
import '../../../customer/data/customer_providers.dart';
import '../../../customer/domain/models/customer.dart';
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

class _AddDebtScreenState extends ConsumerState<AddDebtScreen>
    with TickerProviderStateMixin {
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

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _isReceivable = widget.initialIsReceivable;
    _dueDate = DateTime.now().add(const Duration(days: 30));

    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

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
    _fadeCtrl.dispose();
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

      final repo = ref.read(contextFirestoreRepositoryProvider);
      final ctx = await repo.resolveContextForUser(user.uid);
      final col = repo.scopeCollection(
          uid: user.uid, context: ctx, childCollection: 'debts');

      final amount = double.tryParse(
              _amountCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ??
          0;
      final now = DateTime.now().toIso8601String();

      final data = <String, dynamic>{
        'partyName': _nameCtrl.text.trim(),
        if (_phoneCtrl.text.trim().isNotEmpty)
          'partyPhone': _phoneCtrl.text.trim(),
        if (_linkedCustomer != null) 'customerId': _linkedCustomer!.id,
        'type': _isReceivable ? 'receivable' : 'payable',
        'originalAmount': amount,
        'paidAmount': widget.debtToEdit?.paidAmount ?? 0,
        'dueDate': _fmtDate(_dueDate),
        'status': 'current',
        if (_invoiceCtrl.text.trim().isNotEmpty)
          'invoiceRef': _invoiceCtrl.text.trim(),
        if (_noteCtrl.text.trim().isNotEmpty) 'note': _noteCtrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.debtToEdit != null) {
        await col.doc(widget.debtToEdit!.id).update(data);
      } else {
        data['createdBy'] = user.uid;
        data['createdAt'] = now;
        await col.add(data);
      }

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
    final accentColor =
        _isReceivable ? AppColors.success : AppColors.error;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.navyPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          isEdit
              ? _tr('Edit Entry', 'Hariri Rekodi')
              : _isReceivable
                  ? _tr('Add Receivable', 'Ongeza Dai')
                  : _tr('Add Payable', 'Ongeza Deni'),
          style: GoogleFonts.dmSans(
              color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: [
              // Type toggle (only when adding new)
              if (!isEdit) ...[
                _TypeToggle(
                  isReceivable: _isReceivable,
                  onChanged: (v) => setState(() => _isReceivable = v),
                ),
                const SizedBox(height: 16),
              ],

              // Amount card
              _AmountCard(
                controller: _amountCtrl,
                accentColor: accentColor,
                isReceivable: _isReceivable,
              ),
              const SizedBox(height: 14),

              // Customer link (receivables only — suppliers aren't in customer DB)
              if (_isReceivable) ...[
                CustomerPickerField(
                  selected: _linkedCustomer,
                  onSelected: _selectCustomer,
                  labelEn: 'Link to Customer (optional)',
                  labelSw: 'Unganisha na Mteja (si lazima)',
                ),
                const SizedBox(height: 14),
              ],

              // Party details
              _FieldCard(
                children: [
                  _LabeledField(
                    label: _isReceivable
                        ? _tr('Customer Name', 'Jina la Mteja')
                        : _tr('Supplier Name', 'Jina la Muuzaji'),
                    child: TextFormField(
                      controller: _nameCtrl,
                      decoration: _fieldDecoration(
                        hint: _isReceivable
                            ? _tr('e.g. John Mwangi', 'mfano: John Mwangi')
                            : _tr('e.g. ABC Suppliers', 'mfano: ABC Suppliers'),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? _tr('Name is required', 'Jina linahitajika')
                          : null,
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  _LabeledField(
                    label: _tr('Phone Number', 'Namba ya Simu'),
                    child: TextFormField(
                      controller: _phoneCtrl,
                      decoration: _fieldDecoration(
                          hint: _tr('+255 7XX XXX XXX', '+255 7XX XXX XXX')),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Due date
              _FieldCard(
                children: [
                  _LabeledField(
                    label: _tr('Due Date', 'Tarehe ya Mwisho'),
                    child: GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 16, color: accentColor),
                            const SizedBox(width: 10),
                            Text(
                              _fmtDate(_dueDate),
                              style: GoogleFonts.jetBrainsMono(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary),
                            ),
                            const Spacer(),
                            Text(
                              _daysLabel(),
                              style: GoogleFonts.dmSans(
                                  fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Invoice ref & note
              _FieldCard(
                children: [
                  _LabeledField(
                    label: _tr('Invoice / Ref # (optional)',
                        'Nambari ya Ankara (hiari)'),
                    child: TextFormField(
                      controller: _invoiceCtrl,
                      decoration: _fieldDecoration(hint: 'INV-001'),
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  _LabeledField(
                    label: _tr('Note (optional)', 'Maelezo (hiari)'),
                    child: TextFormField(
                      controller: _noteCtrl,
                      decoration: _fieldDecoration(
                          hint: _tr('Any additional details…',
                              'Maelezo zaidi…')),
                      maxLines: 3,
                      minLines: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: _saving ? AppColors.border : accentColor,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  isEdit
                      ? _tr('Save Changes', 'Hifadhi Mabadiliko')
                      : _isReceivable
                          ? _tr('Add Receivable', 'Ongeza Dai')
                          : _tr('Add Payable', 'Ongeza Deni'),
                  style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
        ),
      ),
    );
  }

  String _daysLabel() {
    final diff = _dueDate.difference(DateTime.now()).inDays;
    if (diff == 0) return _tr('today', 'leo');
    if (diff > 0) return '${_tr('in', 'baada ya')} $diff ${_tr('days', 'siku')}';
    return '${diff.abs()} ${_tr('days ago', 'siku zilizopita')}';
  }

  InputDecoration _fieldDecoration({String? hint}) => InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.dmSans(fontSize: 14, color: AppColors.textDisabled),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.navyPrimary, width: 1.5),
        ),
      );
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
        color: Colors.white,
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
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            color: active ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 18,
                  color: active ? Colors.white : AppColors.textMuted),
              const SizedBox(width: 8),
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
  final Color accentColor;
  final bool isReceivable;

  const _AmountCard({
    required this.controller,
    required this.accentColor,
    required this.isReceivable,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navyPrimary, Color(0xFF003153)],
        ),
        borderRadius: BorderRadius.circular(18),
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
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'TZS',
                style: GoogleFonts.dmSans(
                    color: Colors.white54,
                    fontSize: 18,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: GoogleFonts.jetBrainsMono(
                        color: Colors.white30,
                        fontSize: 34,
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
          const SizedBox(height: 8),
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }
}

// ── Field Card & helpers ──────────────────────────────────────────────────────

class _FieldCard extends StatelessWidget {
  final List<Widget> children;
  const _FieldCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

