import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/activities/data/repositories/in_memory_activity_repository.dart';
import '../features/activities/domain/repositories/activity_repository.dart';
import '../features/activities/presentation/cubit/activity_cubit.dart';
import '../features/history/presentation/screens/history_screen.dart';
import '../features/statistics/presentation/screens/statistics_screen.dart';
import '../features/time_entries/data/repositories/in_memory_time_entry_repository.dart';
import '../features/time_entries/domain/repositories/time_entry_repository.dart';
import '../features/timer/presentation/cubit/stopwatch_cubit.dart';
import '../features/timer/presentation/screens/timer_screen.dart';
import 'splash/timeflow_splash.dart';
import 'theme/app_theme.dart';
import 'widgets/timeflow_navigation.dart';

class TimeFlowApp extends StatefulWidget {
  const TimeFlowApp({super.key});

  @override
  State<TimeFlowApp> createState() => _TimeFlowAppState();
}

class _TimeFlowAppState extends State<TimeFlowApp> with WidgetsBindingObserver {
  late final ActivityRepository _activityRepository;
  late final ActivityCubit _activityCubit;
  late final TimeEntryRepository _timeEntryRepository;
  late final StopwatchCubit _stopwatchCubit;
  var _selectedIndex = 0;
  var _showStartup = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timeEntryRepository = InMemoryTimeEntryRepository();
    _activityRepository = InMemoryActivityRepository(
      hasTimeEntries: _timeEntryRepository.hasEntriesForActivity,
    );
    _stopwatchCubit = StopwatchCubit(_timeEntryRepository);
    _activityCubit = ActivityCubit(
      _activityRepository,
      hasSession: () => _stopwatchCubit.hasSession,
      isActivityLocked: _stopwatchCubit.isActivityLocked,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _stopwatchCubit.refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _activityCubit.close();
    _stopwatchCubit.close();
    super.dispose();
  }

  void _selectDestination(int index) {
    if (index > 2 || index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _activityRepository),
        RepositoryProvider.value(value: _timeEntryRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _activityCubit),
          BlocProvider.value(value: _stopwatchCubit),
        ],
        child: MaterialApp(
          title: 'TimeFlow',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          home: AnimatedSwitcher(
            duration: const Duration(milliseconds: 460),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween(begin: 0.985, end: 1.0).animate(animation),
                  child: child,
                ),
              );
            },
            child:
                _showStartup
                    ? TimeFlowSplash(
                      key: const ValueKey('startup'),
                      onFinished: () => setState(() => _showStartup = false),
                    )
                    : Stack(
                      key: const ValueKey('main'),
                      fit: StackFit.expand,
                      children: [
                        _AnimatedScreenStack(
                          selectedIndex: _selectedIndex,
                          children: const [
                            TimerScreen(),
                            HistoryScreen(),
                            StatisticsScreen(),
                          ],
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: TimeFlowNavigation(
                            selectedIndex: _selectedIndex,
                            onDestinationSelected: _selectDestination,
                          ),
                        ),
                      ],
                    ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedScreenStack extends StatelessWidget {
  const _AnimatedScreenStack({
    required this.selectedIndex,
    required this.children,
  });

  static const _duration = Duration(milliseconds: 180);
  static const _hiddenScale = 0.98;

  final int selectedIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: List.generate(children.length, (index) {
        final isSelected = index == selectedIndex;

        return ExcludeSemantics(
          excluding: !isSelected,
          child: IgnorePointer(
            ignoring: !isSelected,
            child: AnimatedScale(
              duration: _duration,
              curve: Curves.easeInOutCubic,
              scale: isSelected ? 1 : _hiddenScale,
              child: AnimatedOpacity(
                duration: _duration,
                curve: Curves.easeInOutCubic,
                opacity: isSelected ? 1 : 0,
                child: children[index],
              ),
            ),
          ),
        );
      }),
    );
  }
}
