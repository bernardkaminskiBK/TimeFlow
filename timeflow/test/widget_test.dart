import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/app/app.dart';
import 'package:timeflow/features/timer/presentation/widgets/current_activity_selector.dart';

void main() {
  testWidgets('renders the TimeFlow home screen', (tester) async {
    await tester.pumpWidget(const TimeFlowApp());
    await tester.pumpAndSettle();

    expect(find.text('TimeFlow'), findsOneWidget);
    expect(find.text('Programming').hitTestable(), findsOneWidget);
    expect(find.text('00:00:00'), findsOneWidget);
    expect(find.text('Start focus'), findsOneWidget);
  });

  testWidgets('switches between all main screens in both directions', (
    tester,
  ) async {
    await tester.pumpWidget(const TimeFlowApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('History').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('Your time, your story.').hitTestable(), findsOneWidget);

    await tester.tap(find.text('Statistics').hitTestable());
    await tester.pumpAndSettle();
    expect(
      find.text('See where your time goes.').hitTestable(),
      findsOneWidget,
    );

    await tester.tap(find.text('History').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('Your time, your story.').hitTestable(), findsOneWidget);

    await tester.tap(find.text('Home').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('Make today count.').hitTestable(), findsOneWidget);
  });

  testWidgets('selects the current activity from the home screen', (
    tester,
  ) async {
    await tester.pumpWidget(const TimeFlowApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Programming').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('Choose activity'), findsOneWidget);

    await tester.tap(find.text('English').hitTestable());
    await tester.pumpAndSettle();

    expect(find.text('English').hitTestable(), findsOneWidget);
    expect(find.text('Choose activity'), findsNothing);
  });

  testWidgets('adds a manual entry from the home screen', (tester) async {
    await tester.pumpWidget(const TimeFlowApp());
    await tester.pumpAndSettle();

    final manualEntryButton = find.bySemanticsLabel('Add manual time');
    await tester.ensureVisible(manualEntryButton);
    await tester.pump();
    await tester.tap(manualEntryButton.hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('Add manual entry'), findsOneWidget);
    expect(find.text('Programming'), findsWidgets);

    await tester.ensureVisible(find.text('Save entry'));
    await tester.tap(find.text('Save entry').hitTestable());
    await tester.pumpAndSettle();

    expect(find.text('Add manual entry'), findsNothing);
    expect(
      find.text('Your manual entry was successfully saved.').hitTestable(),
      findsOneWidget,
    );

    await tester.tap(find.text('History').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('Programming').hitTestable(), findsOneWidget);
    expect(find.text('30m').hitTestable(), findsWidgets);

    await tester.tap(find.text('${DateTime.now().day}').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('Timeline').hitTestable(), findsOneWidget);

    await tester.tap(find.text('Timeline').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('Timeline'), findsNothing);
  });

  testWidgets('keeps a running session across navigation tabs', (tester) async {
    await tester.pumpWidget(const TimeFlowApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Start focus'));
    await tester.pump();
    await tester.tap(find.text('Start focus').hitTestable());
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Pause').hitTestable(), findsOneWidget);
    expect(find.text('Stop').hitTestable(), findsOneWidget);

    await tester.ensureVisible(find.byType(CurrentActivitySelector));
    await tester.pump();
    await tester.tap(find.byType(CurrentActivitySelector));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Choose activity'), findsNothing);

    await tester.tap(find.text('History').hitTestable());
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Your time, your story.').hitTestable(), findsOneWidget);

    await tester.tap(find.text('Home').hitTestable());
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Pause').hitTestable(), findsOneWidget);

    await tester.ensureVisible(find.text('Stop').hitTestable());
    await tester.tap(find.text('Stop').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('Save').hitTestable(), findsOneWidget);
    expect(
      find.bySemanticsLabel('Discard session').hitTestable(),
      findsOneWidget,
    );
    expect(find.text('Resume').hitTestable(), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Discard session').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('Start focus').hitTestable(), findsOneWidget);
  });
}
