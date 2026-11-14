import 'package:flutter_test/flutter_test.dart';
import 'package:mali_up/core/services/localization_service.dart';
import 'package:mali_up/core/services/push_notification_service.dart';

// Topic names must match topicsFor() in functions/src/notifications.ts.
void main() {
  group('PushTopics', () {
    test('all-users topic carries the app language', () {
      expect(PushTopics.all(AppLanguage.swahili), 'all_sw');
      expect(PushTopics.all(AppLanguage.english), 'all_en');
    });

    test('business topic uses the business id and language', () {
      expect(PushTopics.business('abc123', AppLanguage.swahili), 'biz_abc123_sw');
    });

    test('characters FCM rejects are replaced', () {
      expect(PushTopics.business('a/b c', AppLanguage.english), 'biz_a_b_c_en');
    });

    test('forUser skips the business topic until a business exists', () {
      expect(
        PushTopics.forUser(
          businessId: '',
          language: AppLanguage.english,
          isOwner: false,
        ),
        {'all_en'},
      );
      expect(
        PushTopics.forUser(
          businessId: 'x1',
          language: AppLanguage.swahili,
          isOwner: false,
        ),
        {'all_sw', 'biz_x1_sw'},
      );
    });

    test('only owners get the owner-only channels', () {
      expect(
        PushTopics.forUser(
          businessId: 'x1',
          language: AppLanguage.swahili,
          isOwner: true,
        ),
        {'all_sw', 'biz_x1_sw', 'owners_sw', 'biz_x1_owners_sw'},
      );
    });
  });
}
