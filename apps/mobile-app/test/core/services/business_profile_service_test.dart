import 'package:flutter_test/flutter_test.dart';
import 'package:mali_up/core/services/business_profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('caches the business list for offline read-only rendering', () async {
    await BusinessProfileService.cacheProfile('user-1', {
      'selectedBusinessId': 'business-2',
      'plan': 'growth',
      'businesses': [
        {
          'id': 'business-1',
          'businessName': 'Duka Moja',
          'businessCategory': 'retail',
          'city': 'Dar es Salaam',
          'logoUrl': 'https://example.com/logo.png',
          'serverOnlyField': 'not cached',
        },
        {'id': 'business-2', 'businessName': 'Duka Mbili', 'hasWebsite': true},
      ],
    });

    final cached = await BusinessProfileService.loadCachedProfile('user-1');
    final businesses = cached?['businesses'] as List<dynamic>;

    expect(cached?['selectedBusinessId'], 'business-2');
    expect(cached?['plan'], 'growth');
    expect(businesses, hasLength(2));
    expect(
      (businesses.first as Map<String, dynamic>)['businessName'],
      'Duka Moja',
    );
    expect(
      (businesses.first as Map<String, dynamic>).containsKey('serverOnlyField'),
      isFalse,
    );
  });

  test('does not return another user cache', () async {
    await BusinessProfileService.cacheProfile('user-1', {
      'businesses': [
        {'id': 'business-1', 'businessName': 'Duka Moja'},
      ],
    });

    expect(await BusinessProfileService.loadCachedProfile('user-2'), isNull);
  });
}
