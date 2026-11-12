import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../time_entries/domain/models/time_entry.dart';
import '../../../time_entries/domain/repositories/time_entry_repository.dart';
import '../../domain/models/persisted_stopwatch_session.dart';
import '../../domain/repositories/stopwatch_session_repository.dart';
import 'elapsed_time_source.dart';
import 'session_clock.dart';
import 'stopwatch_state.dart';

/// Owns the application's single tracking session.
///
/// Live timing uses a monotonic stopwatch. The active session is persisted at
/// every state transition. On Android, elapsedRealtime and the boot count keep
/// recovery monotonic within one boot; wall time only bridges a device reboot.
class StopwatchCubit extends Cubit<StopwatchState> {
  StopwatchCubit(
    this._repository, {
    StopwatchSessionRepository? sessionRepository,
    ElapsedTimeSource? elapsedTimeSource,
    SessionClock? sessionClock,
    DateTime Function()? now,
  }) : _sessionRepository = sessionRepository ?? _NoopSessionRepository(),
       _elapsedTimeSource = elapsedTimeSource ?? SystemElapsedTimeSource(),
       _sessionClock = sessionClock ?? AndroidSessionClock(),
       _now = now ?? DateTime.now,
       super(const StopwatchState());

  final TimeEntryRepository _repository;
  final StopwatchSessionRepository _sessionRepository;
  final ElapsedTimeSource _elapsedTimeSource;
  final SessionClock _sessionClock;
  final DateTime Function() _now;
  Timer? _ticker;
  Duration _accumulated = Duration.zero;
  DateTime? _lastResumedAt;
  SessionClockSnapshot? _lastClockSnapshot;
  var _isSaving = false;
  var _isRestoring = false;

  bool get hasSession => state.hasSession;

  bool isActivityLocked(String activityId) =>
      state.hasSession && state.activityId == activityId;

  Duration get _elapsed => _accumulated + _elapsedTimeSource.elapsed;

  Future<void> restore() async {
    if (_isRestoring || state.hasSession) return;
    _isRestoring = true;
    try {
      final session = await _sessionRepository.loadSession();
      if (session == null) return;

      final restoredStatus = StopwatchStatus.values.byName(session.status.name);

      _accumulated = session.accumulated;
      if (restoredStatus == StopwatchStatus.running) {
        final now = _now();
        final currentClock = await _sessionClock.snapshot();
        _accumulated += _restoredRunningDuration(
          session: session,
          now: now,
          currentClock: currentClock,
        );
        _lastResumedAt = now;
        _lastClockSnapshot = currentClock;
        _elapsedTimeSource
          ..reset()
          ..start();
      }

      emit(
        StopwatchState(
          status: restoredStatus,
          activityId: session.activityId,
          startedAt: session.startedAt,
          endedAt: session.endedAt,
          elapsed: _elapsed,
        ),
      );
      if (restoredStatus == StopwatchStatus.running) {
        _startTicker();
        await _persistSession();
      }
    } finally {
      _isRestoring = false;
    }
  }

  Future<StopwatchCommandResult> start(String? activityId) async {
    if (state.hasSession) {
      return StopwatchCommandResult.sessionAlreadyExists;
    }
    if (activityId == null || activityId.isEmpty) {
      return StopwatchCommandResult.noSelectedActivity;
    }

    _accumulated = Duration.zero;
    _lastResumedAt = _now();
    _lastClockSnapshot = null;
    _elapsedTimeSource
      ..reset()
      ..start();
    emit(
      StopwatchState(
        status: StopwatchStatus.running,
        activityId: activityId,
        startedAt: _lastResumedAt,
      ),
    );
    _startTicker();
    _lastClockSnapshot = await _sessionClock.snapshot();
    await _persistSession();
    return StopwatchCommandResult.success;
  }

  Future<StopwatchCommandResult> pause() async {
    if (state.status != StopwatchStatus.running) {
      return StopwatchCommandResult.invalidTransition;
    }
    _freezeElapsedSource();
    _ticker?.cancel();
    _emitSession(StopwatchStatus.paused);
    await _persistSession();
    return StopwatchCommandResult.success;
  }

  Future<StopwatchCommandResult> resume() async {
    if (state.status != StopwatchStatus.paused &&
        state.status != StopwatchStatus.stopped) {
      return StopwatchCommandResult.invalidTransition;
    }
    _lastResumedAt = _now();
    _lastClockSnapshot = null;
    _elapsedTimeSource
      ..reset()
      ..start();
    emit(
      StopwatchState(
        status: StopwatchStatus.running,
        activityId: state.activityId,
        startedAt: state.startedAt,
        elapsed: _elapsed,
      ),
    );
    _startTicker();
    _lastClockSnapshot = await _sessionClock.snapshot();
    await _persistSession();
    return StopwatchCommandResult.success;
  }

