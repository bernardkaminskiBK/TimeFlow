import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../activities/presentation/cubit/activity_cubit.dart';
import '../../../activities/presentation/cubit/activity_state.dart';
import '../../../time_entries/domain/models/time_entry.dart';
import '../../../time_entries/presentation/cubit/time_entry_cubit.dart';

class DailySummaryCard extends StatelessWidget {
  const DailySummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TimeEntryCubit, TimeEntryState>(
      buildWhen: (previous, current) => previous.entries != current.entries,
      builder: (context, timeEntryState) {
        return BlocBuilder<ActivityCubit, ActivityState>(
          buildWhen:
              (previous, current) => previous.activities != current.activities,
          builder: (context, activityState) {
            final summary = _DailySummary.from(
              timeEntryState.entries,
              activityState,
              DateTime.now(),
            );
            return _SummaryCard(summary: summary);
          },
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final _DailySummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.stroke.withValues(alpha: 0.68)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x60000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_graph_rounded, size: 17, color: AppColors.cyan),
              SizedBox(width: 8),
              Text(
                "TODAY'S FLOW",
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.45,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: 'TOTAL TIME',
                  value: _formatDuration(summary.todayTotal),
                  detail: _comparisonText(
                    summary.todayTotal,
                    summary.yesterdayTotal,
                  ),
                ),
              ),
              Container(width: 1, height: 54, color: AppColors.stroke),
              const SizedBox(width: 20),
              Expanded(
                child: _SummaryMetric(
                  label: 'SESSIONS',
                  value: '${summary.sessionCount}',
                  detail:
                      summary.topActivityName == null
                          ? 'No sessions yet'
                          : '${_formatDuration(summary.topActivityDuration)} '
                              '${summary.topActivityName}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _comparisonText(Duration today, Duration yesterday) {
    final difference = today - yesterday;
    if (difference == Duration.zero) return 'Same as yesterday';
    final prefix = difference.isNegative ? '-' : '+';
    return '$prefix${_formatDuration(difference.abs())} from yesterday';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final parts = <String>[];
    if (hours > 0) parts.add('${hours}h');
    if (minutes > 0) parts.add('${minutes}m');
    if (seconds > 0 && hours == 0) parts.add('${seconds}s');
    return parts.isEmpty ? '0m' : parts.join(' ');
  }
}

class _DailySummary {
  const _DailySummary({
    required this.todayTotal,
    required this.yesterdayTotal,
    required this.sessionCount,
    required this.topActivityDuration,
    this.topActivityName,
  });

  factory _DailySummary.from(
    List<TimeEntry> entries,
    ActivityState activityState,
    DateTime now,
  ) {
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));
    final todayEntries = entries.where(
      (entry) =>
          !entry.endedAt.isBefore(today) && entry.endedAt.isBefore(tomorrow),
    );
    final yesterdayEntries = entries.where(
      (entry) =>
          !entry.endedAt.isBefore(yesterday) && entry.endedAt.isBefore(today),
    );
    final durationsByActivity = <String, Duration>{};
    var todayTotal = Duration.zero;
    var sessionCount = 0;
    for (final entry in todayEntries) {
      todayTotal += entry.duration;
      sessionCount++;
      durationsByActivity.update(
        entry.activityId,
        (duration) => duration + entry.duration,
        ifAbsent: () => entry.duration,
      );
    }
    final yesterdayTotal = yesterdayEntries.fold(
      Duration.zero,
      (total, entry) => total + entry.duration,
    );
    String? topActivityId;
    var topActivityDuration = Duration.zero;
    for (final entry in durationsByActivity.entries) {
      if (entry.value > topActivityDuration) {
        topActivityId = entry.key;
        topActivityDuration = entry.value;
      }
    }
    String? topActivityName;
    if (topActivityId != null) {
      for (final activity in activityState.activities) {
        if (activity.id == topActivityId) {
          topActivityName = activity.name;
          break;
        }
      }
    }
    return _DailySummary(
      todayTotal: todayTotal,
      yesterdayTotal: yesterdayTotal,
      sessionCount: sessionCount,
      topActivityDuration: topActivityDuration,
      topActivityName: topActivityName,
    );
  }

  final Duration todayTotal;
  final Duration yesterdayTotal;
  final int sessionCount;
  final Duration topActivityDuration;
  final String? topActivityName;
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.detail,
  });

  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.15,
          ),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: Theme.of(context).textTheme.titleLarge),
        ),
        const SizedBox(height: 4),
        Text(
          detail,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
        ),
      ],
    );
  }
}
