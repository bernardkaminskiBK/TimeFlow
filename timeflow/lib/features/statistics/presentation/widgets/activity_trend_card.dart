import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/statistics_snapshot.dart';

class ActivityTrendCard extends StatelessWidget {
  const ActivityTrendCard({required this.snapshot, super.key});

  final StatisticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final peak = snapshot.trend.fold(
      Duration.zero,
      (current, point) => point.duration > current ? point.duration : current,
    );
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
                'Activity trend',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              const Icon(
                Icons.show_chart_rounded,
                color: AppColors.cyan,
                size: 19,
              ),
            ],
          ),
          const SizedBox(height: 7),
          const Text(
            'Daily tracked time',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 165,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(snapshot.trend.length, (index) {
                final point = snapshot.trend[index];
                return Expanded(
                  child: _TrendBar(
                    label: point.label,
                    duration: point.duration,
                    value:
                        peak == Duration.zero
                            ? 0
                            : point.duration.inMicroseconds /
                                peak.inMicroseconds,
                    isCurrent: point.isCurrent,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendBar extends StatelessWidget {
  const _TrendBar({
    required this.label,
    required this.duration,
    required this.value,
    required this.isCurrent,
  });

  final String label;
  final Duration duration;
  final double value;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          height: 11,
          child:
              duration > Duration.zero || isCurrent
                  ? FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _formatDuration(duration),
                      maxLines: 1,
                      style: TextStyle(
                        color:
                            isCurrent
                                ? AppColors.cyan
                                : const Color(0xFF397FEA),
                        fontSize: 9,
                        fontWeight:
                            isCurrent ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  )
                  : null,
        ),
        const SizedBox(height: 6),
        Flexible(
          child: FractionallySizedBox(
            heightFactor: value == 0 ? 0.025 : value,
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 18,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors:
                      isCurrent
                          ? const [Color(0xFF62D1FF), Color(0xFF3478F6)]
                          : const [Color(0xFF397FEA), Color(0xFF173C82)],
                ),
                borderRadius: BorderRadius.circular(9),
                boxShadow:
                    isCurrent
                        ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.28),
                            blurRadius: 12,
                          ),
                        ]
                        : null,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            color: isCurrent ? AppColors.textPrimary : AppColors.textSecondary,
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration value) {
    if (value == Duration.zero) return '0m';
    if (value.inHours > 0) {
      final minutes = value.inMinutes.remainder(60);
      return minutes == 0
          ? '${value.inHours}h'
          : '${value.inHours}h ${minutes}m';
    }
    if (value.inMinutes > 0) return '${value.inMinutes}m';
    return '${value.inSeconds}s';
  }
}
