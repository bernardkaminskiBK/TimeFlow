import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../activities/domain/repositories/activity_repository.dart';
import '../../../activities/presentation/cubit/activity_cubit.dart';
import '../../../time_entries/domain/repositories/time_entry_repository.dart';
import '../../data/services/csv_export_service.dart';
import '../../data/services/csv_import_service.dart';
import '../widgets/csv_import_preview_sheet.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _danger = Color(0xFFFF7188);
  static const _maximumImportBytes = 10 * 1024 * 1024;

  Future<CsvExportDocument?> _createExportDocument(BuildContext context) async {
    final document =
        await CsvExportService(
          context.read<ActivityRepository>(),
          context.read<TimeEntryRepository>(),
        ).create();
    if (!context.mounted) return null;
    if (document.sessionCount == 0) {
      _showFeedback(context, 'There are no sessions to export yet.');
      return null;
    }
    return document;
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      final document = await _createExportDocument(context);
      if (document == null || !context.mounted) return;

      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}${Platform.pathSeparator}${document.fileName}',
      );
      await file.writeAsString(document.csv, encoding: utf8, flush: true);
      if (!context.mounted) return;
      final renderBox = context.findRenderObject() as RenderBox?;
      final shareResult = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'text/csv')],
          fileNameOverrides: [document.fileName],
          title: 'Share TimeFlow export',
          subject: 'TimeFlow data export',
          sharePositionOrigin:
              renderBox == null
                  ? null
                  : renderBox.localToGlobal(Offset.zero) & renderBox.size,
        ),
      );
      if (!context.mounted) return;
      switch (shareResult.status) {
        case ShareResultStatus.success:
          _showFeedback(
            context,
            '${document.sessionCount} '
            '${document.sessionCount == 1 ? 'session' : 'sessions'} exported.',
          );
          break;
        case ShareResultStatus.dismissed:
          break;
        case ShareResultStatus.unavailable:
          _showFeedback(
            context,
            'The system share panel is not available.',
            isError: true,
          );
          break;
      }
    } catch (_) {
      if (context.mounted) {
        _showFeedback(
          context,
          'TimeFlow could not create the CSV export.',
          isError: true,
        );
      }
    }
  }

  Future<void> _saveExportData(BuildContext context) async {
    try {
      final document = await _createExportDocument(context);
      if (document == null || !context.mounted) return;

      final savedPath = await FilePicker.saveFile(
        dialogTitle: 'Save TimeFlow export',
        fileName: document.fileName,
        type: FileType.custom,
        allowedExtensions: const ['csv'],
        bytes: Uint8List.fromList(utf8.encode(document.csv)),
      );
      if (savedPath == null || !context.mounted) return;
      _showFeedback(
        context,
        '${document.sessionCount} '
        '${document.sessionCount == 1 ? 'session' : 'sessions'} saved to CSV.',
      );
    } catch (_) {
      if (context.mounted) {
        _showFeedback(
          context,
          'TimeFlow could not save the CSV export.',
          isError: true,
        );
      }
    }
  }

  Future<void> _showExportOptions(BuildContext context) async {
    final action = await showModalBottomSheet<_ExportAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => const _ExportOptionsSheet(),
    );
    if (!context.mounted) return;
    switch (action) {
      case _ExportAction.save:
        await _saveExportData(context);
        break;
      case _ExportAction.share:
        await _exportData(context);
        break;
      case null:
        break;
    }
  }

  Future<void> _importData(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles(
        dialogTitle: 'Choose a TimeFlow CSV file',
        type: FileType.custom,
        allowedExtensions: const ['csv'],
        withData: true,
      );
      if (result == null || !context.mounted) return;
      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        _showFeedback(
          context,
          'TimeFlow could not read the selected file.',
          isError: true,
        );
        return;
      }
      if (bytes.length > _maximumImportBytes) {
        _showFeedback(
          context,
          'The CSV is larger than the 10 MB import limit.',
          isError: true,
        );
        return;
      }

      final service = CsvImportService(
        context.read<ActivityRepository>(),
        context.read<TimeEntryRepository>(),
      );
      final activityCubit = context.read<ActivityCubit>();
      final preview = await service.prepare(utf8.decode(bytes));
      if (!context.mounted) return;
      // Some Android document providers return before the app's resumed frame
      // has been painted. Opening a modal immediately can leave its contents
      // unpainted even though the widgets and semantics are present.
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (!context.mounted) return;
      final confirmed = await showCsvImportPreviewSheet(
        context,
        fileName: file.name,
        preview: preview,
      );
      if (!confirmed || !context.mounted) return;

      final imported = await service.import(preview);
      await activityCubit.loadActivities();
      if (!context.mounted) return;
      _showFeedback(
        context,
        '${imported.importedEntries} '
        '${imported.importedEntries == 1 ? 'session' : 'sessions'} imported '
        'successfully.',
      );
    } on FormatException {
      if (context.mounted) {
        _showFeedback(
          context,
          'The selected file is not valid UTF-8 text.',
          isError: true,
        );
      }
    } catch (_) {
      if (context.mounted) {
        _showFeedback(
          context,
          'TimeFlow could not complete the import.',
          isError: true,
        );
      }
    }
  }

  void _showFeedback(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    final color = isError ? _danger : const Color(0xFF4FD6A3);
    final bottomInset = math.max(
      MediaQuery.viewPaddingOf(context).bottom,
      MediaQuery.systemGestureInsetsOf(context).bottom,
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_rounded,
                color: color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.elevatedSurface,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: color.withValues(alpha: 0.22)),
          ),
        ),
      );
  }

  void _showPlanned(BuildContext context, String feature) {
    final bottomInset = math.max(
      MediaQuery.viewPaddingOf(context).bottom,
      MediaQuery.systemGestureInsetsOf(context).bottom,
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppColors.cyan),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$feature is planned for a future TimeFlow update.',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.elevatedSurface,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: AppColors.stroke.withValues(alpha: 0.8)),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.68, -0.72),
            radius: 1.18,
            colors: [Color(0xFF10284B), AppColors.background],
            stops: [0, 0.68],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final side = constraints.maxWidth < 380 ? 18.0 : 24.0;
              final bottomInset = math.max(
                MediaQuery.viewPaddingOf(context).bottom,
                MediaQuery.systemGestureInsetsOf(context).bottom,
              );
              return ListView(
                padding: EdgeInsets.fromLTRB(side, 16, side, bottomInset + 32),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Make TimeFlow yours.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 22),
                          _AccountCard(
                            onSignIn:
                                () => _showPlanned(context, 'Account sync'),
                          ),
                          const SizedBox(height: 26),
                          _SettingsSection(
                            title: 'DATA & BACKUP',
                            children: [
                              _SettingsTile(
                                icon: Icons.file_download_outlined,
                                iconColor: AppColors.cyan,
                                title: 'Import data',
                                subtitle: 'Bring sessions into TimeFlow',
                                status: 'READY',
                                statusTone: _StatusTone.success,
                                onTap: () => _importData(context),
                              ),
                              _SettingsTile(
                                icon: Icons.ios_share_rounded,
                                iconColor: const Color(0xFF8C82FF),
                                title: 'Export data',
                                subtitle: 'Create a portable CSV export',
                                status: 'READY',
                                statusTone: _StatusTone.success,
                                onTap: () => _showExportOptions(context),
                              ),
                              _SettingsTile(
                                icon: Icons.backup_outlined,
                                iconColor: const Color(0xFF4FD6A3),
                                title: 'Database backup',
                                subtitle: 'Save a complete TimeFlow backup',
                                status: 'PLANNED',
                                onTap:
                                    () => _showPlanned(
                                      context,
                                      'Database backup',
                                    ),
                              ),
                              _SettingsTile(
                                icon: Icons.settings_backup_restore_rounded,
                                iconColor: const Color(0xFFFFB85C),
                                title: 'Restore backup',
                                subtitle: 'Recover from a TimeFlow backup',
                                status: 'PLANNED',
                                onTap:
                                    () =>
                                        _showPlanned(context, 'Backup restore'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          _SettingsSection(
                            title: 'PREFERENCES',
                            children: [
                              _SettingsTile(
                                icon: Icons.schedule_rounded,
                                iconColor: AppColors.cyan,
                                title: '24-hour time',
                                subtitle: 'Use the 00:00 time format',
                                value: 'ON',
                                onTap:
                                    () => _showPlanned(
                                      context,
                                      'Time format selection',
                                    ),
                              ),
                              _SettingsTile(
                                icon: Icons.timer_outlined,
                                iconColor: const Color(0xFF8C82FF),
                                title: 'Show seconds',
                                subtitle: 'Control precision across the app',
                                value: 'AUTO',
                                onTap:
                                    () => _showPlanned(
                                      context,
                                      'Time precision settings',
                                    ),
                              ),
                              _SettingsTile(
                                icon: Icons.vibration_rounded,
                                iconColor: const Color(0xFFFFB85C),
                                title: 'Haptic feedback',
                                subtitle: 'Feel important timer actions',
                                status: 'PLANNED',
                                onTap:
                                    () => _showPlanned(
                                      context,
                                      'Haptic feedback',
                                    ),
                              ),
                              _SettingsTile(
                                icon: Icons.calendar_view_week_rounded,
                                iconColor: const Color(0xFF4FD6A3),
                                title: 'First day of week',
                                subtitle: 'Choose how weeks are displayed',
                                value: 'MON',
                                onTap:
                                    () => _showPlanned(
                                      context,
                                      'Week preferences',
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          _SettingsSection(
                            title: 'STOPWATCH',
                            children: [
                              _SettingsTile(
                                icon: Icons.screen_lock_portrait_rounded,
                                iconColor: AppColors.cyan,
                                title: 'Keep screen awake',
                                subtitle: 'Prevent sleep while tracking',
                                status: 'PLANNED',
                                onTap:
                                    () => _showPlanned(
                                      context,
                                      'Keep screen awake',
                                    ),
                              ),
                              _SettingsTile(
                                icon: Icons.fact_check_outlined,
                                iconColor: const Color(0xFF4FD6A3),
                                title: 'Confirm before discard',
                                subtitle: 'Protect an unfinished session',
                                status: 'PLANNED',
                                onTap:
                                    () => _showPlanned(
                                      context,
                                      'Discard confirmation',
                                    ),
                              ),
                              _SettingsTile(
                                icon: Icons.notifications_active_outlined,
                                iconColor: const Color(0xFF8C82FF),
                                title: 'Background controls',
                                subtitle: 'Control tracking from notifications',
                                status: 'ROADMAP',
                                onTap:
                                    () => _showPlanned(
                                      context,
                                      'Background controls',
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          _SettingsSection(
                            title: 'NOTIFICATIONS',
                            children: [
                              _SettingsTile(
                                icon: Icons.alarm_rounded,
                                iconColor: const Color(0xFFFFB85C),
                                title: 'Session reminders',
                                subtitle: 'Build consistent activity habits',
                                status: 'PLANNED',
                                onTap:
                                    () => _showPlanned(
                                      context,
                                      'Session reminders',
                                    ),
                              ),
                              _SettingsTile(
                                icon: Icons.flag_outlined,
                                iconColor: const Color(0xFF4FD6A3),
                                title: 'Daily goal',
                                subtitle: 'Set a tracked-time target',
                                status: 'PLANNED',
                                onTap:
                                    () => _showPlanned(context, 'Daily goals'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          _SettingsSection(
                            title: 'APPEARANCE',
                            children: [
                              _SettingsTile(
                                icon: Icons.dark_mode_outlined,
                                iconColor: AppColors.cyan,
                                title: 'Theme',
                                subtitle: 'TimeFlow midnight blue',
                                value: 'DARK',
                                onTap:
                                    () => _showPlanned(
                                      context,
                                      'Theme selection',
                                    ),
                              ),
                              _SettingsTile(
                                icon: Icons.palette_outlined,
                                iconColor: const Color(0xFF3478F6),
                                title: 'Accent color',
                                subtitle: 'Electric blue',
                                value: 'BLUE',
                                onTap:
                                    () => _showPlanned(
                                      context,
                                      'Accent customization',
                                    ),
                              ),
                              _SettingsTile(
                                icon: Icons.animation_rounded,
                                iconColor: const Color(0xFF8C82FF),
                                title: 'Reduce motion',
                                subtitle: 'Use simpler transitions',
                                status: 'PLANNED',
                                onTap:
                                    () => _showPlanned(
                                      context,
                                      'Motion preferences',
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          _SettingsSection(
                            title: 'ABOUT',
                            children: [
                              const _SettingsTile(
                                icon: Icons.auto_awesome_rounded,
                                iconColor: AppColors.cyan,
                                title: 'TimeFlow',
                                subtitle: 'First working beta',
                                value: 'BETA',
                              ),
                              _SettingsTile(
                                icon: Icons.privacy_tip_outlined,
                                iconColor: const Color(0xFF4FD6A3),
                                title: 'Privacy & data',
                                subtitle: 'How TimeFlow protects your data',
                                status: 'PLANNED',
                                onTap:
                                    () => _showPlanned(
                                      context,
                                      'Privacy information',
                                    ),
                              ),
                              _SettingsTile(
                                icon: Icons.description_outlined,
                                iconColor: const Color(0xFF8C82FF),
                                title: 'Open-source licenses',
                                subtitle: 'Libraries used by TimeFlow',
                                onTap:
                                    () => showLicensePage(
                                      context: context,
                                      applicationName: 'TimeFlow',
                                      applicationVersion: 'Beta',
                                    ),
                              ),
                              _SettingsTile(
                                icon: Icons.android_rounded,
                                iconColor: const Color(0xFF7FDD72),
                                title: 'Android roadmap',
                                subtitle: 'Widgets and background controls',
                                status: 'ROADMAP',
                                onTap:
                                    () => _showPlanned(
                                      context,
                                      'Android integrations',
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          _SettingsSection(
                            title: 'DANGER ZONE',
                            tone: _SectionTone.danger,
                            children: [
                              _SettingsTile(
                                icon: Icons.delete_sweep_outlined,
                                iconColor: _danger,
                                title: 'Delete all sessions',
                                subtitle: 'Permanently remove tracked history',
                                status: 'PLANNED',
                                statusTone: _StatusTone.danger,
                                onTap:
                                    () => _showPlanned(
                                      context,
                                      'Session deletion',
                                    ),
                              ),
                              _SettingsTile(
                                icon: Icons.restart_alt_rounded,
                                iconColor: _danger,
                                title: 'Reset TimeFlow',
                                subtitle: 'Erase all application data',
                                status: 'PLANNED',
                                statusTone: _StatusTone.danger,
                                onTap:
                                    () => _showPlanned(
                                      context,
                                      'Application reset',
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Made for focused time.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

enum _ExportAction { save, share }

class _ExportOptionsSheet extends StatelessWidget {
  const _ExportOptionsSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.elevatedSurface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.stroke),
          boxShadow: const [
            BoxShadow(
              color: Color(0x99000000),
              blurRadius: 30,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Export TimeFlow data',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            const Text(
              'Save the CSV on this device or share it with another app.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            _ExportOption(
              icon: Icons.save_alt_rounded,
              color: AppColors.cyan,
              title: 'Save to device',
              subtitle: 'Choose a folder on your phone',
              onTap: () => Navigator.pop(context, _ExportAction.save),
            ),
            const SizedBox(height: 10),
            _ExportOption(
              icon: Icons.ios_share_rounded,
              color: const Color(0xFF8C82FF),
              title: 'Share CSV',
              subtitle: 'Send it to another app or device',
              onTap: () => Navigator.pop(context, _ExportAction.share),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportOption extends StatelessWidget {
  const _ExportOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background.withValues(alpha: 0.42),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.stroke.withValues(alpha: 0.7)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Icon(icon, color: color, size: 23),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF18375E), Color(0xFF0B192D)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xA02A4B73)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x50000000),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF58C8FF), Color(0xFF2865EC)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Local profile',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Your data stays on this device',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const _StatusBadge(label: 'LOCAL', tone: _StatusTone.success),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.36),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.stroke.withValues(alpha: 0.66),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.cloud_off_outlined, color: AppColors.cyan, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Cloud sync and account recovery are on the roadmap.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: _GradientButton(
              label: 'Sign in to TimeFlow',
              icon: Icons.login_rounded,
              onTap: onSignIn,
            ),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'COMING SOON',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF5A91FA)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 19),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
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

enum _SectionTone { normal, danger }

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
    this.tone = _SectionTone.normal,
  });

  final String title;
  final List<Widget> children;
  final _SectionTone tone;

  @override
  Widget build(BuildContext context) {
    final danger = tone == _SectionTone.danger;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: TextStyle(
              color: danger ? SettingsScreen._danger : AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color:
                  danger
                      ? SettingsScreen._danger.withValues(alpha: 0.24)
                      : AppColors.stroke.withValues(alpha: 0.72),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3D000000),
                blurRadius: 16,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(21),
            child: Column(
              children: [
                for (var index = 0; index < children.length; index++) ...[
                  children[index],
                  if (index != children.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(left: 68),
                      child: Divider(
                        height: 1,
                        color: AppColors.stroke.withValues(alpha: 0.56),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.status,
    this.value,
    this.statusTone = _StatusTone.neutral,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? status;
  final String? value;
  final _StatusTone statusTone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: iconColor.withValues(alpha: 0.22)),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (status case final status?)
                _StatusBadge(label: status, tone: statusTone)
              else if (value case final value?)
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.cyan,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              if (onTap != null) ...[
                const SizedBox(width: 7),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                  size: 19,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum _StatusTone { neutral, accent, success, danger }

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.tone});

  final String label;
  final _StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      _StatusTone.neutral => AppColors.textSecondary,
      _StatusTone.accent => AppColors.cyan,
      _StatusTone.success => const Color(0xFF4FD6A3),
      _StatusTone.danger => SettingsScreen._danger,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
