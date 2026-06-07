import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';

/// Single instance of AppDatabase for the entire app lifetime.
/// Closed automatically when the provider is disposed (e.g. on sign-out).
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
