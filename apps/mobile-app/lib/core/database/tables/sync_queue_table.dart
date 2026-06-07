import 'package:drift/drift.dart';

class SyncQueueTable extends Table {
  @override
  String get tableName => 'sync_queue';

  IntColumn get id => integer().autoIncrement()();
  // UUID — unique per operation, prevents double-processing after a crash
  TextColumn get operationId => text().unique()();
  // invoice | customer | expense | inventory_item | business_settings
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  // create | update | delete
  TextColumn get operation => text()();
  // Full JSON snapshot of the entity at the time of queuing
  TextColumn get payload => text()();
  // pending | processing | completed | failed | conflict | cancelled
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  IntColumn get maxAttempts => integer().withDefault(const Constant(5))();
  // unix ms — entry is not retried before this time (exponential backoff)
  IntColumn get nextRetryAt => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  TextColumn get errorMessage =>
      text().withDefault(const Constant(''))();
  // SHA-256 of payload — detects in-flight corruption before sending
  TextColumn get checksum => text()();
  // localVersion of the entity at enqueue time — used to skip stale entries
  IntColumn get localVersion => integer()();
}
