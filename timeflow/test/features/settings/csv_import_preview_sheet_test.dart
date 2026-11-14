import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/features/settings/data/services/csv_import_service.dart';
import 'package:timeflow/features/settings/presentation/widgets/csv_import_preview_sheet.dart';

void main() {
  testWidgets('renders an invalid CSV preview without decoration errors', (
    tester,
  ) async {
    const preview = CsvImportPreview(
      totalRows: 1,
      newActivities: [],
      newEntries: [],
      duplicateEntries: 0,
      errors: ['Row 2 is invalid.'],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: CsvImportPreviewSheet(
              fileName: 'timeflow-export.csv',
              preview: preview,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('CSV needs attention'), findsOneWidget);
    expect(find.text('Row 2 is invalid.'), findsOneWidget);
  });
}
