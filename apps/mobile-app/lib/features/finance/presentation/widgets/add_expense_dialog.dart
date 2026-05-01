import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/expense_provider.dart';
import '../../domain/models/expense.dart';
import '../../../../core/services/localization_service.dart';

// Provider declaration
final expenseProvider = ChangeNotifierProvider<ExpenseProvider>((ref) {
  return ExpenseProvider();
});

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
    return AlertDialog(
      title: Text(
        LocalizationService.tr(
          en: 'Add New Expense',
          sw: 'Ongeza Matumizi Mpya',
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Category dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
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
              
              // Amount
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
              
              // Date
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
              
              // Recipient (optional)
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
              
              // Note
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
          onPressed: _isLoading ? null : _addExpense,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  LocalizationService.tr(en: 'Add Expense', sw: 'Ongeza Matumizi'),
                ),
        ),
      ],
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
        final success = await ref.read(expenseProvider.notifier).addExpense(
          category: _selectedCategory,
          amount: double.parse(_amountController.text.trim()),
          note: _noteController.text.trim(),
          recipient: _recipientController.text.trim(),
          date: _dateController.text.trim(),
        );

        if (success && mounted) {
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
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                LocalizationService.tr(
                  en: 'Failed to add expense',
                  sw: 'Imeshindikana kuongeza matumizi',
                ),
              ),
              backgroundColor: Colors.red,
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
