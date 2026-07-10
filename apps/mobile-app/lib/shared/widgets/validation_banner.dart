import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

/// Inline "something needs fixing" banner for forms shown in a modal sheet.
///
/// Sheets pushed via `showAppSheet` (`useRootNavigator: true`, up to
/// 80-95% of the screen height) sit above the underlying Scaffold in the
/// Overlay stack, so a `ScaffoldMessenger.showSnackBar` fired from inside
/// one renders *behind* the sheet and the user never sees it. Use this
/// widget instead, placed directly under the field the message is about,
/// so the message is exactly where the user needs to look.
///
/// Styled as a friendly warning (amber), not an alarming error (red) —
/// this is guiding the user to a missing/invalid field, not reporting a
/// system failure.
class ValidationBanner extends StatelessWidget {
  final String? message;
  final VoidCallback? onDismiss;
  final EdgeInsetsGeometry margin;

  const ValidationBanner({
    super.key,
    required this.message,
    this.onDismiss,
    this.margin = const EdgeInsets.only(top: 8),
  });

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.warningText,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message!,
              style: GoogleFonts.dmSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.warningText,
              ),
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.warningText,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
