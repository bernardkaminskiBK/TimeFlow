import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class TimeFlowNavigation extends StatelessWidget {
  const TimeFlowNavigation({
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  });

  static const clearanceHeight = 100.0;

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
            BoxShadow(
              color: Color(0x183478F6),
              blurRadius: 18,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xD90B1729),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: const Color(0x382F6FAC)),
              ),
              child: NavigationBar(
                height: 64,
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                indicatorColor: AppColors.primary.withValues(alpha: 0.16),
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.timer_outlined),
                    selectedIcon: Icon(
                      Icons.timer_rounded,
                      color: AppColors.cyan,
                    ),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.history_outlined),
                    selectedIcon: Icon(
                      Icons.history_rounded,
                      color: AppColors.cyan,
                    ),
                    label: 'History',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.bar_chart_outlined),
                    selectedIcon: Icon(
                      Icons.bar_chart_rounded,
                      color: AppColors.cyan,
                    ),
                    label: 'Statistics',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
