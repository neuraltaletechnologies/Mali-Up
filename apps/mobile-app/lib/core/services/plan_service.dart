import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Plan tiers
// Free:    Up to 20 invoices/month — no credit card required
// Premium: TZS 3,000/month — unlimited invoices + M-Pesa import
//          Note: M-Pesa import uses manual verification initially
// ─────────────────────────────────────────────────────────────────────────────

enum PlanTier { free, premium }

const int kFreeInvoiceMonthlyLimit = 20;
const int kPremiumPriceMonthlyTZS = 3000;

class PlanStatus {
  final PlanTier tier;
  final int invoicesUsedThisMonth;
  final DateTime? premiumExpiresAt;

  const PlanStatus({
    required this.tier,
    required this.invoicesUsedThisMonth,
    this.premiumExpiresAt,
  });

  bool get isPremium => tier == PlanTier.premium;
  bool get isFree => tier == PlanTier.free;

  int get invoicesRemaining =>
      isPremium ? 999999 : (kFreeInvoiceMonthlyLimit - invoicesUsedThisMonth).clamp(0, kFreeInvoiceMonthlyLimit);

  bool get canCreateInvoice => isPremium || invoicesUsedThisMonth < kFreeInvoiceMonthlyLimit;

  double get usagePercent =>
      isPremium ? 0 : (invoicesUsedThisMonth / kFreeInvoiceMonthlyLimit).clamp(0.0, 1.0);
}

class PlanService {
  static final _firestore = FirebaseFirestore.instance;

  static Future<PlanStatus> fetchStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const PlanStatus(tier: PlanTier.free, invoicesUsedThisMonth: 0);

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data() ?? {};

      final tierRaw = (data['plan'] as String?)?.toLowerCase();
      final tier = tierRaw == 'premium' ? PlanTier.premium : PlanTier.free;

      final premiumExpiresRaw = data['premiumExpiresAt'];
      DateTime? expiresAt;
      if (premiumExpiresRaw is Timestamp) {
        expiresAt = premiumExpiresRaw.toDate();
      }

      // If premium has expired, treat as free
      final effectiveTier = (tier == PlanTier.premium && expiresAt != null && expiresAt.isBefore(DateTime.now()))
          ? PlanTier.free
          : tier;

