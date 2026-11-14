import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../data/services/csv_import_service.dart';

Future<bool> showCsvImportPreviewSheet(
  BuildContext context, {
  required String fileName,
  required CsvImportPreview preview,
}) async {
  return await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder:
            (context) =>
                CsvImportPreviewSheet(fileName: fileName, preview: preview),
      ) ??
      false;
}

class CsvImportPreviewSheet extends StatelessWidget {
  const CsvImportPreviewSheet({
    required this.fileName,
    required this.preview,
    super.key,
  });

  final String fileName;
  final CsvImportPreview preview;

  @override
  Widget build(BuildContext context) {
    final canImport = preview.isValid && preview.hasChanges;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.86,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0A1424),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.fromBorderSide(BorderSide(color: Color(0xFF1D3553))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.34),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: (preview.isValid
                                  ? AppColors.cyan
                                  : const Color(0xFFFF7188))
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: (preview.isValid
                                    ? AppColors.cyan
                                    : const Color(0xFFFF7188))
                                .withValues(alpha: 0.24),
                          ),
                        ),
                        child: Icon(
                          preview.isValid
                              ? Icons.table_view_rounded
                              : Icons.error_outline_rounded,
                          color:
                              preview.isValid
                                  ? AppColors.cyan
                                  : const Color(0xFFFF7188),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              preview.isValid
                                  ? 'Import preview'
                                  : 'CSV needs attention',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).pop(false),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  if (preview.isValid) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.86),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.stroke.withValues(alpha: 0.76),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _Metric(
                                  label: 'NEW SESSIONS',
                                  value: '${preview.newEntries.length}',
                                  color: AppColors.cyan,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 42,
                                color: AppColors.stroke,
                              ),
                              Expanded(
                                child: _Metric(
                                  label: 'NEW ACTIVITIES',
                                  value: '${preview.newActivities.length}',
                                  color: const Color(0xFF8C82FF),
                                ),
                              ),
                            ],
                          ),
                          if (preview.duplicateEntries > 0) ...[
                            const SizedBox(height: 15),
                            const Divider(height: 1, color: AppColors.stroke),
                            const SizedBox(height: 13),
                            Row(
                              children: [
                                const Icon(
                                  Icons.content_copy_rounded,
                                  color: AppColors.textSecondary,
                                  size: 17,
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    '${preview.duplicateEntries} existing '
                                    '${preview.duplicateEntries == 1 ? 'session' : 'sessions'} will be skipped',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (preview.earliestEntry case final earliest?) ...[
                      const SizedBox(height: 14),
                      _DateRange(
                        earliest: earliest,
                        latest: preview.latestEntry!,
                      ),
                    ],
                    if (!preview.hasChanges) ...[
                      const SizedBox(height: 16),
                      const _InfoMessage(
                        icon: Icons.check_circle_outline_rounded,
                        color: Color(0xFF4FD6A3),
                        message:
                            'Everything in this file already exists in TimeFlow.',
                      ),
                    ],
                  ] else ...[
                    _ErrorList(errors: preview.errors),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              22,
              10,
              22,
              MediaQuery.viewPaddingOf(context).bottom + 18,
            ),
            child:
                canImport
                    ? _ImportButton(
                      count: preview.newEntries.length,
                      onTap: () => Navigator.of(context).pop(true),
                    )
                    : SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.stroke),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DateRange extends StatelessWidget {
  const _DateRange({required this.earliest, required this.latest});

  final DateTime earliest;
  final DateTime latest;

  @override
  Widget build(BuildContext context) {
    return _InfoMessage(
      icon: Icons.date_range_rounded,
      color: AppColors.cyan,
      message: '${_date(earliest)}  –  ${_date(latest)}',
    );
  }

  String _date(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

class _InfoMessage extends StatelessWidget {
  const _InfoMessage({
    required this.icon,
    required this.color,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorList extends StatelessWidget {
  const _ErrorList({required this.errors});

  final List<String> errors;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFFF7188);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'The file was not imported',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          for (final error in errors.take(5)) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 5),
                  child: Icon(Icons.circle, color: color, size: 5),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    error,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
          ],
          if (errors.length > 5)
            Text(
              'And ${errors.length - 5} more issues.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }
}

class _ImportButton extends StatelessWidget {
  const _ImportButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF58C8FF), Color(0xFF2865EC)],
        ),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFF5A91FA)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.file_download_done_rounded),
                const SizedBox(width: 8),
                Text(
                  'Import $count ${count == 1 ? 'session' : 'sessions'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
