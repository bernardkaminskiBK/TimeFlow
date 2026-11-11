import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/app/app.dart';

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
}
