import 'package:flutter_test/flutter_test.dart';
import 'package:mali_up/core/services/plan_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('restores a paid plan for the same user while offline', () async {
    final expiresAt = DateTime.now().add(const Duration(days: 30));
    await PlanStatusCache.save(
      'user-a',
      PlanStatus(
        tier: PlanTier.business,
        invoicesUsedThisMonth: 12,
        expiresAt: expiresAt,
      ),
    );

    final restored = await PlanStatusCache.load('user-a');

    expect(restored, isNotNull);
    expect(restored!.tier, PlanTier.business);
    expect(restored.isPaid, isTrue);
    expect(restored.invoicesUsedThisMonth, 12);
    expect(
      restored.expiresAt?.millisecondsSinceEpoch,
      expiresAt.millisecondsSinceEpoch,
    );
  });

  test('does not expose one user plan to another user', () async {
    await PlanStatusCache.save(
      'user-a',
      const PlanStatus(tier: PlanTier.growth, invoicesUsedThisMonth: 0),
    );

    expect(await PlanStatusCache.load('user-b'), isNull);
  });

  test('expired paid plan is restored as Starter', () async {
    await PlanStatusCache.save(
      'user-a',
      PlanStatus(
        tier: PlanTier.growth,
        invoicesUsedThisMonth: 0,
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    );

    final restored = await PlanStatusCache.load('user-a');

    expect(restored, isNotNull);
    expect(restored!.tier, PlanTier.starter);
    expect(restored.isPaid, isFalse);
  });

  test('preserves enterprise override limits', () async {
    const overrides = PlanLimits(
      monthlyInvoices: 250,
      maxUsers: 25,
      fullReports: true,
      mpesaImport: true,
      smsReminders: true,
      multiLocation: true,
      apiAccess: true,
      allExports: true,
      prioritySupport: true,
    );
    await PlanStatusCache.save(
      'user-a',
      const PlanStatus(
        tier: PlanTier.enterprise,
        invoicesUsedThisMonth: 7,
        overrideLimits: overrides,
      ),
    );

    final restored = await PlanStatusCache.load('user-a');

    expect(restored?.limits.monthlyInvoices, 250);
    expect(restored?.limits.maxUsers, 25);
  });
}
