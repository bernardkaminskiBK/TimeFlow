import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/time_entry.dart';
import '../../domain/repositories/time_entry_repository.dart';

enum ManualEntryResult { success, sessionActive, invalidInput, failure }

class TimeEntryState {
  const TimeEntryState({this.isSaving = false});
  final bool isSaving;
}

class TimeEntryCubit extends Cubit<TimeEntryState> {
  TimeEntryCubit(this._repository, {required bool Function() hasSession})
    : _hasSession = hasSession,
      super(const TimeEntryState());

  final TimeEntryRepository _repository;
  final bool Function() _hasSession;
  var _idSequence = 0;

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

    emit(const TimeEntryState(isSaving: true));
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
      emit(const TimeEntryState());
    }
  }
}
