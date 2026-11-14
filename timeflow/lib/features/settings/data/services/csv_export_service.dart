import 'package:csv/csv.dart';

import '../../../activities/domain/repositories/activity_repository.dart';
import '../../../time_entries/domain/repositories/time_entry_repository.dart';
import 'timeflow_csv_schema.dart';

class CsvExportDocument {
  const CsvExportDocument({
    required this.fileName,
    required this.csv,
    required this.sessionCount,
    required this.activityCount,
  });

  final String fileName;
  final String csv;
  final int sessionCount;
  final int activityCount;
}

class CsvExportService {
  const CsvExportService(this._activityRepository, this._timeEntryRepository);

  final ActivityRepository _activityRepository;
  final TimeEntryRepository _timeEntryRepository;

  Future<CsvExportDocument> create({DateTime? now}) async {
    final activities = await _activityRepository.getActivities();
    final entries = await _timeEntryRepository.getEntries();
    final activityById = {
      for (final activity in activities) activity.id: activity,
    };
    final rows = <List<Object?>>[timeFlowCsvHeaders];
    final exportedActivityIds = <String>{};

    for (final entry in entries) {
      final activity = activityById[entry.activityId];
      if (activity == null) {
        throw StateError(
          'Time entry ${entry.id} references a missing activity.',
        );
      }
      exportedActivityIds.add(activity.id);
      rows.add([
        timeFlowCsvFormatVersion,
        entry.id,
        activity.id,
        activity.name,
        activity.colorValue,
        activity.iconKey,
        activity.isArchived,
        activity.createdAt?.toIso8601String() ?? '',
        entry.startedAt.toIso8601String(),
        entry.endedAt.toIso8601String(),
        entry.duration.inMilliseconds,
        entry.createdAt.toIso8601String(),
        entry.note ?? '',
      ]);
    }

    final createdAt = now ?? DateTime.now();
    return CsvExportDocument(
      fileName: 'timeflow-export-${_fileTimestamp(createdAt)}.csv',
      csv: const ListToCsvConverter().convert(rows),
      sessionCount: entries.length,
      activityCount: exportedActivityIds.length,
    );
  }

  String _fileTimestamp(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}-'
      '${value.hour.toString().padLeft(2, '0')}'
      '${value.minute.toString().padLeft(2, '0')}'
      '${value.second.toString().padLeft(2, '0')}';
}
