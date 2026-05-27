import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/localization_service.dart';

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
      illustrationIndex: 0,
      titleEn: 'Make confident\nbusiness decisions',
      titleSw: 'Fanya maamuzi ya\nbiashara kwa ujasiri',
      bodyEn:
          'Understand your money, sales, and business performance clearly.',
      bodySw:
          'Elewa pesa yako, mauzo, na utendaji wa biashara kwa uwazi.',
    ),
    _SlideData(
      illustrationIndex: 1,
      titleEn: 'Spend less time\nwriting things down',
      titleSw: 'Tumia muda mchache\nkuandika mambo',
      bodyEn:
          'Automate invoices, stock updates, and payment tracking.',
      bodySw:
          'Otomatisha ankara, masasisho ya hifadhi, na ufuatiliaji wa malipo.',
    ),
    _SlideData(
      illustrationIndex: 2,
      titleEn: 'Built for\nAfrican businesses',
      titleSw: 'Imeundwa kwa\nbiashara za Afrika',
      bodyEn:
          'Offline-first, mobile-first, and designed for the way real businesses work.',
      bodySw:
          'Inafanya kazi bila mtandao, kwenye simu, iliyoundwa kwa jinsi biashara halisi zinavyofanya kazi.',
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

  void _onPageChanged(int index) {
    if (index == _slides.length) {
      widget.onOnboardingComplete();
      return;
    }
    setState(() => _current = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: PageView.builder(
          controller: _pageCtrl,
          onPageChanged: _onPageChanged,
          itemCount: _slides.length + 1,
          itemBuilder: (context, index) {
            if (index == _slides.length) return const SizedBox.shrink();
            return _SlidePage(
              slide: _slides[index],
              isSwahili: _sw,
              isCurrent: index == _current,
            );
          },
        ),
      ),
    );
  }
}

// ── Slide page ─────────────────────────────────────────────────────────────────

class _SlidePage extends StatefulWidget {
  final _SlideData slide;
  final bool isSwahili;
  final bool isCurrent;

  const _SlidePage({
    required this.slide,
    required this.isSwahili,
    required this.isCurrent,
  });

  @override
  State<_SlidePage> createState() => _SlidePageState();
}

class _SlidePageState extends State<_SlidePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 480),
      vsync: this,
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isSwahili
        ? widget.slide.titleSw
        : widget.slide.titleEn;
    final body = widget.isSwahili
        ? widget.slide.bodySw
        : widget.slide.bodyEn;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // Illustration
              Expanded(
                flex: 5,
                child: Center(
                  child: _Illustration(index: widget.slide.illustrationIndex),
                ),
              ),

              // Text content
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navyPrimary,
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      body,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textMuted,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Abstract geometric illustrations (no external assets needed) ───────────────

class _Illustration extends StatelessWidget {
  final int index;
  const _Illustration({required this.index});

  @override
  Widget build(BuildContext context) {
    return switch (index) {
      0 => const _DashboardIllustration(),
      1 => const _AutomationIllustration(),
      _ => const _MobileIllustration(),
    };
  }
}

/// Slide 1 — bar chart representing business clarity
class _DashboardIllustration extends StatelessWidget {
  const _DashboardIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background card
          Container(
            width: 240,
            height: 210,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
          ),

