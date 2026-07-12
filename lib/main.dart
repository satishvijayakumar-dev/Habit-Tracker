import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/security_gate.dart';
import 'services/habit_provider.dart';
import 'services/notification_service.dart';
import 'services/supabase_config.dart';
import 'theme/app_theme.dart';

/// Crash/error reporting DSN, injected at build time:
///   flutter build ipa --dart-define=SENTRY_DSN=https://...@...ingest.sentry.io/...
/// When empty (default), Sentry stays off and the app boots normally — so
/// there's zero behaviour change until the DSN is set in Codemagic.
const String _sentryDsn = String.fromEnvironment('SENTRY_DSN');

Future<void> main() async {
  if (_sentryDsn.isEmpty) {
    await _bootstrap();
    return;
  }
  await SentryFlutter.init(
    (options) {
      options.dsn = _sentryDsn;
      options.tracesSampleRate = 0.2;
      // Health data is sensitive — never attach request bodies or PII.
      options.sendDefaultPii = false;
    },
    appRunner: _bootstrap,
  );
}

/// App startup, wrapped by Sentry's zone when a DSN is configured so uncaught
/// errors (Flutter + Dart) are captured automatically.
Future<void> _bootstrap() async {
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
