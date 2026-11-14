import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../time_entries/domain/models/time_entry.dart';

class WeeklySummaryCard extends StatelessWidget {
  const WeeklySummaryCard({
    required this.entries,
    required this.selectedDate,
    super.key,
  });

  final List<TimeEntry> entries;
  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    final selectedDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final weekStart = selectedDay.subtract(
      Duration(days: selectedDay.weekday - DateTime.monday),
    );
    final weekEnd = weekStart.add(const Duration(days: 7));
    final weekEntries = entries.where(
      (entry) =>
          !entry.endedAt.isBefore(weekStart) && entry.endedAt.isBefore(weekEnd),
    );
    final total = weekEntries.fold(
      Duration.zero,
      (sum, entry) => sum + entry.duration,
    );
    final count = weekEntries.length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF142743), Color(0xFF0B1628)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x9A213654)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x52000000),
            blurRadius: 20,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.24),
              ),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: AppColors.cyan,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 6,
            child: _SummaryValue(
              label: 'SELECTED WEEK',
              value: _formatDuration(total),
            ),
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 42, color: AppColors.stroke),
          const SizedBox(width: 16),
          Expanded(
            flex: 5,
            child: _SummaryValue(
              label: 'COMPLETED',
              value: '$count ${count == 1 ? 'session' : 'sessions'}',
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final parts = <String>[];
    if (hours > 0) parts.add('${hours}h');
    if (minutes > 0) parts.add('${minutes}m');
    if (seconds > 0) parts.add('${seconds}s');
    return parts.isEmpty ? '0m' : parts.join(' ');
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.label, required this.value});

  final String label;
  final String value;

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
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 7),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: Theme.of(context).textTheme.titleLarge),
        ),
      ],
    );
  }
}
