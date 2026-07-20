/// Health metric types — docs/api.md §8.
enum HealthMetricType {
  height,
  weight,
  bloodPressure,
}

/// Maps [HealthMetricType] to the wire string the backend expects.
String healthMetricTypeToWire(HealthMetricType t) {
  switch (t) {
    case HealthMetricType.height:
      return 'HEIGHT';
    case HealthMetricType.weight:
      return 'WEIGHT';
    case HealthMetricType.bloodPressure:
      return 'BLOOD_PRESSURE';
  }
}

/// Parses a wire string back to [HealthMetricType].
HealthMetricType healthMetricTypeFromWire(String? raw) {
  switch (raw?.toUpperCase()) {
    case 'HEIGHT':
      return HealthMetricType.height;
    case 'WEIGHT':
      return HealthMetricType.weight;
    case 'BLOOD_PRESSURE':
      return HealthMetricType.bloodPressure;
    default:
      return HealthMetricType.weight;
  }
}

/// A single health record — docs/api.md §8.1 / §8.2 / §8.3.
///
/// Uniqueness rule on the server: same user + same [metricType] + same
/// [recordedAt] date → upsert. Re-submitting today's weight is the
/// intended "edit" path; no separate update endpoint exists.
class HealthRecord {
  final int id;
  final int userId;
  final HealthMetricType metricType;
  final double value;
  final double? valueSecondary;
  final String recordedAt;

  const HealthRecord({
    required this.id,
    required this.userId,
    required this.metricType,
    required this.value,
    this.valueSecondary,
    required this.recordedAt,
  });

  factory HealthRecord.fromJson(Map<String, dynamic> json) {
    return HealthRecord(
      id: json['id'] as int,
      userId: json['userId'] as int,
      metricType: healthMetricTypeFromWire(json['metricType'] as String?),
      value: (json['value'] as num).toDouble(),
      valueSecondary: json['valueSecondary'] != null
          ? (json['valueSecondary'] as num).toDouble()
          : null,
      recordedAt: json['recordedAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'id': id,
      'userId': userId,
      'metricType': healthMetricTypeToWire(metricType),
      'value': value,
      'recordedAt': recordedAt,
    };
    if (valueSecondary != null) m['valueSecondary'] = valueSecondary;
    return m;
  }

  HealthRecord copyWith({
    int? id,
    int? userId,
    HealthMetricType? metricType,
    double? value,
    double? valueSecondary,
    String? recordedAt,
  }) {
    return HealthRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      metricType: metricType ?? this.metricType,
      value: value ?? this.value,
      valueSecondary: valueSecondary ?? this.valueSecondary,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }
}

/// One metric's visibility setting — docs/api.md §8.4 / §8.5.
class HealthVisibility {
  final HealthMetricType metricType;
  final bool visible;

  const HealthVisibility({required this.metricType, required this.visible});

  factory HealthVisibility.fromJson(Map<String, dynamic> json) {
    return HealthVisibility(
      metricType: healthMetricTypeFromWire(json['metricType'] as String?),
      visible: json['visible'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'metricType': healthMetricTypeToWire(metricType),
      'visible': visible,
    };
  }
}

/// Daily reminder settings — docs/api.md §8.6 / §8.7.
///
/// [remindTime] is a `HH:mm:ss` string (e.g. `"20:00:00"`), or `null`
/// when never configured. [enabled] is `false` by default.
class HealthReminder {
  final String? remindTime;
  final bool enabled;

  const HealthReminder({this.remindTime, this.enabled = false});

  factory HealthReminder.fromJson(Map<String, dynamic> json) {
    return HealthReminder(
      remindTime: json['remindTime'] as String?,
      enabled: json['enabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (remindTime != null) 'remindTime': remindTime,
      'enabled': enabled,
    };
  }

  HealthReminder copyWith({String? remindTime, bool? enabled}) {
    return HealthReminder(
      remindTime: remindTime ?? this.remindTime,
      enabled: enabled ?? this.enabled,
    );
  }
}
