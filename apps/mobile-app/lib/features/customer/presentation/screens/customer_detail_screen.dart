import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../sales/data/sales_providers.dart';
import '../../data/customer_providers.dart';
import '../../domain/models/customer.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

// Standard segment tags
const _kTagVip = 'VIP';
const _kTagWholesale = 'Jumla';
const _kTagRetail = 'Reja reja';
const _kTagBlacklisted = 'Orodha Nyeusi';
const _kStandardTags = [_kTagVip, _kTagWholesale, _kTagRetail, _kTagBlacklisted];

// Note types
enum _NoteType { note, call, email, meeting, reminder }

extension _NoteTypeX on _NoteType {
  String get label => switch (this) {
        _NoteType.note => _tr('Note', 'Kumbukumbu'),
        _NoteType.call => _tr('Call', 'Simu'),
        _NoteType.email => _tr('Email', 'Barua pepe'),
        _NoteType.meeting => _tr('Meeting', 'Mkutano'),
        _NoteType.reminder => _tr('Reminder', 'Kumbusho'),
      };

  IconData get icon => switch (this) {
        _NoteType.note => Icons.sticky_note_2_rounded,
        _NoteType.call => Icons.phone_rounded,
        _NoteType.email => Icons.email_rounded,
        _NoteType.meeting => Icons.handshake_rounded,
        _NoteType.reminder => Icons.alarm_rounded,
      };

  Color get color => switch (this) {
        _NoteType.note => AppColors.navyPrimary,
        _NoteType.call => AppColors.success,
        _NoteType.email => AppColors.tealAccent,
        _NoteType.meeting => const Color(0xFFB45309),
        _NoteType.reminder => AppColors.warning,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  ConsumerState<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen>
    with TickerProviderStateMixin {
  late Customer _customer;
  late TabController _tabCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
    _tabCtrl = TabController(length: 3, vsync: this);
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  void _callCustomer() async {
    if (_customer.phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: _customer.phone);
    await launchUrl(uri);
  }

  void _whatsappCustomer() async {
    if (_customer.phone.isEmpty) return;
    final phone = _customer.phone.replaceAll(RegExp(r'[^0-9+]'), '');
    await launchUrl(Uri.parse('https://wa.me/$phone'),
        mode: LaunchMode.externalApplication);
  }

  void _sendReminder() async {
    final balance = double.tryParse(_customer.balance) ?? 0;
    if (balance <= 0) {
      _showSnack(_tr('No outstanding balance', 'Hakuna deni linalodaiwa'));
      return;
    }

    // Build overdue invoices for message
    final invoices = ref
        .read(customerInvoicesProvider(_customer.id))
        .maybeWhen(data: (d) => d, orElse: () => <Map<String, dynamic>>[]);
    final overdue = invoices.where((inv) {
      final s = (inv['status'] ?? '').toString().toLowerCase();
      return s != 'paid' && s != 'cancelled' && s != 'draft';
    }).toList();

    final phone = _customer.phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final msg = _buildReminderText(_customer, balance, overdue);
    final url = 'https://wa.me/$phone?text=${Uri.encodeComponent(msg)}';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

    // Log the reminder as a note
    await _saveNote(
      type: _NoteType.reminder,
      text: _tr('Payment reminder sent via WhatsApp',
          'Kumbusho la malipo kilitumwa kupitia WhatsApp'),
    );
  }

  String _buildReminderText(
      Customer c, double balance, List<Map<String, dynamic>> overdue) {
    final buf = StringBuffer();
    buf.writeln(_tr('Dear *${c.name}*,', 'Ndugu *${c.name}*,'));
    buf.writeln('');
    buf.writeln(_tr(
        'This is a friendly reminder of your outstanding balance with us.',
        'Hii ni ukumbusho wa kirafiki wa salio lako linalodaiwa kwetu.'));
    buf.writeln('');
    if (overdue.isNotEmpty) {
      buf.writeln(_tr('Unpaid invoices:', 'Ankara ambazo hazijalipwa:'));
      for (final inv in overdue.take(5)) {
        final num = inv['invoiceNumber']?.toString() ?? inv['id']?.toString() ?? '';
        final amt = parseNumericAmount(inv['totalAmount']);
        buf.writeln('• $num — TZS ${_fmtNum(amt)}');
      }
      buf.writeln('');
    }
    buf.writeln(
        '*${_tr('Total Outstanding: TZS ${_fmtNum(balance)}', 'Jumla Inayodaiwa: TZS ${_fmtNum(balance)}')}*');
    buf.writeln('');
    buf.writeln(_tr('Please arrange payment at your earliest convenience.',
        'Tafadhali panga malipo haraka iwezekanavyo.'));
    buf.writeln(_tr('Thank you!', 'Asante!'));
    return buf.toString();
  }

  Future<void> _saveNote({
    required _NoteType type,
    required String text,
    DateTime? scheduledFor,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final repo = ref.read(contextFirestoreRepositoryProvider);
      final ctx = await repo.resolveContextForUser(user.uid);
      final customersCol = repo.scopeCollection(
          uid: user.uid, context: ctx, childCollection: 'customers');
      await customersCol.doc(_customer.id).collection('notes').add({
        'type': type.name,
        'text': text,
        'addedAt': FieldValue.serverTimestamp(),
        if (scheduledFor != null)
          'scheduledFor': Timestamp.fromDate(scheduledFor),
        if (type == _NoteType.reminder) 'reminderSent': false,
      });
    } catch (_) {}
  }

  Future<void> _updateTags(List<String> newTags) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final repo = ref.read(contextFirestoreRepositoryProvider);
      final ctx = await repo.resolveContextForUser(user.uid);
      await repo
          .scopeCollection(uid: user.uid, context: ctx, childCollection: 'customers')
          .doc(_customer.id)
          .update({'tags': newTags, 'updatedAt': FieldValue.serverTimestamp()});
      setState(() => _customer = _customer.copyWith(tags: newTags));
    } catch (e) {
      _showSnack(_tr('Update failed', 'Imeshindwa kusasisha'));
    }
  }

