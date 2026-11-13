import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/localization_service.dart';
import '../../core/theme/app_colors.dart';

/// The Sales screen's point-of-sale product card, shared by every list page
/// on wide screens (products, debts, team, businesses…) so they all look the
/// same: a picture (or a soft coloured initials tile) on top, then a bold
/// name, a value line and a coloured status line, with a hover lift and a
/// press shrink.
///
/// Swipe actions don't work in a grid, so [onEdit] / [onDelete] appear in a
/// ⋮ menu on the picture (shown on hover), on right-click and on long-press.

// ── Grid ─────────────────────────────────────────────────────────────────────

/// Grid geometry of the POS catalog — every tile grid uses the same numbers.
const posTileGridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 190,
  mainAxisSpacing: 14,
  crossAxisSpacing: 14,
  childAspectRatio: 0.78,
);

/// A scrolling grid of [PosTile]s.
class PosTileGrid extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry padding;

  const PosTileGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.physics,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 24),
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: physics,
      padding: padding,
      gridDelegate: posTileGridDelegate,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}

/// [PosTileGrid] for a [CustomScrollView].
class SliverPosTileGrid extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry padding;

  const SliverPosTileGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 12),
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: padding,
      sliver: SliverGrid(
        gridDelegate: posTileGridDelegate,
        delegate: SliverChildBuilderDelegate(
          itemBuilder,
          childCount: itemCount,
        ),
      ),
    );
  }
}

// ── Picture / placeholder ────────────────────────────────────────────────────

const _tileColors = [
  Color(0xFFE0F2FE),
  Color(0xFFFEF3C7),
  Color(0xFFDCFCE7),
  Color(0xFFFCE7F3),
  Color(0xFFEDE9FE),
  Color(0xFFFFEDD5),
];

/// Soft pastel picked from the first letter of [name], so a given name always
/// gets the same colour.
Color posTileColorFor(String name) =>
    _tileColors[name.isEmpty ? 0 : name.codeUnitAt(0) % _tileColors.length];

/// One or two uppercase initials of [name] ('?' when empty).
String posInitials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return (parts[0].characters.first + parts[1].characters.first).toUpperCase();
}

/// A network picture when [imageUrl] is set, otherwise a pastel tile with the
/// initials of [name] (or [icon] when given).
class PosTileImage extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final IconData? icon;
  final double fontSize;

  const PosTileImage({
    super.key,
    required this.name,
    this.imageUrl,
    this.icon,
    this.fontSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    final placeholder = Container(
      color: posTileColorFor(name),
      alignment: Alignment.center,
      child: icon != null
          ? Icon(icon, size: fontSize * 1.2, color: AppColors.navyPrimary)
          : Text(
              posInitials(name),
              style: GoogleFonts.dmSans(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                color: AppColors.navyPrimary.withValues(alpha: 0.75),
              ),
            ),
    );
    if (url.isEmpty) return placeholder;
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => placeholder,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : placeholder,
    );
  }
}

// ── Tile ─────────────────────────────────────────────────────────────────────

class PosTile extends StatefulWidget {
  final String title;

  /// Top area. Defaults to a [PosTileImage] of [title] / [imageUrl] / [icon].
  final Widget? image;
  final String? imageUrl;
  final IconData? icon;

  /// Optional muted one-liner under the title (phone, category…).
  final String? subtitle;

  /// Bold line under the title — an amount in the POS catalog.
  final String? value;
  final Color valueColor;

  /// Money in JetBrains Mono (POS style); plain text otherwise.
  final bool valueIsMoney;

  /// Small coloured line at the bottom (stock, due date, member status…).
  final String? status;
  final Color? statusColor;

  /// Overlaid on the picture's top-left corner (a status pill, plan badge…).
  final Widget? badge;

  /// Teal border, e.g. the active business.
  final bool selected;

