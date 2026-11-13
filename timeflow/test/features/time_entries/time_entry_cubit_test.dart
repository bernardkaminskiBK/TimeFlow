import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/features/time_entries/data/repositories/in_memory_time_entry_repository.dart';
import 'package:timeflow/features/time_entries/presentation/cubit/time_entry_cubit.dart';

void main() {
  group('TimeEntryCubit manual entries', () {
    test('saves the selected activity and duration', () async {
      final repository = InMemoryTimeEntryRepository();
      final cubit = TimeEntryCubit(repository, hasSession: () => false);
      addTearDown(cubit.close);
      final endedAt = DateTime(2026, 11, 12, 10, 45);

      final result = await cubit.addManualEntry(
        activityId: 'activity-english',
        endedAt: endedAt,
        duration: const Duration(hours: 1, minutes: 15),
      );

      final entries = await repository.getEntries();
      expect(result, ManualEntryResult.success);
      expect(entries, hasLength(1));
      expect(entries.single.activityId, 'activity-english');
      expect(entries.single.startedAt, DateTime(2026, 11, 12, 9, 30));
      expect(entries.single.endedAt, endedAt);
      expect(entries.single.duration, const Duration(hours: 1, minutes: 15));
    });

    test('rejects manual entry while a stopwatch session exists', () async {
      final repository = InMemoryTimeEntryRepository();
      final cubit = TimeEntryCubit(repository, hasSession: () => true);
      addTearDown(cubit.close);

      final result = await cubit.addManualEntry(
        activityId: 'activity-programming',
        endedAt: DateTime(2026, 11, 12, 9, 30),
        duration: const Duration(minutes: 30),
      );

      expect(result, ManualEntryResult.sessionActive);
      expect(await repository.getEntries(), isEmpty);
    });

    test('rejects a zero duration', () async {
      final repository = InMemoryTimeEntryRepository();
      final cubit = TimeEntryCubit(repository, hasSession: () => false);
      addTearDown(cubit.close);

      final result = await cubit.addManualEntry(
        activityId: 'activity-programming',
        endedAt: DateTime(2026, 11, 12, 9),
        duration: Duration.zero,
      );

      expect(result, ManualEntryResult.invalidInput);
      expect(await repository.getEntries(), isEmpty);
    });

    test('rejects an entry ending in the future', () async {
      final repository = InMemoryTimeEntryRepository();
      final cubit = TimeEntryCubit(repository, hasSession: () => false);
      addTearDown(cubit.close);

      final result = await cubit.addManualEntry(
        activityId: 'activity-programming',
        endedAt: DateTime.now().add(const Duration(minutes: 1)),
        duration: const Duration(minutes: 30),
      );

      expect(result, ManualEntryResult.invalidInput);
      expect(await repository.getEntries(), isEmpty);
    });

    test('adds, updates, and clears a session note', () async {
      final repository = InMemoryTimeEntryRepository();
      final cubit = TimeEntryCubit(repository, hasSession: () => false);
      addTearDown(cubit.close);
      final endedAt = DateTime(2026, 11, 12, 9, 30);

      await cubit.addManualEntry(
        activityId: 'activity-programming',
        endedAt: endedAt,
        duration: const Duration(minutes: 30),
        note: '  Initial note  ',
      );
      final entry = (await repository.getEntries()).single;
      expect(entry.note, 'Initial note');

      expect(
        await cubit.updateNote(entry.id, 'Updated note'),
        NoteUpdateResult.success,
      );
      expect((await repository.getEntries()).single.note, 'Updated note');

      expect(await cubit.updateNote(entry.id, '   '), NoteUpdateResult.success);
      expect((await repository.getEntries()).single.note, isNull);
    });

    test(
      'updates session details while preserving identity and note',
      () async {
        final repository = InMemoryTimeEntryRepository();
        final cubit = TimeEntryCubit(repository, hasSession: () => false);
        addTearDown(cubit.close);
        await cubit.addManualEntry(
          activityId: 'activity-programming',
          endedAt: DateTime(2026, 11, 12, 9, 30),
          duration: const Duration(minutes: 30),
          note: 'Keep this note',
        );
        final original = (await repository.getEntries()).single;
        final newEnd = DateTime(2026, 11, 12, 11, 15, 20);

        final result = await cubit.updateEntry(
          entry: original,
          activityId: 'activity-english',
          endedAt: newEnd,
          duration: const Duration(hours: 1, minutes: 5, seconds: 20),
        );

        final updated = (await repository.getEntries()).single;
        expect(result, EntryUpdateResult.success);
        expect(updated.id, original.id);
        expect(updated.createdAt, original.createdAt);
        expect(updated.note, 'Keep this note');
        expect(updated.activityId, 'activity-english');
        expect(updated.endedAt, newEnd);
        expect(updated.startedAt, DateTime(2026, 11, 12, 10, 10));
        expect(
          updated.duration,
          const Duration(hours: 1, minutes: 5, seconds: 20),
        );
      },
    );

    test('rejects invalid edits and reports a missing session', () async {
      final repository = InMemoryTimeEntryRepository();
      final cubit = TimeEntryCubit(repository, hasSession: () => false);
      addTearDown(cubit.close);
      await cubit.addManualEntry(
        activityId: 'activity-programming',
        endedAt: DateTime(2026, 11, 12, 9, 30),
        duration: const Duration(minutes: 30),
      );
      final entry = (await repository.getEntries()).single;

      expect(
        await cubit.updateEntry(
          entry: entry,
          activityId: entry.activityId,
          endedAt: entry.endedAt,
          duration: Duration.zero,
        ),
        EntryUpdateResult.invalidInput,
      );
      await repository.deleteEntry(entry.id);
      expect(
        await cubit.updateEntry(
          entry: entry,
          activityId: entry.activityId,
          endedAt: entry.endedAt,
          duration: entry.duration,
        ),
        EntryUpdateResult.notFound,
      );
    });

    test('deletes a session and reports a missing entry', () async {
      final repository = InMemoryTimeEntryRepository();
      final cubit = TimeEntryCubit(repository, hasSession: () => false);
      addTearDown(cubit.close);
      await cubit.addManualEntry(
        activityId: 'activity-programming',
        endedAt: DateTime(2026, 11, 12, 9, 0, 12),
        duration: const Duration(seconds: 12),
      );
      final entry = (await repository.getEntries()).single;

      expect(await cubit.deleteEntry(entry.id), EntryDeletionResult.success);
      expect(await repository.getEntries(), isEmpty);
      expect(await cubit.deleteEntry(entry.id), EntryDeletionResult.notFound);
    });
  });
}
