import 'package:flutter/material.dart';

import '../features/timer/presentation/screens/timer_screen.dart';
import 'theme/app_theme.dart';

class TimeFlowApp extends StatelessWidget {
  const TimeFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TimeFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const TimerScreen(),
    );
  }
}
