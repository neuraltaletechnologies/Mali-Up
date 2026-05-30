import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_up/core/database/app_database.dart';
import 'package:mali_up/core/database/daos/settings_dao.dart';

import 'test_helpers.dart';

void main() {
  late AppDatabase db;
  late SettingsDao dao;

  setUp(() {
    db = openTestDatabase();
    dao = db.settingsDao;
  });

  tearDown(() async => db.close());

  group('UserSettings', () {
    test('upsertUserSettings inserts when no row exists', () async {
      await dao.upsertUserSettings(UserSettingsTableCompanion(
        userId: const Value('uid-1'),
        businessId: const Value('biz-1'),
        language: const Value('sw'),
      ));

      final result = await dao.getUserSettings();
      expect(result, isNotNull);
      expect(result!.userId, 'uid-1');
      expect(result.language, 'sw');
    });

    test('upsertUserSettings overwrites existing row', () async {
      await dao.upsertUserSettings(UserSettingsTableCompanion(
        userId: const Value('uid-1'),
        businessId: const Value('biz-1'),
        language: const Value('sw'),
      ));
      await dao.upsertUserSettings(UserSettingsTableCompanion(
        userId: const Value('uid-1'),
        businessId: const Value('biz-1'),
        language: const Value('en'),
      ));

      final result = await dao.getUserSettings();
      expect(result!.language, 'en');
    });

    test('updateLastSyncAt stores the timestamp', () async {
      await dao.upsertUserSettings(UserSettingsTableCompanion(
        userId: const Value('uid-1'),
        businessId: const Value('biz-1'),
      ));
      const ts = 1700000000000;
      await dao.updateLastSyncAt(ts);

      final result = await dao.getUserSettings();
      expect(result!.lastSyncAt, ts);
    });

    test('setOfflineSince and clearOfflineSince round-trip', () async {
      await dao.upsertUserSettings(UserSettingsTableCompanion(
        userId: const Value('uid-1'),
        businessId: const Value('biz-1'),
      ));

      const ts = 1700000000000;
      await dao.setOfflineSince(ts);
      expect((await dao.getUserSettings())!.offlineSince, ts);

      await dao.clearOfflineSince();
      expect((await dao.getUserSettings())!.offlineSince, isNull);
    });

    test('watchUserSettings emits updates reactively', () async {
      await dao.upsertUserSettings(UserSettingsTableCompanion(
        userId: const Value('uid-1'),
        businessId: const Value('biz-1'),
        language: const Value('sw'),
      ));

      final stream = dao.watchUserSettings();
      final first = await stream.first;
      expect(first!.language, 'sw');

      await dao.upsertUserSettings(UserSettingsTableCompanion(
        userId: const Value('uid-1'),
        businessId: const Value('biz-1'),
        language: const Value('en'),
      ));

      final second = await stream.first;
      expect(second!.language, 'en');
    });
  });

  group('BusinessSettings', () {
    test('upsertBusinessSettings inserts and retrieves', () async {
      await dao.upsertBusinessSettings(BusinessSettingsTableCompanion(
        businessId: const Value('biz-1'),
        businessName: const Value('Duka la Amina'),
        vatRate: const Value(0.18),
        currency: const Value('TZS'),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ));

      final result = await dao.getBusinessSettings();
      expect(result, isNotNull);
      expect(result!.businessName, 'Duka la Amina');
      expect(result.vatRate, 0.18);
    });

    test('incrementAndGetNextInvoiceNumber increments atomically', () async {
      await dao.upsertBusinessSettings(BusinessSettingsTableCompanion(
        businessId: const Value('biz-1'),
        businessName: const Value('Test Biz'),
        nextInvoiceNumber: const Value(42),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ));

      final first = await dao.incrementAndGetNextInvoiceNumber();
      final second = await dao.incrementAndGetNextInvoiceNumber();
      final third = await dao.incrementAndGetNextInvoiceNumber();

      expect(first, 43);
      expect(second, 44);
      expect(third, 45);
    });

    test('incrementAndGetNextInvoiceNumber starts from 1 when no row exists',
        () async {
      await dao.upsertBusinessSettings(BusinessSettingsTableCompanion(
        businessId: const Value('biz-1'),
        businessName: const Value('Test Biz'),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ));

      final result = await dao.incrementAndGetNextInvoiceNumber();
      expect(result, 1);
    });
  });
}
