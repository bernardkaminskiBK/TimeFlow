import 'dart:async';

import '../../domain/models/time_entry.dart';
import '../../domain/repositories/time_entry_repository.dart';

class InMemoryTimeEntryRepository implements TimeEntryRepository {
  final List<TimeEntry> _entries = [];
  final _changes = StreamController<void>.broadcast();

  @override
  Future<List<TimeEntry>> getEntries() async => _orderedEntries();

  @override
  Stream<List<TimeEntry>> watchEntries() async* {
    yield _orderedEntries();
    await for (final _ in _changes.stream) {
      yield _orderedEntries();
    }
  }

  List<TimeEntry> _orderedEntries() {
    final entries = [..._entries]..sort((left, right) {
      final byEnd = right.endedAt.compareTo(left.endedAt);
      if (byEnd != 0) return byEnd;
      final byStart = right.startedAt.compareTo(left.startedAt);
      if (byStart != 0) return byStart;
      final byCreation = right.createdAt.compareTo(left.createdAt);
      if (byCreation != 0) return byCreation;
      return right.id.compareTo(left.id);
    });
    return List.unmodifiable(entries);
  }

  @override
  Future<bool> hasEntriesForActivity(String activityId) async =>
      _entries.any((entry) => entry.activityId == activityId);

  @override
  Future<void> saveEntry(TimeEntry entry) async {
    _entries.add(entry);
    _changes.add(null);
  }

  @override
  Future<bool> updateEntry(TimeEntry entry) async {
    final index = _entries.indexWhere((existing) => existing.id == entry.id);
    if (index == -1) return false;
    _entries[index] = entry;
    _changes.add(null);
    return true;
  }

  @override
  Future<bool> updateNote(String entryId, String? note) async {
    final index = _entries.indexWhere((entry) => entry.id == entryId);
    if (index == -1) return false;
    _entries[index] = _entries[index].copyWith(
      note: note,
      clearNote: note == null,
    );
    _changes.add(null);
    return true;
  }

  @override
  Future<bool> deleteEntry(String entryId) async {
    final index = _entries.indexWhere((entry) => entry.id == entryId);
    if (index == -1) return false;
    _entries.removeAt(index);
    _changes.add(null);
    return true;
  }
}