  Future<void> _updateCreditLimit(double limit) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final repo = ref.read(contextFirestoreRepositoryProvider);
      final ctx = await repo.resolveContextForUser(user.uid);
      await repo
          .scopeCollection(uid: user.uid, context: ctx, childCollection: 'customers')
          .doc(_customer.id)
          .update({'creditLimit': limit, 'updatedAt': FieldValue.serverTimestamp()});
      setState(() => _customer = _customer.copyWith(creditLimit: limit));
      _showSnack(_tr('Credit limit updated', 'Kikomo cha mkopo kimesasishwa'));
    } catch (_) {}
  }

  void _openEdit() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => _EditCustomerFullSheet(
        customer: _customer,
        onSaved: (updated) => setState(() => _customer = updated),
      ),
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── UI ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            _buildSliverAppBar(),
            SliverToBoxAdapter(child: _buildTabBar()),
          ],
          body: TabBarView(
            controller: _tabCtrl,
            children: [
              _OverviewTab(
                customer: _customer,
                onTagsChanged: _updateTags,
                onCreditLimitSave: _updateCreditLimit,
                onCall: _callCustomer,
                onWhatsApp: _whatsappCustomer,
                onReminder: _sendReminder,
              ),
              _InvoicesTab(customerId: _customer.id),
              _NotesTab(
                customerId: _customer.id,
                customerName: _customer.name,
                onAddNote: _showAddNoteSheet,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final balance = double.tryParse(_customer.balance) ?? 0;
    final hasBalance = balance > 0;
    final initials = _customer.name.isNotEmpty
        ? _customer.name
            .trim()
            .split(' ')
            .take(2)
            .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
            .join()
        : '?';

    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: AppColors.navyPrimary,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_rounded, size: 20),
          tooltip: _tr('Edit', 'Hariri'),
          onPressed: _openEdit,
        ),
        IconButton(
          icon: const Icon(Icons.phone_rounded, size: 20),
          tooltip: _tr('Call', 'Piga Simu'),
          onPressed: _callCustomer,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.navyPrimary,
                AppColors.navyPrimary.withValues(alpha: 0.85),
                AppColors.navySecondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Hero(
                    tag: 'customer-${_customer.id}',
                    child: CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      child: Text(
                        initials,
                        style: GoogleFonts.dmSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Name + meta
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _customer.name,
                                style: GoogleFonts.dmSans(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_customer.isOrganisation)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  _tr('ORG', 'SHIRIKA'),
                                  style: GoogleFonts.dmSans(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white70),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (_customer.phone.isNotEmpty)
                          Text(_customer.phone,
                              style: GoogleFonts.dmSans(
                                  fontSize: 13, color: Colors.white60)),
                        const SizedBox(height: 12),
                        // Tags row
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: _customer.tags.map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.25)),
                              ),
                              child: Text(
                                tag,
                                style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        // Balance
                        Row(
                          children: [
                            Text(
                              _tr('Balance: ', 'Salio: '),
                              style: GoogleFonts.dmSans(
                                  fontSize: 12, color: Colors.white54),
                            ),
                            Text(
                              hasBalance
                                  ? 'TZS ${_fmtNum(balance)}'
                                  : _tr('No outstanding balance',
                                      'Hakuna deni'),
                              style: GoogleFonts.dmSerifDisplay(
                                fontSize: 16,
                                color: hasBalance
                                    ? const Color(0xFFFC8181)
                                    : const Color(0xFF86EFAC),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          TabBar(
            controller: _tabCtrl,
            labelStyle: GoogleFonts.dmSans(
                fontSize: 13, fontWeight: FontWeight.w700),
            unselectedLabelStyle:
                GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500),
            labelColor: AppColors.navyPrimary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.navyPrimary,
            indicatorWeight: 2.5,
            tabs: [
              Tab(text: _tr('Overview', 'Muhtasari')),
              Tab(text: _tr('Invoices', 'Ankara')),
              Tab(text: _tr('Notes', 'Logi')),
            ],
          ),
          const Divider(height: 1, color: AppColors.border),
        ],
      ),
    );
  }

  void _showAddNoteSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddNoteSheet(
        onSave: (type, text, scheduledFor) async {
          await _saveNote(
              type: type, text: text, scheduledFor: scheduledFor);
          if (mounted) Navigator.of(context).pop();
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — Overview
// ─────────────────────────────────────────────────────────────────────────────

class _OverviewTab extends StatefulWidget {
  final Customer customer;
  final ValueChanged<List<String>> onTagsChanged;
  final ValueChanged<double> onCreditLimitSave;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;
  final VoidCallback onReminder;

  const _OverviewTab({
    required this.customer,
    required this.onTagsChanged,
    required this.onCreditLimitSave,
    required this.onCall,
    required this.onWhatsApp,
    required this.onReminder,
  });

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  late List<String> _tags;
  final _limitCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tags = List.from(widget.customer.tags);
    _limitCtrl.text = widget.customer.creditLimit > 0
        ? widget.customer.creditLimit.toStringAsFixed(0)
        : '';
  }

  @override
  void dispose() {
    _limitCtrl.dispose();
    super.dispose();
  }

  void _toggleTag(String tag) {
    final updated = List<String>.from(_tags);
    if (updated.contains(tag)) {
      updated.remove(tag);
    } else {
      updated.add(tag);
    }
    setState(() => _tags = updated);
    widget.onTagsChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final balance = double.tryParse(widget.customer.balance) ?? 0;
    final limit = widget.customer.creditLimit;
    final c = widget.customer;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        // Quick actions
        _QuickActions(
          onCall: widget.onCall,
          onWhatsApp: widget.onWhatsApp,
          onReminder: widget.onReminder,
        ),
        const SizedBox(height: 16),
        // Balance + credit limit card
        _BalanceCard(
          balance: balance,
          limit: limit,
          limitCtrl: _limitCtrl,
          onSaveLimit: (v) => widget.onCreditLimitSave(v),
        ),
        const SizedBox(height: 16),
        // Contact info
        _ContactCard(customer: c),
        const SizedBox(height: 16),
        // Segmentation tags
        _TagsCard(
          tags: _tags,
          standardTags: _kStandardTags,
          onToggle: _toggleTag,
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;
  final VoidCallback onReminder;

  const _QuickActions(
      {required this.onCall,
      required this.onWhatsApp,
      required this.onReminder});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionBtn(
            icon: Icons.phone_rounded,
            label: _tr('Call', 'Simu'),
            color: AppColors.success,
            onTap: onCall,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionBtn(
            icon: Icons.chat_rounded,
            label: 'WhatsApp',
            color: const Color(0xFF25D366),
            onTap: onWhatsApp,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionBtn(
            icon: Icons.alarm_rounded,
            label: _tr('Remind', 'Kumbushia'),
            color: AppColors.warning,
            onTap: onReminder,
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 6),
            Text(label,
                style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatefulWidget {
  final double balance;
  final double limit;
  final TextEditingController limitCtrl;
  final ValueChanged<double> onSaveLimit;

  const _BalanceCard({
    required this.balance,
    required this.limit,
    required this.limitCtrl,
    required this.onSaveLimit,
  });

  @override
  State<_BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<_BalanceCard> {
  bool _editingLimit = false;

  @override
  Widget build(BuildContext context) {
    final hasLimit = widget.limit > 0;
    final progress =
        hasLimit ? (widget.balance / widget.limit).clamp(0.0, 1.0) : 0.0;
    final overLimit = hasLimit && widget.balance > widget.limit;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
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
                      _tr('Outstanding Balance', 'Deni Linalodaiwa'),
                      style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          letterSpacing: 0.4),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.balance > 0
                          ? 'TZS ${_fmtNum(widget.balance)}'
                          : _tr('All clear', 'Hakuna deni'),
                      style: GoogleFonts.dmSerifDisplay(
                          fontSize: 24,
                          color: widget.balance > 0
                              ? AppColors.error
                              : AppColors.success),
                    ),
                  ],
                ),
              ),
              if (overLimit)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _tr('OVER LIMIT', 'IMEZIDI'),
                    style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error),
                  ),
                ),
            ],
          ),
          if (hasLimit) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation(
                    overLimit ? AppColors.error : AppColors.warning),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).toStringAsFixed(0)}% ${_tr('of limit used', 'ya kikomo kimetumika')}',
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: AppColors.textMuted),
                ),
                Text(
                  _tr('Limit: TZS ${_fmtNum(widget.limit)}',
                      'Kikomo: TZS ${_fmtNum(widget.limit)}'),
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          // Credit limit editor
          if (_editingLimit)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.limitCtrl,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: GoogleFonts.jetBrainsMono(fontSize: 14),
                    decoration: InputDecoration(
                      prefixText: 'TZS ',
                      prefixStyle: GoogleFonts.dmSans(
                          fontSize: 12, color: AppColors.textMuted),
                      hintText:
                          _tr('0 = no limit', '0 = bila kikomo'),
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    final v = double.tryParse(widget.limitCtrl.text) ?? 0;
                    widget.onSaveLimit(v);
                    setState(() => _editingLimit = false);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navyPrimary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(_tr('Save', 'Hifadhi'),
                      style: GoogleFonts.dmSans(fontSize: 13)),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => setState(() => _editingLimit = false),
                  child: const Icon(Icons.close_rounded,
                      size: 18, color: AppColors.textMuted),
                ),
              ],
            )
          else
            GestureDetector(
              onTap: () => setState(() => _editingLimit = true),
              child: Row(
                children: [
                  const Icon(Icons.credit_score_rounded,
                      size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    hasLimit
                        ? _tr('Edit credit limit',
                            'Badilisha kikomo cha mkopo')
                        : _tr('Set credit limit',
                            'Weka kikomo cha mkopo'),
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: AppColors.navyPrimary,
                        fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded,
                      size: 16, color: AppColors.textMuted),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final Customer customer;
  const _ContactCard({required this.customer});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          if (customer.phone.isNotEmpty)
            _ContactRow(
              icon: Icons.phone_rounded,
              label: _tr('Phone', 'Simu'),
              value: customer.phone,
              onTap: () async {
                await Clipboard.setData(
                    ClipboardData(text: customer.phone));
              },
            ),
          if (customer.email.isNotEmpty) ...[
            const Divider(height: 1, color: AppColors.border),
            _ContactRow(
              icon: Icons.email_rounded,
              label: _tr('Email', 'Barua pepe'),
              value: customer.email,
            ),
          ],
          if (customer.address.isNotEmpty) ...[
            const Divider(height: 1, color: AppColors.border),
            _ContactRow(
              icon: Icons.location_on_rounded,
              label: _tr('Address', 'Anwani'),
              value: customer.address,
            ),
          ],
          if (customer.tinNumber.isNotEmpty) ...[
            const Divider(height: 1, color: AppColors.border),
            _ContactRow(
              icon: Icons.numbers_rounded,
              label: 'TIN',
              value: customer.tinNumber,
            ),
          ],
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _ContactRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.dmSans(
                          fontSize: 10, color: AppColors.textMuted)),
                  Text(value,
                      style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary)),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.copy_rounded,
                  size: 14, color: AppColors.textDisabled),
          ],
        ),
      ),
    );
  }
}

