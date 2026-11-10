import 'package:flutter/material.dart';

import '../features/history/presentation/screens/history_screen.dart';
import '../features/timer/presentation/screens/timer_screen.dart';
import 'theme/app_theme.dart';

class TimeFlowApp extends StatefulWidget {
  const TimeFlowApp({super.key});

  @override
  State<TimeFlowApp> createState() => _TimeFlowAppState();
}

class _TimeFlowAppState extends State<TimeFlowApp> {
  var _selectedIndex = 0;

  void _selectDestination(int index) {
    if (index > 1 || index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TimeFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: IndexedStack(
        index: _selectedIndex,
        children: [
          TimerScreen(onDestinationSelected: _selectDestination),
          HistoryScreen(onDestinationSelected: _selectDestination),
        ],
      ),
    );
  }
}
