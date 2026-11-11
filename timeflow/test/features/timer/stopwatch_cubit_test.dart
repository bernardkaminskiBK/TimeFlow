import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/features/activities/data/repositories/in_memory_activity_repository.dart';
import 'package:timeflow/features/activities/domain/repositories/activity_repository.dart';
import 'package:timeflow/features/activities/presentation/cubit/activity_cubit.dart';
import 'package:timeflow/features/activities/presentation/cubit/activity_state.dart';
import 'package:timeflow/features/time_entries/data/repositories/in_memory_time_entry_repository.dart';
import 'package:timeflow/features/timer/domain/models/persisted_stopwatch_session.dart';
import 'package:timeflow/features/timer/domain/repositories/stopwatch_session_repository.dart';
import 'package:timeflow/features/timer/presentation/cubit/elapsed_time_source.dart';
import 'package:timeflow/features/timer/presentation/cubit/session_clock.dart';
import 'package:timeflow/features/timer/presentation/cubit/stopwatch_cubit.dart';
import 'package:timeflow/features/timer/presentation/cubit/stopwatch_state.dart';

void main() {
  group('StopwatchCubit', () {
    test('start, stop, and save creates an entry', () async {
      final fixture = _Fixture();
      addTearDown(fixture.close);

      expect(
        await fixture.cubit.start('activity-programming'),
        StopwatchCommandResult.success,
      );
      fixture.advance(const Duration(seconds: 12));
      expect(await fixture.cubit.stop(), StopwatchCommandResult.success);
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

      await fixture.cubit.start('activity-programming');
      fixture.advance(const Duration(seconds: 4));
      await fixture.cubit.stop();

      expect(await fixture.cubit.discard(), StopwatchCommandResult.success);
      expect(await fixture.repository.getEntries(), isEmpty);
      expect(fixture.cubit.state.status, StopwatchStatus.ready);
    });

    test('pause and resume excludes paused time', () async {
      final fixture = _Fixture();
      addTearDown(fixture.close);

      await fixture.cubit.start('activity-english');
      fixture.advance(const Duration(seconds: 5));
      await fixture.cubit.pause();
      fixture.advance(const Duration(seconds: 30));
      expect(fixture.cubit.state.elapsed, const Duration(seconds: 5));
      await fixture.cubit.resume();
      fixture.advance(const Duration(seconds: 7));
      await fixture.cubit.stop();
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

      await fixture.cubit.start('activity-workout');
      fixture.advance(const Duration(seconds: 3));
      await fixture.cubit.pause();
      fixture.advance(const Duration(seconds: 10));
      await fixture.cubit.resume();
      fixture.advance(const Duration(seconds: 4));
      await fixture.cubit.pause();
      fixture.advance(const Duration(seconds: 20));
      await fixture.cubit.resume();
      fixture.advance(const Duration(seconds: 5));
      await fixture.cubit.stop();

      expect(fixture.cubit.state.elapsed, const Duration(seconds: 12));
    });

    test('resumes a stopped session without counting stopped time', () async {
      final fixture = _Fixture();
      addTearDown(fixture.close);

      await fixture.cubit.start('activity-programming');
      fixture.advance(const Duration(seconds: 3));
      await fixture.cubit.stop();
      fixture.advance(const Duration(seconds: 20));

      expect(await fixture.cubit.resume(), StopwatchCommandResult.success);
      expect(fixture.cubit.state.endedAt, isNull);
      fixture.advance(const Duration(seconds: 2));
      await fixture.cubit.stop();
      await fixture.cubit.save();

      final entry = (await fixture.repository.getEntries()).single;
      expect(entry.duration, const Duration(seconds: 5));
      expect(
        entry.endedAt.difference(entry.startedAt),
        const Duration(seconds: 25),
      );
    });

    test('refresh catches up after time passes in the background', () async {
      final fixture = _Fixture();
      addTearDown(fixture.close);

      await fixture.cubit.start('activity-reading');
      fixture.advance(const Duration(minutes: 2), refresh: false);
      fixture.cubit.refresh();

      expect(fixture.cubit.state.elapsed, const Duration(minutes: 2));
    });

    test('rejects starting a second session and invalid transitions', () async {
      final fixture = _Fixture();
      addTearDown(fixture.close);

      expect(
        await fixture.cubit.start(null),
        StopwatchCommandResult.noSelectedActivity,
      );
      expect(
        await fixture.cubit.start('activity-programming'),
        StopwatchCommandResult.success,
      );
      expect(
        await fixture.cubit.start('activity-english'),
        StopwatchCommandResult.sessionAlreadyExists,
      );
      expect(
        await fixture.cubit.resume(),
        StopwatchCommandResult.invalidTransition,
      );
      expect(
        await fixture.cubit.discard(),
        StopwatchCommandResult.invalidTransition,
      );
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
      await fixture.cubit.start(programming.id);

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

      await fixture.cubit.start('activity-programming');
      fixture.advance(const Duration(seconds: 8));
      await fixture.cubit.stop();
      await fixture.cubit.save();

      expect(
        await activityRepository.deleteActivity('activity-programming'),
        ActivityDeletionResult.referenced,
      );
    });

    test(
      'restores a running session after process death in the same boot',
      () async {
        final sessionRepository = _MemorySessionRepository();
        final first = _Fixture(sessionRepository: sessionRepository);
        await first.cubit.start('activity-reading');
        first.advance(const Duration(minutes: 35), refresh: false);
        await first.close();

        final restored = _Fixture(
          sessionRepository: sessionRepository,
          wallClock: first.wallClock,
          clockElapsed: first.sessionClock.elapsed,
        );
        addTearDown(restored.close);
        await restored.cubit.restore();

        expect(restored.cubit.state.status, StopwatchStatus.running);
        expect(restored.cubit.state.elapsed, const Duration(minutes: 35));
        expect(restored.cubit.state.activityId, 'activity-reading');
      },
    );

    test('uses wall time to bridge a device reboot', () async {
      final sessionRepository = _MemorySessionRepository();
      final first = _Fixture(sessionRepository: sessionRepository);
      await first.cubit.start('activity-workout');
      first.advance(const Duration(minutes: 20), refresh: false);
      await first.close();

      final restored = _Fixture(
        sessionRepository: sessionRepository,
        wallClock: first.wallClock,
        clockElapsed: const Duration(minutes: 3),
        bootCount: 8,
      );
      addTearDown(restored.close);
      restored.wallClock = restored.wallClock.add(const Duration(minutes: 2));
      await restored.cubit.restore();

      expect(restored.cubit.state.status, StopwatchStatus.running);
      expect(restored.cubit.state.elapsed, const Duration(minutes: 22));
    });

    test('restores paused and stopped sessions without adding time', () async {
      final pausedRepository = _MemorySessionRepository();
      final paused = _Fixture(sessionRepository: pausedRepository);
      await paused.cubit.start('activity-english');
      paused.advance(const Duration(minutes: 5));
      await paused.cubit.pause();
      await paused.close();

      final restoredPaused = _Fixture(
        sessionRepository: pausedRepository,
        wallClock: paused.wallClock.add(const Duration(hours: 2)),
        clockElapsed: paused.sessionClock.elapsed + const Duration(hours: 2),
      );
      addTearDown(restoredPaused.close);
      await restoredPaused.cubit.restore();
      expect(restoredPaused.cubit.state.status, StopwatchStatus.paused);
      expect(restoredPaused.cubit.state.elapsed, const Duration(minutes: 5));

      await restoredPaused.cubit.stop();
      final stoppedTime = restoredPaused.cubit.state.elapsed;
      await restoredPaused.close();
      final restoredStopped = _Fixture(
        sessionRepository: pausedRepository,
        wallClock: restoredPaused.wallClock.add(const Duration(hours: 1)),
        clockElapsed:
            restoredPaused.sessionClock.elapsed + const Duration(hours: 1),
      );
      addTearDown(restoredStopped.close);
      await restoredStopped.cubit.restore();
      expect(restoredStopped.cubit.state.status, StopwatchStatus.stopped);
      expect(restoredStopped.cubit.state.elapsed, stoppedTime);
    });
  });
}

