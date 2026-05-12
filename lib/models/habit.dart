/// A single habit the user is tracking.
class Habit {
  final int? id;
  final String name;
  final String description;
  final String colorName; // "blue", "red", etc. — kept as string for portability
  final String iconName;  // Material icon name (see icon_helper.dart)
  final DateTime createdAt;
  final bool isArchived;
  final int? reminderHour;   // 0-23, null = no reminder
  final int? reminderMinute; // 0-59, null = no reminder

  const Habit({
    this.id,
    required this.name,
    this.description = '',
    this.colorName = 'blue',
    this.iconName = 'check_circle',
    required this.createdAt,
    this.isArchived = false,
    this.reminderHour,
    this.reminderMinute,
  });

  bool get hasReminder => reminderHour != null && reminderMinute != null;

  Habit copyWith({
    int? id,
    String? name,
    String? description,
    String? colorName,
    String? iconName,
    DateTime? createdAt,
    bool? isArchived,
    int? reminderHour,
    int? reminderMinute,
    bool clearReminder = false,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      colorName: colorName ?? this.colorName,
      iconName: iconName ?? this.iconName,
      createdAt: createdAt ?? this.createdAt,
      isArchived: isArchived ?? this.isArchived,
      reminderHour: clearReminder ? null : (reminderHour ?? this.reminderHour),
      reminderMinute: clearReminder ? null : (reminderMinute ?? this.reminderMinute),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color_name': colorName,
      'icon_name': iconName,
      'created_at': createdAt.millisecondsSinceEpoch,
      'is_archived': isArchived ? 1 : 0,
      'reminder_hour': reminderHour,
      'reminder_minute': reminderMinute,
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: (map['description'] as String?) ?? '',
      colorName: (map['color_name'] as String?) ?? 'blue',
      iconName: (map['icon_name'] as String?) ?? 'check_circle',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      isArchived: (map['is_archived'] as int) == 1,
      reminderHour: map['reminder_hour'] as int?,
      reminderMinute: map['reminder_minute'] as int?,
    );
  }
}

/// A single completion event for a habit on a specific date.
class Completion {
  final int? id;
  final int habitId;
  final DateTime date;

  const Completion({
    this.id,
    required this.habitId,
    required this.date,
  });

  /// Returns the date with time zeroed out, in local time. We store
  /// completions normalized to midnight so we can dedupe per day.
  DateTime get dayKey => DateTime(date.year, date.month, date.day);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habit_id': habitId,
      // Store as the start-of-day millis so dedupe is straightforward.
      'date': dayKey.millisecondsSinceEpoch,
    };
  }

  factory Completion.fromMap(Map<String, dynamic> map) {
    return Completion(
      id: map['id'] as int?,
      habitId: map['habit_id'] as int,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
    );
  }
}
