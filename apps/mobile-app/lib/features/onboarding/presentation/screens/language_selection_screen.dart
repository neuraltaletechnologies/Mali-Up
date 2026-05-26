import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/localization_service.dart';

class LanguageSelectionScreen extends StatefulWidget {
  final VoidCallback onLanguageSelected;

  const LanguageSelectionScreen({super.key, required this.onLanguageSelected});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen>
    with TickerProviderStateMixin {
  AppLanguage _language = LocalizationService.languageNotifier.value;
  bool _isContinuing = false;

  late AnimationController _entranceCtrl;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _cardsFade;
  late Animation<Offset> _cardsSlide;

  // Exit animation when navigating away
  late AnimationController _exitCtrl;
  late Animation<double> _exitFade;

  String _tr(String en, String sw) =>
      _language == AppLanguage.swahili ? sw : en;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _entranceCtrl = AnimationController(
      duration: const Duration(milliseconds: 680),
      vsync: this,
    );
    _exitCtrl = AnimationController(
      duration: const Duration(milliseconds: 260),
      vsync: this,
    );

    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
      ),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    ));
    _cardsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.35, 0.85, curve: Curves.easeOut),
      ),
    );
    _cardsSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic),
    ));
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn),
    );

    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  void _selectLanguage(AppLanguage lang) {
    if (_isContinuing) return;
    HapticFeedback.selectionClick();
    setState(() => _language = lang);
  }

  Future<void> _continue() async {
    if (_isContinuing) return;
    HapticFeedback.lightImpact();
    setState(() => _isContinuing = true);
    await _exitCtrl.forward();
    if (!mounted) return;
    await LocalizationService.setLanguage(_language);
    if (mounted) widget.onLanguageSelected();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final headerH = size.height * 0.42;

    return FadeTransition(
      opacity: _exitFade,
      child: Scaffold(
        backgroundColor: AppColors.navyPrimary,
        body: Stack(
          children: [
            // ── Navy header area ─────────────────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: headerH,
              child: Container(
                color: AppColors.navyPrimary,
                child: Stack(
                  children: [
                    // Decorative orbs
                    Positioned(
                      right: -70,
                      top: -50,
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.tealAccent.withValues(alpha: 0.07),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -50,
                      bottom: 30,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.yellowBrand.withValues(alpha: 0.05),
                        ),
                      ),
                    ),

                    // Header content
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(28, 24, 28, 36),
                        child: FadeTransition(
                          opacity: _headerFade,
                          child: SlideTransition(
                            position: _headerSlide,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                            

                                Text(
                                  _tr('Welcome ', 'Karibu '),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    height: 1.1,
                                    letterSpacing: -0.6,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _tr(
                                    'Choose the language you\'re most comfortable with.',
                                    'Chagua lugha ambayo unayostarehesha nayo zaidi',
                                  ),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.60),
                                    fontSize: 15,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── White card sheet ─────────────────────────────────────────────
            Positioned(
              top: headerH - 28,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SafeArea(
                  top: false,
                  child: FadeTransition(
                    opacity: _cardsFade,
                    child: SlideTransition(
                      position: _cardsSlide,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Drag handle
                            Center(
                              child: Container(
                                width: 36,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppColors.border,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),

                            Text(
                              _tr('Select language', 'Chagua lugha'),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navyPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _tr(
                                'You can change this anytime in Settings.',
                                'Unaweza kubadilisha badaye kwenye Mipangilio.',
                              ),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ── Language cards ─────────────────────────────────
                            _LanguageCard(
                              flag: '🇬🇧',
                              name: 'English',
                              nativeName: 'Continue in English',
                              selected: _language == AppLanguage.english,
                              enabled: !_isContinuing,
                              onTap: () => _selectLanguage(AppLanguage.english),
                            ),
                            const SizedBox(height: 12),
                            _LanguageCard(
                              flag: '🇹🇿',
                              name: 'Kiswahili',
                              nativeName: 'Endelea kwa Kiswahili',
                              selected: _language == AppLanguage.swahili,
                              enabled: !_isContinuing,
                              onTap: () => _selectLanguage(AppLanguage.swahili),
                            ),

                            const Spacer(),

                            // Continue button
                            _ContinueButton(
                              label: _tr('Continue', 'Endelea'),
                              isLoading: _isContinuing,
                              onTap: _continue,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Language Card — full-width horizontal row ────────────────────────────────

class _LanguageCard extends StatefulWidget {
  final String flag;
  final String name;
  final String nativeName;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.flag,
    required this.name,
    required this.nativeName,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_LanguageCard> createState() => _LanguageCardState();
}

class _LanguageCardState extends State<_LanguageCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 200),
      lowerBound: 0.97,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pressCtrl,
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => _pressCtrl.reverse() : null,
        onTapUp: widget.enabled
            ? (_) {
                _pressCtrl.forward();
                widget.onTap();
              }
            : null,
        onTapCancel: () => _pressCtrl.forward(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.navyPrimary
                : AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.selected
                  ? AppColors.navyPrimary
                  : AppColors.border,
              width: widget.selected ? 1.5 : 1.0,
            ),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: AppColors.navyPrimary.withValues(alpha: 0.22),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Flag
              Text(
                widget.flag,
                style: const TextStyle(fontSize: 26),
              ),
              const SizedBox(width: 14),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: widget.selected
                            ? Colors.white
                            : AppColors.navyPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.nativeName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: widget.selected
                            ? Colors.white.withValues(alpha: 0.60)
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Check indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.selected
                      ? AppColors.yellowBrand
                      : AppColors.border.withValues(alpha: 0.6),
                ),
                child: widget.selected
                    ? const Icon(Icons.check_rounded,
                        size: 16, color: AppColors.navyPrimary)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Continue button ──────────────────────────────────────────────────────────

class _ContinueButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  const _ContinueButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
      lowerBound: 0.96,
      vsync: this,
    );
    _scale = _pressCtrl;
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: widget.isLoading ? null : (_) => _pressCtrl.reverse(),
        onTapUp: widget.isLoading
            ? null
            : (_) {
                _pressCtrl.forward();
                widget.onTap();
              },
        onTapCancel: () => _pressCtrl.forward(),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.navyPrimary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.navyPrimary.withValues(alpha: 0.25),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.1,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
