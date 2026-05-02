import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Authentication service for handling phone authentication and user profile management
class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get the current authenticated user
  User? get currentUser => _auth.currentUser;

  /// Get the current user ID (null if not authenticated)
  String? get currentUserId => _auth.currentUser?.uid;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Check if user is currently signed in
  bool get isSignedIn => _auth.currentUser != null;

  // ============================================
  // PHONE AUTHENTICATION
  // ============================================

  /// Verify a phone number and send verification code
  /// Returns [PhoneConfirmationResult] on success
  /// Throws [FirebaseAuthException] on failure
  Future<PhoneConfirmationResult> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(String verificationId, int? resendToken) onCodeAutoRetrieved,
    required Function(String error) onVerificationFailed,
    required Function() onCodeExpired,
    int? timeout,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: timeout != null ? Duration(seconds: timeout) : const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-retrieval completed - sign in automatically
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onVerificationFailed(e.message ?? 'Verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          onCodeAutoRetrieved(verificationId, null);
        },
      );
      
      // Return a placeholder - the actual result comes through callbacks
      return PhoneConfirmationResult._();
    } catch (e) {
      if (kDebugMode) {
        print('Phone verification error: $e');
      }
      rethrow;
    }
  }

  /// Sign in with phone credential
  /// Returns [UserCredential] on success
  /// Throws [FirebaseAuthException] on failure
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    try {
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      if (kDebugMode) {
        print('Sign in with credential error: $e');
      }
      rethrow;
    }
  }

  /// Sign in with phone number and verification code
  /// Returns [UserCredential] on success
  /// Throws [FirebaseAuthException] on failure
  Future<UserCredential> signInWithPhoneNumber({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      return await signInWithCredential(credential);
    } catch (e) {
      if (kDebugMode) {
        print('Sign in with phone number error: $e');
      }
      rethrow;
    }
  }

  // ============================================
  // USER PROFILE MANAGEMENT
  // ============================================

  /// Create user profile after successful signup
  /// This method creates both the user document and business settings document
  /// using a batch write to ensure atomicity
  /// 
  /// Returns true on success, throws exception on failure
  Future<bool> createUserProfileAfterSignup({
    required String userId,
    required String phoneNumber,
    required String displayName,
    required String businessName,
    double taxRate = 0.18,
    String invoicePrefix = 'INV-',
    String currency = 'TZS',
    String language = 'sw',
  }) async {
    try {
      // Create a batch write operation
      final batch = _firestore.batch();

      // 1. Create user document
      final userRef = _firestore.collection('users').doc(userId);
      final userData = {
        'phoneNumber': phoneNumber,
        'displayName': displayName,
        'businessName': businessName,
        'subscriptionStatus': 'free',
        'currency': currency,
        'language': language,
        'activeMode': 'business',
        'createdAt': FieldValue.serverTimestamp(),
        'defaultContext': 'business',
        'selectedBusinessId': userId, // User's business ID is same as their UID
      };
      batch.set(userRef, userData);

      // 2. Create business settings document
      // Business document is at business/{userId}
      final businessRef = _firestore.collection('business').doc(userId);
      final businessData = {
        'ownerId': userId,
        'name': businessName,
        'createdAt': FieldValue.serverTimestamp(),
      };
      batch.set(businessRef, businessData);

      // 3. Create business settings subcollection document
      final settingsRef = _firestore.collection('business').doc(userId).collection('settings').doc('main');
      final settingsData = {
        'taxRate': taxRate,
        'invoicePrefix': invoicePrefix,
        'nextInvoiceNumber': 1,
        'currency': currency,
        'businessType': null,
        'createdAt': FieldValue.serverTimestamp(),
      };
      batch.set(settingsRef, settingsData);

      // 4. Create empty subcollections with placeholder documents (for structure)
      // This helps with Firestore security rules and makes the structure explicit
      final collectionsToCreate = [
        'invoices',
        'customers',
        'expenses',
        'inventory',
        'cashFlow',
        'suppliers',
        'staff',
      ];

      for (final collection in collectionsToCreate) {
        final placeholderRef = _firestore
            .collection('business')
            .doc(userId)
            .collection(collection)
            .doc('_placeholder');
        batch.set(placeholderRef, {
          'createdAt': FieldValue.serverTimestamp(),
          '_isPlaceholder': true,
        });
      }

      // Commit the batch
      await batch.commit();

      if (kDebugMode) {
        print('User profile created successfully for userId: $userId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating user profile: $e');
      }
      rethrow;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? displayName,
    String? businessName,
    String? language,
    String? activeMode,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final updateData = <String, dynamic>{};

      if (displayName != null) updateData['displayName'] = displayName;
      if (businessName != null) updateData['businessName'] = businessName;
      if (language != null) updateData['language'] = language;
      if (activeMode != null) updateData['activeMode'] = activeMode;

      if (updateData.isNotEmpty) {
        await userRef.update(updateData);
      }

      // Update business name if provided
      if (businessName != null) {
        final businessRef = _firestore.collection('business').doc(userId);
        await businessRef.update({'name': businessName});
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user profile: $e');
      }
      rethrow;
    }
  }

  /// Get user profile data
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user profile: $e');
      }
      rethrow;
    }
  }

  /// Get user by phone number (for login flow)
  Future<Map<String, dynamic>?> getUserByPhone(String phoneNumber) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user by phone: $e');
      }
      rethrow;
    }
  }

  /// Check if user has completed onboarding
  Future<bool> hasCompletedOnboarding(String userId) async {
    try {
      final profile = await getUserProfile(userId);
      if (profile == null) return false;
      
      // Check if essential fields are set
      final hasBusinessName = profile['businessName'] != null && 
                              (profile['businessName'] as String).isNotEmpty;
      final hasDisplayName = profile['displayName'] != null && 
                             (profile['displayName'] as String).isNotEmpty;
      
      return hasBusinessName && hasDisplayName;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking onboarding status: $e');
      }
      return false;
    }
  }

  // ============================================
  // SIGN OUT
  // ============================================

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      if (kDebugMode) {
        print('Error signing out: $e');
      }
      rethrow;
    }
  }

  // ============================================
  // DELETE ACCOUNT
  // ============================================

  /// Delete user account and all associated data
  /// WARNING: This is irreversible
  Future<void> deleteAccount() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('No user is currently signed in');
      }

      // Delete user document
      await _firestore.collection('users').doc(userId).delete();

      // Delete business document and all subcollections
      final businessRef = _firestore.collection('business').doc(userId);
      
      // Delete subcollections (Firestore doesn't support cascading deletes)
      final subcollections = [
        'invoices',
        'customers',
        'expenses',
        'inventory',
        'settings',
        'cashFlow',
        'suppliers',
        'staff',
      ];

      for (final collection in subcollections) {
        final snapshot = await businessRef.collection(collection).get();
        final batch = _firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      // Delete business document itself
      await businessRef.delete();

      // Delete the Firebase Auth user
      await currentUser?.delete();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting account: $e');
      }
      rethrow;
    }
  }

  // ============================================
  // UTILITY METHODS
  // ============================================

  /// Refresh the current user's ID token
  Future<String?> refreshIdToken() async {
    try {
      await currentUser?.getIdToken(true);
      return currentUser?.getIdToken();
    } catch (e) {
      if (kDebugMode) {
        print('Error refreshing ID token: $e');
      }
      rethrow;
    }
  }

  /// Get the current user's ID token
  Future<String?> getIdToken() async {
    try {
      return await currentUser?.getIdToken();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting ID token: $e');
      }
      rethrow;
    }
  }
}

/// Placeholder class for phone confirmation result
class PhoneConfirmationResult {
  PhoneConfirmationResult._();
}