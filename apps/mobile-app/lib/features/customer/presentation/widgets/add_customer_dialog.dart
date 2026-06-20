import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../config/routing.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/services/sentry_metrics_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../rbac/data/audit_log_service.dart';
import '../../data/customer_providers.dart';
import '../../data/repositories/customer_repository.dart';
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

  InputDecoration _field(String label, IconData icon, {String? hint}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surface,
        labelStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
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
          borderSide: BorderSide(
            color: AppColors.navyPrimary.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 14),
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24, 20, 24,
                24 + MediaQuery.of(context).viewInsets.bottom +
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──────────────────────────────────────────────
                    Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.navyPrimary,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(Icons.person_add_alt_1_rounded,
                              size: 22, color: AppColors.yellowBrand),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _tr('Add New Customer', 'Ongeza Mteja Mpya'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.navyPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Text(
                                _tr('Fill in the details below.',
                                    'Jaza maelezo hapa chini.'),
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Type toggle ──────────────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          _TypeTab(
                            label: _tr('Individual', 'Mtu Binafsi'),
                            icon: Icons.person_outline_rounded,
                            active: !_isOrganisation,
                            onTap: () => setState(() => _isOrganisation = false),
                          ),
                          const SizedBox(width: 4),
                          _TypeTab(
                            label: _tr('Organisation', 'Shirika'),
                            icon: Icons.business_outlined,
                            active: _isOrganisation,
                            onTap: () => setState(() => _isOrganisation = true),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Import from Contacts ─────────────────────────────────
                    GestureDetector(
                      onTap: (_isLoading || _isImportingContact)
                          ? null
                          : _addFromContacts,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 13),
                        decoration: BoxDecoration(
                          color: AppColors.navyPrimary.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.navyPrimary.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _isImportingContact
                                ? const SizedBox(
                                    width: 18, height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.navyPrimary,
                                    ),
                                  )
                                : const Icon(Icons.contacts_outlined,
                                    size: 18, color: AppColors.navyPrimary),
                            const SizedBox(width: 8),
                            Text(
                              _isImportingContact
                                  ? _tr('Opening contacts…', 'Inafungua mawasiliano…')
                                  : _tr('Import from Contacts',
                                      'Ingiza kutoka Mawasiliano'),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.navyPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── OR divider ───────────────────────────────────────────
                    Row(
                      children: [
                        const Expanded(
                            child: Divider(color: AppColors.border)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            _tr('or enter manually', 'au weka mwenyewe'),
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textMuted),
                          ),
                        ),
                        const Expanded(
                            child: Divider(color: AppColors.border)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Fields ───────────────────────────────────────────────
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(
                          fontSize: 15, color: AppColors.navyPrimary),
                      decoration: _field(
                        _isOrganisation
                            ? _tr('Organisation Name *', 'Jina la Shirika *')
                            : _tr('Customer Name *', 'Jina la Mteja *'),
                        _isOrganisation
                            ? Icons.business_outlined
                            : Icons.person_outline_rounded,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? _tr('Name is required', 'Jina linahitajika')
                          : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(
                          fontSize: 15, color: AppColors.navyPrimary),
                      decoration: _field(
                        _tr('Phone Number *', 'Namba ya Simu *'),
                        Icons.phone_outlined,
                        hint: '+255 7XX XXX XXX',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? _tr('Phone number is required',
                              'Namba ya simu inahitajika')
                          : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(
                          fontSize: 15, color: AppColors.navyPrimary),
                      decoration: _field(
                        _tr('Email (Optional)', 'Barua pepe (Hiari)'),
                        Icons.email_outlined,
                      ),
                    ),

                    if (_isOrganisation) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _tinController,
                        textCapitalization: TextCapitalization.characters,
                        style: const TextStyle(
                            fontSize: 15, color: AppColors.navyPrimary),
                        decoration: _field(
                          _tr('TIN Number (Optional)', 'Namba ya TIN (Hiari)'),
                          Icons.numbers_outlined,
                          hint: 'e.g. 100-123-456',
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(
                          fontSize: 15, color: AppColors.navyPrimary),
                      decoration: _field(
                        _tr('Address (Optional)', 'Anwani (Hiari)'),
                        Icons.location_on_outlined,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Actions ──────────────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              foregroundColor: AppColors.navyPrimary,
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(_tr('Cancel', 'Ghairi')),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _addCustomer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.navyPrimary,
                              elevation: 3,
                              shadowColor:
                                  AppColors.primary.withValues(alpha: 0.35),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20, height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: AppColors.navyPrimary,
                                    ),
                                  )
                                : Text(
                                    _tr('Add Customer', 'Ongeza Mteja'),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15),
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
        ],
      ),
    );
  }

  void _addCustomer() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final phone = _phoneController.text.trim();

        // Duplicate check before writing anything
        final existing =
            await ref.read(customerRepositoryProvider).findByPhone(phone);
        if (existing != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(_tr(
                'A contact with this phone number already exists: ${existing.name}',
                'Mteja mwenye namba hii tayari yupo: ${existing.name}',
              )),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
            ));
          }
          return;
        }

        final customer = await _saveCustomer(
          name: _nameController.text.trim(),
          phone: phone,
          email: _emailController.text.trim(),
          balance: _balanceController.text.trim(),
          tags: _tags,
          isOrganisation: _isOrganisation,
          tinNumber: _tinController.text.trim(),
          address: _addressController.text.trim(),
        );
        if (mounted) {
          final messenger = ScaffoldMessenger.of(context);
          // StreamProvider auto-updates on Firestore writes — invalidate not needed
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
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
            ),
          );
          widget.onAdded?.call(customer);
        }
      } catch (e) {
        if (mounted) {
          final msg = e.toString().toLowerCase().contains('unavailable') ||
                  e.toString().toLowerCase().contains('network') ||
                  e.toString().toLowerCase().contains('offline')
              ? _tr(
                  'Saved offline — will sync when connected.',
                  'Imehifadhiwa bila mtandao — itasawazishwa ukiunganika.',
                )
              : _tr(
                  'Could not add customer. Please try again.',
                  'Imeshindwa kuongeza mteja. Tafadhali jaribu tena.',
                );
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ));
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

      // Navigate back immediately — import continues in the background
      if (!mounted) return;
      final total = selectedContacts.length;

      // Capture everything needed before closing the dialog
      final messenger = ScaffoldMessenger.of(context);
      final router = GoRouter.of(context);
      final customerRepo = ref.read(customerRepositoryProvider);
      final auditLogger = ref.read(customerAuditLoggerProvider);
      final user = FirebaseAuth.instance.currentUser;
      final bizId =
          ref.read(currentBusinessIdProvider).valueOrNull?.trim() ?? '';

      if (user == null || bizId.isEmpty) {
        _showSnackBar(
          _tr(
            'No active session. Please sign in and try again.',
            'Hakuna kikao kinachotumika. Tafadhali ingia tena.',
          ),
          AppColors.error,
        );
        return;
      }

      // Pop the dialog first; GoRouter navigation deferred to the next frame so
      // the pop finishes cleaning up its inherited-widget dependencies before
      // GoRouter rebuilds its own inherited widget — doing both in the same
      // synchronous block triggers a Flutter framework assertion.
      Navigator.pop(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        router.go(AppRouter.crmPath);
      });

      messenger.showSnackBar(SnackBar(
        content: Text(_tr(
          'Importing $total contact${total == 1 ? '' : 's'}…',
          'Inaingiza mawasiliano $total…',
        )),
        duration: const Duration(seconds: 60),
        behavior: SnackBarBehavior.floating,
      ));

      // Run the import detached from the widget tree; list updates live via Drift
      unawaited(_runBackgroundImport(
        contacts: selectedContacts,
        user: user,
        customerRepo: customerRepo,
        auditLogger: auditLogger,
        messenger: messenger,
        total: total,
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

  /// Saves each contact to Drift + audit log, then shows a completion snackbar.
  /// Runs fully detached from the widget tree so the dialog can close first.
  Future<void> _runBackgroundImport({
    required List<Contact> contacts,
    required User user,
    required CustomerRepository customerRepo,
    required CustomerAuditLogger auditLogger,
    required ScaffoldMessengerState messenger,
    required int total,
  }) async {
    var done = 0;
    var skipped = 0;
    for (final contact in contacts) {
      final name = contact.displayName.trim();
      final phone = await _resolveImportPhone(contact);
      if (name.isEmpty || phone.isEmpty) {
        done++;
        continue;
      }
      try {
        // Skip contacts whose phone already exists in the customer book
        final duplicate = await customerRepo.findByPhone(phone);
        if (duplicate != null) {
          skipped++;
          done++;
          continue;
        }
        final customer = Customer(
          id: '',
          name: name,
          phone: phone,
          tags: const ['Contact'],
          createdByUserId: user.uid,
        );
        final saved = await customerRepo.save(customer);
        SentryMetricsService.customerAdded(source: 'add_customer_dialog');
        await auditLogger.log(
          AuditLogService.customerCreated,
          customerId: saved.id,
          customerName: saved.name,
        );
      } catch (_) {
        // Skip failed contacts silently; the rest still import
      }
      done++;
    }
    messenger.hideCurrentSnackBar();
    final imported = done - skipped;
    final body = skipped > 0
        ? _tr(
            '$imported imported, $skipped already exist',
            '$imported yameingizwa, $skipped tayari yapo',
          )
        : _tr(
            imported == 1 ? '1 contact imported' : '$imported contacts imported',
            imported == 1
                ? 'Mawasiliano 1 yameingizwa'
                : 'Mawasiliano $imported yameingizwa',
          );
    messenger.showSnackBar(SnackBar(
      content: Text(body),
      backgroundColor:
          skipped > 0 && imported == 0 ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
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

    final bizId =
        ref.read(currentBusinessIdProvider).valueOrNull?.trim() ?? '';
    if (bizId.isEmpty) {
      throw StateError(_tr(
        'No active business found. Please finish business setup first.',
        'Hakuna biashara inayotumika. Tafadhali kamilisha usajili wa biashara kwanza.',
      ));
    }

    final customer = Customer(
      id: '',
      name: name,
      phone: phone,
      email: email,
      balance: balance,
      tags: tags,
      isOrganisation: isOrganisation,
      tinNumber: tinNumber,
      address: address,
      createdByUserId: user.uid,
    );

    // Offline-first: commits to Drift + sync queue in one transaction, so the
    // customer appears in the list immediately and syncs when connected.
    final saved = await ref.read(customerRepositoryProvider).save(customer);

    SentryMetricsService.customerAdded(source: 'add_customer_dialog');
    await ref.read(customerAuditLoggerProvider).log(
          AuditLogService.customerCreated,
          customerId: saved.id,
          customerName: saved.name,
        );

    return saved;
  }

  Future<String> _resolveImportPhone(Contact contact) async {
    try {
      if (contact.phones.isNotEmpty) {
        final phone = contact.phones.first.number.trim();
        if (phone.isNotEmpty) {
          return phone;
        }
      }

      final full = await FlutterContacts.getContact(contact.id);
      return full?.phones.firstOrNull?.number.trim() ?? '';
    } catch (_) {
      return '';
    }
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

// ─── Type tab (Individual / Organisation toggle) ──────────────────────────────

class _TypeTab extends StatelessWidget {
  const _TypeTab({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
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
                    size: 15,
                    color: active ? Colors.white : AppColors.textMuted),
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
