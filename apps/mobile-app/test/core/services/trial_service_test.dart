import 'package:flutter_test/flutter_test.dart';
import 'package:mali_up/core/services/plan_service.dart';
import 'package:mali_up/core/services/trial_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('fills admin placeholders and leaves unknown ones alone', () {
    final out = fillTrialTemplate(
      'Hongera {name}! Siku {days}, inaisha {{endDate}} {unknown}',
      {'name': 'Amina', 'days': 7, 'endDate': '21/11/2026'},
    );
    expect(out, 'Hongera Amina! Siku 7, inaisha 21/11/2026 {unknown}');
  });

  test('trialDaysLeft rounds up and is zero off-trial', () {
    final trial = PlanStatus(
      tier: PlanTier.growth,
      invoicesUsedThisMonth: 0,
      isTrial: true,
      expiresAt: DateTime.now().add(const Duration(days: 1, hours: 3)),
    );
    expect(trial.trialDaysLeft, 2);

    final paid = PlanStatus(
      tier: PlanTier.growth,
      invoicesUsedThisMonth: 0,
      expiresAt: DateTime.now().add(const Duration(days: 5)),
    );
    expect(paid.trialDaysLeft, 0);
  });

  test('cache keeps the trial flag while active and drops it once expired',
      () async {
    final started = DateTime.now().subtract(const Duration(days: 2));
    await PlanStatusCache.save(
      'biz-a',
      PlanStatus(
        tier: PlanTier.growth,
        invoicesUsedThisMonth: 0,
        isTrial: true,
        trialStartedAt: started,
        expiresAt: DateTime.now().add(const Duration(days: 5)),
      ),
    );
    final active = await PlanStatusCache.load('biz-a');
    expect(active!.isTrial, isTrue);
    expect(
      active.trialStartedAt?.millisecondsSinceEpoch,
      started.millisecondsSinceEpoch,
    );

    await PlanStatusCache.save(
      'biz-b',
      PlanStatus(
        tier: PlanTier.growth,
        invoicesUsedThisMonth: 0,
        isTrial: true,
        trialStartedAt: started,
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    );
    final expired = await PlanStatusCache.load('biz-b');
    expect(expired!.tier, PlanTier.starter);
    expect(expired.isTrial, isFalse);
  });

  test('gift popup is claimed once per trial', () async {
    final started = DateTime(2026, 11, 14, 9);
    expect(await TrialGiftTracker.claim('biz-a', started), isTrue);
    expect(await TrialGiftTracker.claim('biz-a', started), isFalse);
    // A later, different trial (e.g. admin re-grant) shows again.
    expect(
      await TrialGiftTracker.claim('biz-a', started.add(const Duration(days: 30))),
      isTrue,
    );
  });
}
