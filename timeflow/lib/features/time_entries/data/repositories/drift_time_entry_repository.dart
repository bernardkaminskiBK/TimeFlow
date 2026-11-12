import 'dart:async';

import 'package:drift/drift.dart';

import '../../../../app/database/app_database.dart';
import '../../domain/models/time_entry.dart' as domain;
import '../../domain/repositories/time_entry_repository.dart';

class DriftTimeEntryRepository implements TimeEntryRepository {
  DriftTimeEntryRepository(this.db);
  final AppDatabase db;
  final _changes = StreamController<void>.broadcast();

  @override
  Future<List<domain.TimeEntry>> getEntries() async =>
      (await _orderedEntries().get()).map(_toDomain).toList();

  @override
  Stream<List<domain.TimeEntry>> watchEntries() async* {
    yield await getEntries();
    await for (final _ in _changes.stream) {
      yield await getEntries();
    }
  }

  SimpleSelectStatement<$TimeEntriesTable, TimeEntryRow> _orderedEntries() =>
      db.select(db.timeEntries)
        ..orderBy([(table) => OrderingTerm.desc(table.startedAt)]);

  domain.TimeEntry _toDomain(TimeEntryRow row) => domain.TimeEntry(
    id: row.id,
    activityId: row.activityId,
    startedAt: row.startedAt,
    endedAt: row.endedAt,
    duration: Duration(milliseconds: row.durationMilliseconds),
    createdAt: row.createdAt,
  );

  @override
  Future<bool> hasEntriesForActivity(String id) async =>
      await (db.select(db.timeEntries)
            ..where((t) => t.activityId.equals(id))
            ..limit(1))
          .getSingleOrNull() !=
      null;

  @override
  Future<void> saveEntry(domain.TimeEntry e) async {
    await db
        .into(db.timeEntries)
        .insertOnConflictUpdate(
          TimeEntriesCompanion.insert(
            id: e.id,
            activityId: e.activityId,
            startedAt: e.startedAt,
            endedAt: e.endedAt,
            durationMilliseconds: e.duration.inMilliseconds,
            createdAt: e.createdAt,
          ),
        );
    _changes.add(null);
  }
}
