import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/features/activities/domain/models/activity.dart';
import 'package:timeflow/features/statistics/domain/statistics_snapshot.dart';
import 'package:timeflow/features/time_entries/domain/models/time_entry.dart';

void main() {
  const programming = Activity(
    id: 'programming',
    name: 'Programming',
    colorValue: 0xFF52C7FF,
    iconKey: 'code',
  );
  const english = Activity(
    id: 'english',
    name: 'English',
    colorValue: 0xFF8B7CFF,
    iconKey: 'language',
  );

  test('calculates active-day averages and weekly trend', () {
    final snapshot = StatisticsSnapshot.from(
      entries: [
        _entry('p1', programming.id, DateTime(2026, 11, 9, 10), 30),
        _entry('p2', programming.id, DateTime(2026, 11, 9, 16), 15),
        _entry('p3', programming.id, DateTime(2026, 11, 11, 10), 45),
        _entry('e1', english.id, DateTime(2026, 11, 10, 10), 20),
      ],
      activities: const [programming, english],
      period: StatisticsPeriod.week,
      now: DateTime(2026, 11, 13),
    );

    expect(snapshot.total, const Duration(minutes: 110));
    expect(snapshot.activities.first.activity, programming);
    expect(snapshot.activities.first.activeDays, 2);
    expect(
      snapshot.activities.first.activeDayAverage,
      const Duration(minutes: 45),
    );
    expect(snapshot.trend, hasLength(7));
    expect(snapshot.trend[0].duration, const Duration(minutes: 45));
    expect(snapshot.trend[1].duration, const Duration(minutes: 20));
    expect(snapshot.trend[2].duration, const Duration(minutes: 45));
    expect(
      snapshot.trend.where((point) => point.isCurrent).single.label,
      'Fri',
    );
  });

  test('compares the selected period with the previous period', () {
    final snapshot = StatisticsSnapshot.from(
      entries: [
        _entry('current', programming.id, DateTime(2026, 11, 10), 60),
        _entry('previous', programming.id, DateTime(2026, 11, 3), 40),
      ],
      activities: const [programming],
      period: StatisticsPeriod.week,
      now: DateTime(2026, 11, 13),
    );

    expect(snapshot.previousTotal, const Duration(minutes: 40));
    expect(snapshot.comparisonLabel, '+50% vs last week');
    expect(snapshot.isImproved, isTrue);
  });

  test('groups month and year trends into readable buckets', () {
    final month = StatisticsSnapshot.from(
      entries: [_entry('november', programming.id, DateTime(2026, 11, 30), 30)],
      activities: const [programming],
      period: StatisticsPeriod.month,
      now: DateTime(2026, 11, 13),
    );
    final year = StatisticsSnapshot.from(
      entries: [_entry('november', programming.id, DateTime(2026, 11, 30), 30)],
      activities: const [programming],
      period: StatisticsPeriod.year,
      now: DateTime(2026, 11, 13),
    );

    expect(month.trend.map((point) => point.label), [
      '1–7',
      '8–14',
      '15–21',
      '22–28',
      '29–30',
    ]);
    expect(month.trend.last.duration, const Duration(minutes: 30));
    expect(month.trend.where((point) => point.isCurrent).single.label, '8–14');
    expect(year.trend, hasLength(12));
    expect(year.trend[10].label, 'Nov');
    expect(year.trend[10].duration, const Duration(minutes: 30));
    expect(year.trend.where((point) => point.isCurrent).single.label, 'Nov');
  });
}

TimeEntry _entry(String id, String activityId, DateTime endedAt, int minutes) {
  final duration = Duration(minutes: minutes);
  return TimeEntry(
    id: id,
    activityId: activityId,
    startedAt: endedAt.subtract(duration),
    endedAt: endedAt,
    duration: duration,
    createdAt: endedAt,
  );
}
