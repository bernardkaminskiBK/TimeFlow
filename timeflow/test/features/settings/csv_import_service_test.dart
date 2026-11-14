import 'package:csv/csv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/features/activities/data/repositories/in_memory_activity_repository.dart';
import 'package:timeflow/features/activities/domain/models/activity.dart';
import 'package:timeflow/features/settings/data/services/csv_export_service.dart';
import 'package:timeflow/features/settings/data/services/csv_import_service.dart';
import 'package:timeflow/features/settings/data/services/timeflow_csv_schema.dart';
import 'package:timeflow/features/time_entries/data/repositories/in_memory_time_entry_repository.dart';
import 'package:timeflow/features/time_entries/domain/models/time_entry.dart';

void main() {
  test(
    'previews and imports activities and sessions without duplicates',
    () async {
      final activities = InMemoryActivityRepository();
      final entries = InMemoryTimeEntryRepository();
      final service = CsvImportService(activities, entries);
      final csv = const ListToCsvConverter().convert([
        timeFlowCsvHeaders,
        _row(
          entryId: 'entry-one',
          activityId: 'activity-cycling',
          activityName: 'Cycling',
          endedAt: DateTime(2026, 11, 10, 11),
          note: 'Sunny, but windy',
        ),
        _row(
          entryId: 'entry-two',
          activityId: 'activity-cycling',
          activityName: 'Cycling',
          endedAt: DateTime(2026, 11, 11, 11),
          note: 'Intervals\nand cooldown',
        ),
      ]);

      final preview = await service.prepare(csv);

      expect(preview.isValid, isTrue);
      expect(preview.newActivities, hasLength(1));
      expect(preview.newEntries, hasLength(2));
      expect(preview.duplicateEntries, 0);

      final result = await service.import(preview);
      expect(result.importedActivities, 1);
      expect(result.importedEntries, 2);
      expect(await entries.getEntries(), hasLength(2));
      expect(
        (await activities.getActivities()).where(
          (activity) => activity.id == 'activity-cycling',
        ),
        hasLength(1),
      );

      final duplicatePreview = await service.prepare(csv);
      expect(duplicatePreview.isValid, isTrue);
      expect(duplicatePreview.hasChanges, isFalse);
      expect(duplicatePreview.duplicateEntries, 2);
    },
  );

  test('rejects malformed schemas and invalid session durations', () async {
    final service = CsvImportService(
      InMemoryActivityRepository(),
      InMemoryTimeEntryRepository(),
    );
    final missingColumns = const ListToCsvConverter().convert([
      ['entry_id', 'activity_id'],
      ['one', 'activity-programming'],
    ]);
    final invalidDuration = const ListToCsvConverter().convert([
      timeFlowCsvHeaders,
      _row(
        entryId: 'entry-invalid',
        activityId: 'activity-programming',
        activityName: 'Programming',
        endedAt: DateTime(2026, 11, 10, 11),
        durationMilliseconds: 7200000,
      ),
    ]);

    final schemaPreview = await service.prepare(missingColumns);
    final durationPreview = await service.prepare(invalidDuration);

    expect(schemaPreview.isValid, isFalse);
    expect(schemaPreview.errors.single, contains('Missing columns'));
    expect(durationPreview.isValid, isFalse);
    expect(
      durationPreview.errors.single,
      contains('exceeds the session time range'),
    );
  });

  test(
    'accepts sub-second clock drift in exported stopwatch sessions',
    () async {
      final service = CsvImportService(
        InMemoryActivityRepository(),
        InMemoryTimeEntryRepository(),
      );
      final csv = const ListToCsvConverter().convert([
        timeFlowCsvHeaders,
        _row(
          entryId: 'entry-clock-drift',
          activityId: 'activity-programming',
          activityName: 'Programming',
          endedAt: DateTime(2026, 11, 10, 11),
          durationMilliseconds: 3600250,
        ),
      ]);

      final preview = await service.prepare(csv);

      expect(preview.isValid, isTrue);
      expect(preview.newEntries, hasLength(1));
    },
  );

  test('round-trips activities and sessions through one CSV file', () async {
    final sourceActivities = InMemoryActivityRepository();
    final sourceEntries = InMemoryTimeEntryRepository();
    const cycling = Activity(
      id: 'activity-cycling',
      name: 'Cycling',
      colorValue: 0xFF4FD6A3,
      iconKey: 'other',
      createdAt: null,
    );
    final endedAt = DateTime(2026, 11, 14, 10, 30, 15);
    const duration = Duration(hours: 1, minutes: 12, seconds: 9);
    final entry = TimeEntry(
      id: 'entry-round-trip',
      activityId: cycling.id,
      startedAt: endedAt.subtract(duration),
      endedAt: endedAt,
      duration: duration,
      createdAt: DateTime(2026, 11, 14, 10, 31),
      note: 'Long ride, strong finish.',
    );
    await sourceActivities.saveActivity(cycling);
    await sourceEntries.saveEntry(entry);

    final document = await CsvExportService(
      sourceActivities,
      sourceEntries,
    ).create(now: DateTime(2026, 11, 14, 12, 34, 56));

    expect(document.fileName, 'timeflow-export-2026-11-14-123456.csv');
    expect(document.sessionCount, 1);
    expect(document.activityCount, 1);

    final targetActivities = InMemoryActivityRepository();
    final targetEntries = InMemoryTimeEntryRepository();
    final importService = CsvImportService(targetActivities, targetEntries);
    final preview = await importService.prepare(document.csv);
    await importService.import(preview);

    final importedEntry = (await targetEntries.getEntries()).single;
    final importedActivity = (await targetActivities.getActivities())
        .singleWhere((activity) => activity.id == cycling.id);
    expect(importedActivity.name, cycling.name);
    expect(importedActivity.colorValue, cycling.colorValue);
    expect(importedEntry.id, entry.id);
    expect(importedEntry.startedAt, entry.startedAt);
    expect(importedEntry.endedAt, entry.endedAt);
    expect(importedEntry.duration, entry.duration);
    expect(importedEntry.note, entry.note);
  });
}

List<Object?> _row({
  required String entryId,
  required String activityId,
  required String activityName,
  required DateTime endedAt,
  int durationMilliseconds = 3600000,
  String? note,
}) {
  final startedAt = endedAt.subtract(const Duration(hours: 1));
  return [
    '1',
    entryId,
    activityId,
    activityName,
    0xFF4FD6A3,
    'other',
    false,
    DateTime(2026, 1, 1).toIso8601String(),
    startedAt.toIso8601String(),
    endedAt.toIso8601String(),
    durationMilliseconds,
    endedAt.toIso8601String(),
    note ?? '',
  ];
}
