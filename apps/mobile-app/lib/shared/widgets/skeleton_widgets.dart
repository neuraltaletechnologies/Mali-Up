import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'shimmer.dart';

// ── Base skeleton building block ──────────────────────────────────────────────
// Wraps ShimmerBox with a default borderRadius suited for text/content (r8)
// rather than cards (r16). Use ShimmerBox directly when you need r16.

class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerBox(
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }
}

// ── Skeleton text line ────────────────────────────────────────────────────────

class SkeletonText extends StatelessWidget {
  final double? width;
  final double height;

  const SkeletonText({super.key, this.width, this.height = 13});

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: width,
      height: height,
      borderRadius: const BorderRadius.all(Radius.circular(999)),
    );
  }
}

// ── Skeleton avatar ───────────────────────────────────────────────────────────

class SkeletonAvatar extends StatelessWidget {
  final double size;
  final bool circle;

  const SkeletonAvatar({super.key, this.size = 40, this.circle = true});

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: size,
      height: size,
      borderRadius: circle
          ? BorderRadius.all(Radius.circular(size / 2))
          : const BorderRadius.all(Radius.circular(12)),
    );
  }
}

// ── Skeleton list tile ────────────────────────────────────────────────────────

class SkeletonListTile extends StatelessWidget {
  final bool hasSubtitle;
  final bool hasLeadingIcon;
  final bool hasTrailing;

  const SkeletonListTile({
    super.key,
    this.hasSubtitle = true,
    this.hasLeadingIcon = true,
    this.hasTrailing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        children: [
          if (hasLeadingIcon) ...[
            const SkeletonBox(
              width: 40,
              height: 40,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonText(
                  width: MediaQuery.of(context).size.width * 0.42,
                  height: 14,
                ),
                if (hasSubtitle) ...[
                  const SizedBox(height: 6),
                  SkeletonText(
                    width: MediaQuery.of(context).size.width * 0.28,
                    height: 11,
                  ),
                ],
              ],
            ),
          ),
          if (hasTrailing) ...[
            const SizedBox(width: 12),
            const SkeletonText(width: 48, height: 12),
          ],
        ],
      ),
    );
  }
}

// ── Skeleton generic card ─────────────────────────────────────────────────────

class SkeletonCard extends StatelessWidget {
  final double height;
  final EdgeInsetsGeometry padding;

  const SkeletonCard({
    super.key,
    this.height = 80,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SkeletonText(width: 120, height: 14),
          SizedBox(height: 8),
          SkeletonText(width: 180, height: 11),
        ],
      ),
    );
  }
}

// ── Skeleton stat card (for dashboard-style KPI tiles) ───────────────────────

class SkeletonStatCard extends StatelessWidget {
  const SkeletonStatCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonText(width: 80, height: 11),
          SizedBox(height: 8),
          SkeletonBox(
            height: 24,
            width: 120,
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
          SizedBox(height: 6),
          SkeletonText(width: 60, height: 10),
        ],
      ),
    );
  }
}

// ── Skeleton plan info card (subscription screen) ─────────────────────────────

