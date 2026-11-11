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
      _emitActivities(await _repository.getActivities());
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

  void selectActivity(String activityId) {
    final isSelectable = state.activeActivities.any(
      (activity) => activity.id == activityId,
    );
    if (!isSelectable || activityId == state.selectedActivityId) return;

    emit(
      ActivityState(
        status: state.status,
        activities: state.activities,
        selectedActivityId: activityId,
      ),
    );
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
        _emitActivities(await _repository.getActivities());
      }
      return result;
    } finally {
      _pendingDeletions.remove(activityId);
    }
  }

  Future<void> _save(Activity activity) async {
    try {
      await _repository.saveActivity(activity);
      _emitActivities(await _repository.getActivities());
    } catch (_) {
      emit(
        ActivityState(
          status: ActivityStatus.failure,
          activities: state.activities,
          selectedActivityId: state.selectedActivityId,
        ),
      );
    }
  }

  void _emitActivities(List<Activity> activities) {
    final activeActivities =
        activities.where((activity) => !activity.isArchived).toList();
    final currentSelectionIsValid = activeActivities.any(
      (activity) => activity.id == state.selectedActivityId,
    );
    final selectedActivityId =
        currentSelectionIsValid
            ? state.selectedActivityId
            : activeActivities.isEmpty
            ? null
            : activeActivities.first.id;

    emit(
      ActivityState(
        status: ActivityStatus.ready,
        activities: activities,
        selectedActivityId: selectedActivityId,
      ),
    );
  }
}
