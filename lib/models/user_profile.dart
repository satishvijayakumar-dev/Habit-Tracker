class UserProfile {
  final int? id;
  final int age;
  final String sex;
  final double heightCm;
  final double weightKg;
  final String fitnessGoal;
  final String activityLevel;
  final String areaName;
  final bool shareApproxLocation;
  final DateTime updatedAt;

  const UserProfile({
    this.id,
    required this.age,
    required this.sex,
    required this.heightCm,
    required this.weightKg,
    required this.fitnessGoal,
    required this.activityLevel,
    required this.areaName,
    required this.shareApproxLocation,
    required this.updatedAt,
  });

  bool get isComplete => age > 0 && heightCm > 0 && weightKg > 0;

  double get bmi {
    if (heightCm <= 0 || weightKg <= 0) return 0;
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  String get bmiLabel {
    final value = bmi;
    if (value == 0) return 'Unknown';
    if (value < 18.5) return 'Underweight';
    if (value < 25) return 'Healthy range';
    if (value < 30) return 'Overweight range';
    return 'Higher range';
  }

  UserProfile copyWith({
    int? id,
    int? age,
    String? sex,
    double? heightCm,
    double? weightKg,
    String? fitnessGoal,
    String? activityLevel,
    String? areaName,
    bool? shareApproxLocation,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      age: age ?? this.age,
      sex: sex ?? this.sex,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      activityLevel: activityLevel ?? this.activityLevel,
      areaName: areaName ?? this.areaName,
      shareApproxLocation: shareApproxLocation ?? this.shareApproxLocation,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'age': age,
      'sex': sex,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'fitness_goal': fitnessGoal,
      'activity_level': activityLevel,
      'area_name': areaName,
      'share_approx_location': shareApproxLocation ? 1 : 0,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as int?,
      age: map['age'] as int,
      sex: map['sex'] as String,
      heightCm: (map['height_cm'] as num).toDouble(),
      weightKg: (map['weight_kg'] as num).toDouble(),
      fitnessGoal: map['fitness_goal'] as String,
      activityLevel: map['activity_level'] as String,
      areaName: map['area_name'] as String,
      shareApproxLocation: (map['share_approx_location'] as int? ?? 0) == 1,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }
}

class BodyMetric {
  final int? id;
  final double weightKg;
  final double? waistCm;
  final String note;
  final DateTime recordedAt;

  const BodyMetric({
    this.id,
    required this.weightKg,
    this.waistCm,
    this.note = '',
    required this.recordedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'weight_kg': weightKg,
      'waist_cm': waistCm,
      'note': note,
      'recorded_at': recordedAt.millisecondsSinceEpoch,
    };
  }

  factory BodyMetric.fromMap(Map<String, dynamic> map) {
    return BodyMetric(
      id: map['id'] as int?,
      weightKg: (map['weight_kg'] as num).toDouble(),
      waistCm: (map['waist_cm'] as num?)?.toDouble(),
      note: (map['note'] as String?) ?? '',
      recordedAt: DateTime.fromMillisecondsSinceEpoch(
        map['recorded_at'] as int,
      ),
    );
  }
}
