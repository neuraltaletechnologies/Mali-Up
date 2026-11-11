import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// A scrolling list that becomes a grid of cards when there is room.
///
/// On a phone it's a plain one-column [ListView] of full-width rows (the
/// existing look). Once the available width fits two or more cards of at
/// least [minCardWidth] — a laptop/desktop window, or a tablet in either
/// orientation — the same rows are laid out side by side, each wrapped in
/// its own bordered card, the way the Sales screen's POS catalog looks.
///
/// [itemBuilder] gets `inGrid` so a row can drop its bottom divider, which
/// only makes sense between stacked rows.
class ResponsiveCardList extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index, bool inGrid)
  itemBuilder;
  final ScrollPhysics? physics;

  /// Bottom padding so the last row clears a FAB / bottom nav.
  final double bottomPadding;
  final double minCardWidth;

  const ResponsiveCardList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.physics,
    this.bottomPadding = 120,
    this.minCardWidth = 340,
  });

  static const double _gap = 12;
  static const double _hPad = 16;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final usable = constraints.maxWidth - _hPad * 2;
        final columns = ((usable + _gap) / (minCardWidth + _gap)).floor();

        if (columns < 2) {
          return ListView.builder(
            physics: physics,
            padding: EdgeInsets.only(bottom: bottomPadding),
            itemCount: itemCount,
            itemBuilder: (ctx, i) => itemBuilder(ctx, i, false),
          );
        }

        final rowCount = (itemCount / columns).ceil();
        return ListView.builder(
          physics: physics,
          padding: EdgeInsets.fromLTRB(_hPad, 4, _hPad, bottomPadding),
          itemCount: rowCount,
          itemBuilder: (ctx, row) {
            final cells = <Widget>[];
            for (var c = 0; c < columns; c++) {
              if (c > 0) cells.add(const SizedBox(width: _gap));
              final i = row * columns + c;
              cells.add(
                Expanded(
                  child: i < itemCount
                      ? _GridCard(child: itemBuilder(ctx, i, true))
                      : const SizedBox.shrink(),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: _gap),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: cells,
              ),
            );
          },
        );
      },
    );
  }
}

class _GridCard extends StatelessWidget {
  final Widget child;
  const _GridCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyPrimary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
