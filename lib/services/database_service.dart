import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/habit.dart';

/// Wraps the SQLite database. Single source of truth for persistence.
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
      version: 1,
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
            reminder_minute INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE completions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            habit_id INTEGER NOT NULL,
            date INTEGER NOT NULL,
            FOREIGN KEY (habit_id) REFERENCES habits (id) ON DELETE CASCADE,
            UNIQUE (habit_id, date)
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_completions_habit_id ON completions (habit_id)',
        );
      },
    );
  }

  // ── Habits ─────────────────────────────────────────────────────────────────

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
    // Cascade handles completions, but be explicit for safety on platforms
    // where foreign keys aren't enforced by default.
    await db.delete('completions', where: 'habit_id = ?', whereArgs: [habitId]);
    await db.delete('habits', where: 'id = ?', whereArgs: [habitId]);
  }

  // ── Completions ────────────────────────────────────────────────────────────

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

  /// Adds a completion for the given habit on the given date (normalized to
  /// midnight). The UNIQUE index makes this idempotent.
  Future<void> addCompletion(int habitId, DateTime date) async {
    final db = await database;
    final dayKey = DateTime(date.year, date.month, date.day);
    await db.insert(
      'completions',
      {
        'habit_id': habitId,
        'date': dayKey.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
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
}
