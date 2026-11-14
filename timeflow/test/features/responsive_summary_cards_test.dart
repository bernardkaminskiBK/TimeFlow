import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/app/theme/app_theme.dart';
import 'package:timeflow/features/history/presentation/widgets/weekly_summary_card.dart';
import 'package:timeflow/features/statistics/domain/statistics_snapshot.dart';
import 'package:timeflow/features/statistics/presentation/widgets/focus_summary_card.dart';
import 'package:timeflow/features/time_entries/domain/models/time_entry.dart';

void main() {
  testWidgets('summary values fit a narrow card with large totals', (
    tester,
  ) async {
    const snapshot = StatisticsSnapshot(
      period: StatisticsPeriod.week,
      total: Duration(hours: 123, minutes: 45, seconds: 56),
      previousTotal: Duration(hours: 100),
      activities: [],
      trend: [],
    );

    await tester.pumpWidget(
      _TestFrame(child: FocusSummaryCard(snapshot: snapshot)),
    );
    expect(tester.takeException(), isNull);

    final selectedDate = DateTime(2026, 11, 14, 12);
    final entries = List.generate(100, (index) {
      const duration = Duration(hours: 1, minutes: 14);
      return TimeEntry(
        id: 'entry-$index',
        activityId: 'activity-programming',
        startedAt: selectedDate.subtract(duration),
        endedAt: selectedDate,
        duration: duration,
        createdAt: selectedDate,
      );
    });

    await tester.pumpWidget(
      _TestFrame(
        child: WeeklySummaryCard(entries: entries, selectedDate: selectedDate),
      ),
    );
    expect(find.text('123h 20m'), findsOneWidget);
    expect(find.text('100 sessions'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _TestFrame extends StatelessWidget {
  const _TestFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: Center(child: SizedBox(width: 320, child: child))),
    );
  }
}
