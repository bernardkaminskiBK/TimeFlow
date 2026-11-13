import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../activities/domain/models/activity.dart';
import '../../../activities/presentation/activity_visuals.dart';
import '../../../activities/presentation/cubit/activity_cubit.dart';
import '../../../time_entries/domain/models/time_entry.dart';
import '../../../time_entries/presentation/cubit/time_entry_cubit.dart';
import 'edit_session_sheet.dart';

Future<void> showSessionDetailSheet(
  BuildContext context, {
  required TimeEntry entry,
  required Activity? activity,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  builder: (_) => _SessionDetailSheet(entry: entry, activity: activity),
);

class _SessionDetailSheet extends StatefulWidget {
  const _SessionDetailSheet({required this.entry, required this.activity});
  final TimeEntry entry;
  final Activity? activity;

  @override
  State<_SessionDetailSheet> createState() => _SessionDetailSheetState();
}

class _SessionDetailSheetState extends State<_SessionDetailSheet> {
  late final TextEditingController _noteController;
  late TimeEntry _entry;
  Activity? _activity;
  String? _error;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
    _activity = widget.activity;
    _noteController = TextEditingController(text: _entry.note);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    setState(() => _error = null);
    final result = await context.read<TimeEntryCubit>().updateNote(
      _entry.id,
      _noteController.text,
    );
    if (!mounted) return;
    switch (result) {
      case NoteUpdateResult.success:
        Navigator.of(context).pop();
      case NoteUpdateResult.notFound:
        setState(() => _error = 'This session no longer exists.');
      case NoteUpdateResult.failure:
        setState(() => _error = 'Could not save the note. Please try again.');
    }
  }

  Future<void> _editSession() async {
    final updated = await showEditSessionDialog(context, entry: _entry);
    if (updated == null || !mounted) return;
    final activities = context.read<ActivityCubit>().state.activities;
    Activity? updatedActivity;
    for (final activity in activities) {
      if (activity.id == updated.activityId) {
        updatedActivity = activity;
        break;
      }
    }
    setState(() {
      _entry = updated;
      _activity = updatedActivity;
      _error = null;
    });
  }

  Future<void> _deleteSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: AppColors.elevatedSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: const BorderSide(color: AppColors.stroke),
            ),
            title: const Text('Delete session?'),
            content: const Text(
              'This session will be permanently deleted. This action cannot be undone.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text(
                  'Delete',
                  style: TextStyle(
                    color: Color(0xFFFF6B7D),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;

    final result = await context.read<TimeEntryCubit>().deleteEntry(_entry.id);
    if (!mounted) return;
    switch (result) {
      case EntryDeletionResult.success:
        Navigator.of(context).pop();
      case EntryDeletionResult.notFound:
        setState(() => _error = 'This session no longer exists.');
      case EntryDeletionResult.failure:
        setState(() => _error = 'Could not delete this session.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Color(_activity?.colorValue ?? 0xFF3478F6);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.stroke,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Icon(
                        ActivityVisuals.iconFor(_activity?.iconKey ?? 'other'),
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _activity?.name ?? 'Unknown activity',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _formatDate(_entry.startedAt),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit session',
                      onPressed: _editSession,
                      style: IconButton.styleFrom(
                        foregroundColor: AppColors.cyan,
                        backgroundColor: AppColors.elevatedSurface,
                        side: const BorderSide(color: AppColors.stroke),
                      ),
                      icon: const Icon(Icons.edit_rounded, size: 19),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: _DetailTile(
                        label: 'TIME',
                        value:
                            '${_time(_entry.startedAt)} – '
                            '${_time(_entry.endedAt)}',
                        icon: Icons.schedule_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DetailTile(
                        label: 'DURATION',
                        value: _duration(_entry.duration),
                        icon: Icons.timelapse_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'NOTE',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _noteController,
                  minLines: 4,
                  maxLines: 7,
                  inputFormatters: [LengthLimitingTextInputFormatter(500)],
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Add a note about this session…',
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.elevatedSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.stroke),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _noteController,
                  builder:
                      (context, value, _) => Text(
                        '${value.text.length}/500',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: Color(0xFFFF7A90),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                BlocBuilder<TimeEntryCubit, TimeEntryState>(
                  builder:
                      (context, state) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SaveNoteButton(
                            isSaving: state.isSaving,
                            onTap: _saveNote,
                          ),
                          const SizedBox(height: 10),
                          _DeleteSessionButton(
                            enabled: !state.isSaving,
                            onTap: _deleteSession,
                          ),
                        ],
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _time(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}:'
      '${date.second.toString().padLeft(2, '0')}';

  String _duration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final parts = <String>[];
    if (hours > 0) parts.add('${hours}h');
    if (minutes > 0) parts.add('${minutes}m');
    if (seconds > 0 || parts.isEmpty) parts.add('${seconds}s');
    return parts.join(' ');
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.elevatedSurface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.stroke),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.cyan, size: 19),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SaveNoteButton extends StatelessWidget {
  const _SaveNoteButton({required this.isSaving, required this.onTap});
  final bool isSaving;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient:
          isSaving
              ? null
              : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF58C8FF), Color(0xFF2865EC)],
              ),
      color: isSaving ? AppColors.elevatedSurface : null,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: isSaving ? AppColors.stroke : const Color(0xFF5A91FA),
      ),
      boxShadow:
          isSaving
              ? null
              : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isSaving ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 54,
          child: Center(
            child: Text(
              isSaving ? 'Saving…' : 'Save note',
              style: TextStyle(
                color: isSaving ? AppColors.textSecondary : Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _DeleteSessionButton extends StatelessWidget {
  const _DeleteSessionButton({required this.enabled, required this.onTap});
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: enabled ? onTap : null,
    icon: const Icon(Icons.delete_outline_rounded, size: 19),
    label: const Text('Delete session'),
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFFFF7A90),
      disabledForegroundColor: AppColors.textSecondary,
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
      padding: const EdgeInsets.symmetric(vertical: 13),
    ),
  );
}
