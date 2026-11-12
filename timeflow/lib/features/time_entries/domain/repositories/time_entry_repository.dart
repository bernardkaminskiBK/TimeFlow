import '../models/time_entry.dart';

abstract interface class TimeEntryRepository {
  Future<List<TimeEntry>> getEntries();

  Stream<List<TimeEntry>> watchEntries();

  Future<bool> hasEntriesForActivity(String activityId);

  Future<void> saveEntry(TimeEntry entry);
}
