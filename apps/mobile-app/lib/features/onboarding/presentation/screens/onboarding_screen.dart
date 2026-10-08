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
  final VoidCallback? onBackToWelcome;

  const OnboardingScreen({
    super.key,
    required this.onOnboardingComplete,
    this.onBackToWelcome,
  });

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
      imagePath: 'assets/Picture/offline1.jpg',
      titleEn: 'NO INTERNET?',
      titleSw: 'HUNA MTANDAO?',
      bodyEn:
          'Keep selling, recording sales, and managing stock offline. Everything syncs automatically when you’re back online.',
      bodySw:
          'Endelea kuuza, kurekodi mauzo na kusimamia hifadhi bila mtandao. Kila kitu kitasawazishwa mtandao ukirudi.',
    ),
    _SlideData(
      imagePath: 'assets/Picture/offline2.jpg',
      titleEn: 'LOST IN NUMBERS?',
      titleSw: 'HUJUI BIASHARA YAKO?',
      bodyEn:
          'See your sales, money, and business performance clearly with real-time insights.',
      bodySw:
          'Ona mauzo, pesa na mwenendo wa biashara yako kwa urahisi kupitia taarifa za wakati halisi.',
    ),
    _SlideData(
      imagePath: 'assets/Picture/offline14.jpg',
      titleEn: 'TOO MUCH WRITING?',
      titleSw: 'UNAANDIKA SANA?',
      bodyEn:
          'Create invoices, update stock, and track payments without doing everything manually.',
      bodySw:
          'Tengeneza ankara, sasisha hifadhi na fuatilia malipo bila kufanya kila kitu kwa mkono.',
    ),
    _SlideData(
      imagePath: 'assets/Picture/offline4.jpg',
      titleEn: 'LANGUAGE PROBLEM?',
      titleSw: 'LUGHA INAKUSUMBUA?',
      bodyEn:
          'Use Mali Up in Kiswahili or English. Switch languages anytime to work the way you prefer.',
      bodySw:
          'Tumia Mali Up kwa Kiswahili au Kiingereza. Badilisha lugha wakati wowote unapotaka.',
    ),
    _SlideData(
      imagePath: 'assets/Picture/offline5.jpg',
      titleEn: 'WORRIED ABOUT YOUR DATA?',
      titleSw: 'UNAOGOPA TAARIFA ZAKO?',
      bodyEn:
          'Protect your business with a secure PIN, even when someone else has your phone.',
      bodySw:
          'Linda biashara yako kwa PIN salama, hata mtu mwingine akiwa na simu yako.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
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
    if (widget.onBackToWelcome != null) {
      widget.onBackToWelcome!();
    } else {
      context.go(AppRoutes.welcome);
    }
  }

  /// Hardware/UI back: retreat one slide first, then leave the carousel.
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
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full Screen Carousel
          PageView.builder(
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

          // Top Navigation Bar
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _handleSystemBack,
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.35),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _openWhatsAppHelp,
                      icon: const Icon(
                        Icons.headset_mic_outlined,
                        color: Colors.white,
                        size: 14,
                      ),
                      label: Text(
                        _tr('Help', 'Msaada'),
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.35),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Controls (Indicators & Action Button)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _onPrimaryAction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.navyPrimary,
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
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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

    return Stack(
      fit: StackFit.expand,
      children: [
        // Full screen background image
        Image.asset(
          slide.imagePath,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),

        // Gradient overlay for contrast
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.45),
                Colors.black.withValues(alpha: 0.15),
                Colors.black.withValues(alpha: 0.65),
                Colors.black.withValues(alpha: 0.92),
              ],
              stops: const [0.0, 0.35, 0.65, 1.0],
            ),
          ),
        ),

        // Slide text positioned above bottom controls
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.15,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  body,
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.5,
                    letterSpacing: -0.2,
                  ),
                ),
                // Padding to stay above the bottom indicator and action button
                const SizedBox(height: 130),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Slide data model ───────────────────────────────────────────────────────────

class _SlideData {
  final String imagePath;
  final String titleEn;
  final String titleSw;
  final String bodyEn;
  final String bodySw;

  const _SlideData({
    required this.imagePath,
    required this.titleEn,
    required this.titleSw,
    required this.bodyEn,
    required this.bodySw,
  });
}