  Future<StopwatchCommandResult> stop() async {
    if (state.status != StopwatchStatus.running &&
        state.status != StopwatchStatus.paused) {
      return StopwatchCommandResult.invalidTransition;
    }
    if (state.status == StopwatchStatus.running) _freezeElapsedSource();
    _ticker?.cancel();
    _emitSession(StopwatchStatus.stopped, endedAt: _now());
    await _persistSession();
    return StopwatchCommandResult.success;
  }

  Future<StopwatchCommandResult> save() async {
    if (state.status != StopwatchStatus.stopped || _isSaving) {
      return StopwatchCommandResult.invalidTransition;
    }

    final activityId = state.activityId;
    final startedAt = state.startedAt;
    final endedAt = state.endedAt;
    if (activityId == null || startedAt == null || endedAt == null) {
      return StopwatchCommandResult.invalidTransition;
    }

    _isSaving = true;
    try {
      final createdAt = _now();
      await _repository.saveEntry(
        TimeEntry(
          id: 'session-${startedAt.microsecondsSinceEpoch}-$activityId',
          activityId: activityId,
          startedAt: startedAt,
          endedAt: endedAt,
          duration: _accumulated,
          createdAt: createdAt,
        ),
      );
      await _reset();
      return StopwatchCommandResult.success;
    } finally {
      _isSaving = false;
    }
  }

  Future<StopwatchCommandResult> discard() async {
    if (state.status != StopwatchStatus.stopped) {
      return StopwatchCommandResult.invalidTransition;
    }
    await _reset();
    return StopwatchCommandResult.success;
  }

  void refresh() {
    if (state.status == StopwatchStatus.running) {
      _emitSession(StopwatchStatus.running);
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => refresh(),
    );
  }

  Duration _restoredRunningDuration({
    required PersistedStopwatchSession session,
    required DateTime now,
    required SessionClockSnapshot? currentClock,
  }) {
    final savedElapsedRealtime = session.lastResumedElapsedRealtime;
    final sameBoot =
        currentClock != null &&
        currentClock.bootCount != null &&
        session.bootCount != null &&
        currentClock.bootCount == session.bootCount &&
        savedElapsedRealtime != null;
    if (sameBoot) {
      return _nonNegative(currentClock.elapsedRealtime - savedElapsedRealtime);
    }

    final lastResumedAt = session.lastResumedAt;
    return lastResumedAt == null
        ? Duration.zero
        : _nonNegative(now.difference(lastResumedAt));
  }

  Duration _nonNegative(Duration duration) =>
      duration.isNegative ? Duration.zero : duration;

  void _freezeElapsedSource() {
    _accumulated = _elapsed;
    _elapsedTimeSource
      ..stop()
      ..reset();
    _lastResumedAt = null;
    _lastClockSnapshot = null;
  }

  void _emitSession(StopwatchStatus status, {DateTime? endedAt}) {
    emit(
      StopwatchState(
        status: status,
        activityId: state.activityId,
        startedAt: state.startedAt,
        endedAt: endedAt ?? state.endedAt,
        elapsed: _elapsed,
      ),
    );
  }

  Future<void> _persistSession() async {
    final activityId = state.activityId;
    final startedAt = state.startedAt;
    if (activityId == null || startedAt == null) return;

    await _sessionRepository.saveSession(
      PersistedStopwatchSession(
        status: PersistedStopwatchStatus.values.byName(state.status.name),
        activityId: activityId,
        startedAt: startedAt,
        endedAt: state.endedAt,
        accumulated: _accumulated,
        lastResumedAt:
            state.status == StopwatchStatus.running ? _lastResumedAt : null,
        lastResumedElapsedRealtime:
            state.status == StopwatchStatus.running
                ? _lastClockSnapshot?.elapsedRealtime
                : null,
        bootCount:
            state.status == StopwatchStatus.running
                ? _lastClockSnapshot?.bootCount
                : null,
      ),
    );
  }

  Future<void> _reset() async {
    _ticker?.cancel();
    _elapsedTimeSource
      ..stop()
      ..reset();
    _accumulated = Duration.zero;
    _lastResumedAt = null;
    _lastClockSnapshot = null;
    await _sessionRepository.clearSession();
    emit(const StopwatchState());
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    _elapsedTimeSource.stop();
    return super.close();
  }
}

class _NoopSessionRepository implements StopwatchSessionRepository {
  @override
  Future<void> clearSession() async {}

  @override
  Future<PersistedStopwatchSession?> loadSession() async => null;

  @override
  Future<void> saveSession(PersistedStopwatchSession session) async {}
}
