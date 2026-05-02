import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../shared/widgets/shimmer.dart';
import '../../data/customer_providers.dart';
import '../../domain/models/customer.dart';

class AddCustomerDialog extends ConsumerStatefulWidget {
  const AddCustomerDialog({super.key});

  @override
  ConsumerState<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends ConsumerState<AddCustomerDialog> {
  final _contactPicker = FlutterNativeContactPicker();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _balanceController = TextEditingController(text: '0');
  final List<String> _tags = [];
  final _tagController = TextEditingController();
  bool _isLoading = false;
  bool _isImportingContact = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _balanceController.dispose();
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
                    LocalizationService.tr(
                      en: 'Add New Customer',
                      sw: 'Ongeza Mteja Mpya',
                    ),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),
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
                            ? LocalizationService.tr(
                                en: 'Opening contacts...',
                                sw: 'Inafungua mawasiliano...',
                              )
                            : LocalizationService.tr(
                                en: 'Add from Contacts',
                                sw: 'Ongeza kutoka Mawasiliano',
                              ),
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
                          LocalizationService.tr(en: 'or', sw: 'au'),
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: LocalizationService.tr(
                        en: 'Customer Name',
                        sw: 'Jina la Mteja',
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return LocalizationService.tr(
                          en: 'Please enter customer name',
                          sw: 'Tafadhali weka jina la mteja',
                        );
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: LocalizationService.tr(
                        en: 'Phone Number',
                        sw: 'Namba ya Simu',
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return LocalizationService.tr(
                          en: 'Please enter phone number',
                          sw: 'Tafadhali weka namba ya simu',
                        );
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: LocalizationService.tr(
                        en: 'Email (Optional)',
                        sw: 'Barua pepe (Hiari)',
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _balanceController,
                    decoration: InputDecoration(
                      labelText: LocalizationService.tr(
                        en: 'Initial Balance',
                        sw: 'Salio ya Kuanzia',
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return LocalizationService.tr(
                          en: 'Please enter initial balance',
                          sw: 'Tafadhali weka salio la kuanzia',
                        );
                      }
                      if (double.tryParse(value) == null) {
                        return LocalizationService.tr(
                          en: 'Please enter a valid amount',
                          sw: 'Tafadhali weka kiasi halali',
                        );
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocalizationService.tr(en: 'Tags', sw: 'Lebo'),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _tagController,
                              decoration: InputDecoration(
                                hintText: LocalizationService.tr(
                                  en: 'Add tag',
                                  sw: 'Ongeza lebo',
                                ),
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              onFieldSubmitted: (value) {
                                if (value.isNotEmpty) {
                                  setState(() {
                                    _tags.add(value);
                                    _tagController.clear();
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              if (_tagController.text.isNotEmpty) {
                                setState(() {
                                  _tags.add(_tagController.text);
                                  _tagController.clear();
                                });
                              }
                            },
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _tags
                            .map(
                              (tag) => Chip(
                                label: Text(tag),
                                onDeleted: () {
                                  setState(() {
                                    _tags.remove(tag);
                                  });
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.pop(context),
                          child: Text(
                            LocalizationService.tr(en: 'Cancel', sw: 'Ghairi'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _addCustomer,
                          child: _isLoading
                              ? const ShimmerBox(
                                  width: 88,
                                  height: 14,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(999),
                                  ),
                                )
                              : Text(
                                  LocalizationService.tr(
                                    en: 'Add Customer',
                                    sw: 'Ongeza Mteja',
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
        );
        if (mounted) {
          final messenger = ScaffoldMessenger.of(context);
          Navigator.pop(context);
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                LocalizationService.tr(
                  en: 'Customer added successfully',
                  sw: 'Mteja ameongezwa kwa mafanikio',
                ),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                LocalizationService.tr(
                  en: 'Error: ${e.toString()}',
                  sw: 'Kosa: ${e.toString()}',
                ),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _addFromContacts() async {
    setState(() => _isImportingContact = true);

    try {
      final contact = await _contactPicker.selectPhoneNumber();
      if (contact == null) return;

      final name = (contact.fullName ?? '').trim();
      final phone =
          (contact.selectedPhoneNumber ??
                  contact.phoneNumbers?.firstOrNull ??
                  '')
              .trim();

      if (name.isEmpty || phone.isEmpty) {
        _showSnackBar(
          LocalizationService.tr(
            en: 'Selected contact needs a name and phone number.',
            sw: 'Mawasiliano yaliyochaguliwa yanahitaji jina na namba ya simu.',
          ),
          Colors.red,
        );
        return;
      }

      await _saveCustomer(
        name: name,
        phone: phone,
        email: '',
        balance: '0',
        tags: const ['Contact'],
      );

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            LocalizationService.tr(
              en: 'Customer added from contacts',
              sw: 'Mteja ameongezwa kutoka mawasiliano',
            ),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showSnackBar(
        LocalizationService.tr(
          en: 'Error: ${e.toString()}',
          sw: 'Kosa: ${e.toString()}',
        ),
        Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() => _isImportingContact = false);
      }
    }
  }

  Future<void> _saveCustomer({
    required String name,
    required String phone,
    required String email,
    required String balance,
    required List<String> tags,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError(
        LocalizationService.tr(
          en: 'Please sign in before adding a customer.',
          sw: 'Tafadhali ingia kabla ya kuongeza mteja.',
        ),
      );
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
        lastTransactionDate: LocalizationService.tr(en: 'Today', sw: 'Leo'),
        tags: tags,
      ),
    );
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
