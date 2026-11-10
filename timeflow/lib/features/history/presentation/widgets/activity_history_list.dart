import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

class ActivityHistoryList extends StatelessWidget {
  const ActivityHistoryList({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DateGroupLabel(
          title: 'MONDAY, 10 NOVEMBER',
          sessionCount: '3 sessions',
        ),
        SizedBox(height: 12),
        _HistoryEntryCard(
          icon: Icons.code_rounded,
          accent: AppColors.cyan,
          activity: 'Programming',
          timeRange: '09:00  –  11:15',
          duration: '2h 15m',
        ),
        SizedBox(height: 11),
        _HistoryEntryCard(
          icon: Icons.translate_rounded,
          accent: Color(0xFF8B7CFF),
          activity: 'English',
          timeRange: '13:30  –  14:30',
          duration: '1h',
        ),
        SizedBox(height: 11),
        _HistoryEntryCard(
          icon: Icons.fitness_center_rounded,
          accent: Color(0xFFFF7A90),
          activity: 'Workout',
          timeRange: '17:00  –  17:50',
          duration: '50m',
        ),
        SizedBox(height: 28),
        _DateGroupLabel(
          title: 'SUNDAY, 9 NOVEMBER',
          sessionCount: '2 sessions',
        ),
        SizedBox(height: 12),
        _HistoryEntryCard(
          icon: Icons.menu_book_rounded,
          accent: Color(0xFFFFB85C),
          activity: 'Reading',
          timeRange: '10:20  –  11:05',
          duration: '45m',
        ),
        SizedBox(height: 11),
        _HistoryEntryCard(
          icon: Icons.code_rounded,
          accent: AppColors.cyan,
          activity: 'Programming',
          timeRange: '15:10  –  17:40',
          duration: '2h 30m',
        ),
      ],
    );
  }
}

class _DateGroupLabel extends StatelessWidget {
  const _DateGroupLabel({required this.title, required this.sessionCount});

  final String title;
  final String sessionCount;

  @override
  Widget build(BuildContext context) {
    return Row(
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
          sessionCount,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
        ),
      ],
    );
  }
}

class _HistoryEntryCard extends StatelessWidget {
  const _HistoryEntryCard({
    required this.icon,
    required this.accent,
    required this.activity,
    required this.timeRange,
    required this.duration,
  });

  final IconData icon;
  final Color accent;
  final String activity;
  final String timeRange;
  final String duration;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  timeRange,
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
              duration,
              style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
