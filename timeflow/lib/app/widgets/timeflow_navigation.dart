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
              child: SizedBox(
                height: 64,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          left: 13,
                          right: 13,
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOutCubic,
                            alignment: Alignment(selectedIndex - 1.0, 0),
                            child: Container(
                              width: constraints.maxWidth / 3 - 26,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primary.withValues(alpha: 0.2),
                                    AppColors.primary.withValues(alpha: 0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(17),
                                border: Border.all(
                                  color: AppColors.cyan.withValues(alpha: 0.1),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            _NavigationItem(
                              icon: Icons.timer_rounded,
                              label: 'Home',
                              isSelected: selectedIndex == 0,
                              onTap: () => onDestinationSelected(0),
                            ),
                            _NavigationItem(
                              icon: Icons.history_rounded,
                              label: 'History',
                              isSelected: selectedIndex == 1,
                              onTap: () => onDestinationSelected(1),
                            ),
                            _NavigationItem(
                              icon: Icons.bar_chart_rounded,
                              label: 'Statistics',
                              isSelected: selectedIndex == 2,
                              onTap: () => onDestinationSelected(2),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final targetColor = isSelected ? AppColors.cyan : AppColors.textSecondary;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(19),
            splashFactory: NoSplash.splashFactory,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<Color?>(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOutCubic,
                  tween: ColorTween(end: targetColor),
                  builder: (context, color, child) {
                    return Icon(icon, size: 21, color: color);
                  },
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOutCubic,
                  style: TextStyle(
                    color: targetColor,
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  ),
                  child: Text(label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
