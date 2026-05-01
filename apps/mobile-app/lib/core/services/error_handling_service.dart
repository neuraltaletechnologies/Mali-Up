import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'localization_service.dart';

enum ErrorType {
  network,
  authentication,
  validation,
  server,
  timeout,
  unknown,
}

class AppError {
  final ErrorType type;
  final String message;
  final String? technicalDetails;
  final DateTime timestamp;
  final String? context;

  AppError({
    required this.type,
    required this.message,
    this.technicalDetails,
    required this.timestamp,
    this.context,
  });

  factory AppError.network(String message, {String? context}) {
    return AppError(
      type: ErrorType.network,
      message: message,
      timestamp: DateTime.now(),
      context: context,
    );
  }

  factory AppError.auth(String message, {String? context}) {
    return AppError(
      type: ErrorType.authentication,
      message: message,
      timestamp: DateTime.now(),
      context: context,
    );
  }

  factory AppError.validation(String message, {String? context}) {
    return AppError(
      type: ErrorType.validation,
      message: message,
      timestamp: DateTime.now(),
      context: context,
    );
  }

  factory AppError.server(String message, {String? technicalDetails, String? context}) {
    return AppError(
      type: ErrorType.server,
      message: message,
      technicalDetails: technicalDetails,
      timestamp: DateTime.now(),
      context: context,
    );
  }

  factory AppError.timeout(String message, {String? context}) {
    return AppError(
      type: ErrorType.timeout,
      message: message,
      timestamp: DateTime.now(),
      context: context,
    );
  }

  factory AppError.unknown(String message, {String? technicalDetails, String? context}) {
    return AppError(
      type: ErrorType.unknown,
      message: message,
      technicalDetails: technicalDetails,
      timestamp: DateTime.now(),
      context: context,
    );
  }
}

class ErrorHandlingService {
  static const Duration _defaultTimeout = Duration(seconds: 30);

  static Future<bool> checkConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  static String _getLocalizedErrorMessage(ErrorType type, String fallbackMessage) {
    final isSwahili = LocalizationService.isSwahili;
    
    switch (type) {
      case ErrorType.network:
        return isSwahili 
            ? 'Hitilafu ya mtandao. Tafadhali angalia muunganisho wako.'
            : 'Network error. Please check your connection.';
      case ErrorType.authentication:
        return isSwahili
            ? 'Hitilafu ya kuingia. Tafadhali jaribu tena.'
            : 'Authentication error. Please try again.';
      case ErrorType.validation:
        return isSwahili
            ? 'Taarifa si sahihi. Tafadhali hakiki na ujaribu tena.'
            : 'Invalid information. Please check and try again.';
      case ErrorType.server:
        return isSwahili
            ? 'Hitilafu ya seva. Tafadhali jaribu tena baadaye.'
            : 'Server error. Please try again later.';
      case ErrorType.timeout:
        return isSwahili
            ? 'Muda umekwisha. Tafadhali jaribu tena.'
            : 'Request timed out. Please try again.';
      case ErrorType.unknown:
        return isSwahili
            ? 'Hitilafu isiyotarajiwa. Tafadhali jaribu tena.'
            : 'An unexpected error occurred. Please try again.';
    }
  }

  static String getLocalizedErrorMessage(AppError error) {
    return _getLocalizedErrorMessage(error.type, error.message);
  }

  static Future<T> withErrorHandling<T>({
    required Future<T> Function() operation,
    Duration? timeout,
    String? operationContext,
    required T Function(AppError) onError,
  }) async {
    final effectiveTimeout = timeout ?? _defaultTimeout;
    
    try {
      // Check connectivity first
      if (!await checkConnectivity()) {
        throw AppError.network(
          'No internet connection',
          context: operationContext,
        );
      }

      // Execute operation with timeout
      return await operation().timeout(effectiveTimeout);
    } on TimeoutException {
      return onError(AppError.timeout(
        'Operation timed out after ${effectiveTimeout.inSeconds} seconds',
        context: operationContext,
      ));
    } on FirebaseException catch (e) {
      if (e is FirebaseAuthException) {
        return onError(AppError.auth(
          _getFirebaseAuthErrorMessage(e),
          context: operationContext,
        ));
      } else {
        return onError(AppError.server(
          _getFirebaseErrorMessage(e),
          context: operationContext,
        ));
      }
    } on SocketException {
      return onError(AppError.network(
        'Network connection failed',
        context: operationContext,
      ));
    } on AppError catch (e) {
      return onError(e);
    } catch (e) {
      return onError(AppError.unknown(
        e.toString(),
        context: operationContext,
      ));
    }
  }

  static String _getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    final isSwahili = LocalizationService.isSwahili;
    
