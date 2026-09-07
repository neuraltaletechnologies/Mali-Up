import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/constants/onboarding_strings.dart';

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
  late Animation<double> _fade;
  late Animation<Offset> _slide;

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
      duration: const Duration(milliseconds: 480),
      vsync: this,
    );
    _exitCtrl = AnimationController(
      duration: const Duration(milliseconds: 260),
      vsync: this,
    );

    _fade = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _entranceCtrl, curve: Curves.easeOutCubic));
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

  Future<void> _openWhatsAppHelp() async {
    final sw = _language == AppLanguage.swahili;
    final message = Uri.encodeComponent(
      sw
          ? 'Habari Mali Up Help Desk, nahitaji msaada.'
          : 'Hello Mali Up Help Desk, I need help.',
    );
    final uri = Uri.parse('${OnboardingStrings.helpDeskUrl}$message');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final topHeight = MediaQuery.of(context).size.height * 0.35;

    final headingStyle = GoogleFonts.dmSans(
      fontSize: 28,
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w800,
      height: 1.15,
      letterSpacing: -0.5,
    );
    final subtitleStyle = GoogleFonts.dmSans(
      color: AppColors.textSecondary,
      fontSize: 14,
      height: 1.5,
      fontWeight: FontWeight.w400,
    );

    return FadeTransition(
      opacity: _exitFade,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // Header image
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: topHeight,
              child: ClipRect(
                child: Image.asset(
                  'assets/Picture/sign_up.webp',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),

            // Top navigation bar (no back on first screen)
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: _openWhatsAppHelp,
                      icon: const Icon(
                        Icons.headset_mic_outlined,
                        color: AppColors.navyPrimary,
                        size: 13,
                      ),
                      label: Text(
                        _tr('Help', 'Msaada'),
                        style: GoogleFonts.dmSans(
                          color: AppColors.navyPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.85),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Main content sheet
            DraggableScrollableSheet(
              initialChildSize: 0.68,
              minChildSize: 0.68,
              maxChildSize: 0.8,
              builder: (context, scrollController) {
                return Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 20,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: NotificationListener<OverscrollIndicatorNotification>(
                    onNotification: (overscroll) {
                      overscroll.disallowIndicator();
                      return true;
                    },
                    child: FadeTransition(
                      opacity: _fade,
                      child: SlideTransition(
                        position: _slide,
                        child: SingleChildScrollView(
                          controller: scrollController,
                          physics: const ClampingScrollPhysics(),
                          padding:
                              const EdgeInsets.fromLTRB(24, 24, 24, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Handle bar
                              Center(
                                child: Container(
                                  width: 40,
                                  height: 4,
                                  margin: const EdgeInsets.only(bottom: 20),
                                  decoration: BoxDecoration(
                                    color: AppColors.border,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),

                              // Title
                              Center(
                                child: Text(
                                  _tr('Welcome', 'Karibu'),
                                  textAlign: TextAlign.center,
                                  style: headingStyle,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: Text(
                                  _tr(
                                    'Choose your preferred language.',
                                    'Chagua lugha inayokustarehesha.',
                                  ),
                                  textAlign: TextAlign.center,
                                  style: subtitleStyle,
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Section label
                              Text(
                                _tr('Select language', 'Chagua lugha'),
                                style: GoogleFonts.dmSans(
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
                                  'Unaweza kubadilisha kwenye Mipangilio.',
                                ),
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Language cards
                              _LanguageCard(
                                flag: '🇬🇧',
                                name: 'English',
                                nativeName: 'Continue in English',
                                selected: _language == AppLanguage.english,
                                enabled: !_isContinuing,
                                onTap: () =>
                                    _selectLanguage(AppLanguage.english),
                              ),
                              const SizedBox(height: 12),
                              _LanguageCard(
                                flag: '🇹🇿',
                                name: 'Kiswahili',
                                nativeName: 'Endelea kwa Kiswahili',
                                selected: _language == AppLanguage.swahili,
                                enabled: !_isContinuing,
                                onTap: () =>
                                    _selectLanguage(AppLanguage.swahili),
                              ),
                              const SizedBox(height: 32),

                              // Continue button
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.navyPrimary,
                                    elevation: 4,
                                    shadowColor: AppColors.primary
                                        .withValues(alpha: 0.3),
                                    minimumSize: const Size.fromHeight(52),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: _isContinuing ? null : _continue,
                                  child: _isContinuing
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: AppColors.navyPrimary,
                                          ),
                                        )
                                      : Text(
                                          _tr('Continue', 'Endelea'),
                                          style: GoogleFonts.dmSans(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Language Card ────────────────────────────────────────────────────────────

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
            color: widget.selected ? AppColors.navyPrimary : AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.selected ? AppColors.navyPrimary : AppColors.border,
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
              Text(widget.flag, style: GoogleFonts.dmSans(fontSize: 26)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: GoogleFonts.dmSans(
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
                      style: GoogleFonts.dmSans(
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
