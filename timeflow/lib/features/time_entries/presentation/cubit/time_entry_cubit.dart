import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/time_entry.dart';
import '../../domain/repositories/time_entry_repository.dart';

enum ManualEntryResult { success, sessionActive, invalidInput, failure }

enum NoteUpdateResult { success, notFound, failure }

enum EntryDeletionResult { success, notFound, failure }

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
    required DateTime endedAt,
    required Duration duration,
    String? note,
  }) async {
    if (state.isSaving) return ManualEntryResult.invalidInput;
    if (_hasSession()) return ManualEntryResult.sessionActive;
    if (activityId.isEmpty || duration <= Duration.zero) {
      return ManualEntryResult.invalidInput;
    }
    if (endedAt.isAfter(DateTime.now())) {
      return ManualEntryResult.invalidInput;
    }

    emit(TimeEntryState(isSaving: true, entries: state.entries));
    try {
      final createdAt = DateTime.now();
      await _repository.saveEntry(
        TimeEntry(
          id: 'manual-${createdAt.microsecondsSinceEpoch}-${_idSequence++}',
          activityId: activityId,
          startedAt: endedAt.subtract(duration),
          endedAt: endedAt,
          duration: duration,
          createdAt: createdAt,
          note: _normalizedNote(note),
        ),
      );
      return ManualEntryResult.success;
    } catch (_) {
      return ManualEntryResult.failure;
    } finally {
      emit(TimeEntryState(entries: state.entries));
    }
  }

  Future<NoteUpdateResult> updateNote(String entryId, String? note) async {
    if (state.isSaving) return NoteUpdateResult.failure;
    emit(TimeEntryState(isSaving: true, entries: state.entries));
    try {
      final updated = await _repository.updateNote(
        entryId,
        _normalizedNote(note),
      );
      return updated ? NoteUpdateResult.success : NoteUpdateResult.notFound;
    } catch (_) {
      return NoteUpdateResult.failure;
    } finally {
      emit(TimeEntryState(entries: state.entries));
    }
  }

  Future<EntryDeletionResult> deleteEntry(String entryId) async {
    if (state.isSaving) return EntryDeletionResult.failure;
    emit(TimeEntryState(isSaving: true, entries: state.entries));
    try {
      final deleted = await _repository.deleteEntry(entryId);
      return deleted
          ? EntryDeletionResult.success
          : EntryDeletionResult.notFound;
    } catch (_) {
      return EntryDeletionResult.failure;
    } finally {
      emit(TimeEntryState(entries: state.entries));
    }
  }

  String? _normalizedNote(String? note) {
    final normalized = note?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  @override
  Future<void> close() {
    unawaited(_subscription.cancel());
    return super.close();
  }
}
