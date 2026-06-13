import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/services/notification_service.dart';

/// Covers the only non-plugin logic in NotificationService: deciding
/// whether a daily reminder fires today or rolls to tomorrow.
void main() {
  group('rollsToTomorrow', () {
    final now = DateTime(2026, 6, 13, 14, 30); // 14:30

    test('a later time today fires today', () {
      expect(NotificationService.rollsToTomorrow(now, 18, 0), isFalse);
    });

    test('an earlier time today rolls to tomorrow', () {
      expect(NotificationService.rollsToTomorrow(now, 9, 0), isTrue);
    });

    test('the same minute counts as passed (rolls to tomorrow)', () {
      expect(NotificationService.rollsToTomorrow(now, 14, 30), isTrue);
    });

    test('one minute later still fires today', () {
      expect(NotificationService.rollsToTomorrow(now, 14, 31), isFalse);
    });

    test('midnight reminder when it is already past midnight rolls over', () {
      final justAfterMidnight = DateTime(2026, 6, 13, 0, 5);
      expect(
        NotificationService.rollsToTomorrow(justAfterMidnight, 0, 0),
        isTrue,
      );
    });
  });
}
