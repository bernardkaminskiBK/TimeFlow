import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/widgets/timeflow_navigation.dart';
import '../../../time_entries/presentation/widgets/manual_time_entry_sheet.dart';
import '../../../timer/presentation/cubit/stopwatch_cubit.dart';
import '../widgets/activity_history_list.dart';
import '../widgets/history_date_selector.dart';
import '../widgets/weekly_summary_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final ScrollController _scrollController;
  var _showAddButton = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final isAtBottom =
        position.maxScrollExtent > 0 && position.extentAfter <= 12;
    final shouldShow = !isAtBottom;

    if (shouldShow != _showAddButton) {
      setState(() => _showAddButton = shouldShow);
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasSession = context.select<StopwatchCubit, bool>(
      (cubit) => cubit.state.hasSession,
    );
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
                controller: _scrollController,
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
                        _HistoryHeader(),
                        SizedBox(height: 26),
                        WeeklySummaryCard(),
                        SizedBox(height: 26),
                        HistoryDateSelector(),
                        SizedBox(height: 28),
                        ActivityHistoryList(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
          bottom: TimeFlowNavigation.clearanceHeight,
        ),
        child: IgnorePointer(
          ignoring: !_showAddButton,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            offset: _showAddButton ? Offset.zero : const Offset(0, 0.7),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              scale: _showAddButton ? 1 : 0.82,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 210),
                curve: Curves.easeOut,
                opacity: _showAddButton ? 1 : 0,
                child: _AddEntryButton(
                  onPressed:
                      hasSession
                          ? null
                          : () => showManualTimeEntrySheet(context),
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
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
}

class _AddEntryButton extends StatelessWidget {
  const _AddEntryButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.cyan, AppColors.primary],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.38),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        tooltip: 'Add manual entry',
        elevation: 0,
        highlightElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}
