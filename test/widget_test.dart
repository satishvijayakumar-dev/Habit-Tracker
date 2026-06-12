import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:habit_tracker/main.dart';
import 'package:habit_tracker/services/habit_provider.dart';

void main() {
  testWidgets('shows welcome, captures name, reaches the path quiz',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      HabitTrackerApp(habitProvider: HabitProvider()),
    );
    await tester.pumpAndSettle();

    // Beat 0: brand moment + name capture.
    expect(find.text('ActivHealth'), findsOneWidget);
    expect(find.text('Small loops. Real momentum.'), findsOneWidget);
    expect(
      find.text('What should your coach call you?'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), 'Sam');
    await tester.tap(find.text('Find my path'));
    await tester.pumpAndSettle();

    // Question 1 of the path quiz.
    expect(find.text('Question 1 of 4'), findsOneWidget);
    expect(
      find.text('Which routine looks most like your life right now?'),
      findsOneWidget,
    );
    expect(find.text('Gym or training focused'), findsOneWidget);
    expect(find.text('Runner or walker'), findsOneWidget);
  });
}
