import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../activities/domain/models/activity.dart';
import '../../../activities/presentation/activity_visuals.dart';
import '../../../time_entries/domain/models/time_entry.dart';

class ActivityHistoryList extends StatelessWidget {
  const ActivityHistoryList({
    required this.entries,
    required this.activities,
    required this.onEntryTap,
    this.isDayFocus = false,
    super.key,
  });

  final List<TimeEntry> entries;
  final List<Activity> activities;
  final void Function(TimeEntry entry, Activity? activity) onEntryTap;
  final bool isDayFocus;

  static const _weekdays = [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY',
  ];
  static const _months = [
    'JANUARY',
    'FEBRUARY',
    'MARCH',
    'APRIL',
    'MAY',
    'JUNE',
    'JULY',
    'AUGUST',
    'SEPTEMBER',
    'OCTOBER',
    'NOVEMBER',
    'DECEMBER',
  ];

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return _EmptyHistory(isDayFocus: isDayFocus);
    final byActivity = {
      for (final activity in activities) activity.id: activity,
    };
    final groups = <DateTime, List<TimeEntry>>{};
    for (final entry in entries) {
      final day = DateTime(
        entry.endedAt.year,
        entry.endedAt.month,
        entry.endedAt.day,
      );
      groups.putIfAbsent(day, () => []).add(entry);
    }
    final dates = groups.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var groupIndex = 0; groupIndex < dates.length; groupIndex++) ...[
          _DateGroupLabel(
            title: _formatDate(dates[groupIndex]),
            count: groups[dates[groupIndex]]!.length,
          ),
          const SizedBox(height: 12),
          for (
            var index = 0;
            index < groups[dates[groupIndex]]!.length;
            index++
          ) ...[
            _HistoryEntryCard(
              entry: groups[dates[groupIndex]]![index],
              activity:
                  byActivity[groups[dates[groupIndex]]![index].activityId],
              onTap: () {
                final entry = groups[dates[groupIndex]]![index];
                onEntryTap(entry, byActivity[entry.activityId]);
              },
            ),
            if (index != groups[dates[groupIndex]]!.length - 1)
              const SizedBox(height: 11),
          ],
          if (groupIndex != dates.length - 1) const SizedBox(height: 28),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) =>
      '${_weekdays[date.weekday - 1]}, ${date.day} ${_months[date.month - 1]}';
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.isDayFocus});
  final bool isDayFocus;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 42),
    child: Column(
      children: [
        const Icon(
          Icons.history_rounded,
          color: AppColors.textSecondary,
          size: 34,
        ),
        const SizedBox(height: 12),
        Text(
          isDayFocus
              ? 'No sessions recorded for this day'
              : 'No sessions recorded',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 5),
        Text(
          'Your completed sessions will appear here.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class _DateGroupLabel extends StatelessWidget {
  const _DateGroupLabel({required this.title, required this.count});
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
      Text(
        '$count ${count == 1 ? 'session' : 'sessions'}',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
      ),
    ],
  );
}

class _HistoryEntryCard extends StatelessWidget {
  const _HistoryEntryCard({
    required this.entry,
    required this.activity,
    required this.onTap,
  });
  final TimeEntry entry;
  final Activity? activity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Color(activity?.colorValue ?? 0xFF3478F6);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: AppColors.stroke.withValues(alpha: 0.64)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x3D000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accent.withValues(alpha: 0.22)),
              ),
              child: Icon(
                ActivityVisuals.iconFor(activity?.iconKey ?? 'other'),
                color: accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity?.name ?? 'Unknown activity',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_time(entry.startedAt, entry.duration)}  –  '
                    '${_time(entry.endedAt, entry.duration)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      letterSpacing: 0.15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _duration(entry.duration),
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _time(DateTime date, Duration duration) {
    final base =
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
    if (duration.inSeconds.remainder(60) == 0) return base;
    return '$base:${date.second.toString().padLeft(2, '0')}';
  }

  String _duration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final parts = <String>[];
    if (hours > 0) parts.add('${hours}h');
    if (minutes > 0) parts.add('${minutes}m');
    if (seconds > 0 || parts.isEmpty) parts.add('${seconds}s');
    return parts.join(' ');
  }
}
