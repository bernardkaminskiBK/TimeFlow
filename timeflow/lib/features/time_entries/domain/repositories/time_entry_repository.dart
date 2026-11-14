import '../models/time_entry.dart';

abstract interface class TimeEntryRepository {
  Future<List<TimeEntry>> getEntries();

  Stream<List<TimeEntry>> watchEntries();

  Future<bool> hasEntriesForActivity(String activityId);

  Future<void> saveEntry(TimeEntry entry);

  Future<void> saveEntries(Iterable<TimeEntry> entries);

  Future<bool> updateEntry(TimeEntry entry);

  Future<bool> updateNote(String entryId, String? note);

  Future<bool> deleteEntry(String entryId);
}
