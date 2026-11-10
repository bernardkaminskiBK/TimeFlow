import 'package:flutter/material.dart';

import '../features/history/presentation/screens/history_screen.dart';
import '../features/statistics/presentation/screens/statistics_screen.dart';
import '../features/timer/presentation/screens/timer_screen.dart';
import 'splash/timeflow_splash.dart';
import 'theme/app_theme.dart';
import 'widgets/timeflow_navigation.dart';

class TimeFlowApp extends StatefulWidget {
  const TimeFlowApp({super.key});

  @override
  State<TimeFlowApp> createState() => _TimeFlowAppState();
}

class _TimeFlowAppState extends State<TimeFlowApp> {
  var _selectedIndex = 0;
  var _showStartup = true;

  void _selectDestination(int index) {
    if (index > 2 || index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
