import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/logo.dart';
import '../../../../config/routing.dart';
import '../models/account_type.dart';
import '../widgets/account_type_switcher.dart';
import '../widgets/terms_and_conditions.dart';
import '../widgets/privacy_policy.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Re-using the notification helper from the login screen for consistency
class _NotificationHelper {
  static Future<void> showSuccess(BuildContext context, String message) async {
    _showNotification(context, message, AppColors.success, Icons.check_circle_outline_rounded);
  }

  static Future<void> showError(BuildContext context, String message) async {
    _showNotification(context, message, AppColors.error, Icons.error_outline_rounded);
  }

  static void _showNotification(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _customerPhoneWithCountryCode = '255653520829';
  AccountType _selectedAccountType = AccountType.business;
  
  bool _otpSent = false;
  bool _isLoading = false;
  bool _agreedToTerms = false;
  String? _verificationId;
  String _businessCategory = 'Retail';
  
  // Controllers
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _profileNameController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(4, (_) => TextEditingController());
  
  final List<String> _businessCategories = [
    'Retail', 'Wholesale', 'Manufacturing', 'Services', 'Agriculture', 
    'Technology', 'Healthcare', 'Education', 'Food & Beverage', 
    'Transportation', 'Other',
  ];

  Future<void> _sendRegistrationOTP() async {
    if (!_validateInputs()) return;

    setState(() => _isLoading = true);
    final phone = '+255${_phoneController.text.trim()}';
    
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _completeRegistration(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() => _isLoading = false);
        _NotificationHelper.showError(context, e.message ?? 'An unknown error occurred.');
      },
      codeSent: (String vid, int? resendToken) {
        setState(() {
          _verificationId = vid;
          _otpSent = true;
          _isLoading = false;
        });
        _NotificationHelper.showSuccess(context, 'Code sent to $phone');
      },
      codeAutoRetrievalTimeout: (vid) => _verificationId = vid,
    );
  }

  bool _validateInputs() {
    if (_selectedAccountType == AccountType.business) {
      if (_ownerNameController.text.trim().isEmpty) {
        _NotificationHelper.showError(context, 'Please enter the owner\'s full name');
        return false;
      }
      if (_businessNameController.text.trim().isEmpty) {
        _NotificationHelper.showError(context, 'Please enter the business name');
        return false;
      }
    } else {
      if (_profileNameController.text.trim().isEmpty) {
        _NotificationHelper.showError(context, 'Please enter your full name');
        return false;
      }
    }

    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length != 9) {
      _NotificationHelper.showError(context, 'Phone number must be 9 digits');
      return false;
    }

    final recoveryEmail = _emailController.text.trim();
    if (recoveryEmail.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(recoveryEmail)) {
      _NotificationHelper.showError(context, 'Please enter a valid recovery email');
      return false;
    }
    return true;
  }

  Future<void> _verifyAndRegister() async {
    setState(() => _isLoading = true);
    final smsCode = _otpControllers.map((c) => c.text).join();
    if (smsCode.length != 4) {
      setState(() => _isLoading = false);
      _NotificationHelper.showError(context, 'Please enter all 4 digits of the OTP');
      return;
    }
    final credential = PhoneAuthProvider.credential(verificationId: _verificationId!, smsCode: smsCode);
    await _completeRegistration(credential);
  }

  Future<void> _completeRegistration(AuthCredential credential) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      
      if (user != null) {
        final recoveryEmail = _emailController.text.trim().toLowerCase();
        final displayName = _selectedAccountType == AccountType.business
            ? _ownerNameController.text.trim()
            : _profileNameController.text.trim();

        await _firestore.collection('users').doc(user.uid).set({
          'phone': user.phoneNumber,
          'displayName': displayName,
          'defaultAccountType': _selectedAccountType.value,
          'accountTypes': FieldValue.arrayUnion([_selectedAccountType.value]),
          if (recoveryEmail.isNotEmpty) 'recoveryEmail': recoveryEmail,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (_selectedAccountType == AccountType.business) {
          await _firestore.collection('tenants').doc(user.uid).set({
            'businessName': _businessNameController.text.trim(),
            'businessCategory': _businessCategory,
            'ownerName': _ownerNameController.text.trim(),
            'ownerPhone': user.phoneNumber,
            'ownerUid': user.uid,
            'accountType': AccountType.business.value,
            if (recoveryEmail.isNotEmpty) 'ownerEmail': recoveryEmail,
            'createdAt': FieldValue.serverTimestamp(),
            'plan': 'Trial',
          }, SetOptions(merge: true));
        } else {
          await _firestore.collection('personal_accounts').doc(user.uid).set({
            'fullName': _profileNameController.text.trim(),
            'phone': user.phoneNumber,
            'ownerUid': user.uid,
            'accountType': AccountType.personal.value,
            if (recoveryEmail.isNotEmpty) 'recoveryEmail': recoveryEmail,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
        
        if (mounted) context.go(AppRouter.dashboardPath);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _NotificationHelper.showError(context, 'Registration failed. Please try again.');
    }
  }

  void _onAccountTypeChanged(AccountType accountType) {
    setState(() {
      _selectedAccountType = accountType;
      _otpSent = false;
    });
  }

  void _useCustomerPhone() {
    const localPhone = '653520829';
    setState(() {
      _phoneController.text = localPhone;
      _otpSent = false;
    });
    _NotificationHelper.showInfo(context, 'Customer number loaded: +$_customerPhoneWithCountryCode');
  }

  @override
  void dispose() {
    _profileNameController.dispose();
    _ownerNameController.dispose();
    _businessNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.secondary),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Use customer number +$_customerPhoneWithCountryCode',
            onPressed: _useCustomerPhone,
            icon: const Icon(Icons.support_agent_rounded, color: AppColors.secondary),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: MaliUpLogo(size: 60)),
              const SizedBox(height: 32),

              Text(
                _otpSent ? 'Verify Your Phone' : 'Create an Account',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.secondary),
              ),
              const SizedBox(height: 12),
              Text(
                _otpSent
                    ? 'Enter the code sent to +255${_phoneController.text}'
                    : 'Join Mali Up to simplify your finances.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 24),
              
              AccountTypeSwitcher(
                selectedType: _selectedAccountType,
                onChanged: _onAccountTypeChanged,
              ),
              const SizedBox(height: 32),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isLoading
                    ? const Center(key: ValueKey('loader'), child: CircularProgressIndicator())
                    : _otpSent
                        ? _buildOtpForm(key: const ValueKey('otpForm'))
                        : _buildRegistrationForm(key: const ValueKey('regForm')),
              ),

              const SizedBox(height: 32),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrationForm({required Key key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _selectedAccountType == AccountType.business
              ? _buildBusinessForm(key: const ValueKey('business'))
              : _buildPersonalForm(key: const ValueKey('personal')),
        ),
        const SizedBox(height: 24),
        _buildTermsAndConditions(),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _agreedToTerms ? _sendRegistrationOTP : null,
          child: const Text('Create Account'),
        ),
      ],
    );
  }

  Widget _buildBusinessForm({required Key key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('Business Owner Details'),
        TextField(
          controller: _ownerNameController,
          decoration: const InputDecoration(hintText: 'Full Name', prefixIcon: Icon(Icons.person_outline_rounded)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: '7xx xxx xxx',
            prefixIcon: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('🇹🇿', style: TextStyle(fontSize: 24)),
                SizedBox(width: 8),
                Text('+255', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 16)),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: 'Recovery Email (Optional)', prefixIcon: Icon(Icons.alternate_email_rounded)),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('Business Details'),
        TextField(
          controller: _businessNameController,
          decoration: const InputDecoration(hintText: 'Business Name', prefixIcon: Icon(Icons.storefront_outlined)),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _businessCategory,
          decoration: const InputDecoration(prefixIcon: Icon(Icons.category_outlined)),
          items: _businessCategories.map((String category) {
            return DropdownMenuItem<String>(value: category, child: Text(category));
          }).toList(),
          onChanged: (String? newValue) {
            setState(() => _businessCategory = newValue ?? 'Retail');
          },
        ),
      ],
    );
  }

  Widget _buildPersonalForm({required Key key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('Personal Details'),
        TextField(
          controller: _profileNameController,
          decoration: const InputDecoration(hintText: 'Full Name', prefixIcon: Icon(Icons.person_outline_rounded)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: '7xx xxx xxx',
            prefixIcon: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('🇹🇿', style: TextStyle(fontSize: 24)),
                SizedBox(width: 8),
                Text('+255', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 16)),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: 'Recovery Email (Optional)', prefixIcon: Icon(Icons.alternate_email_rounded)),
        ),
      ],
    );
  }

  Widget _buildOtpForm({required Key key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(4, (index) => _OTPBox(controller: _otpControllers[index])),
        ),
        const SizedBox(height: 32),
        ElevatedButton(onPressed: _verifyAndRegister, child: const Text('Verify & Finish')),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _otpSent = false),
            child: const Text('Go Back', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.secondary),
      ),
    );
  }

  Widget _buildTermsAndConditions() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Checkbox(
          value: _agreedToTerms,
          onChanged: (value) => setState(() => _agreedToTerms = value ?? false),
          activeColor: AppColors.primary,
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              children: [
                const TextSpan(text: 'I agree to the '),
                TextSpan(
                  text: 'Terms',
                  style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                  recognizer: TapGestureRecognizer()..onTap = () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TermsAndConditionsPage())),
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                  recognizer: TapGestureRecognizer()..onTap = () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyPolicyPage())),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Already have an account?", style: TextStyle(color: AppColors.textSecondary)),
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('Login', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class _OTPBox extends StatelessWidget {
  final TextEditingController controller;
  const _OTPBox({required this.controller});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 65,
      height: 70,
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.secondary),
        decoration: InputDecoration(
          counterText: "",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border, width: 2)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border, width: 2)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.secondary, width: 2)),
        ),
        onChanged: (value) {
          if (value.length == 1) FocusScope.of(context).nextFocus();
        },
      ),
    );
  }
}

