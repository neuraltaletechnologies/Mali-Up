import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mali_up/config/routing.dart';

class DefaultContextRoutingService {
  static String routeFromContextValue(String? contextValue) {
    if (contextValue == null || contextValue.isEmpty) {
      return AppRouter.dashboardPath;
    }

    final normalized = contextValue.toLowerCase();
    if (normalized.startsWith('business')) {
      return AppRouter.salesPath;
    }
    if (normalized.startsWith('personal')) {
      return AppRouter.dashboardPath;
    }

    return AppRouter.dashboardPath;
  }

  static Future<String> resolveUserLandingPath({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) async {
    final resolvedAuth = auth ?? FirebaseAuth.instance;
    final resolvedStore = firestore ?? FirebaseFirestore.instance;
    final user = resolvedAuth.currentUser;
    if (user == null) {
      return AppRouter.dashboardPath;
    }

    try {
      final snapshot = await resolvedStore
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions());
      return routeFromUserProfile(snapshot.data());
    } catch (_) {
      // Fall back to dashboard when profile fetch is unavailable.
    }

    return AppRouter.dashboardPath;
  }

  static String routeFromUserProfile(Map<String, dynamic>? data) {
    final defaultContext = data?['defaultContext'];
    if (defaultContext is String && defaultContext.isNotEmpty) {
      return routeFromContextValue(defaultContext);
    }

    final defaultAccountType =
        (data?['defaultAccountType'] as String?)?.toLowerCase();
    if (defaultAccountType == 'business') {
      return AppRouter.salesPath;
    }

    final accountTypesRaw = data?['accountTypes'];
    if (accountTypesRaw is List) {
      final accountTypes = accountTypesRaw
          .whereType<String>()
          .map((e) => e.toLowerCase())
          .toList();
      if (accountTypes.length == 1 && accountTypes.first == 'business') {
        return AppRouter.salesPath;
      }
    }

    return AppRouter.dashboardPath;
  }

  static Future<String?> resolveInitialAuthenticatedPath({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) async {
    final resolvedAuth = auth ?? FirebaseAuth.instance;
    if (resolvedAuth.currentUser == null) {
      return null;
    }

    return resolveUserLandingPath(auth: resolvedAuth, firestore: firestore);
  }
}