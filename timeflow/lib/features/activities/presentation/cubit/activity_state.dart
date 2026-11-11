import '../../domain/models/activity.dart';

enum ActivityStatus { loading, ready, failure }

class ActivityState {
  const ActivityState({
    this.status = ActivityStatus.loading,
    this.activities = const [],
  });

  final ActivityStatus status;
  final List<Activity> activities;

  List<Activity> get activeActivities =>
      activities.where((activity) => !activity.isArchived).toList();

  List<Activity> get archivedActivities =>
      activities.where((activity) => activity.isArchived).toList();
}
