import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../activities/presentation/activity_visuals.dart';
import '../../domain/statistics_snapshot.dart';

class DailyAveragesCard extends StatelessWidget {
  const DailyAveragesCard({required this.snapshot, super.key});

  final StatisticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.stroke.withValues(alpha: 0.7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x47000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Daily averages',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                snapshot.periodLabel,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          const Text(
            'Average time on days each activity was tracked',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 18),
          if (snapshot.activities.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No daily averages for this period yet.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            )
          else
            for (
              var index = 0;
              index < snapshot.activities.length;
              index++
            ) ...[
              if (index > 0) const SizedBox(height: 12),
              _AverageRow(statistic: snapshot.activities[index]),
            ],
        ],
      ),
    );
  }
}

class _AverageRow extends StatelessWidget {
  const _AverageRow({required this.statistic});

  final ActivityStatistic statistic;

  @override
  Widget build(BuildContext context) {
    final color = Color(statistic.activity.colorValue);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.elevatedSurface.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.stroke.withValues(alpha: 0.72)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: color.withValues(alpha: 0.24)),
            ),
            child: Icon(
              ActivityVisuals.iconFor(statistic.activity.iconKey),
              color: color,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statistic.activity.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${statistic.activeDays} active '
                  '${statistic.activeDays == 1 ? 'day' : 'days'}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatStatisticsDuration(statistic.activeDayAverage),
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'PER ACTIVE DAY',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
