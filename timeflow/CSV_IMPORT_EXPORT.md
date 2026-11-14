# TimeFlow CSV import and export

This document describes only the current CSV format and its import/export
rules. It is intended to keep the data contract and validation decisions
visible without having to reconstruct them from the Dart implementation.

## Purpose

The CSV export is a portable copy of TimeFlow sessions. It can be saved on the
device, shared with another device, and imported into another TimeFlow
installation.

The current format is designed for:

- moving session history between devices;
- making a human-readable backup of tracked data;
- safely importing the same file more than once without duplicating sessions;
- evolving the format through an explicit version number.

It is not a complete database backup. In particular, activities without any
sessions are not currently exported because every CSV data row represents one
time entry.

## File format

- Encoding: UTF-8.
- Format version: `1`.
- One header row followed by one row per time entry.
- File name: `timeflow-export-YYYY-MM-DD-HHMMSS.csv`.
- Commas, quotes, and line breaks inside values such as notes are escaped by a
  real CSV encoder and are supported by the importer.
- CRLF and CR line endings are normalized to LF before parsing.
- An optional UTF-8 BOM at the start of the first header is accepted.
- Empty data rows are ignored.
- Import files are limited to 10 MB by the Settings UI.

## Columns

| Column | Required | Meaning and format |
| --- | --- | --- |
| `format_version` | Yes | Must currently be `1`. |
| `entry_id` | Yes | Stable unique identifier of the time entry. |
| `activity_id` | Yes | Stable identifier of the referenced activity. |
| `activity_name` | Yes | Display name of the activity. |
| `activity_color_value` | Yes | Flutter ARGB color encoded as an integer from `0` to `4294967295`. |
| `activity_icon_key` | Yes | Persisted icon identifier, not Flutter `IconData`. |
| `activity_is_archived` | Yes | Accepts `true`, `false`, `1`, or `0`, case-insensitively. |
| `activity_created_at` | No | ISO 8601 timestamp. If empty, `entry_created_at` is used as a fallback. |
| `started_at` | Yes | ISO 8601 timestamp for the session start. |
| `ended_at` | Yes | ISO 8601 timestamp for the session end. |
| `duration_milliseconds` | Yes | Positive integer containing actual tracked time, excluding pauses. |
| `entry_created_at` | Yes | ISO 8601 timestamp recording when the entry was created. |
| `note` | No | Free-form session note. An empty value becomes `null`. |

Header order is not significant. Additional columns are currently tolerated,
but every column listed above must be present, including columns whose row value
may be empty.

## Export behavior

The exporter reads all activities and time entries from their repositories.
For each time entry it:

1. resolves the referenced activity by `activity_id`;
2. writes the entry and a snapshot of that activity's metadata into one row;
3. preserves stable activity and entry identifiers;
4. writes timestamps with `toIso8601String()`;
5. writes the duration in milliseconds so seconds and sub-second precision are
   not lost;
6. writes an empty note when the stored note is `null`.

Export fails instead of producing a broken file if an entry references an
activity that no longer exists. This protects referential integrity.

Only activities referenced by exported entries are represented in version 1.
An activity may therefore appear in several rows, but its metadata must be the
same in every row.

## Import phases

Import intentionally has two phases.

### 1. Prepare and preview

The complete file is parsed and validated without writing anything. The preview
shows:

- the number of new sessions;
- the number of new activities;
- the number of existing sessions that will be skipped;
- the earliest and latest new session dates;
- validation errors, if any.

If any row is invalid, the file cannot be imported. There is no partial import
of only the valid rows.

### 2. Confirm and save

After confirmation, missing activities are saved first and new time entries are
saved second through their repositories. The activity list is then reloaded so
the rest of the application sees imported activities immediately.

The validation phase is all-or-nothing, but the two repository writes are not
currently wrapped in one shared Drift transaction. If stronger crash-level
atomicity becomes necessary, that transaction boundary should be added when the
import architecture is revisited.

## File and header validation

The importer rejects the file when:

