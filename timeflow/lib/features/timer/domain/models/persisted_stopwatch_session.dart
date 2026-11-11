enum PersistedStopwatchStatus { running, paused, stopped }

class PersistedStopwatchSession {
  const PersistedStopwatchSession({
    required this.status,
    required this.activityId,
    required this.startedAt,
    required this.accumulated,
    this.endedAt,
    this.lastResumedAt,
    this.lastResumedElapsedRealtime,
    this.bootCount,
  });

  final PersistedStopwatchStatus status;
  final String activityId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final Duration accumulated;
  final DateTime? lastResumedAt;
  final Duration? lastResumedElapsedRealtime;
  final int? bootCount;

  Map<String, Object?> toJson() => {
    'status': status.name,
    'activityId': activityId,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt?.toIso8601String(),
    'accumulatedMicroseconds': accumulated.inMicroseconds,
    'lastResumedAt': lastResumedAt?.toIso8601String(),
    'lastResumedElapsedRealtimeMicroseconds':
        lastResumedElapsedRealtime?.inMicroseconds,
    'bootCount': bootCount,
  };

  factory PersistedStopwatchSession.fromJson(Map<String, Object?> json) {
    final statusName = json['status'] as String;
    return PersistedStopwatchSession(
      status: PersistedStopwatchStatus.values.byName(statusName),
      activityId: json['activityId'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt:
          json['endedAt'] == null
              ? null
              : DateTime.parse(json['endedAt'] as String),
      accumulated: Duration(
        microseconds: json['accumulatedMicroseconds'] as int,
      ),
      lastResumedAt:
          json['lastResumedAt'] == null
              ? null
              : DateTime.parse(json['lastResumedAt'] as String),
      lastResumedElapsedRealtime:
          json['lastResumedElapsedRealtimeMicroseconds'] == null
              ? null
              : Duration(
                microseconds:
                    json['lastResumedElapsedRealtimeMicroseconds'] as int,
              ),
      bootCount: json['bootCount'] as int?,
    );
  }
}
