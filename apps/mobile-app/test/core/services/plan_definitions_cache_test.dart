import 'package:flutter_test/flutter_test.dart';
import 'package:mali_up/core/services/plan_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fallback Growth plan is limited to one business', () {
    expect(limitsFor(PlanTier.growth).maxBusinesses, 1);
  });

  test('fallback Starter plan meters customers and daily sales', () {
    final starter = limitsFor(PlanTier.starter);
    expect(starter.maxCustomers, 20);
    expect(starter.maxSalesPerDay, 10);
    // Paid tiers stay unlimited on the daily cap.
    expect(limitsFor(PlanTier.growth).maxSalesPerDay, -1);
  });

  test('allowsSaleToday respects the daily cap and unlimited (-1)', () {
    const starter = PlanStatus(tier: PlanTier.starter, invoicesUsedThisMonth: 0);
    expect(starter.limits.maxSalesPerDay, 10);
    expect(starter.allowsSaleToday(9), isTrue);
    expect(starter.allowsSaleToday(10), isFalse);
    expect(starter.allowsSaleToday(11), isFalse);

    const growth = PlanStatus(tier: PlanTier.growth, invoicesUsedThisMonth: 0);
    expect(growth.allowsSaleToday(999), isTrue);
  });

  test('keeps admin-managed plan definitions available offline', () async {
    SharedPreferences.setMockInitialValues({});
    final definitions = <PlanTier, PlanLimits>{
      for (final tier in PlanTier.values) tier: limitsFor(tier),
      PlanTier.growth: const PlanLimits(
        monthlyInvoices: 175,
        maxUsers: 8,
        maxBusinesses: 3,
        maxCustomers: 500,
        maxSalesPerDay: 40,
        pricePerCycle: 72000,
        cycleMonths: 12,
        fullReports: true,
        mpesaImport: false,
        smsReminders: true,
        multiLocation: true,
        apiAccess: false,
        allExports: true,
        prioritySupport: true,
        cashFlow: true,
        expenseTracking: true,
        manualDebt: true,
      ),
    };

    await PlanDefinitionsCache.save(definitions);
    final restored = await PlanDefinitionsCache.load();

    expect(restored, isNotNull);
    expect(restored![PlanTier.growth]!.monthlyInvoices, 175);
    expect(restored[PlanTier.growth]!.maxUsers, 8);
    expect(restored[PlanTier.growth]!.maxBusinesses, 3);
    expect(restored[PlanTier.growth]!.maxCustomers, 500);
    expect(restored[PlanTier.growth]!.maxSalesPerDay, 40);
    expect(restored[PlanTier.growth]!.pricePerCycle, 72000);
    expect(restored[PlanTier.growth]!.mpesaImport, isFalse);
    expect(restored[PlanTier.growth]!.allExports, isTrue);
  });
}
