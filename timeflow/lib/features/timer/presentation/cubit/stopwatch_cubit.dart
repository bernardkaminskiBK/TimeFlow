import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../time_entries/domain/models/time_entry.dart';
import '../../../time_entries/domain/repositories/time_entry_repository.dart';
import 'elapsed_time_source.dart';
import 'stopwatch_state.dart';

/// Owns the single in-memory tracking session.
///
/// The monotonic elapsed-time source keeps a live process accurate across app
/// backgrounding and screen locks. Session recovery after process death or a
/// full restart is intentionally deferred until Drift persistence is added.
class StopwatchCubit extends Cubit<StopwatchState> {
  StopwatchCubit(
    this._repository, {
    ElapsedTimeSource? elapsedTimeSource,
    DateTime Function()? now,
  }) : _elapsedTimeSource = elapsedTimeSource ?? SystemElapsedTimeSource(),
       _now = now ?? DateTime.now,
       super(const StopwatchState());

  final TimeEntryRepository _repository;
  final ElapsedTimeSource _elapsedTimeSource;
  final DateTime Function() _now;
  Timer? _ticker;
  var _entrySequence = 0;
  var _isSaving = false;

  bool get hasSession => state.hasSession;

  bool isActivityLocked(String activityId) =>
      state.hasSession && state.activityId == activityId;

  StopwatchCommandResult start(String? activityId) {
    if (state.hasSession) {
      return StopwatchCommandResult.sessionAlreadyExists;
    }
    if (activityId == null || activityId.isEmpty) {
      return StopwatchCommandResult.noSelectedActivity;
    }

    _elapsedTimeSource
      ..reset()
      ..start();
    emit(
      StopwatchState(
        status: StopwatchStatus.running,
        activityId: activityId,
        startedAt: _now(),
      ),
    );
    _startTicker();
    return StopwatchCommandResult.success;
  }

  StopwatchCommandResult pause() {
    if (state.status != StopwatchStatus.running) {
      return StopwatchCommandResult.invalidTransition;
    }
    _elapsedTimeSource.stop();
    _ticker?.cancel();
    _emitSession(StopwatchStatus.paused);
    return StopwatchCommandResult.success;
  }

  StopwatchCommandResult resume() {
    if (state.status != StopwatchStatus.paused &&
        state.status != StopwatchStatus.stopped) {
      return StopwatchCommandResult.invalidTransition;
    }
    _elapsedTimeSource.start();
    emit(
      StopwatchState(
        status: StopwatchStatus.running,
        activityId: state.activityId,
        startedAt: state.startedAt,
        elapsed: _elapsedTimeSource.elapsed,
      ),
    );
    _startTicker();
    return StopwatchCommandResult.success;
  }

  StopwatchCommandResult stop() {
    if (state.status != StopwatchStatus.running &&
        state.status != StopwatchStatus.paused) {
      return StopwatchCommandResult.invalidTransition;
    }
    _elapsedTimeSource.stop();
    _ticker?.cancel();
    _emitSession(StopwatchStatus.stopped, endedAt: _now());
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
          id: 'entry-${createdAt.microsecondsSinceEpoch}-${_entrySequence++}',
          activityId: activityId,
          startedAt: startedAt,
          endedAt: endedAt,
          duration: _elapsedTimeSource.elapsed,
          createdAt: createdAt,
        ),
      );
      _reset();
      return StopwatchCommandResult.success;
    } finally {
      _isSaving = false;
    }
  }

  StopwatchCommandResult discard() {
    if (state.status != StopwatchStatus.stopped) {
      return StopwatchCommandResult.invalidTransition;
    }
    _reset();
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

  void _emitSession(StopwatchStatus status, {DateTime? endedAt}) {
    emit(
      StopwatchState(
        status: status,
        activityId: state.activityId,
        startedAt: state.startedAt,
        endedAt: endedAt ?? state.endedAt,
        elapsed: _elapsedTimeSource.elapsed,
      ),
    );
  }

  void _reset() {
    _ticker?.cancel();
    _elapsedTimeSource
      ..stop()
      ..reset();
    emit(const StopwatchState());
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    _elapsedTimeSource.stop();
    return super.close();
  }
}
