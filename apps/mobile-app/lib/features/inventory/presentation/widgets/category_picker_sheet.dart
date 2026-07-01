import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../../catalog/domain/models/master_category.dart';
import '../../../catalog/providers/master_catalog_providers.dart';
import '../../../product/data/category_providers.dart';
import '../../../product/domain/models/product_category.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

// ─────────────────────────────────────────────────────────────────────────────
// Entry point — show the picker and await the chosen category
// ─────────────────────────────────────────────────────────────────────────────

Future<MasterCategory?> showCategoryPicker({
  required BuildContext context,
  required List<MasterCategory> categories,
  MasterCategory? selected,
}) {
  return showAppSheet<MasterCategory>(
    context,
    builder: (_) => _CategoryPickerSheet(
      categories: categories,
      selected: selected,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet widget
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryPickerSheet extends ConsumerStatefulWidget {
  final List<MasterCategory> categories;
  final MasterCategory? selected;

  const _CategoryPickerSheet({
    required this.categories,
    required this.selected,
  });

  @override
  ConsumerState<_CategoryPickerSheet> createState() =>
      _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends ConsumerState<_CategoryPickerSheet> {
  final _searchCtrl = TextEditingController();
  final _newCtrl    = TextEditingController();
  String _query  = '';
  bool _showAdd  = false;
  bool _adding   = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _newCtrl.dispose();
    super.dispose();
  }

  List<MasterCategory> get _filtered {
    if (_query.isEmpty) return widget.categories;
    final q = _query.toLowerCase();
    return widget.categories
        .where((c) => c.categoryName.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _addCommunityCategory() async {
    final name = _newCtrl.text.trim();
    if (name.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _adding = true);
    try {
      final bizType =
          ref.read(currentBusinessTypeProvider).valueOrNull ?? 'retail';
      final repo = ref.read(masterCatalogRepositoryProvider);
      final newCat = await repo.addCommunityCategory(
        businessType: bizType,
        categoryName: name,
        addedByUid: user.uid,
      );
      ref.invalidate(masterCategoriesProvider);
      if (mounted) Navigator.of(context).pop(newCat);
    } catch (_) {
      if (mounted) setState(() => _adding = false);
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
            const SheetHandle(),
            const SizedBox(height: 4),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 8, 0),
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
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _showAdd = !_showAdd;
                      if (!_showAdd) _newCtrl.clear();
                    }),
                    icon: Icon(
                      _showAdd ? Icons.close_rounded : Icons.add_rounded,
                      size: 18, color: AppColors.tealAccent,
                    ),
                    label: Text(
                      _showAdd
                          ? _tr('Cancel', 'Ghairi')
                          : _tr('Add New', 'Ongeza Mpya'),
                      style: GoogleFonts.dmSans(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: AppColors.tealAccent,
                      ),
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

            if (_showAdd) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newCtrl,
                        textCapitalization: TextCapitalization.words,
                        autofocus: true,
                        style: GoogleFonts.dmSans(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: AppColors.navyPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: _tr('Category name', 'Jina la kategoria'),
                          hintStyle: GoogleFonts.dmSans(
                              fontSize: 14, color: AppColors.textMuted),
                          filled: true,
                          fillColor: AppColors.card,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
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
                                color: AppColors.tealAccent, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _adding ? null : _addCommunityCategory,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navyPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: _adding
                            ? const SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text(_tr('Save', 'Hifadhi'),
                                style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ] else
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
                    'Search categories…',
                    'Tafuta kategoria…',
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
                        final isSelected = cat.categorySlug.isNotEmpty
                            ? cat.categorySlug == widget.selected?.categorySlug
                            : cat.id == widget.selected?.id;
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
  final MasterCategory category;
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
    final iconData = ProductCategory.categoryIcon(category.categoryName);

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
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(iconData, size: 20, color: accent),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    category.categoryName,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.navyPrimary
                          : AppColors.textPrimary,
                    ),
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
            SizedBox(height: 16),
            Text(
              _tr('No categories found', 'Hakuna kategoria iliyopatikana'),
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.navyPrimary,
              ),
            ),
            SizedBox(height: 6),
            Text(
              _tr(
                'Try a different search term.',
                'Jaribu neno lingine la kutafuta.',
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
  final MasterCategory? selected;
  final ValueChanged<MasterCategory> onChanged;

  const CategorySelectField({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(masterCategoriesProvider);

    final hasValue = selected != null;

    return GestureDetector(
      onTap: categoriesAsync.hasValue
          ? () async {
              final result = await showCategoryPicker(
                context: context,
                categories: categoriesAsync.value ?? [],
                selected: selected,
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
                          ? ProductCategory.categoryIcon(selected!.categoryName)
                          : Icons.category_rounded,
                      size: 20,
                      color: hasValue
                          ? AppColors.tealAccent
                          : AppColors.textMuted,
                    ),
                  ),
                  SizedBox(width: 12),
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
                              ? selected!.categoryName
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
