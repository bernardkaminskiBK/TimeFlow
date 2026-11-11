import '../../domain/models/time_entry.dart';
import '../../domain/repositories/time_entry_repository.dart';

class InMemoryTimeEntryRepository implements TimeEntryRepository {
  final List<TimeEntry> _entries = [];

  @override
  Future<List<TimeEntry>> getEntries() async => List.unmodifiable(_entries);

  @override
  Future<bool> hasEntriesForActivity(String activityId) async =>
      _entries.any((entry) => entry.activityId == activityId);

  @override
  Future<void> saveEntry(TimeEntry entry) async {
    _entries.add(entry);
  }
}
