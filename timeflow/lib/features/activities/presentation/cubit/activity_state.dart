import '../../domain/models/activity.dart';

enum ActivityStatus { loading, ready, failure }

class ActivityState {
  const ActivityState({
    this.status = ActivityStatus.loading,
    this.activities = const [],
    this.selectedActivityId,
  });

  final ActivityStatus status;
  final List<Activity> activities;
  final String? selectedActivityId;

  List<Activity> get activeActivities =>
      activities.where((activity) => !activity.isArchived).toList();

  List<Activity> get archivedActivities =>
      activities.where((activity) => activity.isArchived).toList();

  Activity? get selectedActivity {
    for (final activity in activities) {
      if (activity.id == selectedActivityId && !activity.isArchived) {
        return activity;
      }
    }
    return null;
  }
}
