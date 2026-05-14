import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/services/motion_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/emotional_design.dart';
import '../../../../shared/widgets/mali_components.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
      setState(() {
        _reducedMotionEnabled = MotionService.reducedMotionNotifier.value;
      });
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

  Future<void> _changeLanguage(AppLanguage language) async {
    setState(() => _isLoadingLanguage = true);
    await LocalizationService.changeLanguage(language);
    if (!mounted) return;
    setState(() {
      _selectedLanguage = language;
      _isLoadingLanguage = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _tr(
            'Language changed to ${language.label}',
            'Lugha imebadilishwa kuwa ${language.label}',
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _toggleReducedMotion(bool enabled) async {
    await MotionService.setReducedMotionEnabled(enabled);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled
              ? _tr('Reduced motion enabled', 'Mwendo uliopunguzwa umewashwa')
              : _tr('Reduced motion disabled', 'Mwendo uliopunguzwa umezimwa'),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openExternalLink(String url) async {
    final uri = Uri.parse(url);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr(
              'Could not open link right now.',
              'Imeshindikana kufungua kiungo kwa sasa.',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tr(
                          'Tune your workspace',
                          'Boresha mazingira yako ya kazi',
                        ),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _tr(
                          'Customize language and motion preferences for a smoother experience.',
                          'Binafsisha lugha na mwendo kwa matumizi yaliyo laini zaidi.',
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const EmotionalLottieSpot(
                  scene: EmotionalLottieScene.authWelcome,
                  size: 62,
                ),
              ],
            ),
            const SizedBox(height: 20),

            Text(
              _tr('Language', 'Lugha'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: _isLoadingLanguage
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: SkeletonList(itemCount: 2),
                    )
                  : Column(
                      children: AppLanguage.values.map((language) {
                        final isSelected = _selectedLanguage == language;
                        return _LanguageSettingTile(
                          language: language,
                          isSelected: isSelected,
                          onTap: () => _changeLanguage(language),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 32),
            Text(
              _tr('About', 'Kuhusu'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _tr('App Version', 'Toleo la Programu'),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Text(
                        '1.0.0',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 12),
                  Text(
                    _tr('Terms & Conditions', 'Sheria na Masharti'),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 12),
                  Text(
                    _tr('Privacy Policy', 'Sera ya Faragha'),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 12),
                  Text(
                    _tr('Website & Social Media', 'Tovuti na Mitandao ya Kijamii'),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _SocialLinkChip(
                        label: _tr('Website', 'Tovuti'),
                        icon: Icons.language_rounded,
                        onTap: () => _openExternalLink(_appWebsiteUrl),
                      ),
                      ..._socialLinks.entries.map(
                        (entry) => _SocialLinkChip(
                          label: entry.key,
                          icon: Icons.open_in_new_rounded,
                          onTap: () => _openExternalLink(entry.value),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialLinkChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SocialLinkChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageSettingTile extends StatefulWidget {
  final AppLanguage language;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageSettingTile({
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_LanguageSettingTile> createState() => _LanguageSettingTileState();
}

class _LanguageSettingTileState extends State<_LanguageSettingTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          color: _isHovered && widget.isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : _isHovered
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.language.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: widget.isSelected
                              ? AppColors.primary
                              : AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.language.nativeLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primary,
                    size: 24,
                  )
                else
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
