import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/onboarding_strings.dart';
import '../../../../shared/widgets/app_notification.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../core/services/lookup_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/validators/onboarding_validator.dart';
import '../../providers/onboarding_notifier.dart';
import '../../../../config/routing.dart';
import '../widgets/onboarding_back_handler.dart';
import '_onboarding_scaffold.dart';

// ─── Business type data ───────────────────────────────────────────────────────

class _BizType {
  const _BizType(this.key, this.en, this.sw, this.icon);
  final String key;
  final String en;
  final String sw;
  final IconData icon;
}

const List<_BizType> _kBizTypes = [
  _BizType('retail', 'Retail Shop', 'Duka la Rejareja', Icons.storefront_rounded),
  _BizType('restaurant', 'Restaurant / Café', 'Mkahawa / Café', Icons.restaurant_rounded),
  _BizType('food_beverages', 'Food & Beverages', 'Chakula na Vinywaji', Icons.lunch_dining_rounded),
  _BizType('wholesale', 'Wholesale', 'Jumla', Icons.inventory_2_rounded),
  _BizType('salon', 'Salon & Beauty', 'Saluni na Urembo', Icons.content_cut_rounded),
  _BizType('pharmacy', 'Pharmacy', 'Duka la Dawa', Icons.local_pharmacy_rounded),
  _BizType('electronics', 'Electronics', 'Vifaa vya Elektroniki', Icons.devices_rounded),
  _BizType('hardware', 'Hardware & Building', 'Vifaa vya Ujenzi', Icons.hardware_rounded),
  _BizType('tailoring', 'Tailoring & Fashion', 'Ushonaji na Mitindo', Icons.checkroom_rounded),
  _BizType('agriculture', 'Agriculture & Farming', 'Kilimo na Ufugaji', Icons.grass_rounded),
  _BizType('transport', 'Transport & Logistics', 'Usafirishaji', Icons.local_shipping_rounded),
  _BizType('health', 'Health & Wellness', 'Afya na Ustawi', Icons.favorite_rounded),
  _BizType('education', 'Education & Training', 'Elimu na Mafunzo', Icons.school_rounded),
  _BizType('construction', 'Construction', 'Ujenzi', Icons.construction_rounded),
  _BizType('real_estate', 'Real Estate', 'Mali Isiyohamishika', Icons.home_work_rounded),
  _BizType('printing', 'Printing & Branding', 'Uchapishaji', Icons.print_rounded),
  _BizType('cleaning', 'Cleaning Services', 'Huduma za Usafi', Icons.cleaning_services_rounded),
  _BizType('tech_services', 'IT & Tech Services', 'Huduma za TEHAMA', Icons.computer_rounded),
  _BizType('events', 'Events & Entertainment', 'Matukio na Burudani', Icons.celebration_rounded),
  _BizType('freelance', 'Freelancing', 'Kazi za Mkataba', Icons.work_rounded),
  _BizType('consultancy', 'Consultancy', 'Ushauri wa Kitaalamu', Icons.business_center_rounded),
  _BizType('banking_finance', 'Banking & Finance', 'Benki na Fedha', Icons.account_balance_rounded),
  _BizType('mobile_money', 'Mobile Money Agent', 'Wakala wa Pesa za Simu', Icons.mobile_friendly_rounded),
  _BizType('insurance', 'Insurance', 'Bima', Icons.verified_user_rounded),
  _BizType('photography', 'Photography & Video', 'Upigaji Picha', Icons.camera_alt_rounded),
  _BizType('media', 'Media & Marketing', 'Habari na Masoko', Icons.campaign_rounded),
  _BizType('legal', 'Legal Services', 'Huduma za Kisheria', Icons.gavel_rounded),
  _BizType('security_guard', 'Security Services', 'Huduma za Usalama', Icons.shield_rounded),
  _BizType('travel', 'Travel & Tourism', 'Usafiri na Utalii', Icons.flight_rounded),
  _BizType('other', 'Other', 'Nyingine', Icons.more_horiz_rounded),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class BusinessDetailsScreen extends ConsumerStatefulWidget {
  const BusinessDetailsScreen({super.key});

  @override
  ConsumerState<BusinessDetailsScreen> createState() =>
      _BusinessDetailsScreenState();
}

class _BusinessDetailsScreenState extends ConsumerState<BusinessDetailsScreen>
    with SingleTickerProviderStateMixin {
  final _formKey      = GlobalKey<FormState>();
  final _bizNameCtrl  = TextEditingController();
  final _websiteCtrl  = TextEditingController();

  String? _selectedTypeKey;
  bool _typeError = false;

  String _region   = '';
  String _district = '';
  bool _websiteInterest = false;

  Map<String, List<String>> _tzRegions = LookupService.defaultDistricts;

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

    final s = ref.read(onboardingNotifierProvider);
    _bizNameCtrl.text  = s.businessName;
    _websiteCtrl.text  = s.websiteUrl;
    _selectedTypeKey   = s.businessType.isNotEmpty ? s.businessType : null;
    _region            = s.businessRegion;
    _district          = s.businessDistrict;
    _websiteInterest   = s.websiteInterest;

    LookupService.fetchDistricts().then((data) {
      if (mounted) setState(() => _tzRegions = data);
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _bizNameCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final formValid = _formKey.currentState!.validate();
    if (_selectedTypeKey == null) setState(() => _typeError = true);
    if (!formValid || _selectedTypeKey == null) return;

    final notifier   = ref.read(onboardingNotifierProvider.notifier);
    final websiteUrl = _websiteCtrl.text.trim();
    notifier.setBusinessName(_bizNameCtrl.text.trim());
    notifier.setBusinessType(_selectedTypeKey!);
    notifier.setBusinessRegion(_region);
    notifier.setBusinessDistrict(_district);
    if (_region.isNotEmpty) notifier.setCity(_region);
    notifier.setWebsiteUrl(websiteUrl);
    notifier.setHasWebsite(websiteUrl.isNotEmpty);
    notifier.setWebsiteInterest(_websiteInterest);
    if (_websiteInterest) {
      SharedPreferences.getInstance()
          .then((p) => p.setBool('pending_website_interest', true));
    }
    notifier.advanceFromBusinessDetails();
    context.go(AppRoutes.security);
  }

  Future<void> _pickType(bool sw) async {
    HapticFeedback.selectionClick();
    final picked = await showAppSheet<String>(
      context,
      builder: (_) => _BizTypePickerSheet(
        types: _kBizTypes,
        selectedKey: _selectedTypeKey,
        isSwahili: sw,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedTypeKey = picked;
        _typeError = false;
      });
    }
  }

  Future<void> _pickRegion() async {
    HapticFeedback.selectionClick();
    final picked = await showAppSheet<String>(
      context,
      builder: (_) => _SearchPickerSheet(
        title: 'Select Region',
        items: _tzRegions.keys.toList()..sort(),
        selected: _region.isEmpty ? null : _region,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _region = picked;
        _district = '';
      });
    }
  }

  Future<void> _pickDistrict() async {
    if (_region.isEmpty) return;
    HapticFeedback.selectionClick();
    final districts = _tzRegions[_region] ?? [];
    final picked = await showAppSheet<String>(
      context,
      builder: (_) => _SearchPickerSheet(
        title: 'Select District',
        items: districts,
        selected: _district.isEmpty ? null : _district,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _district = picked);
    }
  }

  Future<void> _openWhatsAppHelp(bool sw) async {
    final message = Uri.encodeComponent(
      sw
          ? 'Habari Mali Up Help Desk, nahitaji msaada wa maelezo ya biashara.'
          : 'Hello Mali Up Help Desk, I need help with my business details.',
    );
    final uri = Uri.parse('${OnboardingStrings.helpDeskUrl}$message');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      AppNotification.error(
        context,
        sw ? 'Hatukuweza kufungua WhatsApp sasa.' : 'We could not open WhatsApp right now.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state     = ref.watch(onboardingNotifierProvider);
    final sw        = state.isSwahili;
    final firstName = state.firstName.isNotEmpty
        ? state.firstName
        : (sw ? 'wewe' : 'there');
    final topHeight = MediaQuery.of(context).size.height * 0.35;

    final selectedType = _selectedTypeKey != null
        ? _kBizTypes.firstWhere((t) => t.key == _selectedTypeKey,
            orElse: () => _kBizTypes.last)
        : null;

    final headingStyle = GoogleFonts.dmSans(
      fontSize: 26,
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w800,
      height: 1.2,
      letterSpacing: -0.4,
    );
    final subtitleStyle = GoogleFonts.dmSans(
      color: AppColors.textSecondary,
      fontSize: 14,
      height: 1.5,
      fontWeight: FontWeight.w400,
    );

    final scaffold = Scaffold(
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

          // Top navigation bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => context.go(AppRoutes.newUser),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      padding: const EdgeInsets.all(10),
                    ),
                  ),
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
                      child: Form(
                        key: _formKey,
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
                                  OnboardingStrings.s(sw,
                                      en: OnboardingStrings.bizGreetEn(
                                          firstName),
                                      sw: OnboardingStrings.bizGreetSw(
                                          firstName)),
                                  textAlign: TextAlign.center,
                                  style: headingStyle,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: Text(
                                  OnboardingStrings.s(sw,
                                      en: OnboardingStrings.bizSubEn,
                                      sw: OnboardingStrings.bizSubSw),
                                  textAlign: TextAlign.center,
                                  style: subtitleStyle,
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Business name
                              OnboardingField(
                                controller: _bizNameCtrl,
                                label: OnboardingStrings.s(sw,
                                    en: OnboardingStrings.bizNameLabelEn,
                                    sw: OnboardingStrings.bizNameLabelSw),
                                hint: OnboardingStrings.s(sw,
                                    en: OnboardingStrings.bizNameHintEn,
                                    sw: OnboardingStrings.bizNameHintSw),
                                autofocus: true,
                                prefix: const Icon(Icons.storefront_outlined,
                                    size: 18, color: AppColors.textMuted),
                                validator: (v) =>
                                    OnboardingValidator.validateBusinessName(
                                        v ?? '', isSwahili: sw),
                              ),
                              const SizedBox(height: 24),

                              // Business type selector
                              _SectionLabel(
                                label: OnboardingStrings.s(sw,
                                    en: OnboardingStrings.bizTypeLabelEn,
                                    sw: OnboardingStrings.bizTypeLabelSw),
                              ),
                              const SizedBox(height: 8),
                              _TapSelector(
                                icon: selectedType?.icon ??
                                    Icons.category_rounded,
                                value: selectedType != null
                                    ? (sw
                                        ? selectedType.sw
                                        : selectedType.en)
                                    : null,
                                placeholder: OnboardingStrings.s(sw,
                                    en: OnboardingStrings
                                        .bizTypeSelectPromptEn,
                                    sw: OnboardingStrings
                                        .bizTypeSelectPromptSw),
                                hasError: _typeError,
                                onTap: () => _pickType(sw),
                              ),
                              if (_typeError) ...[
                                const SizedBox(height: 6),
                                _FieldError(
                                  message: OnboardingStrings.s(sw,
                                      en: OnboardingStrings.bizTypeRequiredEn,
                                      sw: OnboardingStrings.bizTypeRequiredSw),
                                ),
                              ],
                              const SizedBox(height: 28),

                              // Location section
                              _SectionLabel(
                                label: sw
                                    ? 'Mahali pa biashara'
                                    : 'Business location',
                              ),
                              const SizedBox(height: 4),
                              Text(
                                sw
                                    ? 'Saidia wateja kukupata.'
                                    : 'Helps customers and reports stay accurate.',
                                style: GoogleFonts.dmSans(
                                    fontSize: 12, color: AppColors.textMuted),
                              ),
                              const SizedBox(height: 12),

                              // Country (fixed)
                              _LocationRow(
                                icon: Icons.public_rounded,
                                label: sw ? 'Nchi' : 'Country',
                                value: '🇹🇿  Tanzania',
                                isFixed: true,
                                onTap: null,
                              ),
                              const SizedBox(height: 10),

                              // Region
                              _LocationRow(
                                icon: Icons.map_rounded,
                                label: sw ? 'Mkoa' : 'Region',
                                value: _region.isEmpty ? null : _region,
                                placeholder:
                                    sw ? 'Chagua mkoa' : 'Select region',
                                onTap: _pickRegion,
                              ),
                              const SizedBox(height: 10),

                              // District
                              _LocationRow(
                                icon: Icons.location_city_rounded,
                                label: sw ? 'Wilaya' : 'District',
                                value: _district.isEmpty ? null : _district,
                                placeholder: _region.isEmpty
                                    ? (sw
                                        ? 'Chagua mkoa kwanza'
                                        : 'Select region first')
                                    : (sw
                                        ? 'Chagua wilaya'
                                        : 'Select district'),
                                disabled: _region.isEmpty,
                                onTap: _region.isEmpty ? null : _pickDistrict,
                              ),
                              const SizedBox(height: 28),

                              // ── Online presence ──────────────────────────
                              _SectionLabel(
                                label: sw
                                    ? 'Mtandao wa Biashara'
                                    : 'Online Presence',
                              ),
                              const SizedBox(height: 4),
                              Text(
                                sw
                                    ? 'Ongeza tovuti yako kama una moja (si lazima).'
                                    : 'Add your website if you have one (optional).',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _websiteCtrl,
                                keyboardType: TextInputType.url,
                                textInputAction: TextInputAction.done,
                                autocorrect: false,
                                style: GoogleFonts.dmSans(
                                  fontSize: 15,
                                  color: AppColors.navyPrimary,
                                ),
                                decoration: InputDecoration(
                                  labelText: sw
                                      ? 'Tovuti ya Biashara (Si lazima)'
                                      : 'Business Website (Optional)',
                                  hintText: 'https://mybusiness.com',
                                  prefixIcon: const Icon(
                                    Icons.language_rounded,
                                    size: 18,
                                    color: AppColors.textMuted,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                        color: AppColors.border),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                        color: AppColors.border),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: AppColors.navyPrimary
                                          .withValues(alpha: 0.4),
                                      width: 1.5,
                                    ),
                                  ),
                                  labelStyle: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    color: AppColors.textMuted,
                                  ),
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: () => setState(
                                  () => _websiteInterest = !_websiteInterest,
                                ),
                                behavior: HitTestBehavior.opaque,
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: Checkbox(
                                        value: _websiteInterest,
                                        onChanged: (v) => setState(
                                          () => _websiteInterest =
                                              v ?? false,
                                        ),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        activeColor: Colors.white,
                                        checkColor: AppColors.yellowBrand,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        side: const BorderSide(
                                          color: AppColors.yellowBrand,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        sw
                                            ? 'Nitengenezee tovuti yangu'
                                            : 'Build me my website',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 13,
                                          color: AppColors.textMuted,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Error
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
                                  onPressed: _submit,
                                  child: Text(
                                    OnboardingStrings.s(sw,
                                        en: OnboardingStrings.bizCtaEn,
                                        sw: OnboardingStrings.bizCtaSw),
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
    return OnboardingBackHandler(
      onBack: () => context.go(AppRoutes.newUser),
      child: scaffold,
    );
  }
}

// ─── Shared small widgets ──────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.navyPrimary,
          letterSpacing: 0.1,
        ),
      );
}

