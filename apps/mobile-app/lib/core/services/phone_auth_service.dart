import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/localization_service.dart';

enum AuthResult {
  success,
  invalidPhone,
  otpSent,
  otpExpired,
  otpInvalid,
  networkError,
  tooManyRequests,
  userNotFound,
  unknownError,
}

class PhoneAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static String? _verificationId;
  static int? _resendToken;
  static Timer? _resendTimer;
  static int _resendCountdown = 0;
  static StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  static Stream<int> get resendCountdownStream {
    return Stream.periodic(const Duration(seconds: 1), (_) {
      if (_resendCountdown > 0) {
        _resendCountdown--;
        return _resendCountdown;
      }
      return 0;
    });
  }

  static bool get canResendOTP => _resendCountdown == 0;

  static String _normalizeTanzanianPhone(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    
    // Handle different Tanzanian phone formats
    if (digits.startsWith('255') && digits.length >= 12) {
      return digits; // Already in international format
    }
    if (digits.startsWith('0') && digits.length >= 10) {
      return '255${digits.substring(1)}'; // Convert local to international
    }
    if (digits.length >= 9 && !digits.startsWith('255')) {
      return '255$digits'; // Assume local format without leading 0
    }
    
    return digits; // Return as is if validation fails
  }

  static bool _isValidTanzanianPhone(String phone) {
    final normalized = _normalizeTanzanianPhone(phone);
    // Tanzanian phone numbers: +255 7XX XXX XXX or +255 6XX XXX XXX
    return RegExp(r'^255[67]\d{8}$').hasMatch(normalized);
  }

  static Future<AuthResult> sendOTP({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(AuthResult) onError,
    bool forceResending = false,
  }) async {
    try {
      // Check network connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return AuthResult.networkError;
      }

      final normalizedPhone = _normalizeTanzanianPhone(phoneNumber);
      
      if (!_isValidTanzanianPhone(normalizedPhone)) {
        return AuthResult.invalidPhone;
      }

      // Check if user already exists (for login flow)
      final userSnapshot = await _firestore
          .collection('users')
          .where('phone', isEqualTo: normalizedPhone.substring(3)) // Store without 255
          .limit(1)
          .get();

      if (userSnapshot.docs.isEmpty && !forceResending) {
        // For registration, we can proceed
        // For login, this would be an error
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: '+$normalizedPhone',
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-signin for Android devices
          try {
            await _auth.signInWithCredential(credential);
            onCodeSent('');
          } catch (e) {
            onError(AuthResult.unknownError);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          switch (e.code) {
            case 'invalid-phone-number':
              onError(AuthResult.invalidPhone);
              break;
            case 'too-many-requests':
              onError(AuthResult.tooManyRequests);
              break;
            case 'network-request-failed':
              onError(AuthResult.networkError);
              break;
            default:
              onError(AuthResult.unknownError);
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          _startResendCountdown();
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = null;
        },
        timeout: const Duration(seconds: 60),
        forceResendingToken: forceResending ? _resendToken : null,
      );

      return AuthResult.otpSent;
    } catch (e) {
      return AuthResult.unknownError;
    }
  }

  static Future<AuthResult> verifyOTP({
    required String otp,
    required String? phoneNumber,
    Map<String, dynamic>? userData,
  }) async {
    try {
      // Check network connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return AuthResult.networkError;
      }

      if (_verificationId == null && otp.isEmpty) {
        return AuthResult.otpInvalid;
      }

      PhoneAuthCredential credential;
      
      if (_verificationId != null) {
        // Manual OTP entry
        credential = PhoneAuthProvider.credential(
          verificationId: _verificationId!,
          smsCode: otp,
        );
      } else {
        // Auto-retrieved OTP (already handled in verificationCompleted)
        return AuthResult.success;
      }

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        return AuthResult.unknownError;
      }

      // Check if this is a new user (registration) or existing user (login)
      final userSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userSnapshot.exists && userData != null) {
        // New user registration - create profile
        await _createUserProfile(user, userData, phoneNumber);
      }

      _verificationId = null;
      return AuthResult.success;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-verification-code':
          return AuthResult.otpInvalid;
        case 'session-expired':
          return AuthResult.otpExpired;
        case 'network-request-failed':
          return AuthResult.networkError;
        default:
          return AuthResult.unknownError;
      }
    } catch (e) {
      return AuthResult.unknownError;
    }
  }

  static Future<void> _createUserProfile(
    User user,
    Map<String, dynamic> userData,
    String? phoneNumber,
  ) async {
    final normalizedPhone = phoneNumber != null 
        ? _normalizeTanzanianPhone(phoneNumber).substring(3) // Remove 255
        : userData['phone'] ?? '';

    final businessId = userData['includesBusiness'] == true 
        ? _firestore.collection('tenants').doc(user.uid).collection('businesses').doc().id
        : null;

    final defaultContext = userData['includesBusiness'] == true && businessId != null
        ? 'business:$businessId'
        : 'personal';

    final userProfile = {
      'uid': user.uid,
      'phone': normalizedPhone,
      'name': userData['name'] ?? '',
      'displayName': userData['name'] ?? '',
      'email': userData['email']?.toLowerCase(),
      'businessName': userData['businessName'],
      'defaultAccountType': userData['defaultAccountType'] ?? 'personal',
      'accountTypes': userData['accountTypes'] ?? ['personal'],
      'usagePreference': userData['usagePreference'] ?? 'personal',
      'defaultContext': defaultContext,
      'selectedBusinessId': businessId,
      'businesses': userData['includesBusiness'] == true && businessId != null
          ? [
              {
                'id': businessId,
                'name': userData['businessName'] ?? '',
                'type': userData['businessType'] ?? 'Retail',
                'category': userData['businessCategory'] ?? 'retail',
                'placeOfBusiness': userData['placeOfBusiness'] ?? '',
                'createdAt': FieldValue.serverTimestamp(),
              },
            ]
          : <Map<String, dynamic>>[],
      'recoveryEmail': userData['recoveryEmail']?.toLowerCase(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
      'isPhoneVerified': true,
      'registrationMethod': 'phone_otp',
      'isActive': true,
      'profileComplete': true,
    };

    // Create main user document
    await _firestore.collection('users').doc(user.uid).set(userProfile);

    // Create business tenant if business is selected
    if (userData['includesBusiness'] == true && businessId != null) {
      await _firestore
          .collection('tenants')
          .doc(user.uid)
          .collection('businesses')
          .doc(businessId)
          .set({
            'id': businessId,
            'businessName': userData['businessName'] ?? '',
            'businessType': userData['businessType'] ?? 'Retail',
            'businessCategory': userData['businessCategory'] ?? 'retail',
            'placeOfBusiness': userData['placeOfBusiness'] ?? '',
            'ownerName': userData['name'] ?? '',
            'ownerPhone': normalizedPhone,
            'ownerUid': user.uid,
            'accountType': 'business',
            'ownerEmail': userData['email']?.toLowerCase(),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'plan': 'Trial',
            'isActive': true,
            'subscriptionStatus': 'trial',
          });
    }

    // Create personal account if personal is selected
    if (userData['includesPersonal'] == true) {
      await _firestore.collection('personal_accounts').doc(user.uid).set({
        'fullName': userData['name'] ?? '',
        'phone': normalizedPhone,
        'ownerUid': user.uid,
        'accountType': 'personal',
        'recoveryEmail': userData['recoveryEmail']?.toLowerCase(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });
    }
  }

  static void _startResendCountdown() {
    _resendCountdown = 60; // 60 seconds countdown
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown <= 0) {
        timer.cancel();
      }
    });
  }

  static Future<void> signOut() async {
    await _auth.signOut();
    _verificationId = null;
    _resendToken = null;
    _resendTimer?.cancel();
    _resendCountdown = 0;
  }

  static Future<bool> isUserLoggedIn() async {
    return _auth.currentUser != null;
  }

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static void dispose() {
    _resendTimer?.cancel();
    _connectivitySubscription?.cancel();
  }
}