- it cannot be decoded as UTF-8;
- it is larger than 10 MB;
- it is not syntactically valid CSV;
- it is empty;
- the header contains an empty or duplicate name;
- one or more required columns are missing;
- it contains no non-empty data rows.

## Row validation

Each non-empty row is rejected when any of the following is true:

- `format_version` is not supported;
- `entry_id`, `activity_id`, `activity_name`, or `activity_icon_key` is empty;
- `activity_color_value` is not an integer in the unsigned 32-bit range;
- `activity_is_archived` is not a supported boolean representation;
- a required timestamp is missing or cannot be parsed as ISO 8601;
- `duration_milliseconds` is missing, not an integer, or is zero/negative;
- `ended_at` is earlier than `started_at`;
- duration exceeds the wall-clock session range by more than one second;
- the same `entry_id` occurs more than once inside the file;
- rows using the same `activity_id` contain conflicting activity name, color,
  icon, or archived status.

The one-second duration tolerance is deliberate. Stopwatch duration comes from
a monotonic elapsed-time source, while `started_at` and `ended_at` are wall-clock
timestamps. Tiny clock and capture differences must not make TimeFlow reject its
own valid export. Materially impossible durations are still rejected.

## Duplicate and conflict handling

Stable `entry_id` values provide import idempotency:

- if an entry ID already exists in the destination repository, that row is
  counted as an existing session and the entry is skipped;
- importing the same file repeatedly does not create duplicate sessions;
- a duplicate entry ID inside the same CSV is considered a malformed file and
  blocks the import.

Activities use stable `activity_id` values:

- an activity missing from the destination is created from the CSV metadata;
- an activity already present in the destination is retained and is not
  overwritten by CSV metadata;
- conflicting metadata for the same activity ID inside one CSV blocks the
  import.

Current limitation: metadata from the CSV is not compared with metadata of an
already existing destination activity that has the same ID. The local activity
wins. Before supporting imports from untrusted or independently edited sources,
the product should define whether this should remain "local wins", become an
explicit conflict shown to the user, or offer a merge choice.

## Referential integrity

Imported time entries always retain the `activity_id` stored in the CSV.
Missing activities are inserted before their entries. Existing activities are
reused by stable ID.

The Drift database remains responsible for enforcing the activity/time-entry
relationship. Activity deletion must not cascade-delete historical time entries.
An activity referenced by sessions should be archived rather than deleted.

## UI and platform behavior

- Import uses the platform document picker and accepts `.csv` files.
- Export offers both **Save to device** and **Share CSV**.
- Save to device uses the Android system document provider, so no broad storage
  permission is required.
- The preview is shown before any write occurs.
- Canceling the picker, preview, save dialog, or share panel makes no data
  change.

## Future evolution checklist

When changing this format:

1. Increment `format_version` for any incompatible schema or semantic change.
2. Keep older import versions readable through an explicit migration/parser
   path instead of silently changing version 1 behavior.
3. Add round-trip tests proving that export followed by import preserves IDs,
   timestamps, duration, notes, and activity metadata.
4. Keep duplicate imports idempotent.
5. Decide whether activity-only rows are needed so activities without sessions
   can be backed up.
6. Decide and document the conflict policy for an existing activity ID with
   different metadata.
7. Consider a single Drift transaction for activities and entries if import
   must be crash-atomic.
8. Add explicit size/count limits if imports may come from untrusted sources.
9. Preserve the rule that imported entries cannot orphan their activity.
10. Never reinterpret `duration_milliseconds` as wall-clock difference: it is
    the actual tracked duration and excludes paused time.

## Implementation locations

- Schema constants: `lib/features/settings/data/services/timeflow_csv_schema.dart`
- Export logic: `lib/features/settings/data/services/csv_export_service.dart`
- Import and validation: `lib/features/settings/data/services/csv_import_service.dart`
- Import preview UI: `lib/features/settings/presentation/widgets/csv_import_preview_sheet.dart`
- Settings integration: `lib/features/settings/presentation/screens/settings_screen.dart`
- Regression tests: `test/features/settings/`
