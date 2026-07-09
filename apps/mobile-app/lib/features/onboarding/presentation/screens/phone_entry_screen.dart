import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/onboarding_strings.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/validators/onboarding_validator.dart';
import '../../providers/onboarding_notifier.dart';
import '../../../../config/routing.dart';
import '_onboarding_scaffold.dart';

// ─── Country data ─────────────────────────────────────────────────────────────

class _Country {
  const _Country(this.flag, this.name, this.dial, this.code);
  final String flag;
  final String name;
  final String dial;
  final String code; // ISO 2-letter
}

// Africa-first, Tanzania at top, then sorted
const List<_Country> _kCountries = [
  _Country('🇹🇿', 'Tanzania', '+255', 'TZ'),
  _Country('🇰🇪', 'Kenya', '+254', 'KE'),
  _Country('🇺🇬', 'Uganda', '+256', 'UG'),
  _Country('🇷🇼', 'Rwanda', '+250', 'RW'),
  _Country('🇧🇮', 'Burundi', '+257', 'BI'),
  _Country('🇪🇹', 'Ethiopia', '+251', 'ET'),
  _Country('🇸🇸', 'South Sudan', '+211', 'SS'),
  _Country('🇸🇴', 'Somalia', '+252', 'SO'),
  _Country('🇩🇯', 'Djibouti', '+253', 'DJ'),
  _Country('🇪🇷', 'Eritrea', '+291', 'ER'),
  _Country('🇲🇼', 'Malawi', '+265', 'MW'),
  _Country('🇿🇲', 'Zambia', '+260', 'ZM'),
  _Country('🇿🇼', 'Zimbabwe', '+263', 'ZW'),
  _Country('🇲🇿', 'Mozambique', '+258', 'MZ'),
  _Country('🇲🇬', 'Madagascar', '+261', 'MG'),
  _Country('🇧🇼', 'Botswana', '+267', 'BW'),
  _Country('🇳🇦', 'Namibia', '+264', 'NA'),
  _Country('🇿🇦', 'South Africa', '+27', 'ZA'),
  _Country('🇸🇿', 'Eswatini', '+268', 'SZ'),
  _Country('🇱🇸', 'Lesotho', '+266', 'LS'),
  _Country('🇳🇬', 'Nigeria', '+234', 'NG'),
  _Country('🇬🇭', 'Ghana', '+233', 'GH'),
  _Country('🇸🇳', 'Senegal', '+221', 'SN'),
  _Country('🇨🇮', 'Côte d\'Ivoire', '+225', 'CI'),
  _Country('🇨🇲', 'Cameroon', '+237', 'CM'),
  _Country('🇨🇩', 'DR Congo', '+243', 'CD'),
  _Country('🇨🇬', 'Congo', '+242', 'CG'),
  _Country('🇦🇴', 'Angola', '+244', 'AO'),
  _Country('🇸🇩', 'Sudan', '+249', 'SD'),
  _Country('🇪🇬', 'Egypt', '+20', 'EG'),
  _Country('🇱🇾', 'Libya', '+218', 'LY'),
  _Country('🇹🇳', 'Tunisia', '+216', 'TN'),
  _Country('🇩🇿', 'Algeria', '+213', 'DZ'),
  _Country('🇲🇦', 'Morocco', '+212', 'MA'),
  _Country('🇲🇷', 'Mauritania', '+222', 'MR'),
  _Country('🇲🇱', 'Mali', '+223', 'ML'),
  _Country('🇧🇫', 'Burkina Faso', '+226', 'BF'),
  _Country('🇳🇪', 'Niger', '+227', 'NE'),
  _Country('🇹🇩', 'Chad', '+235', 'TD'),
  _Country('🇬🇦', 'Gabon', '+241', 'GA'),
  _Country('🇲🇺', 'Mauritius', '+230', 'MU'),
  _Country('🇬🇧', 'United Kingdom', '+44', 'GB'),
  _Country('🇺🇸', 'United States', '+1', 'US'),
  _Country('🇨🇦', 'Canada', '+1', 'CA'),
  _Country('🇩🇪', 'Germany', '+49', 'DE'),
  _Country('🇫🇷', 'France', '+33', 'FR'),
  _Country('🇮🇹', 'Italy', '+39', 'IT'),
  _Country('🇪🇸', 'Spain', '+34', 'ES'),
  _Country('🇵🇹', 'Portugal', '+351', 'PT'),
  _Country('🇳🇱', 'Netherlands', '+31', 'NL'),
  _Country('🇨🇭', 'Switzerland', '+41', 'CH'),
  _Country('🇸🇪', 'Sweden', '+46', 'SE'),
  _Country('🇳🇴', 'Norway', '+47', 'NO'),
  _Country('🇩🇰', 'Denmark', '+45', 'DK'),
  _Country('🇵🇱', 'Poland', '+48', 'PL'),
  _Country('🇮🇳', 'India', '+91', 'IN'),
  _Country('🇨🇳', 'China', '+86', 'CN'),
  _Country('🇯🇵', 'Japan', '+81', 'JP'),
  _Country('🇰🇷', 'South Korea', '+82', 'KR'),
  _Country('🇦🇺', 'Australia', '+61', 'AU'),
  _Country('🇳🇿', 'New Zealand', '+64', 'NZ'),
  _Country('🇧🇷', 'Brazil', '+55', 'BR'),
  _Country('🇦🇷', 'Argentina', '+54', 'AR'),
  _Country('🇲🇽', 'Mexico', '+52', 'MX'),
  _Country('🇦🇪', 'UAE', '+971', 'AE'),
  _Country('🇸🇦', 'Saudi Arabia', '+966', 'SA'),
  _Country('🇶🇦', 'Qatar', '+974', 'QA'),
  _Country('🇹🇷', 'Turkey', '+90', 'TR'),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class PhoneEntryScreen extends ConsumerStatefulWidget {
  const PhoneEntryScreen({super.key, this.isSwitchAccount = false});

  final bool isSwitchAccount;

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _phoneFocus = FocusNode();

  _Country _country = _kCountries.first; // Tanzania default

  late final AnimationController _animCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 480));
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();

    // Pre-fill any saved phone
    final s = ref.read(onboardingNotifierProvider);
    final saved = s.phone;
    if (saved.isNotEmpty) {
      for (final c in _kCountries) {
        if (saved.startsWith(c.dial)) {
          _country = c;
          _phoneCtrl.text = saved.substring(c.dial.length);
          break;
        }
      }
      if (_phoneCtrl.text.isEmpty) _phoneCtrl.text = saved;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final lang = LocalizationService.languageNotifier.value;
      ref.read(onboardingNotifierProvider.notifier).selectLanguage(lang);
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _phoneCtrl.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isOnline = ref.read(isOnlineProvider);
    if (!isOnline) return; // offline banner already visible; silently ignore taps
    if (!_formKey.currentState!.validate()) return;

    final local = _phoneCtrl.text.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final stripped = local.replaceFirst(RegExp(r'^0+'), '');
    final phone = '${_country.dial}$stripped';

    final notifier = ref.read(onboardingNotifierProvider.notifier);
    notifier.setPhone(phone);
    await notifier.lookupPhone();
    if (!mounted) return;

    final s = ref.read(onboardingNotifierProvider);
    if (s.errorMessage != null) return;

    if (s.isReturningUser) {
      context.go(AppRoutes.pinLogin);
    } else if (s.isTeamMember) {
      context.go(AppRoutes.teamSetup);
    } else {
      context.go(AppRoutes.newUser);
    }
  }

  String? _validatePhone(String? v) {
    final sw = ref.read(onboardingNotifierProvider).isSwahili;
    return OnboardingValidator.validateInternationalPhone(
      v ?? '',
      _country.dial,
      isSwahili: sw,
    );
  }

  Future<void> _pickCountry() async {
    HapticFeedback.selectionClick();
    final sw = ref.read(onboardingNotifierProvider).isSwahili;
    final picked = await showAppSheet<_Country>(
      context,
      builder: (_) => _CountryPickerSheet(countries: _kCountries, isSwahili: sw),
    );
    if (picked != null && mounted) {
      setState(() => _country = picked);
      _formKey.currentState?.validate();
    }
  }

  Future<void> _openWhatsAppHelp(bool sw) async {
    final message = Uri.encodeComponent(
      sw
          ? 'Habari Mali Up Help Desk, nahitaji msaada wa kujiandikisha.'
          : 'Hello Mali Up Help Desk, I need help with registration.',
    );
    final uri = Uri.parse('${OnboardingStrings.helpDeskUrl}$message');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sw
                ? 'Hatukuweza kufungua WhatsApp sasa.'
                : 'We could not open WhatsApp right now.',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);
    final sw = state.isSwahili;
    final isOnline = ref.watch(isOnlineProvider);
    final mediaQuery = MediaQuery.of(context);
    final topHeight = mediaQuery.size.height * 0.35;

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

    return Scaffold(
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
                'assets/Picture/sign_up.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),

          // Top navigation bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!widget.isSwitchAccount)
                    IconButton(
                      onPressed: () => context.go(AppRoutes.intro),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        padding: const EdgeInsets.all(10),
                      ),
                    )
                  else
                    SizedBox(width: 44),
                  TextButton.icon(
                    onPressed: () => _openWhatsAppHelp(sw),
                    icon: const Icon(
                      Icons.headset_mic_outlined,
                      color: Colors.white,
                      size: 15,
                    ),
                    label: Text(
                      sw ? 'Msaada' : 'Help',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
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
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                      child: Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          controller: scrollController,
                          physics: const ClampingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
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
                                  OnboardingStrings.s(sw,
                                      en: OnboardingStrings.phoneTitleEn,
                                      sw: OnboardingStrings.phoneTitleSw),
                                  textAlign: TextAlign.center,
                                  style: headingStyle,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Subtitle
                              Center(
                                child: Text(
                                  OnboardingStrings.s(sw,
                                      en: OnboardingStrings.phoneSubEn,
                                      sw: OnboardingStrings.phoneSubSw),
                                  textAlign: TextAlign.center,
                                  style: subtitleStyle,
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Phone input
                              _PhoneInputRow(
                                country: _country,
                                controller: _phoneCtrl,
                                focusNode: _phoneFocus,
                                isSwahili: sw,
                                enabled: !state.isLoading,
                                validator: _validatePhone,
                                onCountryTap: _pickCountry,
                                onFieldSubmitted: (_) => _submit(),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.lock_outline_rounded,
                                      size: 12, color: AppColors.textMuted),
                                  SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      OnboardingStrings.s(sw,
                                          en: OnboardingStrings.phoneHelperEn,
                                          sw: OnboardingStrings.phoneHelperSw),
                                      style: GoogleFonts.dmSans(
                                          fontSize: 12, color: AppColors.textMuted),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Offline banner
                              if (!isOnline) ...[
                                _OfflineBanner(sw: sw),
                                const SizedBox(height: 16),
                              ],

                              // Error banner
                              if (state.errorMessage != null) ...[
                                OnboardingErrorBanner(
                                    message: state.errorMessage!),
                                const SizedBox(height: 16),
                              ],

                              // CTA button
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
                                  onPressed: (state.isLoading || !isOnline)
                                      ? null
                                      : _submit,
                                  child: state.isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: AppColors.navyPrimary,
                                          ),
                                        )
                                      : Text(
                                          OnboardingStrings.s(sw,
                                              en: OnboardingStrings
                                                  .phoneSendCtaEn,
                                              sw: OnboardingStrings
                                                  .phoneSendCtaSw),
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
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Combined phone input (country code + number field in one row) ────────────

class _PhoneInputRow extends StatefulWidget {
  const _PhoneInputRow({
    required this.country,
    required this.controller,
    required this.focusNode,
    required this.isSwahili,
    required this.enabled,
    required this.validator,
    required this.onCountryTap,
    required this.onFieldSubmitted,
  });

  final _Country country;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSwahili;
  final bool enabled;
  final FormFieldValidator<String> validator;
  final VoidCallback onCountryTap;
  final ValueChanged<String> onFieldSubmitted;

  @override
  State<_PhoneInputRow> createState() => _PhoneInputRowState();
}

class _PhoneInputRowState extends State<_PhoneInputRow> {
  bool _focused = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocus);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocus);
    super.dispose();
  }

  void _onFocus() => setState(() => _focused = widget.focusNode.hasFocus);

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: (_) {
        final err = widget.validator(widget.controller.text);
        setState(() => _error = err);
        return err;
      },
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label
            AnimatedDefaultTextStyle(
              duration: Duration(milliseconds: 180),
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _focused
                    ? AppColors.navyPrimary
                    : AppColors.textMuted,
                letterSpacing: 0.6,
              ),
              child: Text(
                (widget.isSwahili
                    ? OnboardingStrings.phoneLabelSw
                    : OnboardingStrings.phoneLabelEn).toUpperCase(),
              ),
            ),
            const SizedBox(height: 6),

            // Input container
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _error != null
                      ? AppColors.error
                      : _focused
                          ? AppColors.navyPrimary
                          : AppColors.border,
                  width: _focused || _error != null ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  // Country code selector
                  GestureDetector(
                        onTap: widget.enabled ? widget.onCountryTap : null,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 15),
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: _focused
                                ? AppColors.navyPrimary.withValues(alpha: 0.15)
                                : AppColors.border,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.country.flag,
                            style: GoogleFonts.dmSans(fontSize: 20),
                          ),
                          SizedBox(width: 6),
                          Text(
                            widget.country.dial,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.navyPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Number input
                  Expanded(
                    child: TextFormField(
                      controller: widget.controller,
                      focusNode: widget.focusNode,
                      enabled: widget.enabled,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      autofocus: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9\s\-\(\)]')),
                      ],
                      onFieldSubmitted: widget.onFieldSubmitted,
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.navyPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: '7XX XXX XXX',
                        hintStyle: GoogleFonts.dmSans(
                          fontSize: 15,
                          color: AppColors.textDisabled,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 14, vertical: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Error message
            if (_error != null) ...[
              SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 13, color: AppColors.error),
                  SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      _error!,
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

// ─── Country picker bottom sheet ──────────────────────────────────────────────

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet({required this.countries, required this.isSwahili});
  final List<_Country> countries;
  final bool isSwahili;

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _searchCtrl = TextEditingController();
  List<_Country> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.countries;
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filtered = q.isEmpty
          ? widget.countries
          : widget.countries
              .where((c) =>
                  c.name.toLowerCase().contains(q) ||
                  c.dial.contains(q) ||
                  c.code.toLowerCase().contains(q))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.8;

    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
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
          const SizedBox(height: 16),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  widget.isSwahili ? 'Chagua nchi' : 'Select country',
                  style: GoogleFonts.dmSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: AppColors.navyPrimary,
                ),
                decoration: InputDecoration(
                  hintText: widget.isSwahili ? 'Tafuta nchi au nambari…' : 'Search country or code…',
                  hintStyle: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: AppColors.textDisabled,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded,
                      size: 18, color: AppColors.textMuted),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // List
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final c = _filtered[i];
                return _CountryTile(
                  country: c,
                  onTap: () => Navigator.of(context).pop(c),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CountryTile extends StatelessWidget {
  const _CountryTile({required this.country, required this.onTap});
  final _Country country;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
        child: Row(
          children: [
            Text(country.flag, style: GoogleFonts.dmSans(fontSize: 22)),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                country.name,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.navyPrimary,
                ),
              ),
            ),
            Text(
              country.dial,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Offline banner ────────────────────────────────────────────────────────────

class _OfflineBanner extends StatelessWidget {
  final bool sw;
  const _OfflineBanner({required this.sw});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD60A).withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 18, color: Color(0xFF856404)),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sw ? 'Hakuna mtandao' : 'No internet connection',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF856404),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  sw
                      ? 'Tafadhali unganisha mtandao na ujaribu tena.'
                      : 'Please connect to the internet and try again.',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: Color(0xFF856404),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
