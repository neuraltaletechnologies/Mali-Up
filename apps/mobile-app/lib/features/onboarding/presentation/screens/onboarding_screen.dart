import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/routing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/constants/onboarding_strings.dart';

/// Premium 3-slide onboarding carousel.
/// Calls [onOnboardingComplete] when the user taps "Let's get started" on
/// the last slide.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onOnboardingComplete;

  const OnboardingScreen({super.key, required this.onOnboardingComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  int _current = 0;

  late VoidCallback _langListener;
  late AppLanguage _language;
  // ── Slide data ──────────────────────────────────────────────────────────────

  static const _slides = [
    _SlideData(
      titleEn: 'Make confident\nbusiness decisions.',
      titleSw: 'Fanya maamuzi ya\nbiashara kwa ujasiri.',
      bodyEn:
          'Understand your money, sales, and business performance clearly with real-time insights.',
      bodySw:
          'Elewa pesa yako, mauzo, na utendaji wa biashara kwa uwazi kwa kutumia taarifa za wakati halisi.',
    ),
    _SlideData(
      titleEn: 'Spend less time\nwriting things down.',
      titleSw: 'Tumia muda mchache\nkuandika mambo.',
      bodyEn:
          'Automate your invoices, inventory updates, and payment tracking in one seamless ecosystem.',
      bodySw:
          'Otomatisha ankara, masasisho ya hifadhi, na ufuatiliaji wa malipo katika mfumo mmoja madhubuti.',
    ),
    _SlideData(
      titleEn: 'Built specifically for\nAfrican businesses.',
      titleSw: 'Imeundwa maalum kwa\nbiashara za Afrika.',
      bodyEn:
          'Offline-first, mobile-first, and designed for the way real businesses operate.',
      bodySw:
          'Inafanya kazi bila mtandao, kwenye simu, na iliyoundwa kwa jinsi biashara halisi zinavyofanya kazi.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    _language = LocalizationService.languageNotifier.value;
    _langListener = () {
      if (mounted) {
        setState(() => _language = LocalizationService.languageNotifier.value);
      }
    };
    LocalizationService.languageNotifier.addListener(_langListener);
  }

  @override
  void dispose() {
    LocalizationService.languageNotifier.removeListener(_langListener);
    _pageCtrl.dispose();
    super.dispose();
  }

  bool get _sw => _language == AppLanguage.swahili;

  String _tr(String en, String sw) => _sw ? sw : en;

  bool get _isLastSlide => _current == _slides.length - 1;

  Future<void> _openWhatsAppHelp() async {
    final message = Uri.encodeComponent(
      _sw
          ? 'Habari Mali Up Help Desk, nahitaji msaada wa kuendelea.'
          : 'Hello Mali Up Help Desk, I need help getting started.',
    );
    final uri = Uri.parse('${OnboardingStrings.helpDeskUrl}$message');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _goBack() {
    context.go(AppRoutes.welcome);
  }

  void _onPageChanged(int index) {
    setState(() => _current = index);
  }

  Future<void> _onPrimaryAction() async {
    if (_isLastSlide) {
      widget.onOnboardingComplete();
      return;
    }
    await _pageCtrl.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _goBack,
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.navyPrimary,
                      size: 18,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.border.withValues(alpha: 0.3),
                      padding: const EdgeInsets.all(10),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _openWhatsAppHelp,
                    icon: const Icon(
                      Icons.headset_mic_outlined,
                      color: AppColors.navyPrimary,
                      size: 15,
                    ),
                    label: Text(
                      _tr('Help', 'Msaada'),
                      style: const TextStyle(
                        color: AppColors.navyPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.border.withValues(alpha: 0.3),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
              
              const Spacer(flex: 2),
              
              // Carousel
              SizedBox(
                height: 320,
                child: PageView.builder(
                  controller: _pageCtrl,
                  onPageChanged: _onPageChanged,
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    return _SlidePage(
                      slide: _slides[index],
                      isSwahili: _sw,
                    );
                  },
                ),
              ),
              
              const Spacer(flex: 3),
              
              // Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (index) {
                  final active = index == _current;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 32 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.navyPrimary
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  );
                }),
              ),
              
              const SizedBox(height: 40),
              
              // Action Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _onPrimaryAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _isLastSlide
                        ? _tr("Let's get started", 'Tuanze sasa')
                        : _tr('Continue', 'Endelea'),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Slide page ─────────────────────────────────────────────────────────────────

class _SlidePage extends StatelessWidget {
  final _SlideData slide;
  final bool isSwahili;

  const _SlidePage({
    required this.slide,
    required this.isSwahili,
  });

  @override
  Widget build(BuildContext context) {
    final title = isSwahili ? slide.titleSw : slide.titleEn;
    final body = isSwahili ? slide.bodySw : slide.bodyEn;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: AppColors.navyPrimary,
              height: 1.15,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            body,
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.55,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Slide data model ───────────────────────────────────────────────────────────

class _SlideData {
  final String titleEn;
  final String titleSw;
  final String bodyEn;
  final String bodySw;

  const _SlideData({
    required this.titleEn,
    required this.titleSw,
    required this.bodyEn,
    required this.bodySw,
  });
}
