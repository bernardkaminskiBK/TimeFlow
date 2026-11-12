import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/widgets/timeflow_navigation.dart';
import '../../../activities/presentation/cubit/activity_cubit.dart';
import '../../../activities/presentation/cubit/activity_state.dart';
import '../../../time_entries/presentation/cubit/time_entry_cubit.dart';
import '../widgets/activity_history_list.dart';
import '../widgets/history_date_selector.dart';
import '../widgets/session_detail_sheet.dart';
import '../widgets/weekly_summary_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime? _selectedDate;

  Future<void> _chooseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null && mounted) setState(() => _selectedDate = date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.7, -0.6),
            radius: 1.15,
            colors: [Color(0xFF102546), AppColors.background],
            stops: [0, 0.62],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final side = constraints.maxWidth < 380 ? 18.0 : 24.0;
              final mediaQuery = MediaQuery.of(context);
              final systemBottomInset = math.max(
                mediaQuery.viewPadding.bottom,
                mediaQuery.systemGestureInsets.bottom,
              );
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  side,
                  20,
                  side,
                  systemBottomInset + TimeFlowNavigation.clearanceHeight,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _HistoryHeader(),
                        const SizedBox(height: 26),
                        BlocBuilder<TimeEntryCubit, TimeEntryState>(
                          buildWhen:
                              (previous, current) =>
                                  previous.entries != current.entries,
                          builder:
                              (context, state) => WeeklySummaryCard(
                                entries: state.entries,
                                selectedDate: _selectedDate ?? DateTime.now(),
                              ),
                        ),
                        const SizedBox(height: 26),
                        HistoryDateSelector(
                          key: ValueKey(_selectedDate == null),
                          selectedDate: _selectedDate,
                          onDateSelected:
                              (date) => setState(() => _selectedDate = date),
                          onCalendarPressed: _chooseDate,
                        ),
                        const SizedBox(height: 28),
                        if (_selectedDate != null) ...[
                          Align(
                            alignment: Alignment.centerRight,
                            child: _TimelineChip(
                              onTap: () => setState(() => _selectedDate = null),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        BlocBuilder<TimeEntryCubit, TimeEntryState>(
                          builder: (context, timeEntryState) {
                            final selectedDate = _selectedDate;
                            final visibleEntries =
                                selectedDate == null
                                    ? timeEntryState.entries
                                    : timeEntryState.entries
                                        .where(
                                          (entry) =>
                                              !entry.endedAt.isBefore(
                                                selectedDate,
                                              ) &&
                                              entry.endedAt.isBefore(
                                                selectedDate.add(
                                                  const Duration(days: 1),
                                                ),
                                              ),
                                        )
                                        .toList(growable: false);
                            return BlocBuilder<ActivityCubit, ActivityState>(
                              builder:
                                  (context, activityState) =>
                                      ActivityHistoryList(
                                        entries: visibleEntries,
                                        activities: activityState.activities,
                                        isDayFocus: selectedDate != null,
                                        onEntryTap:
                                            (entry, activity) =>
                                                showSessionDetailSheet(
                                                  context,
                                                  entry: entry,
                                                  activity: activity,
                                                ),
                                      ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TimelineChip extends StatelessWidget {
  const _TimelineChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.primary.withValues(alpha: 0.12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: AppColors.cyan.withValues(alpha: 0.24)),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timeline_rounded, color: AppColors.cyan, size: 16),
            SizedBox(width: 7),
            Text(
              'Timeline',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: 5),
            Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 15),
          ],
        ),
      ),
    ),
  );
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('History', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 5),
      Text(
        'Your time, your story.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    ],
  );
}
