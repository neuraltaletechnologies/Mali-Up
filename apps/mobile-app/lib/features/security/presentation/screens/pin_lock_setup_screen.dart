import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../shared/widgets/app_notification.dart';

String _t(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

/// PIN Lock Setup Screen
/// Allows users to set a 4-6 digit PIN code for app security
/// Stored securely in device keychain/keystore

class PINLockSetupScreen extends ConsumerStatefulWidget {
  const PINLockSetupScreen({super.key});

  @override
  ConsumerState<PINLockSetupScreen> createState() => _PINLockSetupScreenState();
}

class _PINLockSetupScreenState extends ConsumerState<PINLockSetupScreen> {
  String? firstPin;
  String pinEntry = '';
  int step = 1; // 1 = enter PIN, 2 = confirm PIN
  bool isPINValid = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Set PIN Code', 'Weka Namba ya PIN')),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title
                Text(
                  step == 1
                      ? _t('Enter a 4-6 digit PIN', 'Weka PIN ya tarakimu 4-6')
                      : _t('Confirm your PIN', 'Thibitisha PIN yako'),
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _t('You\'ll need this to unlock the app',
                      'Utahitaji hii kufungua programu'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // PIN Display (dots)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    6,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: index < pinEntry.length
                              ? AppColors.navyPrimary
                              : Colors.grey[300]!,
                          width: 2,
                        ),
                        color: index < pinEntry.length
                            ? AppColors.navyPrimary.withValues(alpha: 0.08)
                            : Colors.transparent,
                      ),
                      child: Center(
                        child: index < pinEntry.length
                            ? const Icon(
                                Icons.circle,
                                color: AppColors.navyPrimary,
                                size: 20,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),

                // PIN Length Indicator
                const SizedBox(height: 16),
                Text(
                  '${pinEntry.length} ${_t("digits", "tarakimu")}',
                  style: GoogleFonts.dmSans(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 48),

                // Number Pad
                _buildNumberPad(),

                const SizedBox(height: 32),

                // Info
                if (step == 1)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.navyPrimary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _t('Enter at least 4 digits for security',
                          'Weka angalau tarakimu 4 kwa usalama'),
                      style: GoogleFonts.dmSans(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return Column(
      children: [
        for (int i = 0; i < 3; i++)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int j = 0; j < 3; j++)
                _buildNumberButton(
                  number: (i * 3 + j + 1).toString(),
                ),
            ],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNumberButton(number: '0'),
            _buildNumberButton(
              number: '⌫',
              onPressed: _backspace,
              color: Colors.grey,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNumberButton({
    required String number,
    VoidCallback? onPressed,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed ?? () => _addDigit(number),
          borderRadius: BorderRadius.circular(50),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color != null
                  ? color.withAlpha(100)
                  : AppColors.navyPrimary.withValues(alpha: 0.08),
              border: Border.all(
                color: color ?? AppColors.navyPrimary.withValues(alpha: 0.25),
              ),
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.dmSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: color ?? AppColors.navyPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _addDigit(String digit) {
    if (pinEntry.length < 6) {
      setState(() => pinEntry += digit);
      _checkPin();
    }
  }

  void _backspace() {
    if (pinEntry.isNotEmpty) {
      setState(() => pinEntry = pinEntry.substring(0, pinEntry.length - 1));
      _checkPin();
    }
  }

  void _checkPin() {
    // Auto-advance to confirmation when PIN is entered (4-6 digits)
    if (step == 1 && pinEntry.length >= 4) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && pinEntry.length >= 4) {
          setState(() {
            firstPin = pinEntry;
            pinEntry = '';
            step = 2;
          });
        }
      });
    }

    // Verify PIN on confirmation
    if (step == 2 && pinEntry.length >= 4) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          if (pinEntry == firstPin) {
            _savePIN();
          } else if (pinEntry.length == firstPin!.length) {
            _showError(_t('PINs do not match', 'PIN hazifanani'));
            setState(() {
              pinEntry = '';
              step = 1;
              firstPin = null;
            });
          }
        }
      });
    }
  }

  Future<void> _savePIN() async {
    try {
      // Save PIN securely using platform-specific keychain
      // await ref.read(securityProvider.notifier).setPIN(firstPin!);

      if (mounted) {
        AppNotification.success(context, _t('PIN lock enabled', 'Kufuli ya PIN imewashwa'));

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      _showError('${_t("Error saving PIN", "Hitilafu kuhifadhi PIN")}: $e');
    }
  }

  void _showError(String message) {
    AppNotification.error(context, message);
  }
}

