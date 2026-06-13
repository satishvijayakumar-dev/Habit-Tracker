import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:habit_tracker/screens/paywall_screen.dart';
import 'package:habit_tracker/services/habit_provider.dart';
import 'package:habit_tracker/theme/app_theme.dart';

import 'helpers/in_memory_store.dart';

/// PaywallScreen in isolation — no IndexedStack, no perpetual animation,
/// so pumpAndSettle and scrollUntilVisible work normally here.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('paywall shows pricing and the beta unlock flips the user to Pro',
      (tester) async {
    final provider = HabitProvider(store: InMemoryHabitStore());
    await provider.load();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          theme: buildMidnightTheme(),
          home: const PaywallScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ActivHealth Pro'), findsWidgets);
    expect(find.text('£3.99'), findsOneWidget);
    expect(find.text('£24.99'), findsOneWidget);
    expect(provider.isPro, isFalse);

    // Unlock button lives at the bottom of the list — scroll it in.
    final unlock = find.text('Unlock Pro — free during beta');
    await tester.scrollUntilVisible(unlock, 200);
    await tester.tap(unlock);
    await tester.pumpAndSettle();

    expect(provider.isPro, isTrue);
  });
}
