import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/app_rating_service.dart';
import '../../core/services/localization_service.dart';
import '../../core/theme/app_colors.dart';

/// Soft-ask "rate us" dialog, shown once the user has had real value from
/// the app (see [AppRatingService] for when). Each star has its own emoji
/// and label so the choice feels expressive; hovering (desktop) previews it.
/// Picking a star shows a matching call-to-action: 4–5 stars hand off to the
/// native store review sheet, 1–3 stars ask what to improve instead.
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

class _StarMood {
  final String emoji;
  final String en;
  final String sw;
  const _StarMood(this.emoji, this.en, this.sw);
}

const _moods = <_StarMood>[
  _StarMood('😞', 'Not satisfied', 'Sijaridhika'),
  _StarMood('😕', 'Could be better', 'Inaweza kuwa bora'),
  _StarMood('😐', "It's okay", 'Ni sawa tu'),
  _StarMood('😊', 'I like it!', 'Naipenda!'),
  _StarMood('🤩', 'I love it!', 'Naipenda sana!'),
];

class _RateAppDialogState extends State<RateAppDialog> {
  int _selected = 0;
  int _hover = 0;
  bool _showDeflection = false;

  String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

  /// What the header reflects: the hovered star (desktop preview), else the
  /// picked one, else 0 (nothing yet).
  int get _shown => _hover > 0 ? _hover : _selected;

  Future<void> _submit() async {
    final stars = _selected;
    if (stars == 0) return;
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        width: 340,
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _showDeflection ? _deflectionContent() : _askContent(),
          ),
        ),
      ),
    );
  }

  Widget _emojiBadge() {
    final shown = _shown;
    final emoji = shown == 0 ? '💛' : _moods[shown - 1].emoji;
    final tint = shown == 0
        ? AppColors.yellowBrand
        : shown >= 4
        ? AppColors.yellowBrand
        : shown == 3
        ? AppColors.tealAccent
        : AppColors.error;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (child, anim) => ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
          child: child,
        ),
        child: Text(
          emoji,
          key: ValueKey(emoji),
          style: const TextStyle(fontSize: 44),
        ),
      ),
    );
  }

  Widget _askContent() {
    final shown = _shown;
    final mood = shown == 0 ? null : _moods[shown - 1];
    return Column(
      key: const ValueKey('ask'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _emojiBadge(),
        const SizedBox(height: 16),
        Text(
          _tr(
            'How is Mali Up working for your business?',
            'Mali Up inaisaidiaje biashara yako?',
          ),
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.navyPrimary,
            letterSpacing: -0.2,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _tr(
            'Your rating helps other businesses in Tanzania discover Mali Up.',
            'Maoni yako yanasaidia wafanyabiashara wengine Tanzania kuigundua Mali Up.',
          ),
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: AppColors.textMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final n = i + 1;
            final filled = n <= shown;
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => _hover = n),
              onExit: (_) => setState(() => _hover = 0),
              child: GestureDetector(
                onTap: () => setState(() => _selected = n),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AnimatedScale(
                    scale: filled ? (n == shown ? 1.22 : 1.08) : 1.0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutBack,
                    child: Icon(
                      filled ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 38,
                      color: filled ? AppColors.yellowBrand : AppColors.border,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 22,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: Text(
              mood == null
                  ? _tr('Tap a star', 'Gusa nyota')
                  : _tr(mood.en, mood.sw),
              key: ValueKey(shown),
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: mood == null
                    ? AppColors.textMuted
                    : AppColors.navyPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: FilledButton(
            onPressed: _selected == 0 ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: _selected >= 4
                  ? AppColors.yellowBrand
                  : AppColors.navyPrimary,
              foregroundColor: _selected >= 4
                  ? AppColors.navyPrimary
                  : Colors.white,
              disabledBackgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              _selected == 0
                  ? _tr('Choose your rating', 'Chagua kiwango chako')
                  : _selected >= 4
                  ? _tr('Share it on the store 🎉', 'Tuandikie dukani 🎉')
                  : _tr('Tell us what to improve', 'Tuambie tuboreshe nini'),
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
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
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.tealAccent.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Text('🙏', style: TextStyle(fontSize: 36)),
        ),
        const SizedBox(height: 14),
        Text(
          _tr('Thank you for being honest', 'Asante kwa ukweli wako'),
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.navyPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _tr(
            "We read every message and we'd love to fix what's bothering you. "
                'Reach us in Settings › Help & Support.',
            'Tunasoma kila ujumbe na tungependa kurekebisha kinachokusumbua. '
                'Tupate kwenye Mipangilio › Msaada.',
          ),
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: AppColors.textMuted,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.navyPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              _tr('OK', 'Sawa'),
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
