import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habit_tracker/main.dart';
import 'package:habit_tracker/services/habit_provider.dart';
import 'package:habit_tracker/widgets/habit_tile.dart';
import 'package:habit_tracker/widgets/momentum_ring.dart';

import 'helpers/in_memory_store.dart';

/// End-to-end emotional core: welcome -> name -> path quiz -> persona
/// reveal -> starter loops -> Today (ring + 1-tap check-in + celebration).
///
/// HomeShell's IndexedStack keeps the Coach tab's pulse animation running,
/// so pumpAndSettle would never idle — drive with bounded pumps.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('first-run journey ends in a celebrated check-in',
      (tester) async {
    final provider = HabitProvider(store: InMemoryHabitStore());
    await provider.load();
    await tester.pumpWidget(HabitTrackerApp(habitProvider: provider));
    await tester.pumpAndSettle();

    // ---- Welcome beat: name capture ----
    expect(find.text('Small loops. Real momentum.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Sam');
    await tester.tap(find.text('Find my path'));
    await tester.pumpAndSettle();

    // ---- Path quiz: 4 gym-leaning answers ----
    const answers = [
      'Gym or training focused',
      'Strength and energy',
      'Low energy',
      'Fuel training',
    ];
    for (final answer in answers) {
      await tester.ensureVisible(find.text(answer));
      await tester.tap(find.text(answer));
      await tester.pumpAndSettle();
    }

    // ---- Persona reveal, personalised ----
    expect(find.text('Sam, your path is'), findsOneWidget);
    expect(find.text('The Gym Builder'), findsOneWidget);

    await tester.tap(find.text('Start my first loops'));
    await settle(tester);

    // ---- Today ----
    expect(provider.habits.length, 3);
    expect(find.byType(MomentumRing), findsOneWidget);

    // The coach greets the user in a pop-up on open — dismiss it first.
    if (find.text('Maybe later').evaluate().isNotEmpty) {
      await tester.tap(find.text('Maybe later'));
      await settle(tester);
    }

    // The loops sit below the fold in the lazy ListView — scroll (from a
    // fixed screen point, so it works even as widgets scroll off) until all
    // three tiles have built.
    for (var i = 0;
        i < 10 && find.byType(HabitTile).evaluate().length < 3;
        i++) {
      await tester.dragFrom(const Offset(200, 400), const Offset(0, -240));
      await settle(tester);
    }
    expect(find.byType(HabitTile), findsNWidgets(3));

    // ---- 1-tap check-in fires a celebration ----
    final checkAction = find.bySemanticsLabel(RegExp('^Complete ')).first;
    await tester.tap(checkAction);
    await settle(tester);

    expect(provider.completedTodayCount, 1);
    expect(find.byType(SnackBar), findsOneWidget);

    // Drain the celebration snackbar before teardown.
    await tester.pump(const Duration(seconds: 2));
  });
}

/// Advances pending async work, one-shot animations, and route
/// transitions without requiring the whole tree to go idle.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}
