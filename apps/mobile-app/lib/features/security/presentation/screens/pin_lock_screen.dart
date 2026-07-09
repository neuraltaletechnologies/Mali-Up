import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/services/security_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class PinLockScreen extends StatefulWidget {
  const PinLockScreen({super.key});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen>
    with SingleTickerProviderStateMixin {
  final List<String> _digits = ['', '', '', ''];
  int _currentIndex = 0;
  bool _hasError = false;
  bool _isBiometricAvailable = false;
  Duration? _lockoutRemaining;
  Timer? _lockoutTimer;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    _checkBiometricAvailability();
    _refreshLockoutState();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _lockoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshLockoutState() async {
    final remaining = await SecurityService.pinLockoutRemaining();
    if (!mounted) return;
    setState(() => _lockoutRemaining = remaining);
    _lockoutTimer?.cancel();
    if (remaining != null) {
      _lockoutTimer = Timer(const Duration(seconds: 1), _refreshLockoutState);
    }
  }

  Future<void> _checkBiometricAvailability() async {
    if (!SecurityService.biometricEnabledNotifier.value) return;
    final available = await SecurityService.canUseBiometrics();
    if (mounted) setState(() => _isBiometricAvailable = available);
    if (available) {
      await Future.delayed(const Duration(milliseconds: 300));
      _tryBiometric();
    }
  }

  Future<void> _tryBiometric() async {
    final authenticated = await SecurityService.authenticateWithBiometrics(
      reason: _tr(
        'Authenticate to unlock Mali Up',
        'Thibitisha kufungua Mali Up',
      ),
    );
    if (authenticated && mounted) {
      _unlock();
    }
  }

  void _enterDigit(String digit) {
    if (_currentIndex >= 4 || _lockoutRemaining != null) return;
    HapticFeedback.lightImpact();
    setState(() {
      _digits[_currentIndex] = digit;
      _currentIndex++;
      _hasError = false;
    });
    if (_currentIndex == 4) {
      _verifyPin();
    }
  }

  void _deleteDigit() {
    if (_currentIndex == 0) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentIndex--;
      _digits[_currentIndex] = '';
      _hasError = false;
    });
  }

  Future<void> _verifyPin() async {
    final pin = _digits.join();
    final correct = await SecurityService.verifyPin(pin);
    if (!mounted) return;
    if (correct) {
      _unlock();
    } else {
      HapticFeedback.vibrate();
      _shakeController.forward(from: 0);
      setState(() {
        _hasError = true;
        _digits.fillRange(0, 4, '');
        _currentIndex = 0;
      });
      await _refreshLockoutState();
    }
  }

  String _formatLockout(Duration d) {
    if (d.inMinutes >= 1) {
      final mins = d.inSeconds / 60;
      return _tr(
        'Try again in ${mins.ceil()} min',
        'Jaribu tena baada ya dakika ${mins.ceil()}',
      );
    }
    return _tr(
      'Try again in ${d.inSeconds}s',
      'Jaribu tena baada ya sekunde ${d.inSeconds}',
    );
  }

  void _unlock() {
    SecurityService.unlockApp();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.statusBarLightIcons,
      child: Scaffold(
        backgroundColor: AppColors.navyPrimary,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 48),
              // ── Branding ─────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppColors.yellowBrand,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        'M',
                        style: GoogleFonts.dmSans(
                          color: AppColors.navyPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'MALI UP',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 40),
              Text(
                _tr('Enter PIN to continue', 'Ingiza PIN kuendelea'),
                style: GoogleFonts.dmSans(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),

              // ── PIN dots ──────────────────────────────────────────
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  final dx = _hasError
                      ? 12 * (0.5 - _shakeAnimation.value).abs() * 2
                      : 0.0;
                  return Transform.translate(
                    offset: Offset(dx, 0),
                    child: child,
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    final filled = _digits[i].isNotEmpty;
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
                            ? AppColors.yellowBrand
                            : Colors.transparent,
                        border: Border.all(
                          color: _hasError
                              ? AppColors.error
                              : filled
                              ? AppColors.yellowBrand
                              : Colors.white.withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                    );
                  }),
                ),
              ),

              if (_hasError && _lockoutRemaining == null) ...[
                SizedBox(height: 12),
                Text(
                  _tr(
                    'Incorrect PIN. Try again.',
                    'PIN si sahihi. Jaribu tena.',
                  ),
                  style: GoogleFonts.dmSans(
                    color: AppColors.error,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (_lockoutRemaining != null) ...[
                SizedBox(height: 12),
                Text(
                  _tr(
                    'Too many attempts. ${_formatLockout(_lockoutRemaining!)}',
                    'Majaribio mengi sana. ${_formatLockout(_lockoutRemaining!)}',
                  ),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    color: AppColors.error,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],

              const Spacer(),

              // ── Numpad ────────────────────────────────────────────
              IgnorePointer(
                ignoring: _lockoutRemaining != null,
                child: Opacity(
                  opacity: _lockoutRemaining != null ? 0.4 : 1.0,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.12,
                    ),
                    child: Column(
                      children: [
                        _buildNumRow(['1', '2', '3']),
                        const SizedBox(height: 16),
                        _buildNumRow(['4', '5', '6']),
                        const SizedBox(height: 16),
                        _buildNumRow(['7', '8', '9']),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Biometric button or empty spacer
                            if (_isBiometricAvailable)
                              _NumpadKey(
                                onTap: _tryBiometric,
                                child: const Icon(
                                  Icons.fingerprint_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              )
                            else
                              SizedBox(width: 72, height: 72),
                            _NumpadKey(
                              onTap: () => _enterDigit('0'),
                              child: Text(
                                '0',
                                style: GoogleFonts.dmSans(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            _NumpadKey(
                              onTap: _deleteDigit,
                              child: const Icon(
                                Icons.backspace_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Row _buildNumRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: digits
          .map(
            (d) => _NumpadKey(
              onTap: () => _enterDigit(d),
              child: Text(
                d,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _NumpadKey extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _NumpadKey({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        splashColor: AppColors.yellowBrand.withValues(alpha: 0.2),
        child: SizedBox(width: 72, height: 72, child: Center(child: child)),
      ),
    );
  }
}