class _FieldError extends StatelessWidget {
  const _FieldError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 13, color: AppColors.error),
          const SizedBox(width: 5),
          Expanded(
            child: Text(message,
                style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.error)),
          ),
        ],
      );
}

// ─── Tap-to-open selector row ─────────────────────────────────────────────────

class _TapSelector extends StatefulWidget {
  const _TapSelector({
    required this.icon,
    required this.value,
    required this.placeholder,
    required this.onTap,
    this.hasError = false,
  });

  final IconData icon;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;
  final bool hasError;

  @override
  State<_TapSelector> createState() => _TapSelectorState();
}

class _TapSelectorState extends State<_TapSelector>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 180),
      lowerBound: 0.97,
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.value != null;
    return ScaleTransition(
      scale: _pressCtrl,
      child: GestureDetector(
        onTapDown: (_) => _pressCtrl.reverse(),
        onTapUp: (_) {
          _pressCtrl.forward();
          widget.onTap();
        },
        onTapCancel: () => _pressCtrl.forward(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.hasError
                  ? AppColors.error
                  : hasValue
                      ? AppColors.navyPrimary.withValues(alpha: 0.35)
                      : AppColors.border,
              width: hasValue ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: hasValue ? AppColors.navyPrimary : AppColors.textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.value ?? widget.placeholder,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight:
                        hasValue ? FontWeight.w600 : FontWeight.w400,
                    color: hasValue
                        ? AppColors.navyPrimary
                        : AppColors.textDisabled,
                  ),
                ),
              ),
              Icon(
                hasValue
                    ? Icons.check_circle_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: hasValue ? AppColors.success : AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Location row ─────────────────────────────────────────────────────────────

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
    this.placeholder,
    this.isFixed = false,
    this.disabled = false,
  });

  final IconData icon;
  final String label;
  final String? value;
  final String? placeholder;
  final bool isFixed;
  final bool disabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: disabled ? AppColors.surfaceVariant : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue && !isFixed
                ? AppColors.navyPrimary.withValues(alpha: 0.30)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 17,
              color: disabled
                  ? AppColors.textDisabled
                  : hasValue
                      ? AppColors.navyPrimary
                      : AppColors.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: disabled
                          ? AppColors.textDisabled
                          : AppColors.textMuted,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value ?? placeholder ?? '',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight:
                          hasValue ? FontWeight.w600 : FontWeight.w400,
                      color: disabled
                          ? AppColors.textDisabled
                          : hasValue
                              ? AppColors.navyPrimary
                              : AppColors.textDisabled,
                    ),
                  ),
                ],
              ),
            ),
            if (!isFixed)
              Icon(
                hasValue
                    ? Icons.check_circle_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 17,
                color: disabled
                    ? AppColors.textDisabled
                    : hasValue
                        ? AppColors.success
                        : AppColors.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Business type picker bottom sheet ────────────────────────────────────────

class _BizTypePickerSheet extends StatefulWidget {
  const _BizTypePickerSheet({
    required this.types,
    required this.selectedKey,
    required this.isSwahili,
  });

  final List<_BizType> types;
  final String? selectedKey;
  final bool isSwahili;

  @override
  State<_BizTypePickerSheet> createState() => _BizTypePickerSheetState();
}

class _BizTypePickerSheetState extends State<_BizTypePickerSheet> {
  final _searchCtrl = TextEditingController();
  late List<_BizType> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.types;
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
          ? widget.types
          : widget.types
              .where((t) =>
                  t.en.toLowerCase().contains(q) ||
                  t.sw.toLowerCase().contains(q))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.8;
    final sw = widget.isSwahili;

    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              OnboardingStrings.s(sw,
                  en: OnboardingStrings.bizTypeLabelEn,
                  sw: OnboardingStrings.bizTypeLabelSw),
              style: GoogleFonts.dmSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.navyPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
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
                style: GoogleFonts.dmSans(
                    fontSize: 14, color: AppColors.navyPrimary),
                decoration: InputDecoration(
                  hintText: sw
                      ? 'Tafuta aina ya biashara…'
                      : 'Search business type…',
                  hintStyle: GoogleFonts.dmSans(
                      fontSize: 14, color: AppColors.textDisabled),
                  prefixIcon: const Icon(Icons.search_rounded,
                      size: 18, color: AppColors.textMuted),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 32),
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final t = _filtered[i];
                final selected = t.key == widget.selectedKey;
                return _BizTypeTile(
                  type: t,
                  isSwahili: sw,
                  selected: selected,
                  onTap: () => Navigator.of(context).pop(t.key),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BizTypeTile extends StatelessWidget {
  const _BizTypeTile({
    required this.type,
    required this.isSwahili,
    required this.selected,
    required this.onTap,
  });

  final _BizType type;
  final bool isSwahili;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.navyPrimary.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: selected ? AppColors.navyPrimary : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color:
                      selected ? AppColors.navyPrimary : AppColors.border,
                ),
              ),
              child: Icon(
                type.icon,
                size: 18,
                color:
                    selected ? AppColors.yellowBrand : AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                isSwahili ? type.sw : type.en,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                  color: AppColors.navyPrimary,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_rounded,
                  size: 18, color: AppColors.success),
          ],
        ),
      ),
    );
  }
}

