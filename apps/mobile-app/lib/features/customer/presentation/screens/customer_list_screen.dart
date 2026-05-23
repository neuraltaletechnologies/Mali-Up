import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../data/customer_providers.dart';
import '../../domain/models/customer.dart';
import '../widgets/add_customer_dialog.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

String _fmtCustomerBalance(double amount) {
  if (amount >= 1_000_000) {
    return 'TSh ${(amount / 1_000_000).toStringAsFixed(1)}M';
  }
  if (amount >= 1_000) return 'TSh ${(amount / 1_000).toStringAsFixed(0)}K';
  return 'TSh ${amount.toStringAsFixed(0)}';
}

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customers = ref.watch(customerListProvider);
    final allCustomers = customers.maybeWhen(
      data: (items) => items,
      orElse: () => const [],
    );

    // Filter customers based on search
    final filteredCustomers = _searchController.text.isEmpty
        ? allCustomers
        : allCustomers
            .where((customer) =>
                customer.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                customer.phone.toLowerCase().contains(_searchController.text.toLowerCase()))
            .toList();

    final totalBalance = filteredCustomers.fold<double>(
      0,
      (sum, c) => sum + (double.tryParse(c.balance) ?? 0),
    );

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _tr('Active Customers', 'Wateja Hai'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: _tr('Search by name or phone...', 'Tafuta kwa jina au simu...'),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                filled: true,
                fillColor: AppColors.card,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),

          // CRM Summary Header - Compact card style
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _CompactStat(
                  label: _tr('Clients', 'Wateja'),
                  value: '${filteredCustomers.length}',
                  icon: Icons.people_alt_outlined,
                ),
                Container(width: 1, height: 20, color: AppColors.border),
                _CompactStat(
                  label: _tr('Balance', 'Salio'),
                  value: _fmtBalance(totalBalance),
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: customers.isLoading
                ? const CustomerPageSkeleton()
                : filteredCustomers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _tr('No customers found', 'Hakuna wateja waliofumanwa'),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        itemCount: filteredCustomers.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final customer = filteredCustomers[index];
                          return _CustomerCard(customer: customer);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCustomerDialog(context, ref),
        backgroundColor: AppColors.primary,
        child: const Icon(
          Icons.person_add_alt_1_rounded,
          color: AppColors.secondary,
        ),
      ),
    );
  }

  static String _fmtBalance(double amount) {
    if (amount >= 1_000_000) {
      return 'TSh ${(amount / 1_000_000).toStringAsFixed(1)}M';
    }
    if (amount >= 1_000) {
      return 'TSh ${(amount / 1_000).toStringAsFixed(0)}K';
    }
    return 'TSh ${amount.toStringAsFixed(0)}';
  }

  void _showAddCustomerDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddCustomerDialog(),
    );
  }
}

class _CompactStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _CompactStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}


class _CustomerCard extends ConsumerWidget {
  final Customer customer;
  const _CustomerCard({required this.customer});

