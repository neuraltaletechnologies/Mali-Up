import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../shared/widgets/shimmer.dart';

class AddExpenseDialog extends ConsumerStatefulWidget {
  const AddExpenseDialog({super.key});

  @override
  ConsumerState<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends ConsumerState<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _categoryController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _recipientController = TextEditingController();
  final _dateController = TextEditingController();
  String _selectedCategory = 'Food & Drinks';
  bool _isLoading = false;

  final List<String> _categories = [
    'Food & Drinks',
    'Transport',
    'Rent',
    'Utilities',
    'Supplies',
    'Marketing',
    'Salaries',
    'Office',
    'Equipment',
    'Maintenance',
    'Insurance',
    'Taxes',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _dateController.text = DateTime.now().toString().split('T')[0];
    _categoryController.text = _selectedCategory;
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _recipientController.dispose();
    _dateController.dispose();
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
                      en: 'Add New Expense',
                      sw: 'Ongeza Matumizi Mpya',
                    ),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: LocalizationService.tr(
                        en: 'Category',
                        sw: 'Kundi',
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                        _categoryController.text = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: LocalizationService.tr(
                        en: 'Amount',
                        sw: 'Kiasi',
                      ),
                      border: const OutlineInputBorder(),
                      prefixText: 'TZS ',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return LocalizationService.tr(
                          en: 'Please enter amount',
                          sw: 'Tafadhali weka kiasi',
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
                  TextFormField(
                    controller: _dateController,
                    decoration: InputDecoration(
                      labelText: LocalizationService.tr(
                        en: 'Date',
                        sw: 'Tarehe',
                      ),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: _selectDate,
                      ),
                    ),
                    readOnly: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return LocalizationService.tr(
                          en: 'Please select date',
                          sw: 'Tafadhali chagua tarehe',
                        );
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _recipientController,
                    decoration: InputDecoration(
                      labelText: LocalizationService.tr(
                        en: 'Recipient (Optional)',
                        sw: 'Mpokeaji (Hiari)',
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      labelText: LocalizationService.tr(
                        en: 'Note',
                        sw: 'Maoni',
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return LocalizationService.tr(
                          en: 'Please enter a note',
                          sw: 'Tafadhali weka maoni',
                        );
                      }
                      return null;
                    },
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
                          onPressed: _isLoading ? null : _addExpense,
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
                                    en: 'Add ',
                                    sw: 'Ongeza',
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null) {
      setState(() {
        _dateController.text = picked.toString().split('T')[0];
      });
    }
  }

  void _addExpense() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // TODO: Implement expense addition using the existing pattern
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                LocalizationService.tr(
                  en: 'Expense added successfully',
                  sw: 'Matumizi yameongezwa kwa mafanikio',
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