class _Fixture {
  _Fixture({
    StopwatchSessionRepository? sessionRepository,
    DateTime? wallClock,
    Duration clockElapsed = Duration.zero,
    int bootCount = 7,
  }) : wallClock = wallClock ?? DateTime(2026, 11, 11, 9),
       sessionClock = _FakeSessionClock(clockElapsed, bootCount) {
    cubit = StopwatchCubit(
      repository,
      sessionRepository: sessionRepository,
      elapsedTimeSource: elapsedTimeSource,
      sessionClock: sessionClock,
      now: () => this.wallClock,
    );
  }

  final repository = InMemoryTimeEntryRepository();
  final elapsedTimeSource = _FakeElapsedTimeSource();
  final _FakeSessionClock sessionClock;
  DateTime wallClock;

  late final StopwatchCubit cubit;

  void advance(Duration duration, {bool refresh = true}) {
    elapsedTimeSource.advance(duration);
    sessionClock.advance(duration);
    wallClock = wallClock.add(duration);
    if (refresh) cubit.refresh();
  }

  Future<void> close() => cubit.close();
}

class _FakeSessionClock implements SessionClock {
  _FakeSessionClock(this.elapsed, this.bootCount);

  Duration elapsed;
  int bootCount;

  void advance(Duration duration) => elapsed += duration;

  @override
  Future<SessionClockSnapshot?> snapshot() async =>
      SessionClockSnapshot(elapsedRealtime: elapsed, bootCount: bootCount);
}

class _MemorySessionRepository implements StopwatchSessionRepository {
  PersistedStopwatchSession? session;

  @override
  Future<void> clearSession() async => session = null;

  @override
  Future<PersistedStopwatchSession?> loadSession() async => session;

  @override
  Future<void> saveSession(PersistedStopwatchSession session) async {
    this.session = session;
  }
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
