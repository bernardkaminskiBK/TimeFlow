import 'package:csv/csv.dart';

import '../../../activities/domain/models/activity.dart';
import '../../../activities/domain/repositories/activity_repository.dart';
import '../../../time_entries/domain/models/time_entry.dart';
import '../../../time_entries/domain/repositories/time_entry_repository.dart';
import 'timeflow_csv_schema.dart';

class CsvImportPreview {
  const CsvImportPreview({
    required this.totalRows,
    required this.newActivities,
    required this.newEntries,
    required this.duplicateEntries,
    required this.errors,
  });

  final int totalRows;
  final List<Activity> newActivities;
  final List<TimeEntry> newEntries;
  final int duplicateEntries;
  final List<String> errors;

  bool get isValid => totalRows > 0 && errors.isEmpty;
  bool get hasChanges => newActivities.isNotEmpty || newEntries.isNotEmpty;

  DateTime? get earliestEntry {
    if (newEntries.isEmpty) return null;
    return newEntries
        .map((entry) => entry.endedAt)
        .reduce((left, right) => left.isBefore(right) ? left : right);
  }

  DateTime? get latestEntry {
    if (newEntries.isEmpty) return null;
    return newEntries
        .map((entry) => entry.endedAt)
        .reduce((left, right) => left.isAfter(right) ? left : right);
  }
}

class CsvImportResult {
  const CsvImportResult({
    required this.importedActivities,
    required this.importedEntries,
    required this.skippedDuplicates,
  });

  final int importedActivities;
  final int importedEntries;
  final int skippedDuplicates;
}

class CsvImportService {
  const CsvImportService(this._activityRepository, this._timeEntryRepository);

  static const _durationClockTolerance = Duration(seconds: 1);

  final ActivityRepository _activityRepository;
  final TimeEntryRepository _timeEntryRepository;

  Future<CsvImportPreview> prepare(String source) async {
    final errors = <String>[];
    final normalized = source.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    late final List<List<String>> rows;
    try {
      rows = const CsvToListConverter(
        eol: '\n',
        shouldParseNumbers: false,
        allowInvalid: false,
        convertEmptyTo: '',
      ).convert<String>(normalized);
    } catch (_) {
      return const CsvImportPreview(
        totalRows: 0,
        newActivities: [],
        newEntries: [],
        duplicateEntries: 0,
        errors: ['The selected file is not valid CSV.'],
      );
    }

    if (rows.isEmpty) {
      return const CsvImportPreview(
        totalRows: 0,
        newActivities: [],
        newEntries: [],
        duplicateEntries: 0,
        errors: ['The selected CSV file is empty.'],
      );
    }

    final header = <String, int>{};
    for (var index = 0; index < rows.first.length; index++) {
      final name = rows.first[index].trim().replaceFirst('\ufeff', '');
      if (name.isEmpty || header.containsKey(name)) {
        errors.add('The CSV header contains an empty or duplicate column.');
        continue;
      }
      header[name] = index;
    }
    final missingHeaders =
        timeFlowCsvHeaders.where((name) => !header.containsKey(name)).toList();
    if (missingHeaders.isNotEmpty) {
      errors.add('Missing columns: ${missingHeaders.join(', ')}.');
    }
    if (errors.isNotEmpty) {
      return CsvImportPreview(
        totalRows: rows.length > 1 ? rows.length - 1 : 0,
        newActivities: const [],
        newEntries: const [],
        duplicateEntries: 0,
        errors: errors,
      );
    }

    final existingActivities = await _activityRepository.getActivities();
    final existingActivityIds = {
      for (final activity in existingActivities) activity.id,
    };
    final existingEntryIds = {
      for (final entry in await _timeEntryRepository.getEntries()) entry.id,
    };
    final parsedActivities = <String, Activity>{};
    final parsedEntries = <TimeEntry>[];
    final parsedEntryIds = <String>{};
    var duplicateEntries = 0;
    var totalRows = 0;

    for (var rowIndex = 1; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      if (row.every((value) => value.trim().isEmpty)) continue;
      totalRows++;
      try {
        final parsed = _parseRow(row, header);
        final previousActivity = parsedActivities[parsed.activity.id];
        if (previousActivity != null &&
            !_sameActivity(previousActivity, parsed.activity)) {
          throw _CsvRowException(
            'activity metadata conflicts with another row.',
          );
        }
        parsedActivities[parsed.activity.id] = parsed.activity;

        if (!parsedEntryIds.add(parsed.entry.id)) {
          throw _CsvRowException('entry_id is duplicated inside the file.');
        }
        if (existingEntryIds.contains(parsed.entry.id)) {
          duplicateEntries++;
        } else {
          parsedEntries.add(parsed.entry);
        }
      } on _CsvRowException catch (error) {
        errors.add('Row ${rowIndex + 1}: ${error.message}');
      }
    }

    if (totalRows == 0) errors.add('The CSV contains no data rows.');
    final newActivities = parsedActivities.values
        .where((activity) => !existingActivityIds.contains(activity.id))
        .toList(growable: false);
    return CsvImportPreview(
      totalRows: totalRows,
      newActivities: List.unmodifiable(newActivities),
      newEntries: List.unmodifiable(parsedEntries),
      duplicateEntries: duplicateEntries,
      errors: List.unmodifiable(errors),
    );
  }

