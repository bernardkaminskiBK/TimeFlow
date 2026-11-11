import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/features/activities/data/repositories/in_memory_activity_repository.dart';
import 'package:timeflow/features/activities/domain/repositories/activity_repository.dart';
import 'package:timeflow/features/activities/presentation/cubit/activity_cubit.dart';
import 'package:timeflow/features/activities/presentation/cubit/activity_state.dart';
import 'package:timeflow/features/time_entries/data/repositories/in_memory_time_entry_repository.dart';
import 'package:timeflow/features/timer/presentation/cubit/elapsed_time_source.dart';
import 'package:timeflow/features/timer/presentation/cubit/stopwatch_cubit.dart';
import 'package:timeflow/features/timer/presentation/cubit/stopwatch_state.dart';

void main() {
  group('StopwatchCubit', () {
    test('start, stop, and save creates an entry', () async {
      final fixture = _Fixture();
      addTearDown(fixture.close);

      expect(
        fixture.cubit.start('activity-programming'),
        StopwatchCommandResult.success,
      );
      fixture.advance(const Duration(seconds: 12));
      expect(fixture.cubit.stop(), StopwatchCommandResult.success);
      expect(await fixture.cubit.save(), StopwatchCommandResult.success);

      final entries = await fixture.repository.getEntries();
      expect(entries, hasLength(1));
      expect(entries.single.duration, const Duration(seconds: 12));
      expect(entries.single.activityId, 'activity-programming');
      expect(entries.single.startedAt, DateTime(2026, 11, 11, 9));
      expect(entries.single.endedAt, DateTime(2026, 11, 11, 9, 0, 12));
      expect(fixture.cubit.state.status, StopwatchStatus.ready);
    });

    test('start, stop, and discard does not create an entry', () async {
      final fixture = _Fixture();
      addTearDown(fixture.close);

      fixture.cubit.start('activity-programming');
      fixture.advance(const Duration(seconds: 4));
      fixture.cubit.stop();

      expect(fixture.cubit.discard(), StopwatchCommandResult.success);
      expect(await fixture.repository.getEntries(), isEmpty);
      expect(fixture.cubit.state.status, StopwatchStatus.ready);
    });

    test('pause and resume excludes paused time', () async {
      final fixture = _Fixture();
      addTearDown(fixture.close);

      fixture.cubit.start('activity-english');
      fixture.advance(const Duration(seconds: 5));
      fixture.cubit.pause();
      fixture.advance(const Duration(seconds: 30));
      expect(fixture.cubit.state.elapsed, const Duration(seconds: 5));
      fixture.cubit.resume();
      fixture.advance(const Duration(seconds: 7));
      fixture.cubit.stop();
      await fixture.cubit.save();

      final entry = (await fixture.repository.getEntries()).single;
      expect(entry.duration, const Duration(seconds: 12));
      expect(entry.activityId, 'activity-english');
      expect(
        entry.endedAt.difference(entry.startedAt),
        const Duration(seconds: 42),
      );
    });

    test('handles multiple pause and resume cycles', () async {
      final fixture = _Fixture();
      addTearDown(fixture.close);

      fixture.cubit.start('activity-workout');
      fixture.advance(const Duration(seconds: 3));
      fixture.cubit.pause();
      fixture.advance(const Duration(seconds: 10));
      fixture.cubit.resume();
      fixture.advance(const Duration(seconds: 4));
      fixture.cubit.pause();
      fixture.advance(const Duration(seconds: 20));
      fixture.cubit.resume();
      fixture.advance(const Duration(seconds: 5));
      fixture.cubit.stop();

      expect(fixture.cubit.state.elapsed, const Duration(seconds: 12));
    });

    test('resumes a stopped session without counting stopped time', () async {
      final fixture = _Fixture();
      addTearDown(fixture.close);

      fixture.cubit.start('activity-programming');
      fixture.advance(const Duration(seconds: 3));
      fixture.cubit.stop();
      fixture.advance(const Duration(seconds: 20));

      expect(fixture.cubit.resume(), StopwatchCommandResult.success);
      expect(fixture.cubit.state.endedAt, isNull);
      fixture.advance(const Duration(seconds: 2));
      fixture.cubit.stop();
      await fixture.cubit.save();

      final entry = (await fixture.repository.getEntries()).single;
      expect(entry.duration, const Duration(seconds: 5));
      expect(
        entry.endedAt.difference(entry.startedAt),
        const Duration(seconds: 25),
      );
    });

    test('refresh catches up after time passes in the background', () {
      final fixture = _Fixture();
      addTearDown(fixture.close);

      fixture.cubit.start('activity-reading');
      fixture.advance(const Duration(minutes: 2), refresh: false);
      fixture.cubit.refresh();

      expect(fixture.cubit.state.elapsed, const Duration(minutes: 2));
    });

    test('rejects starting a second session and invalid transitions', () {
      final fixture = _Fixture();
      addTearDown(fixture.close);

      expect(
        fixture.cubit.start(null),
        StopwatchCommandResult.noSelectedActivity,
      );
      expect(
        fixture.cubit.start('activity-programming'),
        StopwatchCommandResult.success,
      );
      expect(
        fixture.cubit.start('activity-english'),
        StopwatchCommandResult.sessionAlreadyExists,
      );
      expect(fixture.cubit.resume(), StopwatchCommandResult.invalidTransition);
      expect(fixture.cubit.discard(), StopwatchCommandResult.invalidTransition);
    });

    test('locks selection and mutations for the tracked activity', () async {
      final fixture = _Fixture();
      addTearDown(fixture.close);
      final activityRepository = InMemoryActivityRepository();
      final activityCubit = ActivityCubit(
        activityRepository,
        hasSession: () => fixture.cubit.hasSession,
        isActivityLocked: fixture.cubit.isActivityLocked,
      );
      addTearDown(activityCubit.close);
      await activityCubit.stream.firstWhere(
        (state) => state.status == ActivityStatus.ready,
      );
      final programming = activityCubit.state.selectedActivity!;
      fixture.cubit.start(programming.id);

      expect(
        activityCubit.selectActivity('activity-english'),
        ActivityMutationResult.sessionLocked,
      );
      expect(
        await activityCubit.updateActivity(
          activity: programming,
          name: 'Changed',
          colorValue: programming.colorValue,
          iconKey: programming.iconKey,
        ),
        ActivityMutationResult.sessionLocked,
      );
      expect(
        await activityCubit.archiveActivity(programming),
        ActivityMutationResult.sessionLocked,
      );
      expect(
        await activityCubit.deleteActivity(programming.id),
        ActivityDeletionResult.sessionLocked,
      );
      expect(activityCubit.state.selectedActivity?.name, 'Programming');
    });

    test('saved entries prevent deleting their activity', () async {
      final fixture = _Fixture();
      addTearDown(fixture.close);
      final activityRepository = InMemoryActivityRepository(
        hasTimeEntries: fixture.repository.hasEntriesForActivity,
      );

      fixture.cubit.start('activity-programming');
      fixture.advance(const Duration(seconds: 8));
      fixture.cubit.stop();
      await fixture.cubit.save();

      expect(
        await activityRepository.deleteActivity('activity-programming'),
        ActivityDeletionResult.referenced,
      );
    });
  });
}

class _Fixture {
  _Fixture() {
    cubit = StopwatchCubit(
      repository,
      elapsedTimeSource: elapsedTimeSource,
      now: () => wallClock,
    );
  }

  final repository = InMemoryTimeEntryRepository();
  final elapsedTimeSource = _FakeElapsedTimeSource();
  var wallClock = DateTime(2026, 11, 11, 9);

  late final StopwatchCubit cubit;

  void advance(Duration duration, {bool refresh = true}) {
    elapsedTimeSource.advance(duration);
    wallClock = wallClock.add(duration);
    if (refresh) cubit.refresh();
  }

  Future<void> close() => cubit.close();
}

class _FakeElapsedTimeSource implements ElapsedTimeSource {
  var _elapsed = Duration.zero;
  var _isRunning = false;

  @override
  Duration get elapsed => _elapsed;

  void advance(Duration duration) {
    if (_isRunning) _elapsed += duration;
  }

  @override
  void reset() => _elapsed = Duration.zero;

  @override
  void start() => _isRunning = true;

  @override
  void stop() => _isRunning = false;
}
