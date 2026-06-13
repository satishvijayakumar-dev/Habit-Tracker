import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Directory? _docsDir;

/// Points sqflite at the FFI factory and path_provider at a temp folder,
/// so the real [DatabaseService] runs against real SQLite on the host.
Future<void> bootstrapTestDatabase() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  _docsDir ??= Directory.systemTemp.createTempSync('activhealth_test_');
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async => _docsDir!.path);
}

/// Wipes all rows (schema kept) so each test starts clean.
Future<void> clearDatabase() async {
  final db = await DatabaseService.instance.database;
  for (final table in [
    'habits',
    'completions',
    'settings',
    'activities',
    'local_groups',
    'user_profile',
    'body_metrics',
  ]) {
    await db.delete(table);
  }
}
