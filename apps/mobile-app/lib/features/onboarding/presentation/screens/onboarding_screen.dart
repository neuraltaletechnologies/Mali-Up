import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/routing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/constants/onboarding_strings.dart';
import '../widgets/onboarding_back_handler.dart';

/// Premium onboarding carousel highlighting Mali Up's flagship features
/// (offline-first sync, real-time insights, invoicing/inventory automation,
/// bilingual support, and PIN security).
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
      titleEn: 'Works perfectly,\neven offline.',
      titleSw: 'Inafanya kazi vizuri,\nhata bila mtandao.',
      bodyEn:
          'Mali Up saves everything on your phone first. No internet? No problem — your sales, invoices, and stock keep updating, then sync automatically once you\'re back online.',
      bodySw:
          'Mali Up huhifadhi kila kitu kwenye simu yako kwanza. Huna mtandao? Si tatizo — mauzo, ankara, na hifadhi yako yanaendelea kusasishwa, kisha yanasawazishwa kiotomatiki mtandao ukirudi.',
    ),
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
      titleEn: 'Speaks your language,\nliterally.',
      titleSw: 'Inaongea lugha yako,\nkihalisi.',
      bodyEn:
          'Fully bilingual in Kiswahili and English, switch anytime. Built specifically for the way African businesses actually operate.',
      bodySw:
          'Inapatikana kikamilifu kwa Kiswahili na Kiingereza, badilisha wakati wowote. Imeundwa maalum kwa jinsi biashara za Afrika zinavyofanya kazi.',
    ),
    _SlideData(
      titleEn: 'Your data,\nlocked down.',
      titleSw: 'Taarifa zako,\nzimelindwa.',
      bodyEn:
          'A secure PIN keeps your business safe, even if someone else picks up your phone.',
      bodySw:
          'PIN salama inalinda biashara yako, hata kama mtu mwingine akishika simu yako.',
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

  /// Hardware back: retreat one slide first, then leave the carousel.
  void _handleSystemBack() {
    if (_current > 0) {
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.fastOutSlowIn,
      );
      return;
    }
    _goBack();
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
    final scaffold = Scaffold(
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
                      size: 16,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.border.withValues(alpha: 0.3),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
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
                      backgroundColor: AppColors.border.withValues(alpha: 0.3),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
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
                    style: GoogleFonts.dmSans(
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
    return OnboardingBackHandler(onBack: _handleSystemBack, child: scaffold);
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
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.dmSans(
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
              style: GoogleFonts.dmSans(
                fontSize: 17,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.55,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
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