// ─── Generic searchable picker sheet ─────────────────────────────────────────

class _SearchPickerSheet extends StatefulWidget {
  const _SearchPickerSheet({
    required this.title,
    required this.items,
    this.selected,
  });

  final String title;
  final List<String> items;
  final String? selected;

  @override
  State<_SearchPickerSheet> createState() => _SearchPickerSheetState();
}

class _SearchPickerSheetState extends State<_SearchPickerSheet> {
  final _searchCtrl = TextEditingController();
  late List<String> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
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
          ? widget.items
          : widget.items.where((s) => s.toLowerCase().contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.80;

    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              widget.title,
              style: GoogleFonts.dmSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.navyPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
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
                style: GoogleFonts.dmSans(
                    fontSize: 14, color: AppColors.navyPrimary),
                decoration: InputDecoration(
                  hintText: 'Search…',
                  hintStyle: GoogleFonts.dmSans(
                      fontSize: 14, color: AppColors.textDisabled),
                  prefixIcon: const Icon(Icons.search_rounded,
                      size: 18, color: AppColors.textMuted),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 32),
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final item = _filtered[i];
                final isSelected = item == widget.selected;
                return InkWell(
                  onTap: () => Navigator.of(context).pop(item),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: AppColors.navyPrimary,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_rounded,
                              size: 17, color: AppColors.success),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
