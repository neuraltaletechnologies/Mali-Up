import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
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

  const HeroCard.business({
    super.key,
    required this.child,
    this.padding,
  }) : gradientColors = const [AppColors.navyPrimary, AppColors.navySecondary];

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ?? [AppColors.navyPrimary, AppColors.navySecondary];
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
            Padding(
              padding: padding ?? const EdgeInsets.all(20),
              child: child,
            ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.navyPrimary),
                ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.inverseText),
                ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  static ({Color bg, Color text, String label, IconData icon}) _resolve(InvoiceStatus s) {
    switch (s) {
      case InvoiceStatus.paid:
        return (bg: const Color(0xFFD1FAE5), text: AppColors.success, label: 'Imelipwa', icon: Icons.check_circle_rounded);
      case InvoiceStatus.sent:
        return (bg: const Color(0xFFDBEAFE), text: AppColors.tealAccent, label: 'Imetumwa', icon: Icons.send_rounded);
      case InvoiceStatus.overdue:
        return (bg: AppColors.errorBg, text: AppColors.error, label: 'Imechelewa', icon: Icons.warning_rounded);
      case InvoiceStatus.draft:
        return (bg: AppColors.surfaceVariant, text: AppColors.textMuted, label: 'Rasimu', icon: Icons.edit_rounded);
      case InvoiceStatus.pending:
        return (bg: AppColors.warningBg, text: AppColors.warning, label: 'Inasubiri', icon: Icons.hourglass_empty_rounded);
      case InvoiceStatus.cancelled:
        return (bg: const Color(0xFFF1F5F9), text: AppColors.textDisabled, label: 'Imefutwa', icon: Icons.cancel_rounded);
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
// EmptyState — icon + title + subtitle + optional action
// ─────────────────────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(icon, size: 36, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              PrimaryButton(label: actionLabel!, onPressed: onAction, width: 200),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ContextSwitcher — pill toggle for personal/business (future use)
// ─────────────────────────────────────────────────────────────────────────────

enum AppContext { personal, business }

class ContextSwitcher extends StatelessWidget {
  final AppContext current;
  final ValueChanged<AppContext> onChanged;

  const ContextSwitcher({super.key, required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Pill(
            label: 'Biashara',
            icon: Icons.business_center_rounded,
            active: current == AppContext.business,
            activeColor: AppColors.navyPrimary,
            onTap: () => onChanged(AppContext.business),
          ),
          const SizedBox(width: 4),
          _Pill(
            label: 'Binafsi',
            icon: Icons.person_rounded,
            active: current == AppContext.personal,
            activeColor: AppColors.purpleAccent,
            onTap: () => onChanged(AppContext.personal),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _Pill({
    required this.label,
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: active ? AppColors.inverseText : AppColors.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? AppColors.inverseText : AppColors.textMuted,
              ),
            ),
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
            const ShimmerBox(width: 44, height: 44, borderRadius: BorderRadius.all(Radius.circular(14))),
            const SizedBox(width: 12),
          ],
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: double.infinity, height: 12, borderRadius: BorderRadius.all(Radius.circular(999))),
                SizedBox(height: 8),
                ShimmerBox(width: 140, height: 10, borderRadius: BorderRadius.all(Radius.circular(999))),
              ],
            ),
          ),
          if (hasTrailing) ...[
            const SizedBox(width: 12),
            const ShimmerBox(width: 64, height: 12, borderRadius: BorderRadius.all(Radius.circular(999))),
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
    return Column(
      children: List.generate(
        itemCount,
        (i) => Padding(
          padding: EdgeInsets.only(bottom: i == itemCount - 1 ? 0 : 10),
          child: const SkeletonListItem(),
        ),
      ),
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
                const ShimmerBox(width: 200, height: 20, borderRadius: BorderRadius.all(Radius.circular(999))),
                const SizedBox(height: 8),
                const ShimmerBox(width: 280, height: 14, borderRadius: BorderRadius.all(Radius.circular(999))),
                const SizedBox(height: 24),
              ],
              SkeletonList(itemCount: listItems),
            ],
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: isPremium
            ? const LinearGradient(colors: [AppColors.yellowBrand, Color(0xFFE5AC00)])
            : null,
        color: isPremium ? null : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: isPremium ? null : Border.all(color: AppColors.border),
      ),
      child: Text(
        isPremium ? '★ Premium' : 'Bure',
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isPremium ? AppColors.navyPrimary : AppColors.textMuted,
        ),
      ),
    );
  }
}
