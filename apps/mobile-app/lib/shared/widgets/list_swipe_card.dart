import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/localization_service.dart';

/// Gmail-style swipe-to-reveal action card.
///
/// Swiping right (startToEnd) reveals up to two action buttons:
/// Edit (navy) and/or Delete (red). Provide null for actions you don't need.
class ListSwipeCard extends StatelessWidget {
  final Key itemKey;
  final Widget child;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ListSwipeCard({
    super.key,
    required this.itemKey,
    required this.child,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final sw = LocalizationService.isSwahili;
    final hasEdit = onEdit != null;
    final hasDel = onDelete != null;

    if (!hasEdit && !hasDel) return child;

    const radius14 = Radius.circular(14);

    return Slidable(
      key: itemKey,
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: hasEdit && hasDel ? 0.44 : 0.22,
        children: [
          if (hasEdit)
            SlidableAction(
              onPressed: (_) => onEdit!(),
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              icon: Icons.edit_rounded,
              label: sw ? 'Hariri' : 'Edit',
              borderRadius: BorderRadius.only(
                topLeft: radius14,
                bottomLeft: radius14,
                topRight: hasDel ? Radius.zero : radius14,
                bottomRight: hasDel ? Radius.zero : radius14,
              ),
            ),
          if (hasDel)
            SlidableAction(
              onPressed: (_) => onDelete!(),
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              icon: Icons.delete_outline_rounded,
              label: sw ? 'Futa' : 'Delete',
              borderRadius: BorderRadius.only(
                topLeft: hasEdit ? Radius.zero : radius14,
                bottomLeft: hasEdit ? Radius.zero : radius14,
                topRight: radius14,
                bottomRight: radius14,
              ),
            ),
        ],
      ),
      child: child,
    );
  }
}
