class TimeEntry {
  const TimeEntry({
    required this.id,
    required this.activityId,
    required this.startedAt,
    required this.endedAt,
    required this.duration,
    required this.createdAt,
  });

  final String id;
  final String activityId;
  final DateTime startedAt;
  final DateTime endedAt;
  final Duration duration;
  final DateTime createdAt;
}
