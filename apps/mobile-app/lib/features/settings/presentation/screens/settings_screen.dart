import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../shared/widgets/app_sheet.dart';
import 'audit_log_screen.dart';
import 'data_export_screen.dart';
import 'delete_account_screen.dart';
import 'legal_compliance_screen.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/services/motion_service.dart';
import '../../../../core/services/plan_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../config/routing.dart';
import '../../../onboarding/providers/onboarding_notifier.dart';
import 'subscription_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const String _appWebsiteUrl = 'https://neuraltale.com/';
  static const Map<String, String> _socialLinks = {
    'Facebook': 'https://facebook.com/neuraltale',
    'Instagram': 'https://instagram.com/neuraltale',
    'X': 'https://x.com/neuraltale',
    'LinkedIn': 'https://linkedin.com/company/neuraltale',
    'YouTube': 'https://youtube.com/@neuraltale',
  };

  late final VoidCallback _languageListener;
  late final VoidCallback _motionListener;
  AppLanguage _selectedLanguage = LocalizationService.languageNotifier.value;
  bool _reducedMotionEnabled = MotionService.reducedMotionNotifier.value;
  bool _isLoadingLanguage = false;
  bool _notificationsEnabled = true;
  bool _emailAlertsEnabled = false;

  String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

  @override
  void initState() {
    super.initState();
    _languageListener = () {
      if (!mounted) return;
      setState(() {
        _selectedLanguage = LocalizationService.languageNotifier.value;
        _isLoadingLanguage = false;
      });
    };
    _motionListener = () {
      if (!mounted) return;
      setState(() => _reducedMotionEnabled = MotionService.reducedMotionNotifier.value);
    };
    LocalizationService.languageNotifier.addListener(_languageListener);
    MotionService.reducedMotionNotifier.addListener(_motionListener);
  }

  @override
  void dispose() {
    LocalizationService.languageNotifier.removeListener(_languageListener);
    MotionService.reducedMotionNotifier.removeListener(_motionListener);
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  void _showComingSoon(String feature) {
    _showSnackBar(_tr('$feature coming soon', '$feature itakuja hivi karibuni'));
  }

  Future<void> _changeLanguage(AppLanguage language) async {
    setState(() => _isLoadingLanguage = true);
    await LocalizationService.changeLanguage(language);
    if (!mounted) return;
    setState(() {
      _selectedLanguage = language;
      _isLoadingLanguage = false;
    });
    _showSnackBar(_tr(
      'Language changed to ${language.label}',
      'Lugha imebadilishwa kuwa ${language.label}',
    ));
  }

  Future<void> _toggleReducedMotion(bool enabled) async {
    await MotionService.setReducedMotionEnabled(enabled);
    if (!mounted) return;
    _showSnackBar(enabled
        ? _tr('Reduced motion enabled', 'Mwendo uliopunguzwa umewashwa')
        : _tr('Reduced motion disabled', 'Mwendo uliopunguzwa umezimwa'));
  }

  Future<void> _switchAccount() async {
    await FirebaseAuth.instance.signOut();
    ref.read(onboardingNotifierProvider.notifier).resetToPhoneEntry();
    if (!mounted) return;
    context.go(AppRouter.phonePath, extra: {'switchAccount': true});
  }

  Future<void> _openExternalLink(String url) async {
    final uri = Uri.parse(url);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      _showSnackBar(_tr(
        'Could not open link right now.',
        'Imeshindikana kufungua kiungo kwa sasa.',
      ));
    }
  }

  Future<void> _openLanguagePicker() async {
    await showAppSheet<void>(
      context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _tr('Language', 'Lugha'),
                style: Theme.of(sheetCtx).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _tr('Choose your preferred language.', 'Chagua lugha unayoipendelea.'),
                style: Theme.of(sheetCtx).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              ...AppLanguage.values.map((lang) {
                final isSelected = _selectedLanguage == lang;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      _changeLanguage(lang);
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.secondary.withValues(alpha: 0.06)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.secondary.withValues(alpha: 0.25)
                              : AppColors.border,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            lang == AppLanguage.english ? '🇬🇧' : '🇹🇿',
                            style: const TextStyle(fontSize: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang.label,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: isSelected
                                        ? AppColors.secondary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  lang.nativeLabel,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.secondary,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 70, 20, 40),
        children: [
          // ── Page title ───────────────────────────────────────
          Text(
            _tr('Settings', 'Mipangilio'),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.navyPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _tr('Account & preferences', 'Akaunti na mipangilio'),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 20),

          // ── Profile & Plan card ─────────────────────────────
          _ProfileAndPlanCard(tr: _tr, onSwitchAccount: _switchAccount),
          const SizedBox(height: 20),

          // ── Preferences ──────────────────────────────────────
          _SectionHeader(label: _tr('Preferences', 'Mipangilio ya Msingi')),
          const SizedBox(height: 8),
          _SettingCard(
            children: [
              _SettingTile(
                icon: Icons.language_rounded,
                iconBg: AppColors.secondary.withValues(alpha: 0.07),
                iconColor: AppColors.secondary,
                title: _tr('Language', 'Lugha'),
                subtitle: _selectedLanguage.label,
                onTap: _openLanguagePicker,
                trailing: _isLoadingLanguage
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.secondary,
                        ),
                      )
                    : const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
              ),
              const _TileDivider(),
              _SettingTile(
                icon: Icons.motion_photos_pause_rounded,
                iconBg: AppColors.tealAccent.withValues(alpha: 0.1),
                iconColor: AppColors.tealAccent,
                title: _tr('Reduced Motion', 'Punguza Mwendo'),
                subtitle: _tr(
                  'Less animations for accessibility',
                  'Punguza michoro kwa urahisi',
                ),
                trailing: Switch.adaptive(
                  value: _reducedMotionEnabled,
                  onChanged: (v) {
                    setState(() => _reducedMotionEnabled = v);
                    _toggleReducedMotion(v);
                  },
                  activeThumbColor: Colors.white,
                  activeTrackColor: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Notifications ────────────────────────────────────
          _SectionHeader(label: _tr('Notifications', 'Arifa')),
          const SizedBox(height: 8),
          _SettingCard(
            children: [
              _SettingTile(
                icon: Icons.notifications_rounded,
                iconBg: AppColors.warning.withValues(alpha: 0.1),
                iconColor: AppColors.warning,
                title: _tr('Push Notifications', 'Arifa za Simu'),
                subtitle: _tr('Sales, debts and reminders', 'Mauzo, madeni na vikumbusho'),
                trailing: Switch.adaptive(
                  value: _notificationsEnabled,
                  onChanged: (v) {
                    setState(() => _notificationsEnabled = v);
                    _showComingSoon(_tr('Push notifications', 'Arifa za simu'));
                  },
                  activeThumbColor: Colors.white,
                  activeTrackColor: AppColors.secondary,
                ),
              ),
              const _TileDivider(),
              _SettingTile(
                icon: Icons.mark_email_read_rounded,
                iconBg: AppColors.info.withValues(alpha: 0.1),
                iconColor: AppColors.info,
                title: _tr('Email Alerts', 'Arifa za Barua Pepe'),
                subtitle: _tr('Weekly reports to your inbox', 'Ripoti ya wiki kwa barua pepe'),
                trailing: Switch.adaptive(
                  value: _emailAlertsEnabled,
                  onChanged: (v) {
                    setState(() => _emailAlertsEnabled = v);
                    _showComingSoon(_tr('Email alerts', 'Arifa za barua pepe'));
                  },
                  activeThumbColor: Colors.white,
                  activeTrackColor: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Data & Sync ───────────────────────────────────────
          _SectionHeader(label: _tr('Data & Sync', 'Data na Usawazishaji')),
          const SizedBox(height: 8),
          _SettingCard(
            children: [
              _SettingTile(
                icon: Icons.backup_rounded,
                iconBg: AppColors.success.withValues(alpha: 0.1),
                iconColor: AppColors.success,
                title: _tr('Auto Backup', 'Hifadhi Otomatiki'),
                subtitle: _tr('Back up your data daily', 'Hifadhi data yako kila siku'),
                onTap: () => _showComingSoon(_tr('Auto backup', 'Hifadhi otomatiki')),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.textMuted,
                ),
              ),
              const _TileDivider(),
              _SettingTile(
                icon: Icons.download_rounded,
                iconBg: AppColors.tealAccent.withValues(alpha: 0.1),
                iconColor: AppColors.tealAccent,
                title: _tr('Export Data', 'Hamisha Data'),
                subtitle: _tr('Download as CSV or PDF', 'Pakua kama CSV au PDF'),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const DataExportScreen(),
                )),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.textMuted,
                ),
              ),
              const _TileDivider(),
              _SettingTile(
                icon: Icons.history_rounded,
                iconBg: AppColors.secondary.withValues(alpha: 0.07),
                iconColor: AppColors.secondary,
                title: _tr('Audit Log', 'Kumbukumbu ya Matukio'),
                subtitle: _tr('View account activity history', 'Angalia historia ya shughuli za akaunti'),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const AuditLogScreen(),
                )),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Support ───────────────────────────────────────────
          _SectionHeader(label: _tr('Support', 'Msaada')),
          const SizedBox(height: 8),
          _SettingCard(
            children: [
              _SettingTile(
                icon: Icons.help_rounded,
                iconBg: AppColors.info.withValues(alpha: 0.1),
                iconColor: AppColors.info,
                title: _tr('Help Center', 'Kituo cha Msaada'),
                subtitle: _tr('FAQs and how-to guides', 'Maswali na mwongozo wa matumizi'),
                onTap: () => _showComingSoon(_tr('Help center', 'Kituo cha msaada')),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.textMuted,
                ),
              ),
              const _TileDivider(),
              _SettingTile(
                icon: Icons.bug_report_rounded,
                iconBg: AppColors.warning.withValues(alpha: 0.1),
                iconColor: AppColors.warning,
                title: _tr('Report a Bug', 'Ripoti Hitilafu'),
                subtitle: _tr('Help us improve the app', 'Tusaidie kuboresha programu'),
                onTap: () => _showComingSoon(_tr('Bug reports', 'Ripoti za hitilafu')),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.textMuted,
                ),
              ),
              const _TileDivider(),
              _SettingTile(
                icon: Icons.star_rounded,
                iconBg: AppColors.primary.withValues(alpha: 0.12),
                iconColor: AppColors.primary,
                title: _tr('Rate the App', 'Kadiria Programu'),
                subtitle: _tr('Leave a review on the store', 'Tuachie tathmini kwenye duka'),
                onTap: () => _showComingSoon(_tr('App rating', 'Kadiria programu')),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Legal & Compliance ────────────────────────────────
          _SectionHeader(label: _tr('Legal & Compliance', 'Kisheria na Uzingatiaji')),
          const SizedBox(height: 8),
          _SettingCard(
            children: [
              _SettingTile(
                icon: Icons.shield_outlined,
                iconBg: AppColors.secondary.withValues(alpha: 0.06),
                iconColor: AppColors.secondary,
                title: _tr('Legal & Compliance', 'Kisheria na Uzingatiaji'),
                subtitle: _tr(
                  'BRELA, TRA, BoT, data protection & more',
                  'BRELA, TRA, BoT, ulinzi wa data na zaidi',
                ),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const LegalComplianceScreen(),
                )),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.textMuted,
                ),
              ),
              const _TileDivider(),
              _SettingTile(
                icon: Icons.delete_forever_outlined,
                iconBg: AppColors.error.withValues(alpha: 0.07),
                iconColor: AppColors.error,
                title: _tr('Delete Account', 'Futa Akaunti'),
                subtitle: _tr('Permanently remove your data', 'Futa data yako kabisa'),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const DeleteAccountScreen(),
                )),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── About ─────────────────────────────────────────────
          _SectionHeader(label: _tr('About', 'Kuhusu')),
          const SizedBox(height: 8),
          _SettingCard(
            children: [
              _SettingTile(
                icon: Icons.info_outline_rounded,
                iconBg: AppColors.secondary.withValues(alpha: 0.06),
                iconColor: AppColors.secondary,
                title: _tr('App Version', 'Toleo la Programu'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    '1.1.0',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const _TileDivider(),
              _SettingTile(
                icon: Icons.language_rounded,
                iconBg: AppColors.secondary.withValues(alpha: 0.06),
                iconColor: AppColors.secondary,
                title: _tr('Website', 'Tovuti'),
                subtitle: 'neuraltale.com',
                onTap: () => _openExternalLink(_appWebsiteUrl),
                trailing: const Icon(
                  Icons.open_in_new_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Follow us ─────────────────────────────────────────
          _SectionHeader(label: _tr('Follow Us', 'Tufuate')),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SocialIcon(
                label: 'f',
                color: const Color(0xFF1877F2),
                onTap: () => _openExternalLink(_socialLinks['Facebook']!),
              ),
              const SizedBox(width: 14),
              _SocialIcon(
                label: 'IG',
                color: const Color(0xFFE1306C),
                onTap: () => _openExternalLink(_socialLinks['Instagram']!),
              ),
              const SizedBox(width: 14),
              _SocialIcon(
                label: 'X',
                color: Colors.black87,
                onTap: () => _openExternalLink(_socialLinks['X']!),
              ),
              const SizedBox(width: 14),
              _SocialIcon(
                label: 'in',
                color: const Color(0xFF0A66C2),
                onTap: () => _openExternalLink(_socialLinks['LinkedIn']!),
              ),
              const SizedBox(width: 14),
              _SocialIcon(
                icon: Icons.play_arrow_rounded,
                color: const Color(0xFFFF0000),
                onTap: () => _openExternalLink(_socialLinks['YouTube']!),
              ),
            ],
          ),
          const SizedBox(height: 28),

          Center(
            child: Text(
              _tr('Made with ♥ by Neuraltale', 'Imetengenezwa kwa ♥ na Neuraltale'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textDisabled,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Profile & Plan combined card ─────────────────────────────────────────────

class _ProfileAndPlanCard extends ConsumerWidget {
  final String Function(String en, String sw) tr;
  final VoidCallback onSwitchAccount;
  const _ProfileAndPlanCard({required this.tr, required this.onSwitchAccount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(planStatusProvider);
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim();
    final initial = displayName != null && displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : 'M';
    final name = displayName?.isNotEmpty == true
        ? displayName!
        : tr('Mali Up User', 'Mtumiaji wa Mali Up');
    final contact = (user?.phoneNumber?.trim().isNotEmpty == true
            ? user!.phoneNumber!
            : user?.email?.trim().isNotEmpty == true
                ? user!.email!
                : null) ??
        tr('No contact details', 'Hakuna mawasiliano');

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyPrimary.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // ── Blue gradient section (profile + plan) ──────────
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              ),
              child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.navyPrimary, AppColors.navySecondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile row
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.yellowBrand,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: AppColors.navyPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              contact,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.50),
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: Icon(
                          Icons.edit_outlined,
                          color: Colors.white.withValues(alpha: 0.40),
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Divider(
                      color: Colors.white.withValues(alpha: 0.10),
                      height: 1,
                    ),
                  ),
                  // Plan section
                  planAsync.when(
                      loading: () => _PlanCardBody(
                        planName: 'Starter',
                        statusLabel: tr('Loading…', 'Inapakia…'),
                        isStarter: true,
                        pct: 0,
                        invoicesUsed: 0,
                        invoiceLimit: 10,
                        expiresAt: null,
                        tr: tr,
                      ),
                      error: (err, st) => _PlanCardBody(
                        planName: 'Starter',
                        statusLabel: tr('Free plan', 'Mpango wa bure'),
                        isStarter: true,
                        pct: 0,
                        invoicesUsed: 0,
                        invoiceLimit: 10,
                        expiresAt: null,
                        tr: tr,
                      ),
                      data: (s) => _PlanCardBody(
                        planName: s.tierLabel,
                        statusLabel: s.isStarter
                            ? tr('Free plan · Limited features', 'Mpango wa bure · Vipengele vichache')
                            : tr('Active subscription', 'Usajili unaofanya kazi'),
                        isStarter: s.isStarter,
                        pct: s.isStarter
                            ? (s.invoicesUsedThisMonth / s.limits.monthlyInvoices).clamp(0.0, 1.0)
                            : 1.0,
                        invoicesUsed: s.invoicesUsedThisMonth,
                        invoiceLimit: s.limits.monthlyInvoices,
                        expiresAt: s.expiresAt,
                        tr: tr,
                      ),
                    ),
                ],
              ),
            ),
            ),
            // ── Switch Account (white section) ──────────────────
            Container(
              color: AppColors.surface,
              child: _SettingTile(
                icon: Icons.swap_horiz_rounded,
                iconBg: AppColors.secondary.withValues(alpha: 0.07),
                iconColor: AppColors.secondary,
                title: tr('Switch Account', 'Badili Akaunti'),
                subtitle: tr(
                  'Sign out and use a different account',
                  'Toka na utumie akaunti nyingine',
                ),
                onTap: onSwitchAccount,
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ── Card wrapper ──────────────────────────────────────────────────────────────

class _SettingCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}

// ── Divider between tiles ────────────────────────────────────────────────────

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 66),
      child: Divider(height: 1, color: AppColors.border),
    );
  }
}

// ── Generic setting row ───────────────────────────────────────────────────────

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

// ── Social icon button ────────────────────────────────────────────────────────

class _SocialIcon extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final Color color;
  final VoidCallback onTap;

  const _SocialIcon({
    this.label,
    this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, size: 22, color: color)
              : Text(
                  label!,
                  style: TextStyle(
                    color: color,
                    fontSize: label!.length > 1 ? 12 : 18,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
        ),
      ),
    );
  }
}

class _PlanCardBody extends StatelessWidget {
  final String planName;
  final String statusLabel;
  final bool isStarter;
  final double pct;
  final int invoicesUsed;
  final int invoiceLimit;
  final DateTime? expiresAt;
  final String Function(String, String) tr;

  const _PlanCardBody({
    required this.planName,
    required this.statusLabel,
    required this.isStarter,
    required this.pct,
    required this.invoicesUsed,
    required this.invoiceLimit,
    required this.expiresAt,
    required this.tr,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isStarter ? Icons.workspace_premium_outlined : Icons.stars_rounded,
          color: AppColors.yellowBrand,
          size: 16,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    planName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (isStarter) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.yellowBrand,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        tr('Upgrade', 'Boresha'),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navyPrimary,
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
              if (isStarter) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 3,
                          backgroundColor: Colors.white.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            pct >= 1.0
                                ? AppColors.error
                                : pct >= 0.8
                                    ? AppColors.warning
                                    : AppColors.tealAccent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$invoicesUsed/$invoiceLimit',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: pct >= 0.8
                            ? AppColors.warning
                            : Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ] else if (expiresAt != null) ...[
                const SizedBox(height: 2),
                Text(
                  tr(
                    'Valid until ${_fmtDate(expiresAt!)}',
                    'Inakwisha ${_fmtDate(expiresAt!)}',
                  ),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ],
          ),
        ),
        Icon(
          Icons.chevron_right_rounded,
          size: 16,
          color: Colors.white.withValues(alpha: 0.30),
        ),
      ],
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
