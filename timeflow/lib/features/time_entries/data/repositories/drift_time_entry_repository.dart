import '../../../../app/database/app_database.dart';
import '../../domain/models/time_entry.dart' as domain;
import '../../domain/repositories/time_entry_repository.dart';

class DriftTimeEntryRepository implements TimeEntryRepository {
  DriftTimeEntryRepository(this.db);
  final AppDatabase db;

  @override
  Future<List<domain.TimeEntry>> getEntries() async =>
      (await db.select(db.timeEntries).get())
          .map(
            (r) => domain.TimeEntry(
              id: r.id,
              activityId: r.activityId,
              startedAt: r.startedAt,
              endedAt: r.endedAt,
              duration: Duration(milliseconds: r.durationMilliseconds),
              createdAt: r.createdAt,
            ),
          )
          .toList();

  @override
  Future<bool> hasEntriesForActivity(String id) async =>
      await (db.select(db.timeEntries)
            ..where((t) => t.activityId.equals(id))
            ..limit(1))
          .getSingleOrNull() !=
      null;

  @override
  Future<void> saveEntry(domain.TimeEntry e) => db
      .into(db.timeEntries)
      .insertOnConflictUpdate(
        TimeEntriesCompanion.insert(
          id: e.id,
          activityId: e.activityId,
          startedAt: e.startedAt,
          endedAt: e.endedAt,
          durationMilliseconds: e.duration.inMilliseconds,
          createdAt: e.createdAt,
        ),
      );
}
