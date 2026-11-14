import '../../domain/models/activity.dart';
import '../../domain/repositories/activity_repository.dart';

class InMemoryActivityRepository implements ActivityRepository {
  InMemoryActivityRepository({
    Future<bool> Function(String activityId)? hasTimeEntries,
  }) : _hasTimeEntries = hasTimeEntries ?? ((_) async => false),
       _activities = [
         const Activity(
           id: 'activity-programming',
           name: 'Programming',
           colorValue: 0xFF52C7FF,
           iconKey: 'code',
         ),
         const Activity(
           id: 'activity-english',
           name: 'English',
           colorValue: 0xFF8B7CFF,
           iconKey: 'language',
         ),
         const Activity(
           id: 'activity-workout',
           name: 'Workout',
           colorValue: 0xFFFF7A90,
           iconKey: 'workout',
         ),
         const Activity(
           id: 'activity-reading',
           name: 'Reading',
           colorValue: 0xFFFFB85C,
           iconKey: 'reading',
         ),
       ];

  final List<Activity> _activities;
  final Future<bool> Function(String activityId) _hasTimeEntries;

  @override
  Future<List<Activity>> getActivities() async {
    final activities = [..._activities];
    activities.sort((left, right) {
      final leftCreatedAt = left.createdAt;
      final rightCreatedAt = right.createdAt;
      if (leftCreatedAt == null && rightCreatedAt == null) return 0;
      if (leftCreatedAt == null) return 1;
      if (rightCreatedAt == null) return -1;
      return rightCreatedAt.compareTo(leftCreatedAt);
    });
    return List.unmodifiable(activities);
  }

  @override
  Future<void> saveActivity(Activity activity) async {
    final index = _activities.indexWhere((item) => item.id == activity.id);
    if (index == -1) {
      _activities.add(activity);
      return;
    }
    _activities[index] = activity;
  }

  @override
  Future<void> saveActivities(Iterable<Activity> activities) async {
    for (final activity in activities) {
      await saveActivity(activity);
    }
  }

  @override
  Future<ActivityDeletionResult> deleteActivity(String activityId) async {
    final index = _activities.indexWhere((item) => item.id == activityId);
    if (index == -1) return ActivityDeletionResult.notFound;

    if (await _hasTimeEntries(activityId)) {
      return ActivityDeletionResult.referenced;
    }

    // TODO(drift): Enforce this check with a RESTRICT/NO ACTION foreign key.
    // Never cascade-delete historical TimeEntry records with an activity.
    _activities.removeAt(index);
    return ActivityDeletionResult.deleted;
  }
}
