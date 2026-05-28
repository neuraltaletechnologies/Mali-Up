import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/data/repositories/context_firestore_repository.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/customer_providers.dart';
import '../../domain/models/customer.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

class AddCustomerDialog extends ConsumerStatefulWidget {
  /// Optional callback invoked with the newly created [Customer].
  /// When provided the caller can select the customer immediately after creation.
  final void Function(Customer customer)? onAdded;

  /// Pre-fill the name field (e.g. from a search query that found no match).
  final String initialName;

  const AddCustomerDialog({
    super.key,
    this.onAdded,
    this.initialName = '',
  });

  @override
  ConsumerState<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends ConsumerState<AddCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _balanceController = TextEditingController(text: '0');
  final _tinController = TextEditingController();
  final _addressController = TextEditingController();
  final List<String> _tags = [];
  final _tagController = TextEditingController();
  bool _isLoading = false;
  bool _isImportingContact = false;
  bool _isOrganisation = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _balanceController.dispose();
    _tinController.dispose();
    _addressController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
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
                    _tr('Add New Customer', 'Ongeza Mteja Mpya'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.secondary,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Type toggle: Individual / Organisation
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isOrganisation = false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !_isOrganisation
                                    ? AppColors.secondary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person_outline_rounded,
                                    size: 16,
                                    color: !_isOrganisation
                                        ? Colors.white
                                        : AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _tr('Individual', 'Mtu Binafsi'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: !_isOrganisation
                                          ? Colors.white
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isOrganisation = true),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _isOrganisation
                                    ? AppColors.secondary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.business_outlined,
                                    size: 16,
                                    color: _isOrganisation
                                        ? Colors.white
                                        : AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _tr('Organisation', 'Shirika'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: _isOrganisation
                                          ? Colors.white
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading || _isImportingContact
                          ? null
                          : _addFromContacts,
                      icon: _isImportingContact
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.contacts_outlined),
                      label: Text(
                        _isImportingContact
                            ? _tr('Opening contacts...', 'Inafungua mawasiliano...')
                            : _tr('Add from Contacts', 'Ongeza kutoka Mawasiliano'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          _tr('or', 'au'),
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: _isOrganisation
                          ? _tr('Organisation Name *', 'Jina la Shirika *')
                          : _tr('Customer Name *', 'Jina la Mteja *'),
                      prefixIcon: Icon(
                        _isOrganisation
                            ? Icons.business_outlined
                            : Icons.person_outline_rounded,
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return _tr('Please enter a name', 'Tafadhali weka jina');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: _tr('Phone Number *', 'Namba ya Simu *'),
                      prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return _tr(
                          'Please enter phone number',
                          'Tafadhali weka namba ya simu',
                        );
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: _tr('Email (Optional)', 'Barua pepe (Hiari)'),
                      prefixIcon: const Icon(Icons.email_outlined, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),

                  if (_isOrganisation) ...[
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _tinController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: _tr('TIN Number (Optional)', 'Namba ya TIN (Hiari)'),
                        hintText: 'e.g. 100-123-456',
                        prefixIcon:
                            const Icon(Icons.numbers_outlined, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _addressController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: _tr('Address (Optional)', 'Anwani (Hiari)'),
                      prefixIcon:
                          const Icon(Icons.location_on_outlined, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              _isLoading ? null : () => Navigator.pop(context),
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
                          onPressed: _isLoading ? null : _addCustomer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.secondary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.secondary,
                                  ),
                                )
                              : Text(
                                  _tr('Add Customer', 'Ongeza Mteja'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
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

  void _addCustomer() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final customer = await _saveCustomer(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          balance: _balanceController.text.trim(),
          tags: _tags,
          isOrganisation: _isOrganisation,
          tinNumber: _tinController.text.trim(),
          address: _addressController.text.trim(),
        );
        if (mounted) {
          final messenger = ScaffoldMessenger.of(context);
          ref.invalidate(customerListProvider);
          Navigator.pop(context);
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                _tr(
                  'Customer added successfully',
                  'Mteja ameongezwa kwa mafanikio',
                ),
              ),
              backgroundColor: AppColors.success,
            ),
          );
          widget.onAdded?.call(customer);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_tr("Error", "Kosa")}: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addFromContacts() async {
    setState(() => _isImportingContact = true);

    try {
      // ── Permission check ────────────────────────────────────────────────
      final status = await Permission.contacts.request();
      if (status.isDenied) {
        _showSnackBar(
          _tr(
            'Contacts permission is required to import customers.',
            'Ruhusa ya mawasiliano inahitajika kuingiza wateja.',
          ),
          AppColors.error,
        );
        return;
      }

      if (status.isPermanentlyDenied) {
        if (!mounted) return;
        final open = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text(_tr(
              'Contacts permission required',
              'Ruhusa ya mawasiliano inahitajika',
            )),
            content: Text(_tr(
              'Please enable contacts permission in app settings.',
              'Tafadhali weka ruhusa ya mawasiliano katika mipangilio.',
            )),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(_tr('Cancel', 'Ghairi')),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(_tr('Open Settings', 'Fungua Mipangilio')),
              ),
            ],
          ),
        );
        if (open == true) openAppSettings();
        return;
      }

      // ── Phase 1: Load names fast (no properties) ─────────────────────
      // This call is much faster and lets us show the list immediately.
      final basicContacts = await FlutterContacts.getContacts();
      if (!mounted) return;

      // ── Phase 2: Open picker with progressive property loading ────────
      final selectedContacts = await _showContactPickerSheet(basicContacts);
      if (selectedContacts == null || selectedContacts.isEmpty) return;

      // ── Batch import with progress ────────────────────────────────────
      if (!mounted) return;
      final total = selectedContacts.length;
      var done = 0;

      // Show a progress snackbar that we update.
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(SnackBar(
        content: Text(_tr(
          'Importing contacts… 0 / $total',
          'Inaingiza mawasiliano… 0 / $total',
        )),
        duration: const Duration(seconds: 30),
        behavior: SnackBarBehavior.floating,
      ));

      for (final contact in selectedContacts) {
        final name = contact.displayName.trim();
        final phone = contact.phones.isNotEmpty
            ? contact.phones.first.number.trim()
            : '';
        if (name.isEmpty || phone.isEmpty) {
          done++;
          continue;
        }
        await _saveCustomer(
          name: name,
          phone: phone,
          email: '',
          balance: '0',
          tags: const ['Contact'],
          isOrganisation: false,
          tinNumber: '',
          address: '',
        );
        done++;
        if (mounted) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(_tr(
                'Importing contacts… $done / $total',
                'Inaingiza mawasiliano… $done / $total',
              )),
              duration: const Duration(seconds: 30),
              behavior: SnackBarBehavior.floating,
            ));
        }
      }

      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(
        content: Text(_tr(
          done == 1
              ? '1 customer added from contacts'
              : '$done customers added from contacts',
          done == 1
              ? 'Mteja 1 ameongezwa kutoka mawasiliano'
              : 'Wateja $done wameongezwa kutoka mawasiliano',
        )),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      _showSnackBar(
        '${_tr("Error", "Kosa")}: ${e.toString()}',
        AppColors.error,
      );
    } finally {
      if (mounted) setState(() => _isImportingContact = false);
    }
  }

  /// Shows a bottom sheet contact picker.
  ///
  /// Contacts start with names only (fast Phase 1 load). Properties
  /// (phone numbers) are fetched on-demand per visible contact via a lazy
  /// `FutureBuilder`, so the list renders instantly even with 1000+ contacts.
  Future<List<Contact>?> _showContactPickerSheet(
      List<Contact> contacts) async {
    final searchController = TextEditingController();

    final result = await showModalBottomSheet<List<Contact>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => _ContactPickerSheet(
        allContacts: contacts,
        searchController: searchController,
      ),
    );

    searchController.dispose();
    return result;
  }

  Future<Customer> _saveCustomer({
    required String name,
    required String phone,
    required String email,
    required String balance,
    required List<String> tags,
    required bool isOrganisation,
    required String tinNumber,
    required String address,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError(_tr(
        'Please sign in before adding a customer.',
        'Tafadhali ingia kabla ya kuongeza mteja.',
      ));
    }

    final repository = ref.read(contextFirestoreRepositoryProvider);
    final activeBusinessId = ref.read(currentBusinessIdProvider).valueOrNull?.trim() ?? '';
    final financeContext = activeBusinessId.isNotEmpty
      ? ResolvedFinanceContext.business(activeBusinessId)
      : await repository.resolveContextForUser(user.uid);

    final customer = Customer(
      id: '',
      name: name,
      phone: phone,
      email: email,
      balance: balance,
      lastTransactionDate: _tr('Today', 'Leo'),
      tags: tags,
      isOrganisation: isOrganisation,
      tinNumber: tinNumber,
      address: address,
    );

    final docRef = await repository.addCustomer(
      uid: user.uid,
      context: financeContext,
      customer: customer,
    );

    return Customer(
      id: docRef.id,
      name: name,
      phone: phone,
      email: email,
      balance: balance,
      lastTransactionDate: _tr('Today', 'Leo'),
      tags: tags,
      isOrganisation: isOrganisation,
      tinNumber: tinNumber,
      address: address,
    );
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }
}

