import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

@DataClassName('ActivityRow')
class Activities extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get colorValue => integer()();
  TextColumn get iconKey => text()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().nullable()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('TimeEntryRow')
class TimeEntries extends Table {
  TextColumn get id => text()();
  TextColumn get activityId =>
      text().references(Activities, #id, onDelete: KeyAction.restrict)();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime()();
  IntColumn get durationMilliseconds => integer()();
  DateTimeColumn get createdAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [Activities, TimeEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'timeflow'));
  AppDatabase.inMemory() : super(NativeDatabase.memory());
  @override
  int get schemaVersion => 2;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (_) async => customStatement('PRAGMA foreign_keys = ON'),
    onCreate: (m) async {
      await m.createAll();
      await batch(
        (b) => b.insertAll(activities, [
          ActivitiesCompanion.insert(
            id: 'activity-programming',
            name: 'Programming',
            colorValue: 0xFF52C7FF,
            iconKey: 'code',
          ),
          ActivitiesCompanion.insert(
            id: 'activity-english',
            name: 'English',
            colorValue: 0xFF8B7CFF,
            iconKey: 'language',
          ),
          ActivitiesCompanion.insert(
            id: 'activity-workout',
            name: 'Workout',
            colorValue: 0xFFFF7A90,
            iconKey: 'workout',
          ),
          ActivitiesCompanion.insert(
            id: 'activity-reading',
            name: 'Reading',
            colorValue: 0xFFFFB85C,
            iconKey: 'reading',
          ),
        ]),
      );
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(activities, activities.createdAt);
      }
    },
  );
}
