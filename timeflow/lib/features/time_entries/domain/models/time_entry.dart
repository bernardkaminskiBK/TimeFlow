class TimeEntry {
  const TimeEntry({
    required this.id,
    required this.activityId,
    required this.startedAt,
    required this.endedAt,
    required this.duration,
    required this.createdAt,
    this.note,
  });

  final String id;
  final String activityId;
  final DateTime startedAt;
  final DateTime endedAt;
  final Duration duration;
  final DateTime createdAt;
  final String? note;

  TimeEntry copyWith({
    String? activityId,
    DateTime? startedAt,
    DateTime? endedAt,
    Duration? duration,
    String? note,
    bool clearNote = false,
  }) => TimeEntry(
    id: id,
    activityId: activityId ?? this.activityId,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt ?? this.endedAt,
    duration: duration ?? this.duration,
    createdAt: createdAt,
    note: clearNote ? null : note ?? this.note,
  );
}