          // Chart bars
          Positioned(
            bottom: 30,
            left: 34,
            right: 34,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _Bar(height: 60, color: AppColors.tealAccent.withValues(alpha: 0.35)),
                _Bar(height: 90, color: AppColors.tealAccent.withValues(alpha: 0.6)),
                _Bar(height: 50, color: AppColors.tealAccent.withValues(alpha: 0.35)),
                const _Bar(height: 120, color: AppColors.navyPrimary),
                _Bar(height: 75, color: AppColors.tealAccent.withValues(alpha: 0.5)),
                const _Bar(height: 100, color: AppColors.yellowBrand),
              ],
            ),
          ),

          // Top stat card
          Positioned(
            top: 22,
            right: 22,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.navyPrimary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navyPrimary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.trending_up_rounded,
                      color: AppColors.yellowBrand, size: 14),
                  SizedBox(width: 5),
                  Text(
                    '+24%',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Label dots
          const Positioned(
            top: 22,
            left: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LabelDot(color: AppColors.navyPrimary, label: 'Revenue'),
                SizedBox(height: 5),
                _LabelDot(color: AppColors.yellowBrand, label: 'Profit'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double height;
  final Color color;
  const _Bar({required this.height, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: 22,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
      );
}

class _LabelDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LabelDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
}

/// Slide 2 — document/invoice automation
class _AutomationIllustration extends StatelessWidget {
  const _AutomationIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Back card
          Positioned(
            top: 10,
            left: 10,
            child: Transform.rotate(
              angle: -0.06,
              child: Container(
                width: 185,
                height: 220,
                decoration: BoxDecoration(
                  color: AppColors.tealAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: AppColors.tealAccent.withValues(alpha: 0.18)),
                ),
              ),
            ),
          ),

          // Main document card
          Container(
            width: 195,
            height: 225,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navyPrimary.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.yellowBrand,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.receipt_rounded,
                            size: 15, color: AppColors.navyPrimary),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Invoice #0042',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Line items
                  ...[
                    ('Product A', 'TZS 45,000', true),
                    ('Service B', 'TZS 30,000', true),
                    ('Item C', 'TZS 12,500', false),
                  ].map((item) => _InvoiceLine(
                        label: item.$1,
                        amount: item.$2,
                        checked: item.$3,
                      )),
                  const SizedBox(height: 8),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 8),
                  // Total
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyPrimary,
                        ),
                      ),
                      Text(
                        'TZS 87,500',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navyPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        '✓  Sent automatically',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceLine extends StatelessWidget {
  final String label;
  final String amount;
  final bool checked;
  const _InvoiceLine(
      {required this.label, required this.amount, required this.checked});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            checked ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 14,
            color: checked ? AppColors.success : AppColors.border,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.navyPrimary),
          ),
        ],
      ),
    );
  }
}

/// Slide 3 — mobile-first, African businesses
class _MobileIllustration extends StatelessWidget {
  const _MobileIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Phone frame
          Container(
            width: 130,
            height: 225,
            decoration: BoxDecoration(
              color: AppColors.navyPrimary,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navyPrimary.withValues(alpha: 0.30),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Screen
                Positioned.fill(
                  top: 14,
                  bottom: 14,
                  left: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        // Status bar mock
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('9:41',
                                  style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.navyPrimary)),
                              Row(children: [
                                Icon(Icons.wifi_rounded,
                                    size: 8, color: AppColors.navyPrimary),
                                SizedBox(width: 2),
                                Icon(Icons.signal_cellular_alt_rounded,
                                    size: 8, color: AppColors.navyPrimary),
                              ]),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Mini dashboard
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.navyPrimary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Today',
                                  style: TextStyle(
                                      fontSize: 7,
                                      color: Colors.white54,
                                      fontWeight: FontWeight.w500)),
                              SizedBox(height: 3),
                              Text('TZS 124K',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.yellowBrand,
                                      fontWeight: FontWeight.w800)),
                              SizedBox(height: 2),
                              Row(children: [
                                Icon(Icons.arrow_upward_rounded,
                                    size: 8, color: AppColors.success),
                                Text(' +18%',
                                    style: TextStyle(
                                        fontSize: 7, color: AppColors.success)),
                              ]),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Menu grid
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _AppIcon(icon: Icons.storefront_rounded, label: 'Sales'),
                              _AppIcon(icon: Icons.inventory_2_rounded, label: 'Stock'),
                              _AppIcon(icon: Icons.people_rounded, label: 'CRM'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Home bar
                Positioned(
                  bottom: 18,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Floating offline badge
          Positioned(
            top: 20,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Works offline',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navyPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating language badge
          Positioned(
            bottom: 24,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.yellowBrand,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.yellowBrand.withValues(alpha: 0.30),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Text(
                '🇹🇿 Kiswahili',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  const _AppIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.navyPrimary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 12, color: AppColors.navyPrimary),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 7, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

// ── Slide data model ───────────────────────────────────────────────────────────

class _SlideData {
  final int illustrationIndex;
  final String titleEn;
  final String titleSw;
  final String bodyEn;
  final String bodySw;

  const _SlideData({
    required this.illustrationIndex,
    required this.titleEn,
    required this.titleSw,
    required this.bodyEn,
    required this.bodySw,
  });
}