      // Count invoices created this calendar month from the active business
      final selectedBusinessId = (data['selectedBusinessId'] as String?)?.trim();
      int invoiceCount = 0;
      if (selectedBusinessId != null && selectedBusinessId.isNotEmpty) {
        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month);
        final invoiceSnap = await _firestore
            .collection('businesses')
            .doc(selectedBusinessId)
            .collection('invoices')
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
            .count()
            .get();
        invoiceCount = invoiceSnap.count ?? 0;
      }

      return PlanStatus(
        tier: effectiveTier,
        invoicesUsedThisMonth: invoiceCount,
        premiumExpiresAt: expiresAt,
      );
    } catch (_) {
      return const PlanStatus(tier: PlanTier.free, invoicesUsedThisMonth: 0);
    }
  }

  /// Mark a user as premium after confirmed M-Pesa payment.
  /// Note: M-Pesa verification is manual for now — agent reviews payment
  /// screenshot and calls this after confirmation.
  static Future<void> activatePremium({required String uid, required int months}) async {
    final expiresAt = DateTime.now().add(Duration(days: 30 * months));
    await _firestore.collection('users').doc(uid).set({
      'plan': 'premium',
      'premiumExpiresAt': Timestamp.fromDate(expiresAt),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Riverpod provider
// ─────────────────────────────────────────────────────────────────────────────

final planStatusProvider = FutureProvider<PlanStatus>((ref) async {
  return PlanService.fetchStatus();
});

// ─────────────────────────────────────────────────────────────────────────────
// PlanUpgradeCard — shown inline when user hits invoice limit
// ─────────────────────────────────────────────────────────────────────────────

class PlanUpgradeCard extends StatelessWidget {
  final PlanStatus status;
  final VoidCallback? onUpgradeTap;

  const PlanUpgradeCard({super.key, required this.status, this.onUpgradeTap});

  @override
  Widget build(BuildContext context) {
    if (status.isPremium) return const SizedBox.shrink();

    final atLimit = !status.canCreateInvoice;
    final nearLimit = status.usagePercent >= 0.8;

    if (!nearLimit && !atLimit) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: atLimit
              ? [AppColors.error.withValues(alpha: 0.08), AppColors.error.withValues(alpha: 0.03)]
              : [AppColors.warning.withValues(alpha: 0.08), AppColors.warning.withValues(alpha: 0.03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: atLimit
              ? AppColors.error.withValues(alpha: 0.25)
              : AppColors.warning.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (atLimit ? AppColors.error : AppColors.warning).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              atLimit ? Icons.lock_rounded : Icons.warning_amber_rounded,
              color: atLimit ? AppColors.error : AppColors.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  atLimit
                      ? 'Umefika kikomo cha ankara'
                      : 'Karibu kukamilisha ankara ${status.invoicesUsedThisMonth}/$kFreeInvoiceMonthlyLimit',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: atLimit ? AppColors.error : AppColors.warning,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pata Premium: TZS ${kPremiumPriceMonthlyTZS.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}/mwezi kupitia M-Pesa',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onUpgradeTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.yellowBrand,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Panda',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PlanInfoCard — shown in settings to display current plan + upgrade CTA
// ─────────────────────────────────────────────────────────────────────────────

class PlanInfoCard extends StatelessWidget {
  final PlanStatus status;
  final VoidCallback? onUpgradeTap;

  const PlanInfoCard({super.key, required this.status, this.onUpgradeTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: status.isPremium
            ? const LinearGradient(
                colors: [AppColors.navyPrimary, AppColors.navySecondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: status.isFree ? AppColors.surface : null,
        borderRadius: BorderRadius.circular(20),
        border: status.isFree ? Border.all(color: AppColors.border) : null,
        boxShadow: status.isPremium
            ? [BoxShadow(color: AppColors.navyPrimary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                status.isPremium ? Icons.stars_rounded : Icons.workspace_premium_outlined,
                color: status.isPremium ? AppColors.yellowBrand : AppColors.textMuted,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                status.isPremium ? 'Premium' : 'Mpango wa Bure',
                style: GoogleFonts.dmSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: status.isPremium ? AppColors.inverseText : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (status.isFree) ...[
            _UsageBar(status: status),
            const SizedBox(height: 12),
            Text(
              'Ankara ${status.invoicesUsedThisMonth} / $kFreeInvoiceMonthlyLimit mwezi huu',
              style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            const _FeatureRow(text: 'Ankara hadi $kFreeInvoiceMonthlyLimit / mwezi', available: true),
            const _FeatureRow(text: 'Ankara zisizo na kikomo', available: false),
            const _FeatureRow(text: 'Kuingiza data ya M-Pesa (mwongozo)', available: false),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onUpgradeTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.yellowBrand,
                  foregroundColor: AppColors.navyPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Panda Premium — TZS 3,000/mwezi',
                  style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Malipo ya M-Pesa. Uthibitisho wa mwongozo kwa sasa.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textMuted),
            ),
          ] else ...[
            const _FeatureRow(text: 'Ankara zisizo na kikomo', available: true, light: true),
            const _FeatureRow(text: 'Kuingiza data ya M-Pesa', available: true, light: true),
            const _FeatureRow(text: 'Msaada wa kipaumbele', available: true, light: true),
            if (status.premiumExpiresAt != null) ...[
              const SizedBox(height: 12),
              Text(
                'Inaisha: ${_formatDate(status.premiumExpiresAt!)}',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.inverseText.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  static String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year}';
}

class _UsageBar extends StatelessWidget {
  final PlanStatus status;
  const _UsageBar({required this.status});

  @override
  Widget build(BuildContext context) {
    final pct = status.usagePercent;
    final barColor = pct >= 1.0
        ? AppColors.error
        : pct >= 0.8
            ? AppColors.warning
            : AppColors.success;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: pct,
        minHeight: 6,
        backgroundColor: AppColors.border,
        valueColor: AlwaysStoppedAnimation<Color>(barColor),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String text;
  final bool available;
  final bool light;

  const _FeatureRow({required this.text, required this.available, this.light = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            available ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: available
                ? (light ? AppColors.yellowBrand : AppColors.success)
                : AppColors.textDisabled,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: available
                  ? (light ? AppColors.inverseText : AppColors.textPrimary)
                  : AppColors.textDisabled,
              fontWeight: available ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
