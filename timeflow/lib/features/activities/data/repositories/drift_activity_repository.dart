import 'package:drift/drift.dart';
import '../../../../app/database/app_database.dart';
import '../../domain/models/activity.dart' as domain;
import '../../domain/repositories/activity_repository.dart';

class DriftActivityRepository implements ActivityRepository {
  DriftActivityRepository(this.db);
  final AppDatabase db;
  @override
  Future<List<domain.Activity>> getActivities() async =>
      (await (db.select(db.activities)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get())
          .map(
            (r) => domain.Activity(
              id: r.id,
              name: r.name,
              colorValue: r.colorValue,
              iconKey: r.iconKey,
              isArchived: r.isArchived,
              createdAt: r.createdAt,
            ),
          )
          .toList();
  @override
  Future<void> saveActivity(domain.Activity a) => db
      .into(db.activities)
      .insertOnConflictUpdate(
        ActivitiesCompanion.insert(
          id: a.id,
          name: a.name,
          colorValue: a.colorValue,
          iconKey: a.iconKey,
          isArchived: Value(a.isArchived),
          createdAt: Value(a.createdAt),
        ),
      );

  @override
  Future<void> saveActivities(Iterable<domain.Activity> activities) =>
      db.transaction(() async {
        for (final activity in activities) {
          await saveActivity(activity);
        }
      });
  @override
  Future<ActivityDeletionResult> deleteActivity(String id) async {
    if (await (db.select(db.activities)
          ..where((t) => t.id.equals(id))).getSingleOrNull() ==
        null) {
      return ActivityDeletionResult.notFound;
    }
    if (await (db.select(db.timeEntries)
              ..where((t) => t.activityId.equals(id))
              ..limit(1))
            .getSingleOrNull() !=
        null) {
      return ActivityDeletionResult.referenced;
    }
    await (db.delete(db.activities)..where((t) => t.id.equals(id))).go();
    return ActivityDeletionResult.deleted;
  }
}
