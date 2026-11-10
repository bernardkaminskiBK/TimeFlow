import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/widgets/timeflow_navigation.dart';
import '../widgets/activity_breakdown_card.dart';
import '../widgets/activity_trend_card.dart';
import '../widgets/focus_summary_card.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _StatisticsHeader(),
                        SizedBox(height: 22),
                        _PeriodSelector(),
                        SizedBox(height: 24),
                        FocusSummaryCard(),
                        SizedBox(height: 18),
                        ActivityBreakdownCard(),
                        SizedBox(height: 18),
                        ActivityTrendCard(),
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
  const _PeriodSelector();

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
      child: const Row(
        children: [
          Expanded(child: _PeriodOption(label: 'Week', isSelected: true)),
          Expanded(child: _PeriodOption(label: 'Month')),
          Expanded(child: _PeriodOption(label: 'Year')),
        ],
      ),
    );
  }
}

class _PeriodOption extends StatelessWidget {
  const _PeriodOption({required this.label, this.isSelected = false});

  final String label;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