class _TagsCard extends StatelessWidget {
  final List<String> tags;
  final List<String> standardTags;
  final ValueChanged<String> onToggle;

  const _TagsCard(
      {required this.tags,
      required this.standardTags,
      required this.onToggle});

  Color _color(String tag) {
    final t = tag.toLowerCase();
    if (t == 'vip') return const Color(0xFFB45309);
    if (t.contains('nyeusi') || t.contains('black')) return AppColors.error;
    if (t.contains('jumla') || t.contains('wholesale')) {
      return AppColors.tealAccent;
    }
    return AppColors.navySecondary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _tr('Segment Tags', 'Lebo za Kundi'),
            style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: standardTags.map((tag) {
              final active = tags.contains(tag);
              final color = _color(tag);
              return GestureDetector(
                onTap: () => onToggle(tag),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? color : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: active ? color : AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (active)
                        Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: Icon(Icons.check_rounded,
                              size: 13, color: Colors.white),
                        ),
                      Text(
                        tag,
                        style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: active ? Colors.white : AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (tags.any((t) => !standardTags.contains(t))) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 10),
            Text(
              _tr('Custom Tags', 'Lebo za Mtumiaji'),
              style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: AppColors.textMuted),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags
                  .where((t) => !standardTags.contains(t))
                  .map((tag) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.navyPrimary
                              .withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(tag,
                            style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: AppColors.navyPrimary)),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — Invoices
// ─────────────────────────────────────────────────────────────────────────────

class _InvoicesTab extends ConsumerWidget {
  final String customerId;
  const _InvoicesTab({required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(customerInvoicesProvider(customerId));

    return invoicesAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(
              color: AppColors.navyPrimary, strokeWidth: 2)),
      error: (e, _) => Center(child: Text('$e')),
      data: (invoices) {
        if (invoices.isEmpty) {
          return _EmptyState(
            icon: Icons.receipt_long_rounded,
            message: _tr('No invoices yet', 'Hakuna ankara bado'),
          );
        }

        // Stats row
        final totalPaid = invoices
            .where((i) =>
                (i['status'] ?? '').toString().toLowerCase() == 'paid')
            .fold<double>(0, (s, i) => s + parseNumericAmount(i['totalAmount']));
        final totalPending = invoices
            .where((i) {
              final s = (i['status'] ?? '').toString().toLowerCase();
              return s != 'paid' && s != 'cancelled' && s != 'draft';
            })
            .fold<double>(0, (s, i) => s + parseNumericAmount(i['totalAmount']));

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      label: _tr('Paid', 'Imelipwa'),
                      value: 'TZS ${_fmtShort(totalPaid)}',
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniStat(
                      label: _tr('Pending', 'Inasubiri'),
                      value: 'TZS ${_fmtShort(totalPending)}',
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniStat(
                      label: _tr('Total', 'Jumla'),
                      value: '${invoices.length}',
                      color: AppColors.navyPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 60),
                itemCount: invoices.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _InvoiceTile(invoice: invoices[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  final Map<String, dynamic> invoice;
  const _InvoiceTile({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final status = (invoice['status'] ?? 'pending').toString().toLowerCase();
    final total = parseNumericAmount(invoice['totalAmount']);
    final number = invoice['invoiceNumber']?.toString() ??
        invoice['id']?.toString() ??
        '—';
    final createdAt = readTimestamp(invoice['createdAt'] ?? invoice['invoiceDate']);
    final isQuotation =
        (invoice['type'] ?? '').toString().toLowerCase() == 'quotation';

    final statusColor = switch (status) {
      'paid' => AppColors.success,
      'sent' => AppColors.tealAccent,
      'overdue' => AppColors.error,
      'draft' => AppColors.textMuted,
      'cancelled' => AppColors.textDisabled,
      _ => AppColors.warning,
    };
    final statusLabel = switch (status) {
      'paid' => _tr('Paid', 'Imelipwa'),
      'sent' => _tr('Sent', 'Imetumwa'),
      'overdue' => _tr('Overdue', 'Imechelewa'),
      'draft' => _tr('Draft', 'Rasimu'),
      'cancelled' => _tr('Cancelled', 'Imefutwa'),
      _ => _tr('Pending', 'Inasubiri'),
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: statusColor, width: 3),
          right: const BorderSide(color: AppColors.border),
          top: const BorderSide(color: AppColors.border),
          bottom: const BorderSide(color: AppColors.border),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      number,
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                    if (isQuotation) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.tealAccent
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _tr('QUOTE', 'NUKUU'),
                          style: GoogleFonts.dmSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.tealAccent),
                        ),
                      ),
                    ],
                  ],
                ),
                if (createdAt != null)
                  Text(
                    _fmtDate(createdAt),
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'TZS ${_fmtNum(total)}',
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 3),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusColor),
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
// Tab 3 — Notes / Communication Log
// ─────────────────────────────────────────────────────────────────────────────

class _NotesTab extends ConsumerWidget {
  final String customerId;
  final String customerName;
  final VoidCallback onAddNote;

  const _NotesTab({
    required this.customerId,
    required this.customerName,
    required this.onAddNote,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(customerNotesProvider(customerId));

    return notesAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(
              color: AppColors.navyPrimary, strokeWidth: 2)),
      error: (e, _) => Center(child: Text('$e')),
      data: (notes) => Stack(
        children: [
          notes.isEmpty
              ? _EmptyState(
                  icon: Icons.chat_bubble_outline_rounded,
                  message: _tr('No notes yet — log a call, reminder or note',
                      'Hakuna logi bado — andika simu, kumbusho au kumbukumbu'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: notes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _NoteTile(note: notes[i]),
                ),
          // FAB-style add button
          Positioned(
            bottom: 20,
            right: 16,
            child: FloatingActionButton.extended(
              heroTag: 'add-note-fab',
              onPressed: onAddNote,
              backgroundColor: AppColors.navyPrimary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text(
                _tr('Add Note', 'Ongeza Logi'),
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  final Map<String, dynamic> note;
  const _NoteTile({required this.note});

  @override
  Widget build(BuildContext context) {
    final typeStr = (note['type'] ?? 'note').toString();
    final type = _NoteType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => _NoteType.note,
    );
    final text = note['text']?.toString() ?? '';
    final addedAt = readTimestamp(note['addedAt']);
    final scheduledFor = readTimestamp(note['scheduledFor']);
    final isReminder = type == _NoteType.reminder;
    final reminderSent = note['reminderSent'] as bool? ?? false;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: type.color, width: 3),
          right: const BorderSide(color: AppColors.border),
          top: const BorderSide(color: AppColors.border),
          bottom: const BorderSide(color: AppColors.border),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: type.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(type.icon, size: 15, color: type.color),
              ),
              const SizedBox(width: 8),
              Text(
                type.label,
                style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: type.color),
              ),
              const Spacer(),
              if (addedAt != null)
                Text(
                  _fmtDate(addedAt),
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: AppColors.textMuted),
                ),
            ],
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(text,
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: AppColors.textPrimary)),
          ],
          if (isReminder && scheduledFor != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 12,
                  color: reminderSent
                      ? AppColors.success
                      : AppColors.warning,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_tr("Scheduled:", "Imepangwa:")} ${_fmtDate(scheduledFor)}',
                  style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: reminderSent
                          ? AppColors.success
                          : AppColors.warning),
                ),
                if (reminderSent) ...[
                  const SizedBox(width: 6),
                  Text(
                    _tr('Sent', 'Imetumwa'),
                    style: GoogleFonts.dmSans(
                        fontSize: 10, color: AppColors.success),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Note Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AddNoteSheet extends StatefulWidget {
  final Future<void> Function(
      _NoteType type, String text, DateTime? scheduledFor) onSave;

  const _AddNoteSheet({required this.onSave});

  @override
  State<_AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends State<_AddNoteSheet> {
  _NoteType _type = _NoteType.note;
  final _textCtrl = TextEditingController();
  DateTime? _scheduledFor;
  bool _saving = false;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _scheduledFor = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _tr('Log Activity', 'Rekodi Shughuli'),
              style: GoogleFonts.dmSans(
                  fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            // Type selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _NoteType.values.map((t) {
                  final active = t == _type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _type = t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: active ? t.color : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: active ? t.color : AppColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(t.icon,
                                size: 13,
                                color: active ? Colors.white : t.color),
                            const SizedBox(width: 5),
                            Text(t.label,
                                style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: active
                                        ? Colors.white
                                        : AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
            // Text area
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _textCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: _type == _NoteType.call
                      ? _tr('What was discussed?', 'Nini kilijadiliwa?')
                      : _type == _NoteType.reminder
                          ? _tr('Reminder details…', 'Maelezo ya kumbusho…')
                          : _tr('Add notes…', 'Ongeza maelezo…'),
                  hintStyle: GoogleFonts.dmSans(
                      fontSize: 13, color: AppColors.textMuted),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
                style: GoogleFonts.dmSans(fontSize: 14),
              ),
            ),
            if (_type == _NoteType.reminder) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.alarm_rounded,
                          size: 16, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Text(
                        _scheduledFor != null
                            ? _fmtDate(_scheduledFor!)
                            : _tr('Set reminder date',
                                'Weka tarehe ya kumbusho'),
                        style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.warning),
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right_rounded,
                          size: 16, color: AppColors.warning),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving
                    ? null
                    : () async {
                        if (_textCtrl.text.trim().isEmpty) return;
                        setState(() => _saving = true);
                        await widget.onSave(
                          _type,
                          _textCtrl.text.trim(),
                          _scheduledFor,
                        );
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navyPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(
                        _tr('Save', 'Hifadhi'),
                        style: GoogleFonts.dmSans(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit Customer Full Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _EditCustomerFullSheet extends ConsumerStatefulWidget {
  final Customer customer;
  final ValueChanged<Customer> onSaved;

  const _EditCustomerFullSheet(
      {required this.customer, required this.onSaved});

  @override
  ConsumerState<_EditCustomerFullSheet> createState() =>
      _EditCustomerFullSheetState();
}

class _EditCustomerFullSheetState
    extends ConsumerState<_EditCustomerFullSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _tinCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _limitCtrl;
  late bool _isOrg;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _nameCtrl = TextEditingController(text: c.name);
    _phoneCtrl = TextEditingController(text: c.phone);
    _emailCtrl = TextEditingController(text: c.email);
    _tinCtrl = TextEditingController(text: c.tinNumber);
    _addressCtrl = TextEditingController(text: c.address);
    _limitCtrl = TextEditingController(
        text: c.creditLimit > 0 ? c.creditLimit.toStringAsFixed(0) : '');
    _isOrg = c.isOrganisation;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _tinCtrl.dispose();
    _addressCtrl.dispose();
    _limitCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');
      final repo = ref.read(contextFirestoreRepositoryProvider);
      final ctx = await repo.resolveContextForUser(user.uid);
      final limit = double.tryParse(_limitCtrl.text) ?? 0;

      final data = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'isOrganisation': _isOrg,
        'address': _addressCtrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (limit > 0) 'creditLimit': limit,
      };
      final tin = _tinCtrl.text.trim();
      if (tin.isNotEmpty) data['tinNumber'] = tin;

      await repo
          .scopeCollection(uid: user.uid, context: ctx, childCollection: 'customers')
          .doc(widget.customer.id)
          .update(data);

      final updated = widget.customer.copyWith(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        isOrganisation: _isOrg,
        address: _addressCtrl.text.trim(),
        tinNumber: _tinCtrl.text.trim(),
        creditLimit: limit,
      );

      widget.onSaved(updated);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmSans(fontSize: 13),
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.navyPrimary, width: 2),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(999)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _tr('Edit Profile', 'Hariri Wasifu'),
                    style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navyPrimary),
                  ),
                  const SizedBox(height: 16),
                  _TypeToggleRow(
                    isOrg: _isOrg,
                    onChanged: (v) => setState(() => _isOrg = v),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: _dec(
                      _isOrg
                          ? _tr('Organisation Name *', 'Jina la Shirika *')
                          : _tr('Customer Name *', 'Jina la Mteja *'),
                      _isOrg
                          ? Icons.business_outlined
                          : Icons.person_outline_rounded,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? _tr('Required', 'Inahitajika')
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration:
                        _dec(_tr('Phone *', 'Simu *'), Icons.phone_outlined),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? _tr('Required', 'Inahitajika')
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _dec(
                        _tr('Email', 'Barua pepe'), Icons.email_outlined),
                  ),
                  if (_isOrg) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _tinCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration:
                          _dec(_tr('TIN Number', 'Namba ya TIN'), Icons.numbers_outlined),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _dec(
                        _tr('Address', 'Anwani'), Icons.location_on_outlined),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _limitCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _dec(
                      _tr('Credit Limit (TZS)', 'Kikomo cha Mkopo (TZS)'),
                      Icons.credit_score_rounded,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(_tr('Cancel', 'Ghairi'),
                              style: GoogleFonts.dmSans()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.navyPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _saving
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Colors.white))
                              : Text(
                                  _tr('Save Changes', 'Hifadhi Mabadiliko'),
                                  style: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color),
              overflow: TextOverflow.ellipsis),
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: AppColors.textDisabled),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                    fontSize: 14, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual / Organisation toggle (duplicated from customer_list_screen)
// ─────────────────────────────────────────────────────────────────────────────

class _TypeToggleRow extends StatelessWidget {
  final bool isOrg;
  final ValueChanged<bool> onChanged;

  const _TypeToggleRow({required this.isOrg, required this.onChanged});

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
          _ToggleTab(
            label: _tr('Individual', 'Mtu Binafsi'),
            icon: Icons.person_outline_rounded,
            active: !isOrg,
            onTap: () => onChanged(false),
          ),
          const SizedBox(width: 4),
          _ToggleTab(
            label: _tr('Organisation', 'Shirika'),
            icon: Icons.business_outlined,
            active: isOrg,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _ToggleTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ToggleTab(
      {required this.label,
      required this.icon,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.navyPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: active ? Colors.white : AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: active ? Colors.white : AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _fmtNum(double v) {
  if (v == 0) return '0';
  final s = v.toStringAsFixed(0);
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

String _fmtShort(double v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
  return v.toStringAsFixed(0);
}

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