  Future<void> _deleteCustomer(BuildContext context, WidgetRef ref) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final repo = ref.read(contextFirestoreRepositoryProvider);
      final ctx = await repo.resolveContextForUser(user.uid);
      await repo
          .scopeCollection(uid: user.uid, context: ctx, childCollection: 'customers')
          .doc(customer.id)
          .delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_tr('Customer deleted', 'Mteja amefutwa')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_tr('Failed to delete. Try again.', 'Imeshindikana kufuta. Jaribu tena.')),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rawBalance = double.tryParse(customer.balance) ?? 0;
    final hasBalance = rawBalance > 0;

    return Dismissible(
      key: ValueKey(customer.id),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Right swipe → Edit
          await showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            useSafeArea: true,
            builder: (_) => _EditCustomerSheet(customer: customer),
          );
          return false;
        } else {
          // Left swipe → Delete confirmation
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                _tr('Delete Customer?', 'Futa Mteja?'),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              content: Text(
                _tr(
                  'Delete "${customer.name}"? This cannot be undone.',
                  'Futa "${customer.name}"? Hii haiwezi kutenduliwa.',
                ),
                style: theme.textTheme.bodyMedium,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(
                    _tr('Cancel', 'Ghairi'),
                    style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  child: Text(
                    _tr('Delete', 'Futa'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            await _deleteCustomer(context, ref);
            return true;
          }
          return false;
        }
      },
      background: Container(
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_rounded, color: AppColors.primary, size: 22),
            const SizedBox(height: 4),
            Text(
              _tr('Edit', 'Hariri'),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 22),
            const SizedBox(height: 4),
            Text(
              _tr('Delete', 'Futa'),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowCard,
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  customer.name[0],
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(customer.phone, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _tr('Outstanding Balance', 'Salio Linalodaiwa'),
                    style: theme.textTheme.labelSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _fmtCustomerBalance(rawBalance),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: hasBalance ? AppColors.error : AppColors.textMuted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 8,
                children: customer.tags
                    .map<Widget>(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Text(
                          tag,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              Text(
                '${_tr('Last Tx', 'Muamala wa Mwisho')}: ${customer.lastTransactionDate}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}

// ── Edit Customer Sheet ───────────────────────────────────────────────────────

class _EditCustomerSheet extends ConsumerStatefulWidget {
  final Customer customer;
  const _EditCustomerSheet({required this.customer});

  @override
  ConsumerState<_EditCustomerSheet> createState() => _EditCustomerSheetState();
}

class _EditCustomerSheetState extends ConsumerState<_EditCustomerSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _tinCtrl;
  late final TextEditingController _addressCtrl;
  late bool _isOrg;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl    = TextEditingController(text: widget.customer.name);
    _phoneCtrl   = TextEditingController(text: widget.customer.phone);
    _emailCtrl   = TextEditingController(text: widget.customer.email);
    _tinCtrl     = TextEditingController(text: widget.customer.tinNumber);
    _addressCtrl = TextEditingController(text: widget.customer.address);
    _isOrg       = widget.customer.isOrganisation;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _tinCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final nav = Navigator.of(context);
    final msg = ScaffoldMessenger.of(context);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');
      final repo = ref.read(contextFirestoreRepositoryProvider);
      final ctx  = await repo.resolveContextForUser(user.uid);

      final updates = <String, dynamic>{
        'name':           _nameCtrl.text.trim(),
        'phone':          _phoneCtrl.text.trim(),
        'email':          _emailCtrl.text.trim(),
        'isOrganisation': _isOrg,
        'address':        _addressCtrl.text.trim(),
        'updatedAt':      FieldValue.serverTimestamp(),
      };
      final tin = _tinCtrl.text.trim();
      if (tin.isNotEmpty) updates['tinNumber'] = tin;

      await repo
          .scopeCollection(uid: user.uid, context: ctx, childCollection: 'customers')
          .doc(widget.customer.id)
          .update(updates);

      nav.pop();
      msg.showSnackBar(SnackBar(
        content: Text(_tr('Customer updated', 'Mteja amesasishwa')),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      msg.showSnackBar(SnackBar(
        content: Text(_tr('Failed to update. Try again.', 'Imeshindikana kusasisha. Jaribu tena.')),
      ));
    }
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20, 12, 20, 20 + MediaQuery.of(context).viewInsets.bottom,
          ),
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
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _tr('Edit Customer', 'Hariri Mteja'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Individual / Organisation toggle
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _TypeToggleBtn(
                          label: _tr('Individual', 'Mtu Binafsi'),
                          icon: Icons.person_outline_rounded,
                          active: !_isOrg,
                          onTap: () => setState(() => _isOrg = false),
                        ),
                        const SizedBox(width: 4),
                        _TypeToggleBtn(
                          label: _tr('Organisation', 'Shirika'),
                          icon: Icons.business_outlined,
                          active: _isOrg,
                          onTap: () => setState(() => _isOrg = true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: _dec(
                      _isOrg
                          ? _tr('Organisation Name *', 'Jina la Shirika *')
                          : _tr('Customer Name *', 'Jina la Mteja *'),
                      _isOrg ? Icons.business_outlined : Icons.person_outline_rounded,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? _tr('Please enter a name', 'Tafadhali weka jina')
                        : null,
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: _dec(
                      _tr('Phone Number *', 'Namba ya Simu *'),
                      Icons.phone_outlined,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? _tr('Please enter phone number', 'Tafadhali weka namba ya simu')
                        : null,
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _dec(
                      _tr('Email (Optional)', 'Barua pepe (Hiari)'),
                      Icons.email_outlined,
                    ),
                  ),

                  if (_isOrg) ...[
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _tinCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: _dec(
                        _tr('TIN Number (Optional)', 'Namba ya TIN (Hiari)'),
                        Icons.numbers_outlined,
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _addressCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _dec(
                      _tr('Address (Optional)', 'Anwani (Hiari)'),
                      Icons.location_on_outlined,
                    ),
                  ),

                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(_tr('Cancel', 'Ghairi')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.secondary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.secondary,
                                  ),
                                )
                              : Text(
                                  _tr('Save Changes', 'Hifadhi Mabadiliko'),
                                  style: const TextStyle(fontWeight: FontWeight.w700),
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

class _TypeToggleBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _TypeToggleBtn({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.secondary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: active ? Colors.white : AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: active ? Colors.white : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
