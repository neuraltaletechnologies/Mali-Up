import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider that streams the current Firebase auth state
/// Emits the current [User] when signed in, or `null` when signed out
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Provider that returns the current user's UID
/// Returns `null` if no user is signed in
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value?.uid;
});

/// Provider that returns whether a user is currently logged in
final isLoggedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value != null;
});

/// Provider that returns the current [User] object
/// Returns `null` if no user is signed in
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value;
});

/// Provider that returns the current user's phone number
/// Returns `null` if no user is signed in or phone number is not set
final currentPhoneNumberProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.phoneNumber;
});

/// Provider that returns the current user's display name
/// Returns `null` if no user is signed in or display name is not set
final currentDisplayNameProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.displayName;
});

/// Provider that returns the current user's email
/// Returns `null` if no user is signed in or email is not set
final currentUserEmailProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.email;
});

/// Provider that returns the current user's photo URL
/// Returns `null` if no user is signed in or photo URL is not set
final currentUserPhotoProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.photoURL;
});

/// Provider that returns whether the current user's email is verified
/// Returns `false` if no user is signed in
final isEmailVerifiedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.emailVerified ?? false;
});

/// Provider that returns the current user's metadata
/// Returns `null` if no user is signed in
final currentUserMetadataProvider = Provider<UserMetadata?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.metadata;
});

/// Provider that returns the creation timestamp of the current user
/// Returns `null` if no user is signed in
final userCreationTimeProvider = Provider<DateTime?>((ref) {
  final metadata = ref.watch(currentUserMetadataProvider);
  return metadata?.creationTime;
});

/// Provider that returns the last sign-in timestamp of the current user
/// Returns `null` if no user is signed in
final lastSignInTimeProvider = Provider<DateTime?>((ref) {
  final metadata = ref.watch(currentUserMetadataProvider);
  return metadata?.lastSignInTime;
});

/// Provider that returns whether the auth state is currently being loaded
/// Useful for showing loading spinners during initial auth check
final authLoadingProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState is AsyncLoading;
});

/// Provider that returns any error from the auth state stream
/// Returns `null` if no error
final authErrorProvider = Provider<Exception?>((ref) {
  final authState = ref.watch(authStateProvider);
  final error = authState.error;
  if (error is Exception) {
    return error;
  }
  return null;
});

/// Provider that returns whether the auth state has been loaded at least once
final authLoadedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.hasValue;
});

/// Provider that returns the current auth state as an [AsyncValue]
/// Useful for handling loading, error, and data states in UI
final authStateAsyncProvider = Provider<AsyncValue<User?>>((ref) {
  return ref.watch(authStateProvider);
});