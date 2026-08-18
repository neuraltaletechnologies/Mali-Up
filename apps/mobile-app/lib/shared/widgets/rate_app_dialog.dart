import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/app_rating_service.dart';
import '../../core/services/localization_service.dart';
import '../../core/theme/app_colors.dart';

/// Soft-ask "rate us" dialog, shown after a happy-path moment (a confirmed
/// sale). Tap-a-star interaction: 4–5 stars routes straight to the native
/// store review sheet; 1–3 stars quietly deflects to support instead of a
/// public low rating. No confirm button — the star tap itself is the action.
class RateAppDialog extends StatefulWidget {
  const RateAppDialog({super.key});

  static Future<void> show(BuildContext context) {
    AppRatingService.recordPrompted();
    return showDialog<void>(
      context: context,
      builder: (_) => const RateAppDialog(),
    );
  }

  @override
  State<RateAppDialog> createState() => _RateAppDialogState();
}

class _RateAppDialogState extends State<RateAppDialog> {
  int _selected = 0;
  bool _settled = false;
  bool _showDeflection = false;

  String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

  Future<void> _onStarTap(int stars) async {
    if (_settled) return;
    setState(() {
      _selected = stars;
      _settled = true;
    });
    await Future.delayed(const Duration(milliseconds: 320));
    if (!mounted) return;
    if (stars >= 4) {
      Navigator.of(context).pop();
      await AppRatingService.requestNativeReview();
    } else {
      setState(() => _showDeflection = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        width: 320,
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: _showDeflection ? _deflectionContent() : _askContent(),
        ),
      ),
    );
  }

  Widget _askContent() {
    return Column(
      key: const ValueKey('ask'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _tr('Enjoying Mali Up?', 'Unaipenda Mali Up?'),
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.navyPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _tr(
            'Tap a star to rate your experience',
            'Gusa nyota kuweka kiwango chako',
          ),
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final filled = i < _selected;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: GestureDetector(
                onTap: () => _onStarTap(i + 1),
                behavior: HitTestBehavior.opaque,
                child: AnimatedScale(
                  scale: filled ? 1.08 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 30,
                    color: filled ? AppColors.yellowBrand : AppColors.border,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textMuted,
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            _tr('Maybe later', 'Baadaye'),
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _deflectionContent() {
    return Column(
      key: const ValueKey('deflection'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _tr('Thanks for the feedback', 'Asante kwa maoni yako'),
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.navyPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _tr(
            'Tell us what would make it better — Settings › Help & Support.',
            'Tuambie ni nini kingeifanya iwe bora — Mipangilio › Msaada.',
          ),
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: AppColors.textMuted,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.navyPrimary,
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            _tr('OK', 'Sawa'),
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
