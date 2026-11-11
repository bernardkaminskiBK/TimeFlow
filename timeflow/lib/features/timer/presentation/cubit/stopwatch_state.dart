enum StopwatchStatus { ready, running, paused, stopped }

enum StopwatchCommandResult {
  success,
  noSelectedActivity,
  sessionAlreadyExists,
  invalidTransition,
}

class StopwatchState {
  const StopwatchState({
    this.status = StopwatchStatus.ready,
    this.activityId,
    this.startedAt,
    this.endedAt,
    this.elapsed = Duration.zero,
  });

  final StopwatchStatus status;
  final String? activityId;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final Duration elapsed;

  bool get hasSession => status != StopwatchStatus.ready;
}
