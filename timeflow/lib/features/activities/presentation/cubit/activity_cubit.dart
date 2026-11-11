import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/activity.dart';
import '../../domain/repositories/activity_repository.dart';
import 'activity_state.dart';

enum ActivityMutationResult { success, sessionLocked }

class ActivityCubit extends Cubit<ActivityState> {
  ActivityCubit(
    this._repository, {
    bool Function()? hasSession,
    bool Function(String activityId)? isActivityLocked,
  }) : _hasSession = hasSession ?? (() => false),
       _isActivityLocked = isActivityLocked ?? ((_) => false),
       super(const ActivityState()) {
    loadActivities();
  }

  final ActivityRepository _repository;
  final bool Function() _hasSession;
  final bool Function(String activityId) _isActivityLocked;
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

  Future<ActivityMutationResult> updateActivity({
    required Activity activity,
    required String name,
    required int colorValue,
    required String iconKey,
  }) async {
    if (_isActivityLocked(activity.id)) {
      return ActivityMutationResult.sessionLocked;
    }
    await _save(
      activity.copyWith(
        name: name.trim(),
        colorValue: colorValue,
        iconKey: iconKey,
      ),
    );
    return ActivityMutationResult.success;
  }

  Future<ActivityMutationResult> archiveActivity(Activity activity) async {
    if (_isActivityLocked(activity.id)) {
      return ActivityMutationResult.sessionLocked;
    }
    await _save(activity.copyWith(isArchived: true));
    return ActivityMutationResult.success;
  }

  Future<void> restoreActivity(Activity activity) async {
    await _save(activity.copyWith(isArchived: false));
  }

  ActivityMutationResult selectActivity(String activityId) {
    if (_hasSession()) return ActivityMutationResult.sessionLocked;
    final isSelectable = state.activeActivities.any(
      (activity) => activity.id == activityId,
    );
    if (!isSelectable || activityId == state.selectedActivityId) {
      return ActivityMutationResult.success;
    }

    emit(
      ActivityState(
        status: state.status,
        activities: state.activities,
        selectedActivityId: activityId,
      ),
    );
    return ActivityMutationResult.success;
  }

  Future<ActivityDeletionResult> deleteActivity(String activityId) {
    if (_isActivityLocked(activityId)) {
      return Future.value(ActivityDeletionResult.sessionLocked);
    }
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
