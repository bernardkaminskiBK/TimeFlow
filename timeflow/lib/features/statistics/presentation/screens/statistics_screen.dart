import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/widgets/timeflow_navigation.dart';
import '../../../activities/presentation/cubit/activity_cubit.dart';
import '../../../activities/presentation/cubit/activity_state.dart';
import '../../../time_entries/presentation/cubit/time_entry_cubit.dart';
import '../../domain/statistics_snapshot.dart';
import '../widgets/activity_breakdown_card.dart';
import '../widgets/activity_trend_card.dart';
import '../widgets/daily_averages_card.dart';
import '../widgets/focus_summary_card.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  var _period = StatisticsPeriod.week;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TimeEntryCubit, TimeEntryState>(
      builder: (context, timeEntryState) {
        return BlocBuilder<ActivityCubit, ActivityState>(
          builder: (context, activityState) {
            final snapshot = StatisticsSnapshot.from(
              entries: timeEntryState.entries,
              activities: activityState.activities,
              period: _period,
              now: DateTime.now(),
            );
            return Scaffold(
              extendBody: true,
              body: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.72, -0.58),
                    radius: 1.16,
                    colors: [Color(0xFF102746), AppColors.background],
                    stops: [0, 0.63],
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
                      return CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(side, 20, side, 14),
                            sliver: SliverToBoxAdapter(
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 520,
                                  ),
                                  child: const SizedBox(
                                    width: double.infinity,
                                    child: _StatisticsHeader(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _PeriodHeaderDelegate(
                              side: side,
                              child: _PeriodSelector(
                                selected: _period,
                                onSelected:
                                    (period) =>
                                        setState(() => _period = period),
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              side,
                              12,
                              side,
                              systemBottomInset +
                                  TimeFlowNavigation.clearanceHeight,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 520,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      FocusSummaryCard(snapshot: snapshot),
                                      const SizedBox(height: 18),
                                      ActivityBreakdownCard(snapshot: snapshot),
                                      const SizedBox(height: 18),
                                      DailyAveragesCard(snapshot: snapshot),
                                      const SizedBox(height: 18),
                                      ActivityTrendCard(snapshot: snapshot),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PeriodHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _PeriodHeaderDelegate({required this.side, required this.child});

  final double side;
  final Widget child;

  @override
  double get minExtent => 66;

  @override
  double get maxExtent => 66;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(side, 8, side, 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow:
                  overlapsContent
                      ? const [
                        BoxShadow(
                          color: Color(0x8A060B16),
                          blurRadius: 22,
                          offset: Offset(0, 10),
                        ),
                      ]
                      : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PeriodHeaderDelegate oldDelegate) =>
      oldDelegate.side != side || oldDelegate.child != child;
}

class _StatisticsHeader extends StatelessWidget {
  const _StatisticsHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Statistics', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 5),
        Text(
          'See where your time goes.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.selected, required this.onSelected});

  final StatisticsPeriod selected;
  final ValueChanged<StatisticsPeriod> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.stroke.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          for (final period in StatisticsPeriod.values)
            Expanded(
              child: _PeriodOption(
                label: switch (period) {
                  StatisticsPeriod.week => 'Week',
                  StatisticsPeriod.month => 'Month',
                  StatisticsPeriod.year => 'Year',
                },
                isSelected: selected == period,
                onTap: () => onSelected(period),
              ),
            ),
        ],
      ),
    );
  }
}

class _PeriodOption extends StatelessWidget {
  const _PeriodOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient:
                isSelected
                    ? const LinearGradient(
                      colors: [Color(0xFF3E8BF7), Color(0xFF2C65E8)],
                    )
                    : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.24),
                        blurRadius: 12,
                      ),
                    ]
                    : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
