import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/security_gate.dart';
import 'services/habit_provider.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await NotificationService.instance.init();
  } catch (e) {
    debugPrint('Notification init failed: $e');
  }

  final habitProvider = HabitProvider();
  await habitProvider.load();

  runApp(HabitTrackerApp(habitProvider: habitProvider));
}

class HabitTrackerApp extends StatelessWidget {
  final HabitProvider habitProvider;

  const HabitTrackerApp({super.key, required this.habitProvider});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: habitProvider,
      child: MaterialApp(
        title: 'ActivHealth',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFE53935),
            primary: const Color(0xFFE53935),
            secondary: const Color(0xFF0E9F6E),
            tertiary: const Color(0xFF2563EB),
            surface: const Color(0xFFFFFBFA),
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFFFFBFA),
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            backgroundColor: Color(0xFFFFFBFA),
            surfaceTintColor: Colors.transparent,
          ),
          cardTheme: CardThemeData(
            elevation: 0.5,
            shadowColor: const Color(0x22000000),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xFFF0E7E5)),
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: Colors.white,
            indicatorColor: const Color(0xFFFFE4E2),
            labelTextStyle: WidgetStateProperty.all(
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: const SecurityGate(),
      ),
    );
  }
}
