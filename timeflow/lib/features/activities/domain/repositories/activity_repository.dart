import '../models/activity.dart';

enum ActivityDeletionResult { deleted, referenced, notFound, sessionLocked }

abstract interface class ActivityRepository {
  Future<List<Activity>> getActivities();

  Future<void> saveActivity(Activity activity);

  /// Permanently deletes an unreferenced activity.
  ///
  /// Implementations must return [ActivityDeletionResult.referenced] when
  /// time entries reference the activity and must preserve those entries.
  Future<ActivityDeletionResult> deleteActivity(String activityId);
}
