import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/services/security_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/mali_components.dart';

/// Shows as a modal bottom sheet.
/// Returns `true` if the PIN was set and App Lock was enabled.
Future<bool> showPinSetupSheet(BuildContext context) async {
  final result = await showAppSheet<bool>(
    context,
    builder: (_) => const _PinSetupSheet(),
  );
  return result == true;
}

class _PinSetupSheet extends StatefulWidget {
  const _PinSetupSheet();

  @override
  State<_PinSetupSheet> createState() => _PinSetupSheetState();
}

class _PinSetupSheetState extends State<_PinSetupSheet> {
  // 0 = enter new PIN, 1 = confirm PIN
  int _step = 0;
  final List<String> _pin = ['', '', '', ''];
  final List<String> _confirm = ['', '', '', ''];
  int _currentIndex = 0;
  bool _hasError = false;
  String _errorMessage = '';

  String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

  List<String> get _activeDigits => _step == 0 ? _pin : _confirm;

  void _enterDigit(String digit) {
    if (_currentIndex >= 4) return;
    HapticFeedback.lightImpact();
    setState(() {
      _activeDigits[_currentIndex] = digit;
      _currentIndex++;
      _hasError = false;
    });
    if (_currentIndex == 4) {
      _onComplete();
    }
  }

  void _deleteDigit() {
    if (_currentIndex == 0) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentIndex--;
      _activeDigits[_currentIndex] = '';
      _hasError = false;
    });
  }

  Future<void> _onComplete() async {
    if (_step == 0) {
      // Move to confirmation step
      setState(() {
        _step = 1;
        _currentIndex = 0;
        _hasError = false;
      });
    } else {
      // Confirm step — compare PINs
      final pin = _pin.join();
      final confirmed = _confirm.join();
      if (pin == confirmed) {
        await SecurityService.enableAppLock(pin);
        if (mounted) Navigator.of(context).pop(true);
      } else {
        HapticFeedback.vibrate();
        setState(() {
          _hasError = true;
          _errorMessage = _tr(
            'PINs do not match. Try again.',
            'PINs hazilingani. Jaribu tena.',
          );
          _confirm.fillRange(0, 4, '');
          _currentIndex = 0;
        });
      }
    }
  }

  void _goBack() {
    if (_step == 1) {
      setState(() {
        _step = 0;
        _currentIndex = 0;
        _pin.fillRange(0, 4, '');
        _confirm.fillRange(0, 4, '');
        _hasError = false;
      });
    } else {
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return Container(
      height: mediaQuery.size.height * 0.88,
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SheetHandle(),
          const SizedBox(height: 8),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                if (_step == 1)
                  IconButton(
                    onPressed: _goBack,
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: AppColors.secondary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                if (_step == 1) const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _step == 0
                            ? _tr('Create a PIN', 'Tengeneza PIN')
                            : _tr('Confirm your PIN', 'Thibitisha PIN yako'),
                        style: GoogleFonts.dmSans(
                          color: AppColors.secondary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _step == 0
                            ? _tr(
                                'Choose a 4-digit PIN to lock the app.',
                                'Chagua PIN ya tarakimu 4 kufunga programu.',
                              )
                            : _tr(
                                'Enter the same PIN again to confirm.',
                                'Ingiza PIN ile ile tena kuthibitisha.',
                              ),
                        style: GoogleFonts.dmSans(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_step == 0)
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textMuted),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 36),

          // PIN dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final filled = _activeDigits[i].isNotEmpty;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _hasError
                      ? AppColors.error
                      : filled
                          ? AppColors.secondary
                          : Colors.transparent,
                  border: Border.all(
                    color: _hasError
                        ? AppColors.error
                        : filled
                            ? AppColors.secondary
                            : AppColors.border,
                    width: 2,
                  ),
                ),
              );
            }),
          ),

          if (_hasError) ...[
            const SizedBox(height: 10),
            Text(
              _errorMessage,
              style: GoogleFonts.dmSans(
                color: AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          // Step indicator
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(2, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == _step ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color:
                      i == _step ? AppColors.secondary : AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              );
            }),
          ),

          const Spacer(),

          // Numpad
          _PinNumpad(
            onDigit: _enterDigit,
            onDelete: _deleteDigit,
          ),
          SizedBox(height: mediaQuery.padding.bottom + 16),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Shows as a modal bottom sheet.
/// Returns `true` if the PIN was changed successfully.
Future<bool> showPinChangeSheet(BuildContext context) async {
  final result = await showAppSheet<bool>(
    context,
    builder: (_) => const _PinChangeSheet(),
  );
  return result == true;
}

class _PinChangeSheet extends StatefulWidget {
  const _PinChangeSheet();

  @override
  State<_PinChangeSheet> createState() => _PinChangeSheetState();
}

class _PinChangeSheetState extends State<_PinChangeSheet> {
  // 0 = current PIN, 1 = new PIN, 2 = confirm new PIN
  int _step = 0;
  final List<String> _current = ['', '', '', ''];
  final List<String> _newPin = ['', '', '', ''];
  final List<String> _confirm = ['', '', '', ''];
  int _currentIndex = 0;
  bool _hasError = false;
  String _errorMessage = '';

