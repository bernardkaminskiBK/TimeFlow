import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/features/time_entries/data/repositories/in_memory_time_entry_repository.dart';
import 'package:timeflow/features/time_entries/presentation/cubit/time_entry_cubit.dart';

void main() {
  group('TimeEntryCubit manual entries', () {
    test('saves the selected activity and duration', () async {
      final repository = InMemoryTimeEntryRepository();
      final cubit = TimeEntryCubit(repository, hasSession: () => false);
      addTearDown(cubit.close);
      final startedAt = DateTime(2026, 11, 12, 9, 30);

      final result = await cubit.addManualEntry(
        activityId: 'activity-english',
        startedAt: startedAt,
        duration: const Duration(hours: 1, minutes: 15),
      );

      final entries = await repository.getEntries();
      expect(result, ManualEntryResult.success);
      expect(entries, hasLength(1));
      expect(entries.single.activityId, 'activity-english');
      expect(entries.single.startedAt, startedAt);
      expect(entries.single.endedAt, DateTime(2026, 11, 12, 10, 45));
      expect(entries.single.duration, const Duration(hours: 1, minutes: 15));
    });

    test('rejects manual entry while a stopwatch session exists', () async {
      final repository = InMemoryTimeEntryRepository();
      final cubit = TimeEntryCubit(repository, hasSession: () => true);
      addTearDown(cubit.close);

      final result = await cubit.addManualEntry(
        activityId: 'activity-programming',
        startedAt: DateTime(2026, 11, 12, 9),
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
        startedAt: DateTime(2026, 11, 12, 9),
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
        startedAt: DateTime.now(),
        duration: const Duration(minutes: 30),
      );

      expect(result, ManualEntryResult.invalidInput);
      expect(await repository.getEntries(), isEmpty);
    });
  });
}
