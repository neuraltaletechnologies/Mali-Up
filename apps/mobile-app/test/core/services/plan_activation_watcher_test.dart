import 'package:flutter_test/flutter_test.dart';
import 'package:mali_up/core/services/plan_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final watcher = PlanActivationWatcher.instance;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    watcher.resetForTest();
  });

  group('passive watcher (admin activations)', () {
    test('first sighting only seeds the baseline — it never celebrates', () async {
      expect(await watcher.checkForUpgrade('biz', PlanTier.business), isFalse);
    });

    test('re-seeing the same tier does not celebrate', () async {
      await watcher.checkForUpgrade('biz', PlanTier.business);
      expect(await watcher.checkForUpgrade('biz', PlanTier.business), isFalse);
    });

    test(
      'the transient Starter placeholder between two real Business emissions '
      'does not celebrate (the app-open regression)',
      () async {
        // A prior run left the baseline at Business.
        await watcher.checkForUpgrade('biz', PlanTier.business);

        // Cold start: planStatusProvider yields the Starter placeholder
        // before the real tier loads…
        expect(await watcher.checkForUpgrade('biz', PlanTier.starter), isFalse);
        // …then the real tier arrives from Firestore. The baseline was never
        // lowered, so this is a no-op, not a fake upgrade.
        expect(await watcher.checkForUpgrade('biz', PlanTier.business), isFalse);
      },
    );

    test('a genuine admin upgrade celebrates exactly once', () async {
      await watcher.checkForUpgrade('biz', PlanTier.growth); // seed

      expect(await watcher.checkForUpgrade('biz', PlanTier.business), isTrue);
      // Re-emitted (e.g. the app is reopened) — already celebrated.
      watcher.resetForTest();
      expect(await watcher.checkForUpgrade('biz', PlanTier.business), isFalse);
    });

    test('an expiry downgrade keeps the baseline and never re-celebrates', () async {
      await watcher.checkForUpgrade('biz', PlanTier.business); // seed at Business

      // Subscription expired → provider now reports Starter.
      expect(await watcher.checkForUpgrade('biz', PlanTier.starter), isFalse);
      // Baseline is still Business, so drifting back to Business is silent.
      expect(await watcher.checkForUpgrade('biz', PlanTier.business), isFalse);
    });

    test('baselines are scoped per business', () async {
      await watcher.checkForUpgrade('biz-a', PlanTier.business); // seed A only

      // biz-b has never been seen — first sighting seeds, no celebration,
      // even though biz-a is already on a higher tier.
      expect(await watcher.checkForUpgrade('biz-b', PlanTier.growth), isFalse);
    });
  });

  group('in-app purchase claim', () {
    test('a claimed upgrade is recorded silently, not celebrated', () async {
      await watcher.checkForUpgrade('biz', PlanTier.growth); // seed

      watcher.expectPurchase('biz'); // purchase flow starts
      // The businesses/{id} doc change lands via planStatusProvider.
      expect(await watcher.checkForUpgrade('biz', PlanTier.business), isFalse);

      // Claim consumed — a re-emit is a plain no-op, and a later genuine
      // upgrade past Business still celebrates.
      expect(await watcher.checkForUpgrade('biz', PlanTier.business), isFalse);
      expect(await watcher.checkForUpgrade('biz', PlanTier.enterprise), isTrue);
    });

    test('markSeen settles the baseline and releases the claim', () async {
      await watcher.checkForUpgrade('biz', PlanTier.growth); // seed
      watcher.expectPurchase('biz');

      // Purchase flow confirmed success and showed its own celebration.
      await watcher.markSeen('biz', PlanTier.business);

      watcher.resetForTest(); // next launch reads prefs
      expect(await watcher.checkForUpgrade('biz', PlanTier.business), isFalse);
    });

    test('markSeen never lowers the baseline', () async {
      await watcher.checkForUpgrade('biz', PlanTier.enterprise); // seed high
      await watcher.markSeen('biz', PlanTier.growth); // stale/racey callback

      watcher.resetForTest();
      // Enterprise is still the recorded baseline.
      expect(await watcher.checkForUpgrade('biz', PlanTier.enterprise), isFalse);
    });

    test('forgetPurchase restores normal celebration after a failed payment', () async {
      await watcher.checkForUpgrade('biz', PlanTier.growth); // seed

      watcher.expectPurchase('biz');
      watcher.forgetPurchase('biz'); // payment failed / user walked away

      // A later genuine activation of that tier is celebrated normally.
      expect(await watcher.checkForUpgrade('biz', PlanTier.business), isTrue);
    });

    test('a claim on one business does not silence another', () async {
      await watcher.checkForUpgrade('biz-a', PlanTier.growth);
      await watcher.checkForUpgrade('biz-b', PlanTier.growth);

      watcher.expectPurchase('biz-a');

      expect(await watcher.checkForUpgrade('biz-b', PlanTier.business), isTrue);
      expect(await watcher.checkForUpgrade('biz-a', PlanTier.business), isFalse);
    });
  });

  test('an empty businessId is ignored', () async {
    expect(await watcher.checkForUpgrade('', PlanTier.business), isFalse);
    watcher.expectPurchase(''); // must not throw
    watcher.forgetPurchase('');
    await watcher.markSeen('', PlanTier.business);
  });
}
