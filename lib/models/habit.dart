/// A single habit the user is tracking.
class Habit {
  final int? id;
  final String name;
  final String description;
  final String colorName;
  final String iconName;
  final DateTime createdAt;
  final bool isArchived;
  final int? reminderHour;
  final int? reminderMinute;

  // v2: Build or Quit habit
  // "build" = developing a new habit (default)
  // "quit" = breaking a bad habit (tracks days since last occurrence)
  final String habitType; // "build" or "quit"

  // v2: Flexible goal tracking
  // "checkoff" = simple done/not done (default)
  // "amount" = track a quantity (glasses, minutes, pages, etc.)
  final String trackingType; // "checkoff" or "amount"
  final int targetAmount; // e.g., 8 glasses, 30 minutes
  final String unit; // e.g., "glasses", "minutes", "pages", "km"

  // v3: ActivHealth behavior loop
  // A complete loop is: After I... -> I will... -> if life gets in the way... -> I celebrate by...
  final String anchor;
  final String fallbackBehavior;
  final String celebration;
  final String pathName;
  final String difficulty; // "tiny", "manageable", "challenging"

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
    this.habitType = 'build',
    this.trackingType = 'checkoff',
    this.targetAmount = 1,
    this.unit = '',
    this.anchor = '',
    this.fallbackBehavior = '',
    this.celebration = '',
    this.pathName = '',
    this.difficulty = 'tiny',
  });

  bool get hasReminder => reminderHour != null && reminderMinute != null;
  bool get isQuitHabit => habitType == 'quit';
  bool get isAmountTracking => trackingType == 'amount';

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
    String? habitType,
    String? trackingType,
    int? targetAmount,
    String? unit,
    String? anchor,
    String? fallbackBehavior,
    String? celebration,
    String? pathName,
    String? difficulty,
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
      reminderMinute:
          clearReminder ? null : (reminderMinute ?? this.reminderMinute),
      habitType: habitType ?? this.habitType,
      trackingType: trackingType ?? this.trackingType,
      targetAmount: targetAmount ?? this.targetAmount,
      unit: unit ?? this.unit,
      anchor: anchor ?? this.anchor,
      fallbackBehavior: fallbackBehavior ?? this.fallbackBehavior,
      celebration: celebration ?? this.celebration,
      pathName: pathName ?? this.pathName,
      difficulty: difficulty ?? this.difficulty,
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
      'habit_type': habitType,
      'tracking_type': trackingType,
      'target_amount': targetAmount,
      'unit': unit,
      'anchor': anchor,
      'fallback_behavior': fallbackBehavior,
      'celebration': celebration,
      'path_name': pathName,
      'difficulty': difficulty,
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
      habitType: (map['habit_type'] as String?) ?? 'build',
      trackingType: (map['tracking_type'] as String?) ?? 'checkoff',
      targetAmount: (map['target_amount'] as int?) ?? 1,
      unit: (map['unit'] as String?) ?? '',
      anchor: (map['anchor'] as String?) ?? '',
      fallbackBehavior: (map['fallback_behavior'] as String?) ?? '',
      celebration: (map['celebration'] as String?) ?? '',
      pathName: (map['path_name'] as String?) ?? '',
      difficulty: (map['difficulty'] as String?) ?? 'tiny',
    );
  }
}

/// A single completion event for a habit on a specific date.
class Completion {
  final int? id;
  final int habitId;
  final DateTime date;
  final int
      amount; // v2: tracked amount (1 for checkoff, variable for amount tracking)
  final String note; // v2: diary note for this completion

  const Completion({
    this.id,
    required this.habitId,
    required this.date,
    this.amount = 1,
    this.note = '',
  });

  DateTime get dayKey => DateTime(date.year, date.month, date.day);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habit_id': habitId,
      'date': dayKey.millisecondsSinceEpoch,
      'amount': amount,
      'note': note,
    };
  }

  factory Completion.fromMap(Map<String, dynamic> map) {
    return Completion(
      id: map['id'] as int?,
      habitId: map['habit_id'] as int,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      amount: (map['amount'] as int?) ?? 1,
      note: (map['note'] as String?) ?? '',
    );
  }
}
