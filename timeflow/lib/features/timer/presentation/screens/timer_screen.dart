import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/widgets/timeflow_navigation.dart';
import '../../../activities/presentation/screens/manage_activities_screen.dart';
import '../widgets/daily_summary_card.dart';
import '../widgets/stopwatch_dial.dart';
import '../widgets/timer_controls.dart';

class TimerScreen extends StatelessWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.55, -0.38),
            radius: 1.05,
            colors: [Color(0xFF10264A), AppColors.background],
            stops: [0, 0.64],
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
              final navigationClearance =
                  systemBottomInset + TimeFlowNavigation.clearanceHeight;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  side,
                  20,
                  side,
                  navigationClearance,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _Header(),
                        const SizedBox(height: 28),
                        const _ActivityLabel(),
                        const SizedBox(height: 16),
                        const StopwatchDial(),
                        const SizedBox(height: 24),
                        TimerControls(
                          onManageActivities:
                              () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder:
                                      (_) => const ManageActivitiesScreen(),
                                ),
                              ),
                        ),
                        const SizedBox(height: 28),
                        const DailySummaryCard(),
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

class _Header extends StatefulWidget {
  const _Header();

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> with WidgetsBindingObserver {
  static const _weekdays = [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY',
  ];
  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  late DateTime _currentDate;
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateDate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateDate();
    }
  }

  void _updateDate() {
    final now = DateTime.now();
    _midnightTimer?.cancel();
    _midnightTimer = Timer(
      DateTime(now.year, now.month, now.day + 1).difference(now),
      _updateDate,
    );

    if (mounted) {
      setState(() => _currentDate = now);
    } else {
      _currentDate = now;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TimeFlow',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 5),
              Text(
                'Make today count.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _weekdays[_currentDate.weekday - 1],
              style: const TextStyle(
                color: AppColors.cyan,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '${_currentDate.day} ${_months[_currentDate.month - 1]}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActivityLabel extends StatelessWidget {
  const _ActivityLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.28),
            ),
          ),
          child: const Icon(
            Icons.code_rounded,
            size: 19,
            color: AppColors.cyan,
          ),
        ),
        const SizedBox(width: 11),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CURRENT ACTIVITY',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.35,
              ),
            ),
            Text('Programming', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ],
    );
  }
}
