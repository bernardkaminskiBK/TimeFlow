import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/time_entry.dart';
import '../../domain/repositories/time_entry_repository.dart';

enum ManualEntryResult { success, sessionActive, invalidInput, failure }

class TimeEntryState {
  const TimeEntryState({this.isSaving = false, this.entries = const []});
  final bool isSaving;
  final List<TimeEntry> entries;
}

class TimeEntryCubit extends Cubit<TimeEntryState> {
  TimeEntryCubit(this._repository, {required bool Function() hasSession})
    : _hasSession = hasSession,
      super(const TimeEntryState()) {
    _subscription = _repository.watchEntries().listen((entries) {
      if (!isClosed) {
        emit(TimeEntryState(isSaving: state.isSaving, entries: entries));
      }
    });
  }

  final TimeEntryRepository _repository;
  final bool Function() _hasSession;
  var _idSequence = 0;
  late final StreamSubscription<List<TimeEntry>> _subscription;

  Future<ManualEntryResult> addManualEntry({
    required String activityId,
    required DateTime startedAt,
    required Duration duration,
  }) async {
    if (state.isSaving) return ManualEntryResult.invalidInput;
    if (_hasSession()) return ManualEntryResult.sessionActive;
    if (activityId.isEmpty || duration <= Duration.zero) {
      return ManualEntryResult.invalidInput;
    }
    if (startedAt.add(duration).isAfter(DateTime.now())) {
      return ManualEntryResult.invalidInput;
    }

    emit(TimeEntryState(isSaving: true, entries: state.entries));
    try {
      final createdAt = DateTime.now();
      await _repository.saveEntry(
        TimeEntry(
          id: 'manual-${createdAt.microsecondsSinceEpoch}-${_idSequence++}',
          activityId: activityId,
          startedAt: startedAt,
          endedAt: startedAt.add(duration),
          duration: duration,
          createdAt: createdAt,
        ),
      );
      return ManualEntryResult.success;
    } catch (_) {
      return ManualEntryResult.failure;
    } finally {
      emit(TimeEntryState(entries: state.entries));
    }
  }

  @override
  Future<void> close() {
    unawaited(_subscription.cancel());
    return super.close();
  }
}
