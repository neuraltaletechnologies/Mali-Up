import 'package:flutter_test/flutter_test.dart';
import 'package:mali_up/config/routing.dart';
import 'package:mali_up/core/services/default_context_routing_service.dart';

void main() {
  group('DefaultContextRoutingService.routeFromContextValue', () {
    test('routes business context to sales', () {
      final route =
          DefaultContextRoutingService.routeFromContextValue('business:uid123');

      expect(route, AppRouter.salesPath);
    });

    test('routes personal context to dashboard', () {
      final route =
          DefaultContextRoutingService.routeFromContextValue('personal');

      expect(route, AppRouter.dashboardPath);
    });

    test('falls back to dashboard for unknown/empty context', () {
      expect(
        DefaultContextRoutingService.routeFromContextValue(''),
        AppRouter.dashboardPath,
      );
      expect(
        DefaultContextRoutingService.routeFromContextValue('both'),
        AppRouter.dashboardPath,
      );
      expect(
        DefaultContextRoutingService.routeFromContextValue(null),
        AppRouter.dashboardPath,
      );
    });
  });

  group('DefaultContextRoutingService.routeFromUserProfile', () {
    test('uses defaultContext first when available', () {
      final businessRoute = DefaultContextRoutingService.routeFromUserProfile({
        'defaultContext': 'business:tenant42',
        'defaultAccountType': 'personal',
        'accountTypes': ['personal', 'business'],
      });
      final personalRoute = DefaultContextRoutingService.routeFromUserProfile({
        'defaultContext': 'personal',
        'defaultAccountType': 'business',
      });

      expect(businessRoute, AppRouter.salesPath);
      expect(personalRoute, AppRouter.dashboardPath);
    });

    test('falls back to defaultAccountType when defaultContext is missing', () {
      final route = DefaultContextRoutingService.routeFromUserProfile({
        'defaultAccountType': 'business',
      });

      expect(route, AppRouter.salesPath);
    });

    test('falls back to accountTypes for business-only profile', () {
      final route = DefaultContextRoutingService.routeFromUserProfile({
        'accountTypes': ['business'],
      });

      expect(route, AppRouter.salesPath);
    });

    test('falls back to dashboard for both/personal profile shape', () {
      final bothRoute = DefaultContextRoutingService.routeFromUserProfile({
        'accountTypes': ['personal', 'business'],
      });
      final personalRoute = DefaultContextRoutingService.routeFromUserProfile({
        'defaultAccountType': 'personal',
      });

      expect(bothRoute, AppRouter.dashboardPath);
      expect(personalRoute, AppRouter.dashboardPath);
    });
  });
}
