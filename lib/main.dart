import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/security_gate.dart';
import 'services/habit_provider.dart';
import 'services/notification_service.dart';
import 'services/supabase_config.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cloud backend (community + geo). Guarded: the app is local-first and must
  // keep working — habits, coach, and stats — even if init fails or the
  // device is offline.
  if (SupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.publishableKey,
      );
    } catch (e) {
      debugPrint('Supabase init failed (continuing local-first): $e');
    }
  }

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
        // Midnight Coach: dark-first, single accent, one theme — no
        // half-supported light variant (the old system-follow dark mode
        // rendered an unbranded, illegible indigo theme).
        theme: buildMidnightTheme(),
        darkTheme: buildMidnightTheme(),
        themeMode: ThemeMode.dark,
        home: const SecurityGate(),
      ),
    );
  }
}
