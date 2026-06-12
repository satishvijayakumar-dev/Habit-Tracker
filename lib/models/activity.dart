class ActivityLog {
  final int? id;
  final String type;
  final int durationMinutes;
  final String intensity;
  final String notes;
  final DateTime completedAt;

  const ActivityLog({
    this.id,
    required this.type,
    required this.durationMinutes,
    this.intensity = 'Moderate',
    this.notes = '',
    required this.completedAt,
  });

  DateTime get dayKey =>
      DateTime(completedAt.year, completedAt.month, completedAt.day);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'duration_minutes': durationMinutes,
      'intensity': intensity,
      'notes': notes,
      'completed_at': completedAt.millisecondsSinceEpoch,
    };
  }

  factory ActivityLog.fromMap(Map<String, dynamic> map) {
    return ActivityLog(
      id: map['id'] as int?,
      type: map['type'] as String,
      durationMinutes: map['duration_minutes'] as int,
      intensity: (map['intensity'] as String?) ?? 'Moderate',
      notes: (map['notes'] as String?) ?? '',
      completedAt: DateTime.fromMillisecondsSinceEpoch(
        map['completed_at'] as int,
      ),
    );
  }
}

class LocalGroup {
  final int? id;
  final String name;
  final String activityType;
  final String area;
  final String privacy;
  final String skillLevel;
  final bool joined;
  final DateTime createdAt;

  const LocalGroup({
    this.id,
    required this.name,
    required this.activityType,
    required this.area,
    this.privacy = 'public',
    this.skillLevel = 'All',
    this.joined = false,
    required this.createdAt,
  });

  LocalGroup copyWith({
    int? id,
    String? name,
    String? activityType,
    String? area,
    String? privacy,
    String? skillLevel,
    bool? joined,
    DateTime? createdAt,
  }) {
    return LocalGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      activityType: activityType ?? this.activityType,
      area: area ?? this.area,
      privacy: privacy ?? this.privacy,
      skillLevel: skillLevel ?? this.skillLevel,
      joined: joined ?? this.joined,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'activity_type': activityType,
      'area': area,
      'privacy': privacy,
      'skill_level': skillLevel,
      'joined': joined ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory LocalGroup.fromMap(Map<String, dynamic> map) {
    return LocalGroup(
      id: map['id'] as int?,
      name: map['name'] as String,
      activityType: map['activity_type'] as String,
      area: map['area'] as String,
      privacy: (map['privacy'] as String?) ?? 'public',
      skillLevel: (map['skill_level'] as String?) ?? 'All',
      joined: (map['joined'] as int? ?? 0) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['created_at'] as int,
      ),
    );
  }
}
