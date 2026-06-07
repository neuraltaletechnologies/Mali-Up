import 'package:drift/native.dart';
import 'package:mali_up/core/database/app_database.dart';

/// Opens a fresh in-memory database for each test.
/// Using NativeDatabase.memory() avoids any on-disk state between test runs.
AppDatabase openTestDatabase() {
  return AppDatabase(NativeDatabase.memory());
}
