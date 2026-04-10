import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/services/motion_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/emotional_design.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final VoidCallback _languageListener;
  late final VoidCallback _motionListener;
  AppLanguage _selectedLanguage = LocalizationService.languageNotifier.value;
  bool _reducedMotionEnabled = MotionService.reducedMotionNotifier.value;
  bool _isLoadingLanguage = false;

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
    await LocalizationService.setLanguage(language);
    if (!mounted) return;
    setState(() {
      _selectedLanguage = language;
      _isLoadingLanguage = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Language changed to ${language.label}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _toggleReducedMotion(bool enabled) async {
    await MotionService.setReducedMotionEnabled(enabled);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(enabled ? 'Reduced motion enabled' : 'Reduced motion disabled'),
        duration: const Duration(seconds: 2),
      ),
    );
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
                        'Tune your workspace',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Customize language and motion preferences for a smoother experience.',
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
              'Language',
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
                      child: CircularProgressIndicator(),
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
              'Accessibility',
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
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reduced Motion',
                          style: TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Simplify animations, reduce motion, and keep the interface calm.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _reducedMotionEnabled,
                    onChanged: _toggleReducedMotion,
                    activeThumbColor: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'About',
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
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'App Version',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '1.0.0',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Divider(color: AppColors.border),
                  SizedBox(height: 12),
                  Text(
                    'Terms & Conditions',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  SizedBox(height: 12),
                  Divider(color: AppColors.border),
                  SizedBox(height: 12),
                  Text(
                    'Privacy Policy',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
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
                          color: widget.isSelected ? AppColors.primary : AppColors.secondary,
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
                      border: Border.all(
                        color: AppColors.border,
                        width: 2,
                      ),
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
