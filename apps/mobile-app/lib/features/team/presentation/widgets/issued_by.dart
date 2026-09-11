import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';

// Presentational widgets for the "Issued by" attribution shown on entity
// detail and receipt screens. Resolve the label with `issuedByLabel(ref, uid)`
// from creator_providers.dart (returns null → render nothing) and pass the
// result here.

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

/// Boxed "Issued by `<name>`" card for entity detail sheets (sales, debt,
/// expense).
class IssuedByCard extends StatelessWidget {
  final String value;

  /// Label override — defaults to "Issued by" / "Imetolewa na".
  final String? labelEn;
  final String? labelSw;

  /// Card corner radius, to match the surrounding cards on each screen.
  final double radius;

  const IssuedByCard({
    super.key,
    required this.value,
    this.labelEn,
    this.labelSw,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(
            Icons.badge_outlined,
            size: 16,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tr(labelEn ?? 'Issued by', labelSw ?? 'Imetolewa na'),
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact "· `<name>`" fragment for list rows (debt repayments, cash-flow
/// transactions) — drop it into an existing metadata row or column.
class IssuedByInline extends StatelessWidget {
  final String value;

  const IssuedByInline({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.person_outline_rounded,
          size: 11,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}
