import 'package:flutter_test/flutter_test.dart';

import 'package:habit_tracker/main.dart';
import 'package:habit_tracker/services/habit_provider.dart';

void main() {
  testWidgets('shows ActivHealth onboarding', (WidgetTester tester) async {
    await tester.pumpWidget(
      HabitTrackerApp(habitProvider: HabitProvider()),
    );

    expect(find.text('ActivHealth'), findsOneWidget);
    expect(
        find.text('Choose the loop you want to improve first'), findsOneWidget);
    expect(find.text('Health & Energy'), findsOneWidget);
  });
}
