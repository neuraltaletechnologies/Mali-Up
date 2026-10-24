import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:sqlite3/wasm.dart';

/// Web has no offline mode: the database lives only in memory for the life of
/// the tab — nothing is written to IndexedDB/OPFS. Every page load starts
/// empty, so SyncService's first cycle does a full pull from Firestore and the
/// UI reads that fresh, network-sourced copy. Browser storage is too volatile
/// (eviction, private windows, cleared site data) to trust as a cache of
/// business records, and a tab can't carry a sync queue across a reload.
///
/// Requires `web/sqlite3.wasm` matching the locked `sqlite3` package version;
/// it is downloaded at build time (see .github/workflows/deploy-web.yml), not
/// committed.
QueryExecutor openConnection() {
  return DatabaseConnection.delayed(
    Future(() async {
      final sqlite3 = await WasmSqlite3.loadFromUrl(Uri.parse('sqlite3.wasm'));
      sqlite3.registerVirtualFileSystem(InMemoryFileSystem(), makeDefault: true);
      return DatabaseConnection(WasmDatabase.inMemory(sqlite3));
    }),
  ).executor;
}