    switch (e.code) {
      case 'invalid-phone-number':
        return isSwahili 
            ? 'Namba ya simu si sahihi.'
            : 'Invalid phone number.';
      case 'user-disabled':
        return isSwahili
            ? 'Akaunti imelemazwa.'
            : 'Account disabled.';
      case 'user-not-found':
        return isSwahili
            ? 'Akaunti haijapatikana.'
            : 'Account not found.';
      case 'wrong-password':
        return isSwahili
            ? 'Nenosiri si sahihi.'
            : 'Incorrect password.';
      case 'email-already-in-use':
        return isSwahili
            ? 'Barua pepe tayari inatumika.'
            : 'Email already in use.';
      case 'weak-password':
        return isSwahili
            ? 'Nenosiri ni dhaifu.'
            : 'Password is too weak.';
      case 'invalid-verification-code':
        return isSwahili
            ? 'Nambari ya uthibitisho si sahihi.'
            : 'Invalid verification code.';
      case 'session-expired':
        return isSwahili
            ? 'Kipindi kimeisha.'
            : 'Session expired.';
      case 'too-many-requests':
        return isSwahili
            ? 'Maombi mengi sana. Tafadhali jaribu baadaye.'
            : 'Too many requests. Please try again later.';
      case 'network-request-failed':
        return isSwahili
            ? 'Hitilafu ya mtandao.'
            : 'Network request failed.';
      default:
        return isSwahili
            ? 'Hitilafu ya kuingia.'
            : 'Authentication error.';
    }
  }

  static String _getFirebaseErrorMessage(FirebaseException e) {
    final isSwahili = LocalizationService.isSwahili;
    
    switch (e.code) {
      case 'unavailable':
        return isSwahili
            ? 'Hudha haipatikani kwa sasa.'
            : 'Service currently unavailable.';
      case 'permission-denied':
        return isSwahili
            ? 'Hakuna ruhusa.'
            : 'Permission denied.';
      case 'not-found':
        return isSwahili
            ? 'Haijapatikana.'
            : 'Not found.';
      case 'already-exists':
        return isSwahili
            ? 'Tayari ipo.'
            : 'Already exists.';
      case 'resource-exhausted':
        return isSwahili
            ? 'Rasilimali zimekwisha.'
            : 'Resource exhausted.';
      case 'cancelled':
        return isSwahili
            ? 'Imeghairishwa.'
            : 'Cancelled.';
      case 'data-loss':
        return isSwahili
            ? 'Upotevu wa data.'
            : 'Data loss.';
      case 'unauthenticated':
        return isSwahili
            ? 'Hujathibitishwa.'
            : 'Unauthenticated.';
      default:
        return isSwahili
            ? 'Hitilafu ya seva.'
            : 'Server error.';
    }
  }

  static void showErrorSnackBar(BuildContext context, AppError error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(_getIconForErrorType(error.type), color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                getLocalizedErrorMessage(error),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: _getColorForErrorType(error.type),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: error.type == ErrorType.network
            ? SnackBarAction(
                label: LocalizationService.isSwahili ? 'Jaribu Tena' : 'Retry',
                textColor: Colors.white,
                onPressed: () {
                  // Could trigger retry logic here
                },
              )
            : null,
      ),
    );
  }

  static IconData _getIconForErrorType(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.authentication:
        return Icons.lock;
      case ErrorType.validation:
        return Icons.error_outline;
      case ErrorType.server:
        return Icons.cloud_off;
      case ErrorType.timeout:
        return Icons.access_time;
      case ErrorType.unknown:
        return Icons.help_outline;
    }
  }

  static Color _getColorForErrorType(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Colors.orange;
      case ErrorType.authentication:
        return Colors.red;
      case ErrorType.validation:
        return Colors.amber;
      case ErrorType.server:
        return Colors.purple;
      case ErrorType.timeout:
        return Colors.blue;
      case ErrorType.unknown:
        return Colors.grey;
    }
  }

  static Future<void> showErrorDialog(BuildContext context, AppError error) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_getIconForErrorType(error.type), color: _getColorForErrorType(error.type)),
            const SizedBox(width: 8),
            Text(_getTitleForErrorType(error.type)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(getLocalizedErrorMessage(error)),
            if (error.technicalDetails != null) ...[
              const SizedBox(height: 8),
              Text(
                'Technical details: ${error.technicalDetails}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(LocalizationService.isSwahili ? 'Sawa' : 'OK'),
          ),
        ],
      ),
    );
  }

  static String _getTitleForErrorType(ErrorType type) {
    final isSwahili = LocalizationService.isSwahili;
    
    switch (type) {
      case ErrorType.network:
        return isSwahili ? 'Hitilafu ya Mtandao' : 'Network Error';
      case ErrorType.authentication:
        return isSwahili ? 'Hitilafu ya Kuingia' : 'Authentication Error';
      case ErrorType.validation:
        return isSwahili ? 'Hitilafu ya Uthibitisho' : 'Validation Error';
      case ErrorType.server:
        return isSwahili ? 'Hitilafu ya Seva' : 'Server Error';
      case ErrorType.timeout:
        return isSwahili ? 'Muda Umeisha' : 'Timeout Error';
      case ErrorType.unknown:
        return isSwahili ? 'Hitilafu Isiyotarajiwa' : 'Unexpected Error';
    }
  }
}

// Extension for easier timeout handling
extension FutureExtensions<T> on Future<T> {
  Future<T> withTimeout(Duration timeout, {T Function()? onTimeout}) {
    return this.timeout(timeout, onTimeout: onTimeout);
  }
}
