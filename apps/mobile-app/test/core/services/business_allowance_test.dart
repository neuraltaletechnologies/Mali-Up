import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_up/core/services/plan_service.dart';

// Same rule as allowedBusinesses() in functions/src/trial.ts.
void main() {
  final now = DateTime(2026, 11, 14);
  final future = Timestamp.fromDate(now.add(const Duration(days: 30)));
  final past = Timestamp.fromDate(now.subtract(const Duration(days: 1)));

  Map<String, dynamic> biz(String plan, {String? source, Timestamp? expires}) =>
      {'plan': plan, 'planSource': ?source, 'planExpiresAt': ?expires};

  group('allowedBusinessCount', () {
    test('a free account may have exactly one business', () {
      expect(allowedBusinessCount([], now: now), 1);
      expect(allowedBusinessCount([biz('starter')], now: now), 1);
      expect(canAddBusiness([biz('starter')], now: now), isFalse);
      expect(canAddBusiness([], now: now), isTrue);
    });

    test('a trial never unlocks more businesses', () {
      final trialing = biz('business', source: 'trial', expires: future);
      expect(allowedBusinessCount([trialing], now: now), 1);
      expect(canAddBusiness([trialing], now: now), isFalse);
    });

    test('a live paid Business plan allows up to 5 businesses', () {
      final paid = biz('business', source: 'clickpesa', expires: future);
      final starters = List.generate(3, (_) => biz('starter'));
      expect(allowedBusinessCount([paid], now: now), 5);
      expect(canAddBusiness([paid, ...starters], now: now), isTrue);
      expect(
        canAddBusiness([paid, ...starters, biz('starter')], now: now),
        isFalse,
      );
    });

    test('a plan with unlimited businesses always allows adding', () {
      final life = biz('lifetime', source: 'admin_grant');
      expect(allowedBusinessCount([life], now: now), -1);
      expect(
        canAddBusiness([
          life,
          ...List.generate(20, (_) => biz('starter')),
        ], now: now),
        isTrue,
      );
    });

    test('an expired paid plan stops allowing new businesses', () {
      final expired = biz('business', source: 'clickpesa', expires: past);
      expect(canAddBusiness([expired], now: now), isFalse);
    });

    test('Growth keeps its 1-business cap', () {
      final growth = biz('growth', source: 'clickpesa', expires: future);
      expect(canAddBusiness([growth], now: now), isFalse);
    });

    test('Enterprise deal override sets the cap', () {
      final ent = {
        ...biz('enterprise', source: 'admin_grant', expires: future),
        'enterpriseOverrides': {'maxBusinesses': 3},
      };
      expect(allowedBusinessCount([ent], now: now), 3);
      expect(canAddBusiness([ent, biz('starter')], now: now), isTrue);
      expect(
        canAddBusiness([ent, biz('starter'), biz('starter')], now: now),
        isFalse,
      );
    });

    test('reads the offline-cache expiry format', () {
      final cached = {
        'plan': 'business',
        'planSource': 'clickpesa',
        'planExpiresAtMs': past.millisecondsSinceEpoch,
      };
      expect(canAddBusiness([cached], now: now), isFalse);
    });
  });
}
