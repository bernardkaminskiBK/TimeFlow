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
    expect(await entries.updateNote('session-test', 'Persisted note'), isTrue);
    expect((await entries.getEntries()).single.note, 'Persisted note');
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

  test('keeps equal start times in stable creation order', () async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    final entries = DriftTimeEntryRepository(database);
    final startedAt = DateTime(2026, 11, 12, 16, 8);

    for (final entry in [
      TimeEntry(
        id: 'older-entry',
        activityId: 'activity-programming',
        startedAt: startedAt,
        endedAt: startedAt.add(const Duration(minutes: 30)),
        duration: const Duration(minutes: 30),
        createdAt: DateTime(2026, 11, 12, 16, 40),
      ),
      TimeEntry(
        id: 'newer-entry',
        activityId: 'activity-reading',
        startedAt: startedAt,
        endedAt: startedAt.add(const Duration(minutes: 30)),
        duration: const Duration(minutes: 30),
        createdAt: DateTime(2026, 11, 12, 16, 41),
      ),
    ]) {
      await entries.saveEntry(entry);
    }

    expect((await entries.getEntries()).map((entry) => entry.id), [
      'newer-entry',
      'older-entry',
    ]);
    await entries.updateNote('older-entry', 'Edited later');
    expect((await entries.getEntries()).map((entry) => entry.id), [
      'newer-entry',
      'older-entry',
    ]);
  });
}
