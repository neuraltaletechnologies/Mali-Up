import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:timer_count_down/timer_count_down.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/phone_auth_service.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../shared/widgets/shimmer.dart';
import '../../../../shared/widgets/logo.dart';
import '../../../../config/routing.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final bool isRegistration;
  final Map<String, dynamic>? userData;

  const OTPVerificationScreen({
    super.key,
    required this.phoneNumber,
    this.isRegistration = false,
    this.userData,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  bool _isLoading = false;
  bool _isResending = false;
  bool _canResend = false;
  String? _errorMessage;
  String? _successMessage;
  int _resendCountdown = 60;

  late final VoidCallback _languageListener;
  AppLanguage _language = LocalizationService.languageNotifier.value;

  @override
  void initState() {
    super.initState();
    _language = LocalizationService.languageNotifier.value;
    _languageListener = () {
      if (mounted) {
        setState(() => _language = LocalizationService.languageNotifier.value);
      }
    };
    LocalizationService.languageNotifier.addListener(_languageListener);

    // Start OTP sending process
    _sendOTP();
  }

  String _tr(String en, String sw) {
    return _language == AppLanguage.swahili ? sw : en;
  }

  Future<void> _sendOTP() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final result = await PhoneAuthService.sendOTP(
      phoneNumber: widget.phoneNumber,
      onCodeSent: (_) {
        setState(() {
          _isLoading = false;
          _successMessage = _tr(
            'OTP sent to +${widget.phoneNumber}',
            'OTP imetumwa kwenda +${widget.phoneNumber}',
          );
        });
      },
      onError: (error) {
        setState(() {
          _isLoading = false;
          _errorMessage = _getErrorMessage(error);
        });
      },
    );

    if (result != AuthResult.otpSent) {
      setState(() {
        _isLoading = false;
        _errorMessage = _getErrorMessage(result);
      });
    }
  }

  Future<void> _resendOTP() async {
    setState(() {
      _isResending = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final result = await PhoneAuthService.sendOTP(
      phoneNumber: widget.phoneNumber,
      onCodeSent: (_) {
        setState(() {
          _isResending = false;
          _successMessage = _tr('OTP resent successfully', 'OTP imetumwa upya');
          _canResend = false;
          _resendCountdown = 60;
        });
      },
      onError: (error) {
        setState(() {
          _isResending = false;
          _errorMessage = _getErrorMessage(error);
        });
      },
      forceResending: true,
    );

    if (result != AuthResult.otpSent) {
      setState(() {
        _isResending = false;
        _errorMessage = _getErrorMessage(result);
      });
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.length != 6) {
      setState(() {
        _errorMessage = _tr(
          'Please enter the 6-digit code',
          'Tafadhali weka nambari ya tarakimu 6',
        );
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await PhoneAuthService.verifyOTP(
      otp: _otpController.text,
      phoneNumber: widget.phoneNumber,
      userData: widget.isRegistration ? widget.userData : null,
    );

    if (result == AuthResult.success) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _successMessage = _tr(
            'Verification successful!',
            'Uthibitisho umefanikiwa!',
          );
        });

        // Navigate to dashboard after a short delay
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          context.go(AppRouter.dashboardPath);
        }
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = _getErrorMessage(result);
      });
    }
  }

  String _getErrorMessage(AuthResult result) {
    switch (result) {
      case AuthResult.invalidPhone:
        return _tr(
          'Invalid phone number. Please go back and enter a valid number.',
          'Namba ya simu si sahihi. Rudi nyuma na uweke namba sahihi.',
        );
      case AuthResult.otpExpired:
        return _tr(
          'OTP has expired. Please request a new one.',
          'OTP imeshaisha. Tafadhali ota mpya.',
        );
      case AuthResult.otpInvalid:
        return _tr(
          'Invalid OTP. Please try again.',
          'OTP si sahihi. Tafadhali jaribu tena.',
        );
      case AuthResult.networkError:
        return _tr(
          'Network error. Please check your connection.',
          'Hitilafu ya mtandao. Tafadhali angalia muunganisho wako.',
        );
      case AuthResult.tooManyRequests:
        return _tr(
          'Too many requests. Please try again later.',
          'Maombi mengi sana. Tafadhali jaribu baadaye.',
        );
      case AuthResult.userNotFound:
        return _tr(
          'Account not found. Please register first.',
          'Akaunti haijapatikana. Tafadhali sajili kwanza.',
        );
      default:
        return _tr(
          'An error occurred. Please try again.',
          'Hitilafu imetokea. Tafadhali jaribu tena.',
        );
    }
  }

  @override
  void dispose() {
    LocalizationService.languageNotifier.removeListener(_languageListener);
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const textPrimary = Color(0xFF1A1A1A);
    const textSecondary = Color(0xFF6B7280);
    const fieldBg = Color(0xFFEFF5F2);
    final mediaQuery = MediaQuery.of(context);
    final topHeight = mediaQuery.size.height * 0.25;

    const headingStyle = TextStyle(
      fontSize: 30,
      color: textPrimary,
      fontWeight: FontWeight.w700,
      height: 1.15,
    );

    const subtitleStyle = TextStyle(
      color: textSecondary,
      fontSize: 14,
      height: 1.45,
      fontWeight: FontWeight.w400,
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: topHeight,
            child: const SizedBox.expand(),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Material(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lock_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _tr('Secure', 'Salama'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.72,
            minChildSize: 0.72,
            maxChildSize: 0.96,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    24,
                    20,
                    24,
                    MediaQuery.of(context).viewInsets.bottom + 80,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(child: MaliUpLogo(size: 54)),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          _tr('Verify Your Phone', 'Thibitisha Simu Yako'),
                          textAlign: TextAlign.center,
                          style: headingStyle,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          _tr(
                            'Enter the 6-digit code sent to',
                            'Weka nambari ya tarakimu 6 iliyotumwa kwenda',
                          ),
                          textAlign: TextAlign.center,
                          style: subtitleStyle,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text(
                          '+${widget.phoneNumber}',
                          textAlign: TextAlign.center,
                          style: subtitleStyle.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            size: 16,
                            color: textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _tr(
                                'Your verification code is secure and private.',
                                'Nambari yako ya uthibitisho ni salama na ya faragha.',
                              ),
                              style: const TextStyle(
                                color: textSecondary,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_successMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _successMessage!,
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                      Center(
                        child: PinCodeTextField(
                          appContext: context,
                          length: 6,
                          animationType: AnimationType.fade,
                          pinTheme: PinTheme(
                            shape: PinCodeFieldShape.circle,
                            fieldHeight: 52,
                            fieldWidth: 52,
                            activeFillColor: fieldBg,
                            selectedFillColor: fieldBg,
                            inactiveFillColor: fieldBg,
                            activeColor: AppColors.primary,
                            selectedColor: AppColors.primary,
                            inactiveColor: AppColors.border,
                            borderWidth: 1,
                          ),
                          animationDuration: const Duration(milliseconds: 300),
                          enableActiveFill: true,
                          controller: _otpController,
                          focusNode: _otpFocusNode,
                          onCompleted: (value) {
                            _verifyOTP();
                          },
                          onChanged: (value) {
                            setState(() {
                              _errorMessage = null;
                              _successMessage = null;
                            });
                          },
                          beforeTextPaste: (text) {
                            return false; // Disable paste
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isLoading ? null : _verifyOTP,
                          child: _isLoading
                              ? const ShimmerBox(
                                  width: 120,
                                  height: 16,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(999),
                                  ),
                                )
                              : Text(_tr('Verify Code', 'Thibitisha Nambari')),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              _tr(
                                'Didn\'t receive the code?',
                                'Hujapokea nambari?',
                              ),
                              style: const TextStyle(color: textSecondary),
                            ),
                            const SizedBox(height: 8),
                            if (_resendCountdown > 0)
                              Countdown(
                                seconds: _resendCountdown,
                                build: (BuildContext context, double time) =>
                                    Text(
                                      _tr(
                                        'Resend in ${time.toInt()}s',
                                        'Tuma upya ${time.toInt()}s',
                                      ),
                                      style: const TextStyle(
                                        color: textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                onFinished: () {
                                  setState(() {
                                    _canResend = true;
                                  });
                                },
                              )
                            else
                              TextButton(
                                onPressed: (_isResending || !_canResend)
                                    ? null
                                    : _resendOTP,
                                child: _isResending
                                    ? const ShimmerBox(
                                        width: 96,
                                        height: 14,
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(999),
                                        ),
                                      )
                                    : Text(
                                        _tr('Resend Code', 'Tuma Nambari Upya'),
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                          ],
                        ),
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
