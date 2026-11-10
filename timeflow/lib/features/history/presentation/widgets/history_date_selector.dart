import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

class HistoryDateSelector extends StatelessWidget {
  const HistoryDateSelector({super.key});

  static const _days = [
    ('THU', '6'),
    ('FRI', '7'),
    ('SAT', '8'),
    ('SUN', '9'),
    ('MON', '10'),
    ('TUE', '11'),
    ('WED', '12'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'NOVEMBER 2026',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            Spacer(),
            Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 70,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _days.length,
            separatorBuilder: (_, _) => const SizedBox(width: 9),
            itemBuilder: (context, index) {
              final day = _days[index];
              return _DateTile(
                weekday: day.$1,
                day: day.$2,
                isSelected: index == 4,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.weekday,
    required this.day,
    required this.isSelected,
  });

  final String weekday;
  final String day;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 52,
      decoration: BoxDecoration(
        gradient:
            isSelected
                ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF459BFF), Color(0xFF285FEA)],
                )
                : null,
        color: isSelected ? null : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              isSelected
                  ? AppColors.cyan.withValues(alpha: 0.46)
                  : AppColors.stroke.withValues(alpha: 0.72),
        ),
        boxShadow:
            isSelected
                ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 7),
                  ),
                ]
                : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            weekday,
            style: TextStyle(
              color: isSelected ? Colors.white70 : AppColors.textSecondary,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            day,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
