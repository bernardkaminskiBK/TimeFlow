import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/app/database/app_database.dart';
import 'package:timeflow/app/database/development_data_seeder.dart';

void main() {
  test('seeds varied development entries only once', () async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    final now = DateTime(2026, 11, 13, 12);

    await seedDevelopmentData(database, now: now);
    final firstEntries = await database.select(database.timeEntries).get();

    await seedDevelopmentData(database, now: now.add(const Duration(days: 1)));
    final secondEntries = await database.select(database.timeEntries).get();

    expect(firstEntries.length, greaterThan(70));
    expect(secondEntries.length, firstEntries.length);
    expect(
      firstEntries.map((entry) => entry.activityId).toSet(),
      containsAll([
        'activity-programming',
        'activity-english',
        'activity-workout',
        'activity-reading',
      ]),
    );
    expect(firstEntries.any((entry) => entry.note != null), isTrue);
    expect(
      firstEntries.any((entry) => entry.endedAt.year == now.year - 1),
      isTrue,
    );
  });
}
