import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../customer/data/customer_providers.dart';
import '../../../product/data/category_providers.dart';
import '../../../product/domain/models/product_category.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

// ─────────────────────────────────────────────────────────────────────────────
// Entry point — show the picker and await the chosen category
// ─────────────────────────────────────────────────────────────────────────────

Future<ProductCategory?> showCategoryPicker({
  required BuildContext context,
  required List<ProductCategory> categories,
  ProductCategory? selected,
  required Future<ProductCategory?> Function(String name) onAddCustom,
}) {
  return showModalBottomSheet<ProductCategory>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CategoryPickerSheet(
      categories: categories,
      selected: selected,
      onAddCustom: onAddCustom,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet widget
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryPickerSheet extends StatefulWidget {
  final List<ProductCategory> categories;
  final ProductCategory? selected;
  final Future<ProductCategory?> Function(String name) onAddCustom;

  const _CategoryPickerSheet({
    required this.categories,
    required this.selected,
    required this.onAddCustom,
  });

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  final _searchCtrl = TextEditingController();
  bool _addingCategory = false;
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ProductCategory> get _filtered {
    if (_query.isEmpty) return widget.categories;
    final q = _query.toLowerCase();
    return widget.categories
        .where((c) => c.name.toLowerCase().contains(q))
        .toList();
  }

  bool get _queryMatchesExisting => widget.categories
      .any((c) => c.name.trim().toLowerCase() == _query.trim().toLowerCase());

  bool get _canAddNew => _query.isNotEmpty && !_queryMatchesExisting;

  Future<void> _addCustom() async {
    final name = _query.trim();
    if (name.isEmpty) return;
    setState(() => _addingCategory = true);
    HapticFeedback.lightImpact();
    try {
      final created = await widget.onAddCustom(name);
      if (mounted && created != null) {
        Navigator.of(context).pop(created);
      }
    } finally {
      if (mounted) setState(() => _addingCategory = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return ConstrainedBox(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.88),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
                color: Colors.black12, blurRadius: 20, offset: Offset(0, -4)),
          ],
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tr('Select Category', 'Kategoria'),
                          style: GoogleFonts.dmSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navyPrimary,
                          ),
                        ),
                        Text(
                          _tr(
                            '${widget.categories.length} categories available',
                            'Kategoria ${widget.categories.length} zinapatikana',
                          ),
                          style: GoogleFonts.dmSans(
                              fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 22),
                    color: AppColors.textMuted,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceVariant,
                      shape: const CircleBorder(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchCtrl,
                style: GoogleFonts.dmSans(
                    fontSize: 14, color: AppColors.navyPrimary),
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: _tr(
                    'Search or type a new category…',
                    'Tafuta au andika kategoria mpya…',
                  ),
                  hintStyle: GoogleFonts.dmSans(
                      fontSize: 14, color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded,
                      size: 20, color: AppColors.textMuted),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded,
                              size: 18, color: AppColors.textMuted),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.card,
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
                    borderSide: const BorderSide(
                        color: AppColors.navyPrimary, width: 1.5),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),

            // "Add [query]" action — appears when query has no match
            if (_canAddNew)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: GestureDetector(
                  onTap: _addingCategory ? null : _addCustom,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 13),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      children: [
                        _addingCategory
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            : const Icon(Icons.add_circle_rounded,
                                size: 18, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              style: GoogleFonts.dmSans(fontSize: 13),
                              children: [
                                TextSpan(
                                  text: _tr('Add ', 'Ongeza '),
                                  style: const TextStyle(
                                      color: AppColors.textSecondary),
                                ),
                                TextSpan(
                                  text: '"$_query"',
                                  style: const TextStyle(
                                    color: AppColors.navyPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(
                                  text: _tr(' as a new category',
                                      ' kama kategoria mpya'),
                                  style: const TextStyle(
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 8),

            const Divider(height: 1, color: AppColors.border),

            // Category list
            Expanded(
              child: filtered.isEmpty
                  ? _EmptySearch(query: _query)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final cat = filtered[i];
                        final isSelected = cat.id == widget.selected?.id;
                        return _CategoryTile(
                          category: cat,
                          isSelected: isSelected,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.of(context).pop(cat);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single category tile
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryTile extends StatelessWidget {
  final ProductCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isSelected ? AppColors.navyPrimary : AppColors.tealAccent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.navyPrimary.withValues(alpha: 0.06)
                  : AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? AppColors.navyPrimary.withValues(alpha: 0.4)
                    : AppColors.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                // Icon with tinted background — inventory card style
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(category.icon, size: 20, color: accent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.navyPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (category.isDefault)
                        Text(
                          _tr('System category', 'Kategoria ya mfumo'),
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle_rounded,
                      size: 20, color: AppColors.navyPrimary)
                else
                  const Icon(Icons.chevron_right_rounded,
                      size: 18, color: AppColors.textDisabled),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty search state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptySearch extends StatelessWidget {
  final String query;
  const _EmptySearch({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.search_off_rounded,
                  size: 30, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            Text(
              _tr('No categories found', 'Hakuna kategoria iliyopatikana'),
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.navyPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              query.isEmpty
                  ? _tr('Start typing to search or add a new one.',
                      'Anza kuandika kutafuta au kuongeza mpya.')
                  : _tr(
                      'Tap "+ Add" above to create "$query".',
                      'Bonyeza "+ Ongeza" hapo juu kuunda "$query".',
                    ),
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable tap-to-open field for embedding in forms
// ─────────────────────────────────────────────────────────────────────────────

class CategorySelectField extends ConsumerWidget {
  final ProductCategory? selected;
  final ValueChanged<ProductCategory> onChanged;

  const CategorySelectField({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryListProvider);
    final bizIdAsync = ref.watch(currentBusinessIdProvider);
    final bizTypeAsync = ref.watch(currentBusinessTypeProvider);

    Future<ProductCategory?> handleAddCustom(String name) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      try {
        final docId = await addCategory(
          uid: user.uid,
          bizId: bizIdAsync.valueOrNull ?? '',
          businessType: bizTypeAsync.valueOrNull ?? '',
          name: name,
          repo: ref.read(contextFirestoreRepositoryProvider),
        );
        return ProductCategory(
          id: docId,
          name: name,
          createdAt: '',
        );
      } catch (_) {
        return null;
      }
    }

    final hasValue = selected != null;

    return GestureDetector(
      onTap: categoriesAsync.hasValue
          ? () async {
              final result = await showCategoryPicker(
                context: context,
                categories: categoriesAsync.value ?? [],
                selected: selected,
                onAddCustom: handleAddCustom,
              );
              if (result != null) onChanged(result);
            }
          : null,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                hasValue ? AppColors.navyPrimary.withValues(alpha: 0.3) : AppColors.border,
          ),
        ),
        child: categoriesAsync.isLoading
            ? Row(
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          height: 10,
                          width: 60,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(4),
                          )),
                      const SizedBox(height: 6),
                      Container(
                          height: 13,
                          width: 140,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(4),
                          )),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: hasValue
                          ? AppColors.tealAccent.withValues(alpha: 0.10)
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      hasValue
                          ? selected!.icon
                          : Icons.category_rounded,
                      size: 20,
                      color: hasValue
                          ? AppColors.tealAccent
                          : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tr('Category', 'Kategoria'),
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          hasValue
                              ? selected!.name
                              : _tr(
                                  'Tap to select a category',
                                  'Gusa kuchagua kategoria',
                                ),
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: hasValue
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: hasValue
                                ? AppColors.navyPrimary
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    hasValue
                        ? Icons.check_circle_rounded
                        : Icons.expand_more_rounded,
                    size: 20,
                    color:
                        hasValue ? AppColors.success : AppColors.textMuted,
                  ),
                ],
              ),
      ),
    );
  }
}
