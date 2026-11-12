import 'dart:async';

import '../../domain/models/time_entry.dart';
import '../../domain/repositories/time_entry_repository.dart';

class InMemoryTimeEntryRepository implements TimeEntryRepository {
  final List<TimeEntry> _entries = [];
  final _changes = StreamController<void>.broadcast();

  @override
  Future<List<TimeEntry>> getEntries() async => List.unmodifiable(_entries);

  @override
  Stream<List<TimeEntry>> watchEntries() async* {
    yield List.unmodifiable(_entries);
    await for (final _ in _changes.stream) {
      yield List.unmodifiable(_entries.reversed);
    }
  }

  @override
  Future<bool> hasEntriesForActivity(String activityId) async =>
      _entries.any((entry) => entry.activityId == activityId);

  @override
  Future<void> saveEntry(TimeEntry entry) async {
    _entries.add(entry);
    _changes.add(null);
  }
}
