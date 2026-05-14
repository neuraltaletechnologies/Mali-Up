import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/customer_providers.dart';
import '../../domain/models/customer.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

class AddCustomerDialog extends ConsumerStatefulWidget {
  const AddCustomerDialog({super.key});

  @override
  ConsumerState<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends ConsumerState<AddCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
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
        await _saveCustomer(
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
            title: Text(
              _tr(
                'Contacts permission required',
                'Ruhusa ya mawasiliano inahitajika',
              ),
            ),
            content: Text(
              _tr(
                'Please enable contacts permission in app settings.',
                'Tafadhali weka ruhusa ya mawasiliano katika mipangilio.',
              ),
            ),
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

      final contacts =
          await FlutterContacts.getContacts(withProperties: true);
      if (!mounted) return;

      final selectedContacts = await _showContactPickerDialog(contacts);
      if (selectedContacts == null || selectedContacts.isEmpty) return;

      var importedCount = 0;
      for (final contact in selectedContacts) {
        final name = contact.displayName.trim();
        final phone = contact.phones.isNotEmpty
            ? contact.phones.first.number.trim()
            : '';
        if (name.isEmpty || phone.isEmpty) continue;

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
        importedCount++;
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr(
              importedCount == 1
                  ? 'Customer added from contacts'
                  : '$importedCount customers added from contacts',
              importedCount == 1
                  ? 'Mteja ameongezwa kutoka mawasiliano'
                  : '$importedCount wateja wameongezwa kutoka mawasiliano',
            ),
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      _showSnackBar(
        '${_tr("Error", "Kosa")}: ${e.toString()}',
        AppColors.error,
      );
    } finally {
      if (mounted) setState(() => _isImportingContact = false);
    }
  }

  Future<void> _saveCustomer({
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
    final financeContext = await repository.resolveContextForUser(user.uid);

    await repository.addCustomer(
      uid: user.uid,
      context: financeContext,
      customer: Customer(
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
      ),
    );
  }

  Future<List<Contact>?> _showContactPickerDialog(
      List<Contact> contacts) async {
    final searchController = TextEditingController();
    final selectedContactIds = <String>{};

    final result = await showDialog<List<Contact>>(
      context: context,
      builder: (dialogContext) {
        var filteredContacts = contacts;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            void applyFilter(String query) {
              final normalizedQuery = query.trim().toLowerCase();
              setDialogState(() {
                filteredContacts = normalizedQuery.isEmpty
                    ? contacts
                    : contacts.where((contact) {
                        final name = contact.displayName.toLowerCase();
                        final phone = contact.phones
                            .map((p) => p.number.toLowerCase())
                            .join(' ');
                        return name.contains(normalizedQuery) ||
                            phone.contains(normalizedQuery);
                      }).toList();
              });
            }

            return Dialog(
              insetPadding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: SizedBox(
                height: MediaQuery.of(dialogContext).size.height * 0.78,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _tr('Select contacts', 'Chagua mawasiliano'),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setDialogState(() {
                                if (selectedContactIds.length ==
                                    contacts.length) {
                                  selectedContactIds.clear();
                                } else {
                                  selectedContactIds
                                    ..clear()
                                    ..addAll(
                                        contacts.map((c) => c.id));
                                }
                              });
                            },
                            child: Text(
                              _tr('Select all', 'Chagua yote'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        controller: searchController,
                        onChanged: applyFilter,
                        decoration: InputDecoration(
                          hintText: _tr(
                              'Search contacts', 'Tafuta mawasiliano'),
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _tr(
                            '${selectedContactIds.length} selected',
                            '${selectedContactIds.length} imechaguliwa',
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: filteredContacts.isEmpty
                          ? Center(
                              child: Text(
                                _tr('No contacts found',
                                    'Hakuna mawasiliano yaliyopatikana'),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filteredContacts.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final contact = filteredContacts[index];
                                final phone = contact.phones.isNotEmpty
                                    ? contact.phones.first.number
                                    : '';
                                final isSelected = selectedContactIds
                                    .contains(contact.id);

                                return CheckboxListTile(
                                  value: isSelected,
                                  onChanged: (_) {
                                    setDialogState(() {
                                      if (isSelected) {
                                        selectedContactIds
                                            .remove(contact.id);
                                      } else {
                                        selectedContactIds.add(contact.id);
                                      }
                                    });
                                  },
                                  title: Text(
                                    contact.displayName.isEmpty
                                        ? _tr('Unnamed contact',
                                            'Mawasiliano bila jina')
                                        : contact.displayName,
                                  ),
                                  subtitle:
                                      phone.isEmpty ? null : Text(phone),
                                );
                              },
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              child: Text(_tr('Cancel', 'Ghairi')),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: selectedContactIds.isEmpty
                                  ? null
                                  : () {
                                      final selected = contacts
                                          .where((c) => selectedContactIds
                                              .contains(c.id))
                                          .toList();
                                      Navigator.of(dialogContext)
                                          .pop(selected);
                                    },
                              child: Text(
                                LocalizationService.tr(
                                  en: 'Import',
                                  sw: 'Ingiza',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    searchController.dispose();
    return result;
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }
}