// ── Contact Picker Sheet ───────────────────────────────────────────────────────

/// A performant bottom-sheet contact picker.
///
/// Phase 1 contacts (names only, no properties) are shown immediately.
/// Phone numbers are loaded lazily per-item via [FlutterContacts.getContact]
/// so the list renders with 0 visible delay even for 1000+ contacts.
class _ContactPickerSheet extends StatefulWidget {
  final List<Contact> allContacts;
  final TextEditingController searchController;

  const _ContactPickerSheet({
    required this.allContacts,
    required this.searchController,
  });

  @override
  State<_ContactPickerSheet> createState() => _ContactPickerSheetState();
}

class _ContactPickerSheetState extends State<_ContactPickerSheet> {
  final _selectedIds = <String>{};
  List<Contact> _filtered = [];
  String _query = '';

  /// Cache of resolved phone numbers keyed by contact ID.
  final Map<String, String> _phoneCache = {};

  @override
  void initState() {
    super.initState();
    _filtered = widget.allContacts;
    widget.searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_onSearch);
    super.dispose();
  }

  void _onSearch() {
    final q = widget.searchController.text.trim().toLowerCase();
    if (q == _query) return;
    setState(() {
      _query = q;
      _filtered = q.isEmpty
          ? widget.allContacts
          : widget.allContacts.where((c) {
              final name = c.displayName.toLowerCase();
              final phone = (_phoneCache[c.id] ?? '').toLowerCase();
              return name.contains(q) || phone.contains(q);
            }).toList();
    });
  }

  void _toggleAll() {
    setState(() {
      if (_selectedIds.length == _filtered.length) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(_filtered.map((c) => c.id));
      }
    });
  }

  /// Lazily fetches the phone number for a contact, caches it, and
  /// triggers a rebuild only for the affected row.
  Future<String> _resolvePhone(String contactId) async {
    if (_phoneCache.containsKey(contactId)) {
      return _phoneCache[contactId]!;
    }
    try {
      final full = await FlutterContacts.getContact(contactId);
      final phone = full?.phones.firstOrNull?.number ?? '';
      if (mounted) {
        setState(() => _phoneCache[contactId] = phone);
      }
      return phone;
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final allSelected = _selectedIds.length == _filtered.length &&
        _filtered.isNotEmpty;

    return SafeArea(
      child: Column(
        children: [
          // ── Handle ──────────────────────────────────────────────────────
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),

          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _tr('Select contacts', 'Chagua mawasiliano'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _toggleAll,
                  child: Text(
                    allSelected
                        ? _tr('Deselect all', 'Toa chaguzi zote')
                        : _tr('Select all', 'Chagua yote'),
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),

          // ── Search field ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: widget.searchController,
              decoration: InputDecoration(
                hintText: _tr('Search contacts', 'Tafuta mawasiliano'),
                prefixIcon:
                    const Icon(Icons.search_rounded, size: 20),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // ── Selection count ──────────────────────────────────────────────
          if (_selectedIds.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(20, 0, 20, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _tr(
                      '${_selectedIds.length} selected',
                      '${_selectedIds.length} imechaguliwa',
                    ),
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),

          const Divider(height: 1, color: AppColors.border),

          // ── Contact list — virtualized ────────────────────────────────────
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text(
                      _tr(
                        'No contacts found',
                        'Hakuna mawasiliano yaliyopatikana',
                      ),
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (_, index) {
                      final contact = _filtered[index];
                      final isSelected =
                          _selectedIds.contains(contact.id);
                      final cachedPhone = _phoneCache[contact.id];

                      return CheckboxListTile(
                        value: isSelected,
                        activeColor: AppColors.primary,
                        checkColor: AppColors.secondary,
                        onChanged: (_) {
                          setState(() {
                            if (isSelected) {
                              _selectedIds.remove(contact.id);
                            } else {
                              _selectedIds.add(contact.id);
                              // Eagerly resolve phone when selected.
                              if (cachedPhone == null) {
                                _resolvePhone(contact.id);
                              }
                            }
                          });
                        },
                        title: Text(
                          contact.displayName.isEmpty
                              ? _tr('Unnamed contact',
                                  'Mawasiliano bila jina')
                              : contact.displayName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14),
                        ),
                        subtitle: cachedPhone != null
                            ? (cachedPhone.isEmpty
                                ? null
                                : Text(cachedPhone,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted)))
                            : FutureBuilder<String>(
                                future: _resolvePhone(contact.id),
                                builder: (_, snap) {
                                  final phone = snap.data ?? '';
                                  return phone.isEmpty
                                      ? const SizedBox.shrink()
                                      : Text(phone,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textMuted));
                                },
                              ),
                      );
                    },
                  ),
          ),

          // ── Action buttons ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(_tr('Cancel', 'Ghairi')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedIds.isEmpty
                        ? null
                        : () {
                            final selected = _filtered
                                .where((c) =>
                                    _selectedIds.contains(c.id))
                                .toList();
                            Navigator.of(context).pop(selected);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.secondary,
                      disabledBackgroundColor:
                          AppColors.primary.withValues(alpha: 0.4),
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text(
                      _selectedIds.isEmpty
                          ? _tr('Import', 'Ingiza')
                          : _tr(
                              'Import ${_selectedIds.length}',
                              'Ingiza ${_selectedIds.length}',
                            ),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
