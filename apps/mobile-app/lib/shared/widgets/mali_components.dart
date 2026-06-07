import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/localization_service.dart';
import 'shimmer.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MaliCard — standard white card with 16px radius, border, subtle shadow
// ─────────────────────────────────────────────────────────────────────────────

class MaliCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Border? border;

  const MaliCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: border ?? Border.all(color: AppColors.border),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HeroCard — business navy gradient card for dashboard KPIs
// ─────────────────────────────────────────────────────────────────────────────

class HeroCard extends StatelessWidget {
  final Widget child;
  final List<Color>? gradientColors;
  final EdgeInsetsGeometry? padding;

  const HeroCard({
    super.key,
    required this.child,
    this.gradientColors,
    this.padding,
  });

  const HeroCard.business({super.key, required this.child, this.padding})
    : gradientColors = const [AppColors.navyPrimary, AppColors.navySecondary];

  @override
  Widget build(BuildContext context) {
    final colors =
        gradientColors ?? [AppColors.navyPrimary, AppColors.navySecondary];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -30,
              right: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              right: 60,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            Padding(padding: padding ?? const EdgeInsets.all(20), child: child),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PrimaryButton — yellow #FFC107, navy text, 52px height
// ─────────────────────────────────────────────────────────────────────────────

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? leadingIcon;
  final double? width;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.leadingIcon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.yellowBrand,
          foregroundColor: AppColors.navyPrimary,
          disabledBackgroundColor: AppColors.yellowBrand.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: loading
            ? const ShimmerBox(
                width: 96,
                height: 14,
                borderRadius: BorderRadius.all(Radius.circular(999)),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leadingIcon != null) ...[
                    Icon(leadingIcon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyPrimary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SecondaryButton — navy #0D1B3E, white text, 52px height
// ─────────────────────────────────────────────────────────────────────────────

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? leadingIcon;
  final double? width;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.leadingIcon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navyPrimary,
          foregroundColor: AppColors.inverseText,
          disabledBackgroundColor: AppColors.navyPrimary.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: loading
            ? const ShimmerBox(
                width: 96,
                height: 14,
                borderRadius: BorderRadius.all(Radius.circular(999)),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leadingIcon != null) ...[
                    Icon(leadingIcon, size: 20, color: AppColors.inverseText),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inverseText,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GhostButton — transparent with border, dark text
// ─────────────────────────────────────────────────────────────────────────────

class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;
  final double? width;
  final Color? borderColor;
  final Color? textColor;

  const GhostButton({
    super.key,
    required this.label,
    this.onPressed,
    this.leadingIcon,
    this.width,
    this.borderColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final fgColor = textColor ?? AppColors.textPrimary;
    return SizedBox(
      width: width ?? double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: fgColor,
          side: BorderSide(color: borderColor ?? AppColors.border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, size: 20, color: fgColor),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: fgColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AmountDisplay — hero financial figures with DM Serif Display or JetBrains Mono
// ─────────────────────────────────────────────────────────────────────────────

enum AmountDisplayStyle { hero, mono }

class AmountDisplay extends StatelessWidget {
  final String amount;
  final String? currency;
  final Color? color;
  final double fontSize;
  final AmountDisplayStyle style;

  const AmountDisplay({
    super.key,
    required this.amount,
    this.currency = 'TZS',
    this.color,
    this.fontSize = 28,
    this.style = AmountDisplayStyle.mono,
  });

  const AmountDisplay.hero({
    super.key,
    required this.amount,
    this.currency = 'TZS',
    this.color,
    this.fontSize = 32,
  }) : style = AmountDisplayStyle.hero;

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? AppColors.navyPrimary;
    final TextStyle amountStyle = style == AmountDisplayStyle.hero
        ? GoogleFonts.dmSerifDisplay(
            fontSize: fontSize,
            fontWeight: FontWeight.w400,
            color: textColor,
            height: 1.1,
          )
        : GoogleFonts.jetBrainsMono(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: textColor,
            letterSpacing: -0.5,
          );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        if (currency != null) ...[
          Text(
            '$currency ',
            style: GoogleFonts.dmSans(
              fontSize: fontSize * 0.45,
              fontWeight: FontWeight.w600,
              color: textColor.withValues(alpha: 0.6),
              letterSpacing: 0.5,
            ),
          ),
        ],
        Text(amount, style: amountStyle),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// StatusChip — paid / sent / overdue / draft / pending
// ─────────────────────────────────────────────────────────────────────────────

enum InvoiceStatus { paid, sent, overdue, draft, pending, cancelled }

class StatusChip extends StatelessWidget {
  final InvoiceStatus status;
  final String? customLabel;

  const StatusChip({super.key, required this.status, this.customLabel});

  static String _tr(String en, String sw) =>
      LocalizationService.tr(en: en, sw: sw);

  static ({Color bg, Color text, String label, IconData icon}) _resolve(
    InvoiceStatus s,
  ) {
    switch (s) {
      case InvoiceStatus.paid:
        return (
          bg: const Color(0xFFD1FAE5),
          text: AppColors.success,
          label: _tr('Paid', 'Imelipwa'),
          icon: Icons.check_circle_rounded,
        );
      case InvoiceStatus.sent:
        return (
          bg: const Color(0xFFDBEAFE),
          text: AppColors.tealAccent,
          label: _tr('Sent', 'Imetumwa'),
          icon: Icons.send_rounded,
        );
      case InvoiceStatus.overdue:
        return (
          bg: AppColors.errorBg,
          text: AppColors.error,
          label: _tr('Overdue', 'Imechelewa'),
          icon: Icons.warning_rounded,
        );
      case InvoiceStatus.draft:
        return (
          bg: AppColors.surfaceVariant,
          text: AppColors.textMuted,
          label: _tr('Draft', 'Rasimu'),
          icon: Icons.edit_rounded,
        );
      case InvoiceStatus.pending:
        return (
          bg: AppColors.warningBg,
          text: AppColors.warning,
          label: _tr('Pending', 'Inasubiri'),
          icon: Icons.hourglass_empty_rounded,
        );
      case InvoiceStatus.cancelled:
        return (
          bg: const Color(0xFFF1F5F9),
          text: AppColors.textDisabled,
          label: _tr('Cancelled', 'Imefutwa'),
          icon: Icons.cancel_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _resolve(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 12, color: config.text),
          const SizedBox(width: 4),
          Text(
            customLabel ?? config.label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: config.text,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EmptyState — canonical empty / no-data placeholder
//
// Usage:
//   EmptyState(
//     icon: Icons.receipt_long_outlined,
//     title: 'No sales yet',
//     subtitle: 'Tap New Sale to record your first transaction.',
//     actionLabel: 'New Sale',   // optional
//     onAction: () { ... },      // optional
//   )
// ─────────────────────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  /// Label for the optional primary CTA button.
  final String? actionLabel;

  /// Called when the CTA is tapped.
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  /// Pastel icon tint — soft steel-blue that stays invisible against content.
  static const _iconColor = Color(0xFFB0C4DE);

  /// Icon container background — near-white slate.
  static const _containerColor = Color(0xFFF1F5F9);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon container ─────────────────────────────────────────────
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _containerColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 32, color: _iconColor),
            ),
            const SizedBox(height: 20),

            // ── Title ──────────────────────────────────────────────────────
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.navyPrimary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),

            // ── Subtitle ───────────────────────────────────────────────────
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.55,
              ),
            ),

            // ── CTA button ─────────────────────────────────────────────────
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 22),
              SizedBox(
                width: 220,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.navyPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11)),
                    textStyle: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton loaders — screen-level skeletons using ShimmerBox
// ─────────────────────────────────────────────────────────────────────────────

class SkeletonListItem extends StatelessWidget {
  final bool hasLeadingCircle;
  final bool hasTrailing;

  const SkeletonListItem({
    super.key,
    this.hasLeadingCircle = true,
    this.hasTrailing = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          if (hasLeadingCircle) ...[
            const ShimmerBox(
              width: 44,
              height: 44,
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            const SizedBox(width: 12),
          ],
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(
                  width: double.infinity,
                  height: 12,
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
                SizedBox(height: 8),
                ShimmerBox(
                  width: 140,
                  height: 10,
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
              ],
            ),
          ),
          if (hasTrailing) ...[
            const SizedBox(width: 12),
            const ShimmerBox(
              width: 64,
              height: 12,
              borderRadius: BorderRadius.all(Radius.circular(999)),
            ),
          ],
        ],
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  final int itemCount;

  const SkeletonList({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => const SkeletonListItem(),
    );
  }
}

class SkeletonScreen extends StatelessWidget {
  final bool hasHeader;
  final int listItems;

  const SkeletonScreen({super.key, this.hasHeader = true, this.listItems = 5});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasHeader) ...[
                const ShimmerBox(
                  width: 200,
                  height: 20,
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
                const SizedBox(height: 8),
                const ShimmerBox(
                  width: 280,
                  height: 14,
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
                const SizedBox(height: 24),
              ],
              Expanded(child: SkeletonList(itemCount: listItems)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page-specific skeleton screens — each mirrors its page's real content shape
// ─────────────────────────────────────────────────────────────────────────────

/// Stats column used inside page skeletons (value + label shimmer)
class _PageSkeletonStat extends StatelessWidget {
  const _PageSkeletonStat();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShimmerBox(width: 72, height: 14, borderRadius: BorderRadius.all(Radius.circular(4))),
        SizedBox(height: 6),
        ShimmerBox(width: 50, height: 11, borderRadius: BorderRadius.all(Radius.circular(999))),
      ],
    );
  }
}

/// Sales / Invoice list page skeleton
class SalesPageSkeleton extends StatelessWidget {
  const SalesPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          color: AppColors.surface,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _PageSkeletonStat(),
              _PageSkeletonStat(),
              _PageSkeletonStat(),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: SkeletonList(itemCount: 6),
          ),
        ),
      ],
    );
  }
}

/// Inventory / Stock page skeleton
class InventoryPageSkeleton extends StatelessWidget {
  const InventoryPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(child: ShimmerBox(height: 68)),
              SizedBox(width: 16),
              Expanded(child: ShimmerBox(height: 68)),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: SkeletonList(itemCount: 6),
          ),
        ),
      ],
    );
  }
}

