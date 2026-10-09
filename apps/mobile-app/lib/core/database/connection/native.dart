import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

/// Persistent on-device SQLite file — the offline source of truth on
/// Android/iOS/desktop.
QueryExecutor openConnection() => driftDatabase(name: 'mali_up_db');
