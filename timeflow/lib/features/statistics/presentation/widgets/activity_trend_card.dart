import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

class ActivityTrendCard extends StatelessWidget {
  const ActivityTrendCard({super.key});

  static const _values = [0.62, 0.86, 0.48, 1.0, 0.72, 0.39, 0.58];
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

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
              children: List.generate(_days.length, (index) {
                return Expanded(
                  child: _TrendBar(
                    day: _days[index],
                    value: _values[index],
                    isPeak: index == 3,
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
    required this.day,
    required this.value,
    required this.isPeak,
  });

  final String day;
  final double value;
  final bool isPeak;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isPeak)
          const Text(
            '4h',
            style: TextStyle(
              color: AppColors.cyan,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          )
        else
          const SizedBox(height: 11),
        const SizedBox(height: 6),
        Flexible(
          child: FractionallySizedBox(
            heightFactor: value,
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 18,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors:
                      isPeak
                          ? const [Color(0xFF62D1FF), Color(0xFF3478F6)]
                          : const [Color(0xFF397FEA), Color(0xFF173C82)],
                ),
                borderRadius: BorderRadius.circular(9),
                boxShadow:
                    isPeak
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
          day,
          style: TextStyle(
            color: isPeak ? AppColors.textPrimary : AppColors.textSecondary,
            fontSize: 10,
            fontWeight: isPeak ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
