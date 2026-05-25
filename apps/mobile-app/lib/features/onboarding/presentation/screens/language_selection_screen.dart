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
  late Animation<double> _btnFade;

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
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
      ),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    ));
    _cardsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.3, 0.75, curve: Curves.easeOut),
      ),
    );
    _cardsSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.3, 0.75, curve: Curves.easeOutCubic),
    ));
    _btnFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
      ),
    );

    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  void _selectLanguage(AppLanguage lang) {
    if (_language == lang || _isContinuing) return;
    HapticFeedback.selectionClick();
    setState(() => _language = lang);
  }

  Future<void> _continue() async {
    if (_isContinuing) return;
    HapticFeedback.lightImpact();
    setState(() => _isContinuing = true);
    try {
      await LocalizationService.setLanguage(_language);
      if (mounted) widget.onLanguageSelected();
    } finally {
      if (mounted) setState(() => _isContinuing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final headerH = size.height * 0.40;

    return Scaffold(
      backgroundColor: AppColors.navyPrimary,
      body: Stack(
        children: [
          // ── Dark navy header ───────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: headerH,
            child: Container(
              color: AppColors.navyPrimary,
              child: Stack(
                children: [
                  // Decorative accent circle
                  Positioned(
                    right: -60,
                    top: -40,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.tealAccent.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -40,
                    bottom: 20,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.yellowBrand.withValues(alpha: 0.06),
                      ),
                    ),
                  ),

                  // Header content
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
                      child: FadeTransition(
                        opacity: _headerFade,
                        child: SlideTransition(
                          position: _headerSlide,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Mali Up badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.yellowBrand
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(
                                    color: AppColors.yellowBrand
                                        .withValues(alpha: 0.30),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.yellowBrand,
                                      ),
                                    ),
                                    const SizedBox(width: 7),
                                    const Text(
                                      'Mali Up',
                                      style: TextStyle(
                                        color: AppColors.yellowBrand,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),

                              Text(
                                _tr('Welcome to Mali Up 👋',
                                    'Karibu Mali Up 👋'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _tr(
                                  'Your smart business companion.',
                                  'Mshauri wako wa biashara.',
                                ),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.62),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  height: 1.45,
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

          // ── White bottom sheet ─────────────────────────────────────────────
          Positioned(
            top: headerH - 24,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Section label
                      FadeTransition(
                        opacity: _cardsFade,
                        child: SlideTransition(
                          position: _cardsSlide,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _tr('Choose your language', 'Chagua lugha'),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.navyPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _tr(
                                  'Track sales, manage stock, follow payments, and grow your business with confidence.',
                                  'Fuatilia mauzo, simamia hifadhi, fuatilia malipo, na kukuza biashara yako kwa ujasiri.',
                                ),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textMuted,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // ── Language cards side by side ───────────────
                              Row(
                                children: [
                                  Expanded(
                                    child: _LanguageCard(
                                      flag: '🇬🇧',
                                      name: 'English',
                                      subtitle: 'Continue in English',
                                      selected:
                                          _language == AppLanguage.english,
                                      onTap: () =>
                                          _selectLanguage(AppLanguage.english),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _LanguageCard(
                                      flag: '🇹🇿',
                                      name: 'Kiswahili',
                                      subtitle: 'Endelea kwa Kiswahili',
                                      selected:
                                          _language == AppLanguage.swahili,
                                      onTap: () =>
                                          _selectLanguage(AppLanguage.swahili),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Continue button ────────────────────────────────────
                      FadeTransition(
                        opacity: _btnFade,
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: _isContinuing
                                      ? AppColors.disabled
                                      : AppColors.navyPrimary,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: _isContinuing
                                      ? null
                                      : [
                                          BoxShadow(
                                            color: AppColors.navyPrimary
                                                .withValues(alpha: 0.28),
                                            blurRadius: 20,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: _isContinuing ? null : _continue,
                                    child: Center(
                                      child: _isContinuing
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text(
                                              _tr('Continue', 'Endelea'),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.1,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _tr(
                                'You can change language anytime.',
                                'Unaweza kubadilisha lugha wakati wowote.',
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
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
    );
  }
}

// ─── Language Card ─────────────────────────────────────────────────────────────

class _LanguageCard extends StatefulWidget {
  final String flag;
  final String name;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.flag,
    required this.name,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_LanguageCard> createState() => _LanguageCardState();
}

class _LanguageCardState extends State<_LanguageCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 180),
      vsync: this,
      value: widget.selected ? 1.0 : 0.0,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(_LanguageCard old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected) {
      if (widget.selected) {
        _ctrl.forward();
      } else {
        _ctrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        if (!widget.selected) _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        if (!widget.selected) _ctrl.reverse();
      },
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
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
                      color: AppColors.navyPrimary.withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.flag,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(height: 10),
              Text(
                widget.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: widget.selected
                      ? Colors.white
                      : AppColors.navyPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.subtitle,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: widget.selected
                      ? Colors.white.withValues(alpha: 0.65)
                      : AppColors.textMuted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