/// Customer list page skeleton
class CustomerPageSkeleton extends StatelessWidget {
  const CustomerPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: ShimmerBox(height: 46, borderRadius: BorderRadius.all(Radius.circular(12))),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: ShimmerBox(height: 46, borderRadius: BorderRadius.all(Radius.circular(12))),
        ),
        SizedBox(height: 4),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: SkeletonList(itemCount: 7),
          ),
        ),
      ],
    );
  }
}

/// Expense list page skeleton
class ExpensePageSkeleton extends StatelessWidget {
  const ExpensePageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: ShimmerBox(height: 46, borderRadius: BorderRadius.all(Radius.circular(12))),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(24, 4, 24, 16),
          child: Row(
            children: [
              Expanded(child: ShimmerBox(height: 62, borderRadius: BorderRadius.all(Radius.circular(12)))),
              SizedBox(width: 12),
              Expanded(child: ShimmerBox(height: 62, borderRadius: BorderRadius.all(Radius.circular(12)))),
            ],
          ),
        ),
        SizedBox(height: 8),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: SkeletonList(),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DebtListSkeleton — sliver skeleton for the debt tracking tabs
// ─────────────────────────────────────────────────────────────────────────────

/// A single debt card-shaped shimmer placeholder matching _DebtCard's layout.
class DebtCardSkeleton extends StatelessWidget {
  const DebtCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: const Row(
        children: [
          ShimmerBox(
            width: 42,
            height: 42,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShimmerBox(
                  width: 140,
                  height: 11,
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
                SizedBox(height: 7),
                ShimmerBox(
                  width: 90,
                  height: 10,
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShimmerBox(
                width: 72,
                height: 12,
                borderRadius: BorderRadius.all(Radius.circular(999)),
              ),
              SizedBox(height: 6),
              ShimmerBox(
                width: 40,
                height: 9,
                borderRadius: BorderRadius.all(Radius.circular(999)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Sliver version — drop straight into a CustomScrollView.
class SliverDebtListSkeleton extends StatelessWidget {
  final int itemCount;
  const SliverDebtListSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) => const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: DebtCardSkeleton(),
          ),
          childCount: itemCount,
        ),
      ),
    );
  }
}

/// Plain (non-sliver) version for tabs rendered as regular widgets.
class DebtTabSkeleton extends StatelessWidget {
  final int itemCount;
  const DebtTabSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: itemCount,
      separatorBuilder: (ctx, i) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => const DebtCardSkeleton(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PlanBadge — shows Free / Premium tier inline
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// MaliSelectField — tappable input-style field that opens a picker
// ─────────────────────────────────────────────────────────────────────────────

class MaliSelectField extends StatelessWidget {
  final String placeholder;
  final String displayValue;
  final bool hasValue;
  final VoidCallback onTap;
  final IconData icon;

  const MaliSelectField({
    super.key,
    required this.placeholder,
    required this.displayValue,
    required this.hasValue,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: InputDecorator(
        isEmpty: !hasValue,
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: const TextStyle(color: AppColors.textMuted),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Icon(
              icon,
              size: 20,
              color: hasValue ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
          suffixIcon: const Icon(
            Icons.expand_more_rounded,
            size: 20,
            color: AppColors.textMuted,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        child: hasValue
            ? Text(
                displayValue,
                style: GoogleFonts.poppins(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
              )
            : null,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MaliSelectSheet<T> — modal bottom sheet list picker
// ─────────────────────────────────────────────────────────────────────────────

class MaliSelectSheet<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final T? selectedValue;
  final String Function(T) labelBuilder;
  final IconData Function(T)? iconBuilder;

  const MaliSelectSheet({
    super.key,
    required this.title,
    required this.items,
    required this.selectedValue,
    required this.labelBuilder,
    this.iconBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.62,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final label = labelBuilder(item);
                  final icon = iconBuilder?.call(item);
                  final isSelected = item == selectedValue;
                  return InkWell(
                    onTap: () => Navigator.of(context).pop(item),
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.06)
                          : Colors.transparent,
                      child: Row(
                        children: [
                          if (icon != null) ...[
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.1)
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                icon,
                                size: 17,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 14),
                          ],
                          Expanded(
                            child: Text(
                              label,
                              style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 20,
                              color: AppColors.primary,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SafeArea(top: false, child: SizedBox(height: 8)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PlanBadge — shows Free / Premium tier inline
// ─────────────────────────────────────────────────────────────────────────────

class PlanBadge extends StatelessWidget {
  final bool isPremium;

  const PlanBadge({super.key, required this.isPremium});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: isPremium
            ? const LinearGradient(
                colors: [AppColors.yellowBrand, Color(0xFFE5AC00)],
              )
            : null,
        color: isPremium ? null : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: isPremium ? null : Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          isPremium ? '★ Premium' : 'Bure',
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isPremium ? AppColors.navyPrimary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PaymentStatusChip — compact pill for paid / partial / pending / overdue etc.
// Accepts raw string status values used across invoices, debts, and sales.
// ─────────────────────────────────────────────────────────────────────────────

class PaymentStatusChip extends StatelessWidget {
  final String status;

  const PaymentStatusChip({super.key, required this.status});

  static String _tr(String en, String sw) =>
      LocalizationService.tr(en: en, sw: sw);

  static ({Color bg, Color fg, String label, IconData icon}) _resolve(
      String s) {
    switch (s.toLowerCase().trim()) {
      case 'paid':
        return (
          bg: const Color(0xFFD1FAE5),
          fg: AppColors.success,
          label: _tr('Paid', 'Imelipwa'),
          icon: Icons.check_circle_rounded,
        );
      case 'partial':
        return (
          bg: const Color(0xFFFFF3CD),
          fg: const Color(0xFF92600A),
          label: _tr('Partial', 'Sehemu'),
          icon: Icons.timelapse_rounded,
        );
      case 'overdue':
        return (
          bg: AppColors.errorBg,
          fg: AppColors.error,
          label: _tr('Overdue', 'Imechelewa'),
          icon: Icons.warning_rounded,
        );
      case 'sent':
        return (
          bg: const Color(0xFFDBEAFE),
          fg: AppColors.tealAccent,
          label: _tr('Sent', 'Imetumwa'),
          icon: Icons.send_rounded,
        );
      case 'draft':
        return (
          bg: AppColors.surfaceVariant,
          fg: AppColors.textMuted,
          label: _tr('Draft', 'Rasimu'),
          icon: Icons.edit_rounded,
        );
      case 'cancelled':
        return (
          bg: const Color(0xFFF1F5F9),
          fg: AppColors.textDisabled,
          label: _tr('Cancelled', 'Imefutwa'),
          icon: Icons.cancel_rounded,
        );
      case 'written_off':
        return (
          bg: const Color(0xFFF1F5F9),
          fg: AppColors.textDisabled,
          label: _tr('Written Off', 'Imeandikwa'),
          icon: Icons.remove_circle_outline_rounded,
        );
      default: // pending / current / unknown
        return (
          bg: AppColors.warningBg,
          fg: AppColors.warning,
          label: _tr('Pending', 'Inasubiri'),
          icon: Icons.hourglass_empty_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _resolve(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(c.icon, size: 11, color: c.fg),
          const SizedBox(width: 3),
          Text(
            c.label,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: c.fg,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppSearchBar — standard inventory-style search bar
// ─────────────────────────────────────────────────────────────────────────────

class AppSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final EdgeInsetsGeometry padding;
  final FocusNode? focusNode;

  const AppSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.onClear,
    this.focusNode,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (_, value, _) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.navyPrimary),
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
              suffixIcon: value.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                      onPressed: () {
                        controller.clear();
                        onClear?.call();
                        onChanged?.call('');
                      },
                    )
                  : null,
              isDense: true,
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.navyPrimary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppFilterChip — pill-style filter button for horizontal filter bars
// ─────────────────────────────────────────────────────────────────────────────

class AppFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.navyPrimary : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.navyPrimary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textMuted,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.25)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppSectionHeader — consistent section title with optional trailing action
// ─────────────────────────────────────────────────────────────────────────────

class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(24, 20, 24, 8),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.tealAccent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
