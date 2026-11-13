import '../../activities/domain/models/activity.dart';
import '../../time_entries/domain/models/time_entry.dart';

enum StatisticsPeriod { week, month, year }

class ActivityStatistic {
  const ActivityStatistic({
    required this.activity,
    required this.total,
    required this.activeDays,
  });

  final Activity activity;
  final Duration total;
  final int activeDays;

  Duration get activeDayAverage => Duration(
    microseconds: activeDays == 0 ? 0 : total.inMicroseconds ~/ activeDays,
  );
}

class TrendPoint {
  const TrendPoint({
    required this.label,
    required this.duration,
    required this.isCurrent,
  });

  final String label;
  final Duration duration;
  final bool isCurrent;
}

class StatisticsSnapshot {
  const StatisticsSnapshot({
    required this.period,
    required this.total,
    required this.previousTotal,
    required this.activities,
    required this.trend,
  });

  factory StatisticsSnapshot.from({
    required List<TimeEntry> entries,
    required List<Activity> activities,
    required StatisticsPeriod period,
    required DateTime now,
  }) {
    final range = _PeriodRange.forDate(period, now);
    final previousRange = range.previous;
    final currentEntries = entries.where(
      (entry) => range.contains(entry.endedAt),
    );
    final previousEntries = entries.where(
      (entry) => previousRange.contains(entry.endedAt),
    );
    final activityById = {
      for (final activity in activities) activity.id: activity,
    };
    final totals = <String, Duration>{};
    final activeDates = <String, Set<DateTime>>{};
    var total = Duration.zero;

    for (final entry in currentEntries) {
      final activity = activityById[entry.activityId];
      if (activity == null) continue;
      total += entry.duration;
      totals.update(
        entry.activityId,
        (value) => value + entry.duration,
        ifAbsent: () => entry.duration,
      );
      activeDates
          .putIfAbsent(entry.activityId, () => <DateTime>{})
          .add(_dateOnly(entry.endedAt));
    }

    final activityStatistics =
        totals.entries
            .map(
              (entry) => ActivityStatistic(
                activity: activityById[entry.key]!,
                total: entry.value,
                activeDays: activeDates[entry.key]!.length,
              ),
            )
            .toList()
          ..sort((left, right) {
            final byDuration = right.total.compareTo(left.total);
            return byDuration != 0
                ? byDuration
                : left.activity.name.compareTo(right.activity.name);
          });

    return StatisticsSnapshot(
      period: period,
      total: total,
      previousTotal: previousEntries.fold(
        Duration.zero,
        (sum, entry) => sum + entry.duration,
      ),
      activities: List.unmodifiable(activityStatistics),
      trend: List.unmodifiable(_buildTrend(entries, range, period, now)),
    );
  }

  final StatisticsPeriod period;
  final Duration total;
  final Duration previousTotal;
  final List<ActivityStatistic> activities;
  final List<TrendPoint> trend;

  String get periodLabel => switch (period) {
    StatisticsPeriod.week => 'THIS WEEK',
    StatisticsPeriod.month => 'THIS MONTH',
    StatisticsPeriod.year => 'THIS YEAR',
  };

  String get comparisonLabel {
    if (previousTotal == Duration.zero) {
      return total == Duration.zero ? 'No tracked time' : 'New this period';
    }
    final difference = total.inMicroseconds - previousTotal.inMicroseconds;
    final percentage =
        (difference.abs() * 100 / previousTotal.inMicroseconds).round();
    final direction = difference >= 0 ? '+' : '-';
    return '$direction$percentage% vs last ${_previousPeriodName(period)}';
  }

  bool get isImproved => total >= previousTotal;
}

class _PeriodRange {
  const _PeriodRange(this.start, this.end, this.previousStart);

  factory _PeriodRange.forDate(StatisticsPeriod period, DateTime date) {
    final day = _dateOnly(date);
    return switch (period) {
      StatisticsPeriod.week => () {
        final start = day.subtract(
          Duration(days: day.weekday - DateTime.monday),
        );
        return _PeriodRange(
          start,
          _addCalendarDays(start, 7),
          _addCalendarDays(start, -7),
        );
      }(),
      StatisticsPeriod.month => () {
        final start = DateTime(day.year, day.month);
        return _PeriodRange(
          start,
          DateTime(day.year, day.month + 1),
          DateTime(day.year, day.month - 1),
        );
      }(),
      StatisticsPeriod.year => () {
        final start = DateTime(day.year);
        return _PeriodRange(
          start,
          DateTime(day.year + 1),
          DateTime(day.year - 1),
        );
      }(),
    };
  }

  final DateTime start;
  final DateTime end;
  final DateTime previousStart;

  bool contains(DateTime date) => !date.isBefore(start) && date.isBefore(end);

  _PeriodRange get previous =>
      _PeriodRange(previousStart, start, previousStart);
}

List<TrendPoint> _buildTrend(
  List<TimeEntry> entries,
  _PeriodRange range,
  StatisticsPeriod period,
  DateTime now,
) {
  final today = _dateOnly(now);
  return switch (period) {
    StatisticsPeriod.week => List.generate(7, (index) {
      const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final start = _addCalendarDays(range.start, index);
      return TrendPoint(
        label: labels[index],
        duration: _totalBetween(entries, start, _addCalendarDays(start, 1)),
        isCurrent: start == today,
      );
    }),
    StatisticsPeriod.month => _monthTrend(entries, range, today),
    StatisticsPeriod.year => List.generate(12, (index) {
      const labels = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final start = DateTime(range.start.year, index + 1);
      final end = DateTime(range.start.year, index + 2);
      return TrendPoint(
        label: labels[index],
        duration: _totalBetween(entries, start, end),
        isCurrent: now.year == start.year && now.month == start.month,
      );
    }),
  };
}

List<TrendPoint> _monthTrend(
  List<TimeEntry> entries,
  _PeriodRange range,
  DateTime today,
) {
  final points = <TrendPoint>[];
  var start = range.start;
  while (start.isBefore(range.end)) {
    final proposedEnd = _addCalendarDays(start, 7);
    final end = proposedEnd.isBefore(range.end) ? proposedEnd : range.end;
    final lastDay = end.subtract(const Duration(days: 1)).day;
    points.add(
      TrendPoint(
        label: '${start.day}–$lastDay',
        duration: _totalBetween(entries, start, end),
        isCurrent: !today.isBefore(start) && today.isBefore(end),
      ),
    );
    start = end;
  }
  return points;
}

Duration _totalBetween(List<TimeEntry> entries, DateTime start, DateTime end) =>
    entries
        .where(
          (entry) =>
              !entry.endedAt.isBefore(start) && entry.endedAt.isBefore(end),
        )
        .fold(Duration.zero, (sum, entry) => sum + entry.duration);

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime _addCalendarDays(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);

String _previousPeriodName(StatisticsPeriod period) => switch (period) {
  StatisticsPeriod.week => 'week',
  StatisticsPeriod.month => 'month',
  StatisticsPeriod.year => 'year',
};

String formatStatisticsDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  final parts = <String>[];
  if (hours > 0) parts.add('${hours}h');
  if (minutes > 0) parts.add('${minutes}m');
  if (seconds > 0) parts.add('${seconds}s');
  return parts.isEmpty ? '0m' : parts.join(' ');
}
