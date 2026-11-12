import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/app/database/app_database.dart';
import 'package:timeflow/features/activities/data/repositories/drift_activity_repository.dart';
import 'package:timeflow/features/activities/domain/models/activity.dart';
import 'package:timeflow/features/activities/domain/repositories/activity_repository.dart';
import 'package:timeflow/features/time_entries/data/repositories/drift_time_entry_repository.dart';
import 'package:timeflow/features/time_entries/domain/models/time_entry.dart';

void main() {
  test('persists entries and protects referenced activities', () async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    final activities = DriftActivityRepository(database);
    final entries = DriftTimeEntryRepository(database);
    final startedAt = DateTime(2026, 11, 12, 9);

    await entries.saveEntry(
      TimeEntry(
        id: 'session-test',
        activityId: 'activity-programming',
        startedAt: startedAt,
        endedAt: startedAt.add(const Duration(minutes: 30)),
        duration: const Duration(minutes: 30),
        createdAt: startedAt.add(const Duration(minutes: 30)),
      ),
    );

    expect(await entries.getEntries(), hasLength(1));
    expect(
      await activities.deleteActivity('activity-programming'),
      ActivityDeletionResult.referenced,
    );
  });

  test('returns newly created activities first', () async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    final activities = DriftActivityRepository(database);
    const newestId = 'activity-newest';
    await activities.saveActivity(
      Activity(
        id: newestId,
        name: 'Newest',
        colorValue: 0xFF52C7FF,
        iconKey: 'other',
        createdAt: DateTime.utc(2026, 11, 12),
      ),
    );

    expect((await activities.getActivities()).first.id, newestId);
  });
}
