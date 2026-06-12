import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/activity.dart';
import '../models/habit.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'habit_tracker.db');
    return openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE habits (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT NOT NULL DEFAULT '',
            color_name TEXT NOT NULL DEFAULT 'blue',
            icon_name TEXT NOT NULL DEFAULT 'check_circle',
            created_at INTEGER NOT NULL,
            is_archived INTEGER NOT NULL DEFAULT 0,
            reminder_hour INTEGER,
            reminder_minute INTEGER,
            habit_type TEXT NOT NULL DEFAULT 'build',
            tracking_type TEXT NOT NULL DEFAULT 'checkoff',
            target_amount INTEGER NOT NULL DEFAULT 1,
            unit TEXT NOT NULL DEFAULT '',
            anchor TEXT NOT NULL DEFAULT '',
            fallback_behavior TEXT NOT NULL DEFAULT '',
            celebration TEXT NOT NULL DEFAULT '',
            path_name TEXT NOT NULL DEFAULT '',
            difficulty TEXT NOT NULL DEFAULT 'tiny'
          )
        ''');
        await db.execute('''
          CREATE TABLE completions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            habit_id INTEGER NOT NULL,
            date INTEGER NOT NULL,
            amount INTEGER NOT NULL DEFAULT 1,
            note TEXT NOT NULL DEFAULT '',
            FOREIGN KEY (habit_id) REFERENCES habits (id) ON DELETE CASCADE,
            UNIQUE (habit_id, date)
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_completions_habit_id ON completions (habit_id)',
        );
        await db.execute('''
          CREATE TABLE settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
        await _createActivityTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Migrate from v1 to v2: add new columns
          await db.execute(
            "ALTER TABLE habits ADD COLUMN habit_type TEXT NOT NULL DEFAULT 'build'",
          );
          await db.execute(
            "ALTER TABLE habits ADD COLUMN tracking_type TEXT NOT NULL DEFAULT 'checkoff'",
          );
          await db.execute(
            "ALTER TABLE habits ADD COLUMN target_amount INTEGER NOT NULL DEFAULT 1",
          );
          await db.execute(
            "ALTER TABLE habits ADD COLUMN unit TEXT NOT NULL DEFAULT ''",
          );
          await db.execute(
            "ALTER TABLE completions ADD COLUMN amount INTEGER NOT NULL DEFAULT 1",
          );
          await db.execute(
            "ALTER TABLE completions ADD COLUMN note TEXT NOT NULL DEFAULT ''",
          );
        }
        if (oldVersion < 3) {
          await db.execute(
            "ALTER TABLE habits ADD COLUMN anchor TEXT NOT NULL DEFAULT ''",
          );
          await db.execute(
            "ALTER TABLE habits ADD COLUMN fallback_behavior TEXT NOT NULL DEFAULT ''",
          );
          await db.execute(
            "ALTER TABLE habits ADD COLUMN celebration TEXT NOT NULL DEFAULT ''",
          );
          await db.execute(
            "ALTER TABLE habits ADD COLUMN path_name TEXT NOT NULL DEFAULT ''",
          );
          await db.execute(
            "ALTER TABLE habits ADD COLUMN difficulty TEXT NOT NULL DEFAULT 'tiny'",
          );
          await db.execute('''
            CREATE TABLE IF NOT EXISTS settings (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 4) {
          await _createActivityTables(db);
        }
      },
    );
  }

  Future<void> _createActivityTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL,
        intensity TEXT NOT NULL DEFAULT 'Moderate',
        notes TEXT NOT NULL DEFAULT '',
        completed_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS local_groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        activity_type TEXT NOT NULL,
        area TEXT NOT NULL,
        privacy TEXT NOT NULL DEFAULT 'public',
        skill_level TEXT NOT NULL DEFAULT 'All',
        joined INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  // -- Habits --

  Future<List<Habit>> getActiveHabits() async {
    final db = await database;
    final rows = await db.query(
      'habits',
      where: 'is_archived = 0',
      orderBy: 'created_at DESC',
    );
    return rows.map(Habit.fromMap).toList();
  }

  Future<int> insertHabit(Habit habit) async {
    final db = await database;
    final map = habit.toMap()..remove('id');
    return db.insert('habits', map);
  }

  Future<void> updateHabit(Habit habit) async {
    if (habit.id == null) {
      throw ArgumentError('Cannot update a habit without an id');
    }
    final db = await database;
    await db.update(
      'habits',
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  Future<void> deleteHabit(int habitId) async {
    final db = await database;
    await db.delete('completions', where: 'habit_id = ?', whereArgs: [habitId]);
    await db.delete('habits', where: 'id = ?', whereArgs: [habitId]);
  }

  // -- Completions --

  Future<List<Completion>> getCompletionsForHabit(int habitId) async {
    final db = await database;
    final rows = await db.query(
      'completions',
      where: 'habit_id = ?',
      whereArgs: [habitId],
      orderBy: 'date DESC',
    );
    return rows.map(Completion.fromMap).toList();
  }

  Future<void> addCompletion(int habitId, DateTime date,
      {int amount = 1, String note = ''}) async {
    final db = await database;
    final dayKey = DateTime(date.year, date.month, date.day);
    await db.insert(
      'completions',
      {
        'habit_id': habitId,
        'date': dayKey.millisecondsSinceEpoch,
        'amount': amount,
        'note': note,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeCompletion(int habitId, DateTime date) async {
    final db = await database;
    final dayKey = DateTime(date.year, date.month, date.day);
    await db.delete(
      'completions',
      where: 'habit_id = ? AND date = ?',
      whereArgs: [habitId, dayKey.millisecondsSinceEpoch],
    );
  }

  Future<void> updateCompletionNote(
      int habitId, DateTime date, String note) async {
    final db = await database;
    final dayKey = DateTime(date.year, date.month, date.day);
    await db.update(
      'completions',
      {'note': note},
      where: 'habit_id = ? AND date = ?',
      whereArgs: [habitId, dayKey.millisecondsSinceEpoch],
    );
  }

  Future<Completion?> getCompletion(int habitId, DateTime date) async {
    final db = await database;
    final dayKey = DateTime(date.year, date.month, date.day);
    final rows = await db.query(
      'completions',
      where: 'habit_id = ? AND date = ?',
      whereArgs: [habitId, dayKey.millisecondsSinceEpoch],
    );
    if (rows.isEmpty) return null;
    return Completion.fromMap(rows.first);
  }

  // -- Settings --

  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // -- Activities --

  Future<List<ActivityLog>> getActivities() async {
    final db = await database;
    final rows = await db.query('activities', orderBy: 'completed_at DESC');
    return rows.map(ActivityLog.fromMap).toList();
  }

  Future<int> insertActivity(ActivityLog activity) async {
    final db = await database;
    final map = activity.toMap()..remove('id');
    return db.insert('activities', map);
  }

  Future<void> deleteActivity(int activityId) async {
    final db = await database;
    await db.delete('activities', where: 'id = ?', whereArgs: [activityId]);
  }

  // -- Local groups --

  Future<List<LocalGroup>> getLocalGroups() async {
    final db = await database;
    final rows = await db.query('local_groups', orderBy: 'created_at DESC');
    return rows.map(LocalGroup.fromMap).toList();
  }

  Future<int> insertLocalGroup(LocalGroup group) async {
    final db = await database;
    final map = group.toMap()..remove('id');
    return db.insert('local_groups', map);
  }

  Future<void> updateLocalGroup(LocalGroup group) async {
    if (group.id == null) return;
    final db = await database;
    await db.update(
      'local_groups',
      group.toMap(),
      where: 'id = ?',
      whereArgs: [group.id],
    );
  }
}
