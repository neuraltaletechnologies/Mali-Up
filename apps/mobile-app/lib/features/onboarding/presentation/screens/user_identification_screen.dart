import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/emotional_design.dart';
import '../widgets/animated_widgets.dart';

class UserIdentificationScreen extends StatefulWidget {
  const UserIdentificationScreen({super.key});

  @override
  State<UserIdentificationScreen> createState() => _UserIdentificationScreenState();
}

class _UserIdentificationScreenState extends State<UserIdentificationScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  late final AnimationController _entranceController;
  late final Animation<double> _heroFade;
  late final Animation<Offset> _heroSlide;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _heroFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
      ),
    );
    _cardFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.22, 1.0, curve: Curves.easeOut),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.22, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String _normalizeLocalPhone(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('255') && digits.length >= 12) {
      return digits.substring(3);
    }
    if (digits.startsWith('0') && digits.length >= 10) {
      return digits.substring(1);
    }
    return digits;
  }

  String _toE164Tz(String input) {
    final local = _normalizeLocalPhone(input);
    return '+255$local';
  }

  Future<bool> _existsViaServerCallable({
    required String localPhone,
    required String e164Phone,
    required String email,
  }) async {
    final callable = _functions.httpsCallable('checkUserExists');
    final result = await callable.call({
      'phone': localPhone,
      'e164Phone': e164Phone,
      if (email.isNotEmpty) 'email': email,
    });

    final data = result.data;
    if (data is Map) {
      final exists = data['exists'];
      if (exists is bool) {
        return exists;
      }
      final userExists = data['userExists'];
      if (userExists is bool) {
        return userExists;
      }
    }

    return false;
  }

  Future<void> _continue() async {
    final name = _nameController.text.trim();
    final localPhone = _normalizeLocalPhone(_phoneController.text);
    final email = _emailController.text.trim().toLowerCase();

    if (name.isEmpty) {
      _showSnack('Oops!! you forgot your full name', isError: true);
      return;
    }

    if (localPhone.length != 9) {
      _showSnack('Enter a valid 9-digit phone number', isError: true);
      return;
    }

    if (email.isNotEmpty && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _showSnack('Please enter a valid email address', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final e164Phone = _toE164Tz(localPhone);
      final exists = await _existsViaServerCallable(
        localPhone: localPhone,
        e164Phone: e164Phone,
        email: email,
      );

      if (!mounted) {
        return;
      }

      if (exists) {
        _showSnack('Welcome back 👋 Continue where you left off');
        context.go(
          AppRouter.loginPath,
          extra: {
            'phone': localPhone,
            'autoSendOtp': true,
          },
        );
      } else {
        _showSnack("No account found. Let's create one for you");
        context.go(
          AppRouter.registerPath,
          extra: {
            'fullName': name,
            'phone': localPhone,
            if (email.isNotEmpty) 'email': email,
          },
        );
      }
    } on FirebaseFunctionsException catch (e) {
      _showSnack(
        e.message ?? 'Identity service is unavailable. Please try again.',
        isError: true,
      );
    } catch (_) {
      _showSnack('Something went wrong. Please try again.', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red.shade600 : AppColors.secondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const AmbientEmotionBackground(
            palette: [
              AppColors.primary,
              AppColors.secondaryLight,
              AppColors.info,
            ],
            intensity: 0.84,
          ),
          Positioned(
            top: -50,
            left: -30,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.24),
                    AppColors.primary.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 56,
            right: 22,
            child: const AnimatedFloatingIcon(
              icon: Icons.currency_exchange_rounded,
              color: AppColors.success,
              size: 24,
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    children: [
                      FadeTransition(
                        opacity: _heroFade,
                        child: SlideTransition(
                          position: _heroSlide,
                          child: Column(
                            children: [
                              const PulsingGlowWidget(
                                glowColor: AppColors.primary,
                                child: EmotionalCompanion(
                                  mood: CompanionMood.focused,
                                  size: 88,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                children: const [
                                  _InsightChip(icon: Icons.verified_user_rounded, label: 'Secure'),
                                  _InsightChip(icon: Icons.flash_on_rounded, label: 'Fast'),
                                  _InsightChip(icon: Icons.auto_awesome_rounded, label: 'Personalized'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FadeTransition(
                        opacity: _cardFade,
                        child: SlideTransition(
                          position: _cardSlide,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: AppColors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.secondary.withValues(alpha: 0.1),
                                  blurRadius: 30,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tell us about yourself',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.secondary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'We will detect your profile in seconds and route you to the right flow.',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: AppColors.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 22),
                                const _FieldLabel('Full Name'),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _nameController,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. Amina Mushi',
                                    prefixIcon: Icon(Icons.person_rounded),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const _FieldLabel('Phone Number'),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    hintText: '7xx xxx xxx',
                                    prefixIcon: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 16),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('🇹🇿', style: TextStyle(fontSize: 18)),
                                          SizedBox(width: 8),
                                          Text(
                                            '+255',
                                            style: TextStyle(
                                              color: AppColors.secondary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const _FieldLabel('Email (Optional)'),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.done,
                                  decoration: const InputDecoration(
                                    hintText: 'you@example.com',
                                    prefixIcon: Icon(Icons.alternate_email_rounded),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'We use this to personalize your workspace and speed up sign-in.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                EmotionalTapScale(
                                  enabled: !_isLoading,
                                  hapticStyle: TapHapticStyle.medium,
                                  onTap: _isLoading ? null : _continue,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 240),
                                    width: double.infinity,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          AppColors.secondary,
                                          AppColors.primary,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.secondary.withValues(alpha: 0.28),
                                          blurRadius: _isLoading ? 8 : 16,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.4,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Continue',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                Icon(Icons.arrow_forward_rounded, color: Colors.white),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        color: AppColors.secondary,
      ),
    );
  }
}

class _InsightChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InsightChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.secondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
