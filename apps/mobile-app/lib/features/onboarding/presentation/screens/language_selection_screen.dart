import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../shared/widgets/logo.dart';

class LanguageSelectionScreen extends StatefulWidget {
  final VoidCallback onLanguageSelected;

  const LanguageSelectionScreen({
    super.key,
    required this.onLanguageSelected,
  });

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  late final VoidCallback _languageListener;
  AppLanguage _language = LocalizationService.languageNotifier.value;
  bool _isSelecting = false;

  @override
  void initState() {
    super.initState();
    _languageListener = () {
      if (mounted) {
        setState(() => _language = LocalizationService.languageNotifier.value);
      }
    };
    LocalizationService.languageNotifier.addListener(_languageListener);
  }

  @override
  void dispose() {
    LocalizationService.languageNotifier.removeListener(_languageListener);
    super.dispose();
  }

  String _tr(String en, String sw) {
    return _language == AppLanguage.swahili ? sw : en;
  }

  Future<void> _selectLanguage(AppLanguage language) async {
    if (_isSelecting) return;
    setState(() => _isSelecting = true);
    try {
      await LocalizationService.setLanguage(language);
      if (!mounted) return;
      widget.onLanguageSelected();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSelecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const textPrimary = Color(0xFF1A1A1A);
    const textSecondary = Color(0xFF6B7280);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: MediaQuery.of(context).size.height * 0.34,
            child: Container(
              color: AppColors.primary,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                     
                      const Spacer(),
                      Text(
                        _tr('Choose your language', 'Chagua lugha'),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _tr(
                          'You can change this later in Settings.',
                          'Unaweza kubadilisha baadaye kwenye Mipangilio.',
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.92),
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.70,
            minChildSize: 0.70,
            maxChildSize: 0.92,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 46,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppColors.border.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _tr('Language', 'Lugha'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _tr(
                          'Select the language you prefer.',
                          'Chagua lugha unayoipendelea.',
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: textSecondary,
                              height: 1.45,
                            ),
                      ),
                      const SizedBox(height: 18),
                      _PremiumLanguageTile(
                        title: 'English',
                        subtitle: 'Continue in English',
                        selected: LocalizationService.languageNotifier.value == AppLanguage.english,
                        loading: _isSelecting,
                        onTap: () => _selectLanguage(AppLanguage.english),
                      ),
                      const SizedBox(height: 12),
                      _PremiumLanguageTile(
                        title: 'Kiswahili',
                        subtitle: 'Endelea kwa Kiswahili',
                        selected: LocalizationService.languageNotifier.value == AppLanguage.swahili,
                        loading: _isSelecting,
                        onTap: () => _selectLanguage(AppLanguage.swahili),
                      ),
                    ],
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

class _PremiumLanguageTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final bool loading;
  final VoidCallback onTap;

  const _PremiumLanguageTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? AppColors.primary : AppColors.border;
    final bg = selected
        ? AppColors.primary.withValues(alpha: 0.10)
        : Colors.white;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: loading ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: selected ? 1.6 : 1.0),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF111111),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF6B7280),
                            height: 1.35,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (loading)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                )
              else
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? const Center(
                          child: SizedBox(
                            width: 10,
                            height: 10,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