class SkeletonPlanCard extends StatelessWidget {
  const SkeletonPlanCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              SkeletonAvatar(circle: false),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonText(width: 100, height: 16),
                    SizedBox(height: 6),
                    SkeletonText(width: 80, height: 11),
                  ],
                ),
              ),
              SkeletonBox(
                width: 70,
                height: 28,
                borderRadius: BorderRadius.all(Radius.circular(999)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Column(
                    children: [
                      SkeletonText(width: 40, height: 10),
                      SizedBox(height: 5),
                      SkeletonText(width: 60, height: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Column(
                    children: [
                      SkeletonText(width: 40, height: 10),
                      SizedBox(height: 5),
                      SkeletonText(width: 60, height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Skeleton usage meter ──────────────────────────────────────────────────────

class SkeletonUsageMeter extends StatelessWidget {
  const SkeletonUsageMeter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonText(width: 80, height: 14),
              SkeletonText(width: 50, height: 12),
            ],
          ),
          SizedBox(height: 10),
          SkeletonBox(
            height: 8,
            borderRadius: BorderRadius.all(Radius.circular(999)),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton comparison table ─────────────────────────────────────────────────

class SkeletonComparisonTable extends StatelessWidget {
  const SkeletonComparisonTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: SizedBox()),
                Expanded(
                  flex: 2,
                  child: Center(child: SkeletonText(width: 42, height: 11)),
                ),
                Expanded(
                  flex: 2,
                  child: Center(child: SkeletonText(width: 42, height: 11)),
                ),
                Expanded(
                  flex: 2,
                  child: Center(child: SkeletonText(width: 52, height: 11)),
                ),
              ],
            ),
          ),
          ...List.generate(
            6,
            (i) => Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: i < 5
                    ? const Border(
                        bottom: BorderSide(
                          color: AppColors.border,
                          width: 0.5,
                        ),
                      )
                    : null,
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: EdgeInsets.only(left: 14),
                      child: SkeletonText(width: 100, height: 12),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: SkeletonBox(
                        width: 16,
                        height: 16,
                        borderRadius: BorderRadius.all(Radius.circular(999)),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: SkeletonBox(
                        width: 16,
                        height: 16,
                        borderRadius: BorderRadius.all(Radius.circular(999)),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: SkeletonBox(
                        width: 16,
                        height: 16,
                        borderRadius: BorderRadius.all(Radius.circular(999)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Full subscription body skeleton ──────────────────────────────────────────
// Mirrors the layout of SubscriptionScreen so there is zero layout shift.

class SkeletonSubscriptionBody extends StatelessWidget {
  const SkeletonSubscriptionBody({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: const [
        SkeletonPlanCard(),
        SizedBox(height: 28),
        SkeletonText(width: 130),
        SizedBox(height: 12),
        SkeletonUsageMeter(),
        SizedBox(height: 28),
        SkeletonText(width: 110),
        SizedBox(height: 12),
        SkeletonComparisonTable(),
        SizedBox(height: 28),
        SkeletonText(width: 150),
        SizedBox(height: 12),
        SkeletonCard(height: 56, padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
        SizedBox(height: 8),
        SkeletonCard(height: 56, padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
        SizedBox(height: 8),
        SkeletonCard(height: 56, padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
      ],
    );
  }
}

// ── Skeleton business card ────────────────────────────────────────────────────

class SkeletonBusinessCard extends StatelessWidget {
  const SkeletonBusinessCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          SkeletonAvatar(size: 48, circle: false),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonText(width: 140, height: 14),
                SizedBox(height: 6),
                SkeletonText(width: 90, height: 11),
              ],
            ),
          ),
          SkeletonBox(
            width: 20,
            height: 20,
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ],
      ),
    );
  }
}

// ── Full business-list skeleton (manage_businesses_screen) ────────────────────

class SkeletonBusinessList extends StatelessWidget {
  const SkeletonBusinessList({super.key});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return ListView(
      padding: EdgeInsets.fromLTRB(20, topPad + 62, 20, 40),
      children: const [
        ShimmerBox(
          height: 160,
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        SizedBox(height: 28),
        Row(
          children: [
            SkeletonText(width: 110, height: 14),
            Spacer(),
            ShimmerBox(
              width: 28,
              height: 22,
              borderRadius: BorderRadius.all(Radius.circular(999)),
            ),
          ],
        ),
        SizedBox(height: 12),
        SkeletonBusinessCard(),
        SkeletonBusinessCard(),
      ],
    );
  }
}

// ── Skeleton sync log entry ───────────────────────────────────────────────────

class SkeletonSyncEntry extends StatelessWidget {
  const SkeletonSyncEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Row(
        children: [
          const SkeletonBox(width: 28, height: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonText(width: 150, height: 12),
                const SizedBox(height: 5),
                SkeletonText(
                  width: MediaQuery.of(context).size.width * 0.38,
                  height: 10,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const SkeletonText(width: 50, height: 10),
        ],
      ),
    );
  }
}

// ── Skeleton biometric page content ──────────────────────────────────────────
// Mirrors the BiometricSetupScreen body while local-auth is checking availability.

class SkeletonBiometricContent extends StatelessWidget {
  const SkeletonBiometricContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonText(width: 140, height: 22),
          const SizedBox(height: 8),
          const SkeletonText(width: 240, height: 14),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: [
                SkeletonBox(
                  width: 24,
                  height: 24,
                  borderRadius: BorderRadius.all(Radius.circular(6)),
                ),
                SizedBox(width: 12),
                Expanded(child: SkeletonText()),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const SkeletonText(width: 80, height: 22),
          const SizedBox(height: 8),
          const SkeletonText(width: 180, height: 14),
          const SizedBox(height: 16),
          const SkeletonBox(
            height: 52,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonText(width: 140, height: 14),
                SizedBox(height: 10),
                SkeletonText(height: 11),
                SizedBox(height: 6),
                SkeletonText(height: 11),
                SizedBox(height: 6),
                SkeletonText(height: 11),
                SizedBox(height: 6),
                SkeletonText(width: 200, height: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── SkeletonList — generic vertical list of cards ────────────────────────────
// Used in inventory_list_screen (already referenced as SkeletonList) and
// anywhere else a simple vertical skeleton list is needed.

class SkeletonList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const SkeletonList({super.key, this.itemCount = 6, this.itemHeight = 76});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => ShimmerBox(height: itemHeight),
    );
  }
}
