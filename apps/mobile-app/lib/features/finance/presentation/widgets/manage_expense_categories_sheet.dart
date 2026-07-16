import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../data/finance_providers.dart';
import '../../domain/models/expense_category.dart';
import '../expense_category_style.dart';

String _t(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

class ManageExpenseCategoriesSheet extends ConsumerStatefulWidget {
  const ManageExpenseCategoriesSheet({super.key});

  @override
  ConsumerState<ManageExpenseCategoriesSheet> createState() =>
      _ManageExpenseCategoriesSheetState();
}

class _ManageExpenseCategoriesSheetState
    extends ConsumerState<ManageExpenseCategoriesSheet> {
  final _nameController = TextEditingController();
  bool _saving = false;

  static const _customStyles = <({String icon, int color})>[
    (icon: 'category', color: 0xFF1A6E8A),
    (icon: 'food', color: 0xFFB45309),
    (icon: 'maintenance', color: 0xFF7C3AED),
    (icon: 'office', color: 0xFF0D1B3E),
    (icon: 'tax', color: 0xFF16A34A),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _add(List<ExpenseCategory> categories) async {
    final name = _nameController.text.trim();
    final collection = ref.read(expenseCategoryCollectionProvider);
    if (name.isEmpty || collection == null || _saving) return;
    if (categories.any((c) => c.label.toLowerCase() == name.toLowerCase())) {
      _showMessage(_t(
        'That expense type already exists.',
        'Aina hiyo ya matumizi tayari ipo.',
      ));
      return;
    }

    setState(() => _saving = true);
    try {
      final style = _customStyles[categories.length % _customStyles.length];
      await collection.add({
        'name': name,
        'nameEn': name,
        'nameSw': name,
        'iconKey': style.icon,
        'colorValue': style.color,
        'isBuiltIn': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _nameController.clear();
    } catch (_) {
      _showMessage(_t(
        'Could not add the expense type. Try again.',
        'Imeshindwa kuongeza aina ya matumizi. Jaribu tena.',
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _remove(
    ExpenseCategory category,
    List<ExpenseCategory> categories,
  ) async {
    if (categories.length <= 1) {
      _showMessage(_t(
        'Keep at least one expense type.',
        'Baki na angalau aina moja ya matumizi.',
      ));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          _t('Delete expense type?', 'Futa aina ya matumizi?'),
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          _t(
            'Existing expenses keep their records, but this type will no longer appear when adding a new expense.',
            'Matumizi ya zamani yataendelea kuwepo, lakini aina hii haitaonekana unapoongeza matumizi mapya.',
          ),
          style: GoogleFonts.dmSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(_t('Cancel', 'Ghairi')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(_t('Delete', 'Futa')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final collection = ref.read(expenseCategoryCollectionProvider);
    if (collection == null) return;
    try {
      if (category.isBuiltIn) {
        await collection.doc(category.key).set({
          'isHidden': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await collection.doc(category.key).delete();
      }
    } catch (_) {
      _showMessage(_t(
        'Could not delete the expense type. Try again.',
        'Imeshindwa kufuta aina ya matumizi. Jaribu tena.',
      ));
    }
  }

  Future<void> _restoreDefaults() async {
    final collection = ref.read(expenseCategoryCollectionProvider);
    if (collection == null) return;
    final batch = FirebaseFirestore.instance.batch();
    for (final category in ExpenseCategory.defaults) {
      batch.delete(collection.doc(category.key));
    }
    try {
      await batch.commit();
    } catch (_) {
      _showMessage(_t(
        'Could not restore the defaults.',
        'Imeshindwa kurejesha aina za kawaida.',
      ));
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(expenseCategoryListProvider).valueOrNull ??
        ExpenseCategory.defaults;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetHandle(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _t('Expense types', 'Aina za Matumizi'),
                      style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navyPrimary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _restoreDefaults,
                    child: Text(_t('Restore', 'Rejesha')),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _t(
                    'Create or remove the types that fit this business.',
                    'Ongeza au futa aina zinazofaa biashara hii.',
                  ),
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: categories.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: category.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(category.icon, color: category.color, size: 19),
                      ),
                      title: Text(
                        category.label,
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                      ),
                      subtitle: category.isBuiltIn
                          ? Text(
                              _t('Default type', 'Aina ya kawaida'),
                              style: GoogleFonts.dmSans(fontSize: 11),
                            )
                          : null,
                      trailing: IconButton(
                        tooltip: _t('Delete', 'Futa'),
                        onPressed: () => _remove(category, categories),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.error,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _add(categories),
                      decoration: InputDecoration(
                        labelText: _t('New expense type', 'Aina mpya ya matumizi'),
                        hintText: _t('e.g. Internet', 'mfano: Intaneti'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox.square(
                    dimension: 50,
                    child: FilledButton(
                      onPressed: _saving ? null : () => _add(categories),
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: AppColors.navyPrimary,
                      ),
                      child: _saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.add_rounded),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
