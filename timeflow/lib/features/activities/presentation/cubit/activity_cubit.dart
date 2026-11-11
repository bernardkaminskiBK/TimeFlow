import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/activity.dart';
import '../../domain/repositories/activity_repository.dart';
import 'activity_state.dart';

class ActivityCubit extends Cubit<ActivityState> {
  ActivityCubit(this._repository) : super(const ActivityState()) {
    loadActivities();
  }

  final ActivityRepository _repository;
  final Map<String, Future<ActivityDeletionResult>> _pendingDeletions = {};
  var _idSequence = 0;

  Future<void> loadActivities() async {
    try {
      emit(
        ActivityState(
          status: ActivityStatus.ready,
          activities: await _repository.getActivities(),
        ),
      );
    } catch (_) {
      emit(const ActivityState(status: ActivityStatus.failure));
    }
  }

  Future<void> addActivity({
    required String name,
    required int colorValue,
    required String iconKey,
  }) async {
    final activity = Activity(
      id: 'activity-${DateTime.now().microsecondsSinceEpoch}-${_idSequence++}',
      name: name.trim(),
      colorValue: colorValue,
      iconKey: iconKey,
    );
    await _save(activity);
  }

  Future<void> updateActivity({
    required Activity activity,
    required String name,
    required int colorValue,
    required String iconKey,
  }) async {
    await _save(
      activity.copyWith(
        name: name.trim(),
        colorValue: colorValue,
        iconKey: iconKey,
      ),
    );
  }

  Future<void> archiveActivity(Activity activity) async {
    await _save(activity.copyWith(isArchived: true));
  }

  Future<void> restoreActivity(Activity activity) async {
    await _save(activity.copyWith(isArchived: false));
  }

  Future<ActivityDeletionResult> deleteActivity(String activityId) {
    return _pendingDeletions.putIfAbsent(
      activityId,
      () => _deleteActivity(activityId),
    );
  }

  Future<ActivityDeletionResult> _deleteActivity(String activityId) async {
    try {
      final result = await _repository.deleteActivity(activityId);
      if (result != ActivityDeletionResult.referenced) {
        emit(
          ActivityState(
            status: ActivityStatus.ready,
            activities: await _repository.getActivities(),
          ),
        );
      }
      return result;
    } finally {
      _pendingDeletions.remove(activityId);
    }
  }

  Future<void> _save(Activity activity) async {
    try {
      await _repository.saveActivity(activity);
      emit(
        ActivityState(
          status: ActivityStatus.ready,
          activities: await _repository.getActivities(),
        ),
      );
    } catch (_) {
      emit(
        ActivityState(
          status: ActivityStatus.failure,
          activities: state.activities,
        ),
      );
    }
  }
}
