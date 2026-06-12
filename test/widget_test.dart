import 'package:flutter_test/flutter_test.dart';

import 'package:habit_tracker/main.dart';
import 'package:habit_tracker/services/habit_provider.dart';

void main() {
  testWidgets('shows ActivHealth onboarding', (WidgetTester tester) async {
    await tester.pumpWidget(
      HabitTrackerApp(habitProvider: HabitProvider()),
    );
    await tester.pumpAndSettle();

    expect(find.text('ActivHealth'), findsOneWidget);
    expect(
      find.text('Question 1 of 4'),
      findsOneWidget,
    );
    expect(
      find.text('Which routine looks most like your life right now?'),
      findsOneWidget,
    );
    expect(find.text('Gym or training focused'), findsOneWidget);
    expect(find.text('Runner or walker'), findsOneWidget);
  });
}
