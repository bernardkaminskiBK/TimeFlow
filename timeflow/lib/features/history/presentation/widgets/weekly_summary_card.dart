import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

class WeeklySummaryCard extends StatelessWidget {
  const WeeklySummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
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
          const Expanded(
            child: _SummaryValue(label: 'THIS WEEK', value: '18h 45m'),
          ),
          Container(width: 1, height: 42, color: AppColors.stroke),
          const SizedBox(width: 20),
          const Expanded(
            child: _SummaryValue(label: 'COMPLETED', value: '12 sessions'),
          ),
        ],
      ),
    );
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