  /// Faded and not tappable (an out-of-stock product).
  final bool disabled;

  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PosTile({
    super.key,
    required this.title,
    this.image,
    this.imageUrl,
    this.icon,
    this.subtitle,
    this.value,
    this.valueColor = AppColors.tealAccent,
    this.valueIsMoney = true,
    this.status,
    this.statusColor,
    this.badge,
    this.selected = false,
    this.disabled = false,
    this.onTap,
    this.onDoubleTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<PosTile> createState() => _PosTileState();
}

enum _TileAction { edit, delete }

class _PosTileState extends State<PosTile> {
  bool _hover = false;
  bool _pressed = false;

  bool get _hasActions => widget.onEdit != null || widget.onDelete != null;

  void _run(_TileAction? a) {
    if (a == _TileAction.edit) widget.onEdit?.call();
    if (a == _TileAction.delete) widget.onDelete?.call();
  }

  List<PopupMenuEntry<_TileAction>> _menuItems() {
    final sw = LocalizationService.isSwahili;
    PopupMenuItem<_TileAction> item(
      _TileAction a,
      IconData icon,
      String label,
      Color color,
    ) => PopupMenuItem(
      value: a,
      height: 40,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
    return [
      if (widget.onEdit != null)
        item(
          _TileAction.edit,
          Icons.edit_rounded,
          sw ? 'Hariri' : 'Edit',
          AppColors.navyPrimary,
        ),
      if (widget.onDelete != null)
        item(
          _TileAction.delete,
          Icons.delete_outline_rounded,
          sw ? 'Futa' : 'Delete',
          AppColors.error,
        ),
    ];
  }

  Future<void> _showContextMenu(Offset globalPos) async {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;
    final a = await showMenu<_TileAction>(
      context: context,
      position: RelativeRect.fromRect(
        globalPos & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: _menuItems(),
    );
    _run(a);
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final disabled = w.disabled;
    final interactive = !disabled && (w.onTap != null || w.onDoubleTap != null);
    final lifted = _hover && !disabled;

    final borderColor = w.selected
        ? AppColors.tealAccent
        : lifted
        ? AppColors.tealAccent.withValues(alpha: 0.5)
        : AppColors.border;

    final image =
        w.image ??
        PosTileImage(
          name: w.title,
          imageUrl: w.imageUrl,
          icon: w.icon,
          fontSize: 26,
        );

    return MouseRegion(
      cursor: disabled
          ? SystemMouseCursors.forbidden
          : interactive
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: interactive ? (_) => setState(() => _pressed = true) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: disabled ? null : w.onTap,
        onDoubleTap: disabled ? null : w.onDoubleTap,
        onSecondaryTapUp: _hasActions
            ? (d) => _showContextMenu(d.globalPosition)
            : null,
        // Touch screens have no hover, so long-press opens the same menu.
        onLongPressStart: _hasActions
            ? (d) {
                setState(() => _pressed = false);
                _showContextMenu(d.globalPosition);
              }
            : null,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1,
          duration: const Duration(milliseconds: 110),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: w.selected ? 1.6 : 1,
              ),
              boxShadow: lifted
                  ? const [
                      BoxShadow(
                        color: Color(0x1A0D1B3E),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: Opacity(
              opacity: disabled ? 0.5 : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        image,
                        if (w.badge != null)
                          Positioned(top: 8, left: 8, child: w.badge!),
                        if (_hasActions)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IgnorePointer(
                              ignoring: !_hover,
                              child: AnimatedOpacity(
                                opacity: _hover ? 1 : 0,
                                duration: const Duration(milliseconds: 140),
                                child: _MenuButton(
                                  items: _menuItems,
                                  onSelected: _run,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          w.title,
                          maxLines: w.subtitle == null ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            height: 1.25,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navyPrimary,
                          ),
                        ),
                        if (w.subtitle != null && w.subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            w.subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                        if (w.value != null && w.value!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            w.value!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: w.valueIsMoney
                                ? GoogleFonts.jetBrainsMono(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: w.valueColor,
                                  )
                                : GoogleFonts.dmSans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: w.valueColor,
                                  ),
                          ),
                        ],
                        if (w.status != null && w.status!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            w.status!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: w.statusColor ?? AppColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final List<PopupMenuEntry<_TileAction>> Function() items;
  final ValueChanged<_TileAction> onSelected;

  const _MenuButton({required this.items, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      elevation: 1,
      child: PopupMenuButton<_TileAction>(
        tooltip: LocalizationService.isSwahili ? 'Zaidi' : 'More',
        icon: const Icon(
          Icons.more_vert_rounded,
          size: 18,
          color: AppColors.navyPrimary,
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 140),
        iconSize: 18,
        style: IconButton.styleFrom(
          minimumSize: const Size(30, 30),
          fixedSize: const Size(30, 30),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        itemBuilder: (_) => items(),
        onSelected: onSelected,
      ),
    );
  }
}
