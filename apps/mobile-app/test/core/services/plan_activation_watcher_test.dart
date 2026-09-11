import 'package:flutter_test/flutter_test.dart';
import 'package:mali_up/core/services/plan_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final watcher = PlanActivationWatcher.instance;

  // Server `planStartedAt` stamps. Distinct activations of the same business.
  final firstActivation = DateTime(2026, 3, 1, 10);
  final laterActivation = DateTime(2026, 9, 1, 10);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    watcher.resetForTest();
  });

  /// Simulates the app being closed and reopened: in-memory state is gone,
  /// SharedPreferences survives.
  void relaunch() => watcher.resetForTest();

  group('passive watcher (activations outside the app)', () {
    test('the first activation seen on a device is recorded, never celebrated',
        () async {
      expect(
        await watcher.checkForActivation(
          'biz',
          PlanTier.business,
          firstActivation,
        ),
        isFalse,
      );
    });

    test('re-seeing the same activation is silent, launch after launch',
        () async {
      await watcher.checkForActivation('biz', PlanTier.business, firstActivation);

      // planStatusProvider re-emits (cache, then the live snapshot).
      expect(
        await watcher.checkForActivation(
          'biz',
          PlanTier.business,
          firstActivation,
        ),
        isFalse,
      );

      relaunch();
      expect(
        await watcher.checkForActivation(
          'biz',
          PlanTier.business,
          firstActivation,
        ),
        isFalse,
      );
    });

    test('an activation that lands while the app was closed celebrates once',
        () async {
      await watcher.checkForActivation('biz', PlanTier.growth, firstActivation);

      relaunch(); // admin granted a plan meanwhile
      expect(
        await watcher.checkForActivation(
          'biz',
          PlanTier.business,
          laterActivation,
        ),
        isTrue,
      );

      // Re-emitted, and again on the next launch — already celebrated.
      expect(
        await watcher.checkForActivation(
          'biz',
          PlanTier.business,
          laterActivation,
        ),
        isFalse,
      );
      relaunch();
      expect(
        await watcher.checkForActivation(
          'biz',
          PlanTier.business,
          laterActivation,
        ),
        isFalse,
      );
    });

    test(
      'the Starter placeholder planStatusProvider yields on a cold start '
      'neither celebrates nor seeds a record (the app-open regression)',
      () async {
        // Cold start: the hardcoded Starter fallback arrives first…
        expect(
          await watcher.checkForActivation('biz', PlanTier.starter, null),
          isFalse,
        );
        // …then the real, long-standing paid plan. Silent: this is the first
        // activation this device has seen, not something that just happened.
        expect(
          await watcher.checkForActivation(
            'biz',
            PlanTier.business,
            firstActivation,
          ),
          isFalse,
        );
      },
    );

    test('an expiry downgrade to Starter never re-celebrates on renewal',
        () async {
      await watcher.checkForActivation('biz', PlanTier.business, firstActivation);

      // Subscription expired → the provider reports Starter with no stamp.
      expect(
        await watcher.checkForActivation('biz', PlanTier.starter, null),
        isFalse,
      );
      // Drifting back to the *same* activation stays silent.
      expect(
        await watcher.checkForActivation(
          'biz',
          PlanTier.business,
          firstActivation,
        ),
        isFalse,
      );
    });

    test('a business doc with no planStartedAt stamp is left alone', () async {
      // Activated before the field existed — nothing to celebrate, and no
      // record written, so the first real activation still only seeds.
      expect(
        await watcher.checkForActivation('biz', PlanTier.business, null),
        isFalse,
      );
      expect(
        await watcher.checkForActivation(
          'biz',
          PlanTier.business,
          firstActivation,
        ),
        isFalse,
      );
    });

    test('an out-of-order older stamp does not celebrate or lower the record',
        () async {
      await watcher.checkForActivation('biz', PlanTier.growth, firstActivation);
      await watcher.checkForActivation(
        'biz',
        PlanTier.business,
        laterActivation,
      );

      // A stale cached emission carrying the previous stamp.
      expect(
        await watcher.checkForActivation(
          'biz',
          PlanTier.business,
          firstActivation,
        ),
        isFalse,
      );
      // The newest activation is still the recorded one.
      expect(
        await watcher.checkForActivation(
          'biz',
          PlanTier.business,
          laterActivation,
        ),
        isFalse,
      );
    });

    test('concurrent emissions celebrate at most once', () async {
      await watcher.checkForActivation('biz', PlanTier.growth, firstActivation);

      // planStatusProvider emits in a burst (cache, then live snapshot) and
      // each lands here through an async prefs read.
      final results = await Future.wait([
        watcher.checkForActivation('biz', PlanTier.business, laterActivation),
        watcher.checkForActivation('biz', PlanTier.business, laterActivation),
        watcher.checkForActivation('biz', PlanTier.business, laterActivation),
      ]);

      expect(results.where((celebrated) => celebrated), hasLength(1));
    });

    test('records are scoped per business', () async {
      await watcher.checkForActivation(
        'biz-a',
        PlanTier.business,
        firstActivation,
      );

      // biz-b has never been seen — first sighting records, no celebration,
      // even though biz-a already has a newer activation on file.
      expect(
        await watcher.checkForActivation(
          'biz-b',
          PlanTier.growth,
          laterActivation,
        ),
        isFalse,
      );
    });
  });

  group('in-app purchase claim', () {
    test('a claimed activation is recorded silently, not celebrated', () async {
      await watcher.checkForActivation('biz', PlanTier.growth, firstActivation);

      watcher.expectPurchase('biz'); // purchase flow starts
      // The businesses/{id} doc change lands via planStatusProvider.
      expect(
        await watcher.checkForActivation(
          'biz',
          PlanTier.business,
          laterActivation,
        ),
        isFalse,
      );

      // Claim consumed — a later genuine activation still celebrates.
      expect(
        await watcher.checkForActivation(
          'biz',
          PlanTier.enterprise,
          laterActivation.add(const Duration(days: 30)),
        ),
        isTrue,
      );
    });

    test(
      'a claim persisted at celebration time survives a relaunch, so the '
      'activation landing later never repeats the dialog',
      () async {
        await watcher.checkForActivation('biz', PlanTier.growth, firstActivation);

        watcher.expectPurchase('biz');
        // Payment confirmed; showUpgradeSheet shows its one celebration.
        await watcher.claimPurchase('biz');

        // App closed before the businesses/{id} snapshot arrived.
        relaunch();
        expect(
          await watcher.checkForActivation(
            'biz',
            PlanTier.business,
            laterActivation,
          ),
          isFalse,
        );
      },
    );

    test('forgetPurchase restores celebration after a failed payment',
        () async {
      await watcher.checkForActivation('biz', PlanTier.growth, firstActivation);

      watcher.expectPurchase('biz');
      await watcher.forgetPurchase('biz'); // payment failed / user walked away

      expect(
        await watcher.checkForActivation(
          'biz',
          PlanTier.business,
          laterActivation,
        ),
        isTrue,
      );
    });

    test('forgetPurchase clears a persisted claim too', () async {
      await watcher.checkForActivation('biz', PlanTier.growth, firstActivation);
      await watcher.claimPurchase('biz');
      await watcher.forgetPurchase('biz');

      relaunch();
      expect(
        await watcher.checkForActivation(
          'biz',
          PlanTier.business,
          laterActivation,
        ),
        isTrue,
      );
    });

    test('a claim on one business does not silence another', () async {
      await watcher.checkForActivation('biz-a', PlanTier.growth, firstActivation);
      await watcher.checkForActivation('biz-b', PlanTier.growth, firstActivation);

      watcher.expectPurchase('biz-a');

      expect(
        await watcher.checkForActivation(
          'biz-b',
          PlanTier.business,
          laterActivation,
        ),
        isTrue,
      );
      expect(
        await watcher.checkForActivation(
          'biz-a',
          PlanTier.business,
          laterActivation,
        ),
        isFalse,
      );
    });
  });

  test('an empty businessId is ignored', () async {
    expect(
      await watcher.checkForActivation('', PlanTier.business, firstActivation),
      isFalse,
    );
    watcher.expectPurchase(''); // must not throw
    await watcher.forgetPurchase('');
    await watcher.claimPurchase('');
  });
}
