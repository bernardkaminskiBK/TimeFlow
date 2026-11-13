import 'package:drift/drift.dart';

import 'app_database.dart';

const enableDevelopmentData = bool.fromEnvironment(
  'TIMEFLOW_SEED_DEMO_DATA',
  defaultValue: true,
);

Future<void> seedDevelopmentData(AppDatabase database, {DateTime? now}) async {
  final activityIds =
      (await database.select(database.activities).get())
          .map((activity) => activity.id)
          .toSet();
  if (activityIds.isEmpty) return;

  final anchor = now ?? DateTime.now();
  final entries = <TimeEntriesCompanion>[];
  var sequence = 0;

  void addEntry({
    required String activityId,
    required DateTime endedAt,
    required Duration duration,
    String? note,
  }) {
    sequence++;
    if (!activityIds.contains(activityId)) return;
    entries.add(
      TimeEntriesCompanion.insert(
        id: 'dev-seed-v1-${sequence.toString().padLeft(3, '0')}',
        activityId: activityId,
        startedAt: endedAt.subtract(duration),
        endedAt: endedAt,
        durationMilliseconds: duration.inMilliseconds,
        createdAt: endedAt,
        note: Value(note),
      ),
    );
  }

  const activities = [
    'activity-programming',
    'activity-english',
    'activity-workout',
    'activity-reading',
  ];
  const notes = [
    'Deep focus session. The task finally clicked.',
    'Reviewed the difficult parts and wrote a short summary.',
    'Good pace today. Keep the same rhythm next time.',
    'A shorter session, but still moved things forward.',
  ];

  for (var dayOffset = 0; dayOffset < 84; dayOffset++) {
    if (dayOffset % 5 == 3 || dayOffset % 11 == 7) continue;
    final activityIndex = (dayOffset * 3 + dayOffset ~/ 7) % activities.length;
    final minutes = 24 + (dayOffset * 17) % 83;
    final seconds = dayOffset % 6 == 0 ? 37 : 0;
    final endedAt = DateTime(
      anchor.year,
      anchor.month,
      anchor.day - dayOffset,
      8 + (dayOffset * 5) % 12,
      7 + (dayOffset * 13) % 48,
      seconds,
    );
    addEntry(
      activityId: activities[activityIndex],
      endedAt:
          dayOffset == 0
              ? anchor.subtract(const Duration(minutes: 8))
              : endedAt,
      duration: Duration(minutes: minutes, seconds: seconds),
      note:
          dayOffset % 13 == 0 ? notes[(dayOffset ~/ 13) % notes.length] : null,
    );

    if (dayOffset % 8 == 1) {
      final secondDuration = Duration(minutes: 18 + (dayOffset * 9) % 44);
      addEntry(
        activityId: activities[(activityIndex + 1) % activities.length],
        endedAt: DateTime(
          anchor.year,
          anchor.month,
          anchor.day - dayOffset,
          20,
          10 + dayOffset % 35,
        ),
        duration: secondDuration,
      );
    }
  }

  for (var monthOffset = 3; monthOffset <= 11; monthOffset += 2) {
    final month = DateTime(anchor.year, anchor.month - monthOffset, 1);
    for (var index = 0; index < 3; index++) {
      final duration = Duration(minutes: 35 + monthOffset * 4 + index * 16);
      addEntry(
        activityId: activities[(monthOffset + index) % activities.length],
        endedAt: DateTime(month.year, month.month, 5 + index * 8, 18, 20),
        duration: duration,
        note:
            index == 1 && monthOffset % 3 == 0
                ? 'A memorable session from earlier this year.'
                : null,
      );
    }
  }

  for (var month = 1; month <= 12; month += 2) {
    final endedAt = DateTime(anchor.year - 1, month, 12, 17, 45);
    addEntry(
      activityId: activities[(month ~/ 2) % activities.length],
      endedAt: endedAt,
      duration: Duration(minutes: 42 + month * 5),
    );
  }

  await database.batch(
    (batch) => batch.insertAll(
      database.timeEntries,
      entries,
      mode: InsertMode.insertOrIgnore,
    ),
  );
}
