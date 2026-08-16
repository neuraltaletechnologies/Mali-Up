import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/app_rating_service.dart';
import '../../core/services/localization_service.dart';
import '../../core/theme/app_colors.dart';
import 'emotional_design.dart';

/// Soft-ask "rate us" dialog, shown after a happy-path moment (a confirmed
/// sale). Two-step sandwich: ask sentiment first, only route happy users to
/// the store; unhappy users are quietly deflected to feedback instead of a
/// public 1-star review.
class RateAppDialog extends StatefulWidget {
  const RateAppDialog({super.key});

  static Future<void> show(BuildContext context) {
    AppRatingService.recordPrompted();
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const RateAppDialog(),
    );
  }

  @override
  State<RateAppDialog> createState() => _RateAppDialogState();
}

class _RateAppDialogState extends State<RateAppDialog> {
  bool _showFeedbackThanks = false;

  String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

  Future<void> _onLoveIt() async {
    Navigator.of(context).pop();
    await AppRatingService.requestNativeReview();
  }

  void _onNotReally() {
    setState(() => _showFeedbackThanks = true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: _showFeedbackThanks ? _thanksContent() : _askContent(),
      ),
    );
  }

  Widget _askContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const EmotionalLottieSpot(
          scene: EmotionalLottieScene.celebrate,
          size: 120,
          repeat: false,
        ),
        Text(
          _tr('Enjoying Mali Up?', 'Unafurahia Mali Up?'),
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.navyPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _tr(
            'Your feedback helps us make it even better.',
            'Maoni yako yanatusaidia kuiboresha zaidi.',
          ),
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _onLoveIt,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.yellowBrand,
              foregroundColor: AppColors.navyPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _tr('😍 Yes, I love it!', '😍 Ndiyo, ninaipenda!'),
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: TextButton(
            onPressed: _onNotReally,
            style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
            child: Text(
              _tr('Not really', 'Si sana'),
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _thanksContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        const Icon(
          Icons.chat_bubble_outline_rounded,
          color: AppColors.tealAccent,
          size: 40,
        ),
        const SizedBox(height: 12),
        Text(
          _tr('Thanks for letting us know', 'Asante kwa kutujulisha'),
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.navyPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _tr(
            "We'd love to hear what would make Mali Up better for you — "
            'reach us anytime from Settings > Help & Support.',
            'Tungependa kujua ni nini kingefanya Mali Up iwe bora zaidi — '
                'wasiliana nasi wakati wowote kupitia Mipangilio > Msaada.',
          ),
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.navyPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _tr('OK', 'Sawa'),
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