  String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

  List<String> get _activeDigits {
    if (_step == 0) return _current;
    if (_step == 1) return _newPin;
    return _confirm;
  }

  void _enterDigit(String digit) {
    if (_currentIndex >= 4) return;
    HapticFeedback.lightImpact();
    setState(() {
      _activeDigits[_currentIndex] = digit;
      _currentIndex++;
      _hasError = false;
    });
    if (_currentIndex == 4) {
      _onComplete();
    }
  }

  void _deleteDigit() {
    if (_currentIndex == 0) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentIndex--;
      _activeDigits[_currentIndex] = '';
      _hasError = false;
    });
  }

  Future<void> _onComplete() async {
    if (_step == 0) {
      final correct = await SecurityService.verifyPin(_current.join());
      if (!mounted) return;
      if (correct) {
        setState(() {
          _step = 1;
          _currentIndex = 0;
          _hasError = false;
        });
      } else {
        HapticFeedback.vibrate();
        setState(() {
          _hasError = true;
          _errorMessage =
              _tr('Incorrect PIN. Try again.', 'PIN si sahihi. Jaribu tena.');
          _current.fillRange(0, 4, '');
          _currentIndex = 0;
        });
      }
    } else if (_step == 1) {
      setState(() {
        _step = 2;
        _currentIndex = 0;
        _hasError = false;
      });
    } else {
      final newPin = _newPin.join();
      final confirmed = _confirm.join();
      if (newPin == confirmed) {
        await SecurityService.setPin(newPin);
        if (mounted) Navigator.of(context).pop(true);
      } else {
        HapticFeedback.vibrate();
        setState(() {
          _hasError = true;
          _errorMessage = _tr(
            'PINs do not match. Try again.',
            'PINs hazilingani. Jaribu tena.',
          );
          _confirm.fillRange(0, 4, '');
          _currentIndex = 0;
        });
      }
    }
  }

  void _goBack() {
    if (_step > 0) {
      setState(() {
        _step--;
        _currentIndex = 0;
        _activeDigits.fillRange(0, 4, '');
        _hasError = false;
      });
    } else {
      Navigator.of(context).pop(false);
    }
  }

  static const _titles = [
    ['Enter your current PIN', 'Ingiza PIN yako ya sasa'],
    ['Enter your new PIN', 'Ingiza PIN yako mpya'],
    ['Confirm your new PIN', 'Thibitisha PIN yako mpya'],
  ];

  static const _subtitles = [
    [
      'Verify your identity before changing.',
      'Thibitisha utambulisho wako kabla ya kubadilisha.',
    ],
    ['Choose a 4-digit PIN.', 'Chagua PIN ya tarakimu 4.'],
    ['Enter the same PIN again.', 'Ingiza PIN ile ile tena.'],
  ];

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return Container(
      height: mediaQuery.size.height * 0.88,
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                IconButton(
                  onPressed: _goBack,
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: AppColors.secondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tr(_titles[_step][0], _titles[_step][1]),
                        style: GoogleFonts.dmSans(
                          color: AppColors.secondary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _tr(_subtitles[_step][0], _subtitles[_step][1]),
                        style: GoogleFonts.dmSans(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),

          // PIN dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final filled = _activeDigits[i].isNotEmpty;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _hasError
                      ? AppColors.error
                      : filled
                          ? AppColors.secondary
                          : Colors.transparent,
                  border: Border.all(
                    color: _hasError
                        ? AppColors.error
                        : filled
                            ? AppColors.secondary
                            : AppColors.border,
                    width: 2,
                  ),
                ),
              );
            }),
          ),

          if (_hasError) ...[
            const SizedBox(height: 10),
            Text(
              _errorMessage,
              style: GoogleFonts.dmSans(
                color: AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == _step ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _step ? AppColors.secondary : AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              );
            }),
          ),

          const Spacer(),

          _PinNumpad(onDigit: _enterDigit, onDelete: _deleteDigit),
          SizedBox(height: mediaQuery.padding.bottom + 16),
        ],
      ),
    );
  }
}

// ── Shared numpad ─────────────────────────────────────────────────────────────

class _PinNumpad extends StatelessWidget {
  final void Function(String digit) onDigit;
  final VoidCallback onDelete;

  const _PinNumpad({required this.onDigit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.1),
      child: Column(
        children: [
          _buildRow(['1', '2', '3']),
          const SizedBox(height: 12),
          _buildRow(['4', '5', '6']),
          const SizedBox(height: 12),
          _buildRow(['7', '8', '9']),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 72, height: 56),
              _key('0'),
              SizedBox(
                width: 72,
                height: 56,
                child: TextButton(
                  onPressed: onDelete,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.backspace_outlined,
                      color: AppColors.secondary, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Row _buildRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: digits.map(_key).toList(),
    );
  }

  Widget _key(String digit) {
    return Builder(
      builder: (context) => SizedBox(
        width: 72,
        height: 56,
        child: TextButton(
          onPressed: () => onDigit(digit),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.secondary,
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border),
            ),
          ),
          child: Text(
            digit,
            style: GoogleFonts.dmSans(
              color: AppColors.secondary,
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
