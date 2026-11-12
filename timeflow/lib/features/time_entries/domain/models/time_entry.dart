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

  TimeEntry withNote(String? value) => TimeEntry(
    id: id,
    activityId: activityId,
    startedAt: startedAt,
    endedAt: endedAt,
    duration: duration,
    createdAt: createdAt,
    note: value,
  );
}
