import '../models/time_entry.dart';

abstract interface class TimeEntryRepository {
  Future<List<TimeEntry>> getEntries();

  Future<bool> hasEntriesForActivity(String activityId);

  Future<void> saveEntry(TimeEntry entry);
}
