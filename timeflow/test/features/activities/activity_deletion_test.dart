import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/features/activities/data/repositories/in_memory_activity_repository.dart';
import 'package:timeflow/features/activities/domain/models/activity.dart';
import 'package:timeflow/features/activities/domain/repositories/activity_repository.dart';
import 'package:timeflow/features/activities/presentation/cubit/activity_cubit.dart';
import 'package:timeflow/features/activities/presentation/cubit/activity_state.dart';

void main() {
  group('Activity deletion', () {
    test('deletes an active activity', () async {
      final cubit = await _readyCubit(InMemoryActivityRepository());
      addTearDown(cubit.close);

      final result = await cubit.deleteActivity('activity-programming');

      expect(result, ActivityDeletionResult.deleted);
      expect(
        cubit.state.activities.any(
          (activity) => activity.id == 'activity-programming',
        ),
        isFalse,
      );
      expect(cubit.state.activeActivities, hasLength(3));
    });

    test('deletes an archived activity', () async {
      final cubit = await _readyCubit(InMemoryActivityRepository());
      addTearDown(cubit.close);
      final reading = cubit.state.activities.firstWhere(
        (activity) => activity.id == 'activity-reading',
      );
      await cubit.archiveActivity(reading);

      final result = await cubit.deleteActivity(reading.id);

      expect(result, ActivityDeletionResult.deleted);
      expect(cubit.state.archivedActivities, isEmpty);
      expect(
        cubit.state.activities.any((activity) => activity.id == reading.id),
        isFalse,
      );
    });

    test('archiving and restoring still preserve an activity', () async {
      final cubit = await _readyCubit(InMemoryActivityRepository());
      addTearDown(cubit.close);
      final workout = cubit.state.activities.firstWhere(
        (activity) => activity.id == 'activity-workout',
      );

      await cubit.archiveActivity(workout);
      expect(cubit.state.archivedActivities.single.id, workout.id);

      await cubit.restoreActivity(cubit.state.archivedActivities.single);
      expect(
        cubit.state.activeActivities.any(
          (activity) => activity.id == workout.id,
        ),
        isTrue,
      );
      expect(cubit.state.archivedActivities, isEmpty);
    });

    test('returns notFound for a missing activity', () async {
      final cubit = await _readyCubit(InMemoryActivityRepository());
      addTearDown(cubit.close);

      final result = await cubit.deleteActivity('missing-activity');

      expect(result, ActivityDeletionResult.notFound);
      expect(cubit.state.activities, hasLength(4));
    });

    test('keeps referenced activities', () async {
      final repository = _ControlledDeletionRepository(
        result: ActivityDeletionResult.referenced,
      );
      final cubit = await _readyCubit(repository);
      addTearDown(cubit.close);

      final result = await cubit.deleteActivity('activity-test');

      expect(result, ActivityDeletionResult.referenced);
      expect(cubit.state.activities, hasLength(1));
    });

    test('coalesces duplicate delete operations', () async {
      final repository = _ControlledDeletionRepository();
      final cubit = await _readyCubit(repository);
      addTearDown(cubit.close);

      final first = cubit.deleteActivity('activity-test');
      final second = cubit.deleteActivity('activity-test');

      expect(identical(first, second), isTrue);
      expect(repository.deleteCalls, 1);

      repository.completeDeletion(ActivityDeletionResult.deleted);
      expect(await first, ActivityDeletionResult.deleted);
      expect(await second, ActivityDeletionResult.deleted);
      expect(cubit.state.activities, isEmpty);
    });
  });
}

Future<ActivityCubit> _readyCubit(ActivityRepository repository) async {
  final cubit = ActivityCubit(repository);
  await cubit.stream.firstWhere(
    (state) => state.status == ActivityStatus.ready,
  );
  return cubit;
}

class _ControlledDeletionRepository implements ActivityRepository {
  _ControlledDeletionRepository({this.result});

  final ActivityDeletionResult? result;
  final List<Activity> _activities = [
    const Activity(
      id: 'activity-test',
      name: 'Test',
      colorValue: 0xFF52C7FF,
      iconKey: 'other',
    ),
  ];
  final Completer<ActivityDeletionResult> _deletion = Completer();
  var deleteCalls = 0;

  @override
  Future<List<Activity>> getActivities() async =>
      List.unmodifiable(_activities);

  @override
  Future<void> saveActivity(Activity activity) async {}

  @override
  Future<ActivityDeletionResult> deleteActivity(String activityId) {
    deleteCalls++;
    final fixedResult = result;
    if (fixedResult != null) return Future.value(fixedResult);
    return _deletion.future.then((deletionResult) {
      if (deletionResult == ActivityDeletionResult.deleted) {
        _activities.removeWhere((activity) => activity.id == activityId);
      }
      return deletionResult;
    });
  }

  void completeDeletion(ActivityDeletionResult deletionResult) {
    _deletion.complete(deletionResult);
  }
}
