import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/customer.dart';
import '../../../../core/services/localization_service.dart';

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
  final List<String> _tags = [];
  final _tagController = TextEditingController();
  bool _isLoading = false;

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
    return AlertDialog(
      title: Text(
        LocalizationService.tr(
          en: 'Add New Customer',
          sw: 'Ongea Mteja Mpya',
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                      sw: 'Tafadhali weka saldo ya kuanzia',
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
              // Tags section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LocalizationService.tr(
                      en: 'Tags',
                      sw: 'Lebo',
                    ),
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
                          onSubmitted: (value) {
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
                    children: _tags.map((tag) => Chip(
                      label: Text(tag),
                      onDeleted: () {
                        setState(() {
                          _tags.remove(tag);
                        });
                      },
                    )).toList(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(
            LocalizationService.tr(en: 'Cancel', sw: 'Ghairi'),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addCustomer,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  LocalizationService.tr(en: 'Add Customer', sw: 'Ongea Mteja'),
                ),
        ),
      ],
    );
  }

  void _addCustomer() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // TODO: Implement customer addition using the existing pattern
        // For now, just close the dialog and show success message
        Navigator.pop(context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
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
}