  Future<CsvImportResult> import(CsvImportPreview preview) async {
    if (!preview.isValid || !preview.hasChanges) {
      throw StateError('The CSV preview has no importable changes.');
    }
    await _activityRepository.saveActivities(preview.newActivities);
    await _timeEntryRepository.saveEntries(preview.newEntries);
    return CsvImportResult(
      importedActivities: preview.newActivities.length,
      importedEntries: preview.newEntries.length,
      skippedDuplicates: preview.duplicateEntries,
    );
  }

  _ParsedCsvRow _parseRow(List<String> row, Map<String, int> header) {
    String cell(String name) {
      final index = header[name]!;
      return index < row.length ? row[index].trim() : '';
    }

    final version = cell('format_version');
    if (version != timeFlowCsvFormatVersion) {
      throw const _CsvRowException('unsupported format_version.');
    }
    final entryId = _required(cell('entry_id'), 'entry_id');
    final activityId = _required(cell('activity_id'), 'activity_id');
    final activityName = _required(cell('activity_name'), 'activity_name');
    final colorValue = int.tryParse(cell('activity_color_value'));
    if (colorValue == null || colorValue < 0 || colorValue > 0xFFFFFFFF) {
      throw const _CsvRowException('activity_color_value is invalid.');
    }
    final iconKey = _required(cell('activity_icon_key'), 'activity_icon_key');
    final isArchived = _parseBool(
      cell('activity_is_archived'),
      'activity_is_archived',
    );
    final startedAt = _parseDate(cell('started_at'), 'started_at');
    final endedAt = _parseDate(cell('ended_at'), 'ended_at');
    final durationMilliseconds = int.tryParse(cell('duration_milliseconds'));
    if (durationMilliseconds == null || durationMilliseconds <= 0) {
      throw const _CsvRowException('duration_milliseconds must be positive.');
    }
    if (endedAt.isBefore(startedAt)) {
      throw const _CsvRowException('ended_at is before started_at.');
    }
    final elapsed = endedAt.difference(startedAt);
    if (Duration(milliseconds: durationMilliseconds) >
        elapsed + _durationClockTolerance) {
      throw const _CsvRowException(
        'duration_milliseconds exceeds the session time range.',
      );
    }
    final entryCreatedAt = _parseDate(
      cell('entry_created_at'),
      'entry_created_at',
    );
    final activityCreatedValue = cell('activity_created_at');
    final activityCreatedAt =
        activityCreatedValue.isEmpty
            ? entryCreatedAt
            : _parseDate(activityCreatedValue, 'activity_created_at');
    final noteValue = cell('note');

    return _ParsedCsvRow(
      activity: Activity(
        id: activityId,
        name: activityName,
        colorValue: colorValue,
        iconKey: iconKey,
        isArchived: isArchived,
        createdAt: activityCreatedAt,
      ),
      entry: TimeEntry(
        id: entryId,
        activityId: activityId,
        startedAt: startedAt,
        endedAt: endedAt,
        duration: Duration(milliseconds: durationMilliseconds),
        createdAt: entryCreatedAt,
        note: noteValue.isEmpty ? null : noteValue,
      ),
    );
  }

  String _required(String value, String field) {
    if (value.isEmpty) throw _CsvRowException('$field is required.');
    return value;
  }

  DateTime _parseDate(String value, String field) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) throw _CsvRowException('$field is invalid.');
    return parsed;
  }

  bool _parseBool(String value, String field) {
    return switch (value.toLowerCase()) {
      'true' || '1' => true,
      'false' || '0' => false,
      _ => throw _CsvRowException('$field must be true or false.'),
    };
  }

  bool _sameActivity(Activity left, Activity right) =>
      left.name == right.name &&
      left.colorValue == right.colorValue &&
      left.iconKey == right.iconKey &&
      left.isArchived == right.isArchived;
}

class _ParsedCsvRow {
  const _ParsedCsvRow({required this.activity, required this.entry});

  final Activity activity;
  final TimeEntry entry;
}

class _CsvRowException implements Exception {
  const _CsvRowException(this.message);

  final String message;
}
