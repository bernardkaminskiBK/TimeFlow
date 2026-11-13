import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

class HistoryDateSelector extends StatefulWidget {
  const HistoryDateSelector({
    required this.selectedDate,
    required this.onDateSelected,
    required this.onCalendarPressed,
    super.key,
  });

  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onCalendarPressed;

  @override
  State<HistoryDateSelector> createState() => _HistoryDateSelectorState();
}

class _HistoryDateSelectorState extends State<HistoryDateSelector> {
  static const _weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
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
  late DateTime _rangeEnd;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _rangeEnd = _dateOnly(DateTime.now());
    final selectedDate = widget.selectedDate;
    if (selectedDate != null && !_isVisible(selectedDate)) {
      _rangeEnd = _dateOnly(selectedDate);
    }
  }

  @override
  void didUpdateWidget(covariant HistoryDateSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selectedDate = widget.selectedDate;
    final returnedToTimeline =
        oldWidget.selectedDate != null && selectedDate == null;
    if (returnedToTimeline) {
      _rangeEnd = _dateOnly(DateTime.now());
      _resetScrollPosition();
    } else if (selectedDate != null && !_isVisible(selectedDate)) {
      _rangeEnd = _dateOnly(selectedDate);
      _resetScrollPosition();
    }
  }

  void _resetScrollPosition() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _isVisible(DateTime date) {
    final day = _dateOnly(date);
    final start = _rangeEnd.subtract(const Duration(days: 6));
    return !day.isBefore(start) && !day.isAfter(_rangeEnd);
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  @override
  Widget build(BuildContext context) {
    final days = List.generate(
      7,
      (index) => _rangeEnd.subtract(Duration(days: index)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${_months[(widget.selectedDate ?? _rangeEnd).month - 1]} '
              '${(widget.selectedDate ?? _rangeEnd).year}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Choose date',
              onPressed: widget.onCalendarPressed,
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.calendar_today_outlined,
                size: 17,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 70,
          child: ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            reverse: true,
            itemCount: days.length,
            separatorBuilder: (_, _) => const SizedBox(width: 9),
            itemBuilder: (context, index) {
              final day = days[index];
              return _DateTile(
                weekday: _weekdays[day.weekday - 1],
                day: '${day.day}',
                isSelected:
                    widget.selectedDate != null &&
                    DateUtils.isSameDay(day, widget.selectedDate),
                isToday: DateUtils.isSameDay(day, DateTime.now()),
                onTap: () => widget.onDateSelected(day),
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
    required this.isToday,
    required this.onTap,
  });
  final String weekday;
  final String day;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
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
                    : isToday
                    ? AppColors.cyan.withValues(alpha: 0.26)
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
      ),
    ),
  );
}
