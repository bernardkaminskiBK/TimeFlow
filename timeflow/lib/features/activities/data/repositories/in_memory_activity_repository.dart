import '../../domain/models/activity.dart';
import '../../domain/repositories/activity_repository.dart';

class InMemoryActivityRepository implements ActivityRepository {
  InMemoryActivityRepository()
    : _activities = [
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

  @override
  Future<List<Activity>> getActivities() async =>
      List.unmodifiable(_activities);

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
  Future<ActivityDeletionResult> deleteActivity(String activityId) async {
    final index = _activities.indexWhere((item) => item.id == activityId);
    if (index == -1) return ActivityDeletionResult.notFound;

    // TODO(time-entries): Before deletion, check TimeEntry storage for records
    // referencing activityId and return referenced when any exist. The future
    // Drift foreign key must use RESTRICT/NO ACTION, never cascade deletion of
    // historical time entries.
    _activities.removeAt(index);
    return ActivityDeletionResult.deleted;
  }
}
