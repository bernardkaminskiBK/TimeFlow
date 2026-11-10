import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/app/app.dart';

void main() {
  testWidgets('renders the TimeFlow home screen', (tester) async {
    await tester.pumpWidget(const TimeFlowApp());

    expect(find.text('TimeFlow'), findsOneWidget);
    expect(find.text('Programming'), findsOneWidget);
    expect(find.text('00:00:00'), findsOneWidget);
    expect(find.text('Start focus'), findsOneWidget);
  });
}
