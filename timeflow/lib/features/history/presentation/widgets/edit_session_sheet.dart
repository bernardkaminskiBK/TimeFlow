import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../activities/domain/models/activity.dart';
import '../../../activities/presentation/activity_visuals.dart';
import '../../../activities/presentation/cubit/activity_cubit.dart';
import '../../../time_entries/domain/models/time_entry.dart';
import '../../../time_entries/presentation/cubit/time_entry_cubit.dart';

Future<TimeEntry?> showEditSessionDialog(
  BuildContext context, {
  required TimeEntry entry,
}) => showGeneralDialog<TimeEntry>(
  context: context,
  barrierDismissible: true,
  barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
  barrierColor: const Color(0xB3060B16),
  transitionDuration: const Duration(milliseconds: 280),
  pageBuilder:
      (_, animation, secondaryAnimation) => _EditSessionDialog(entry: entry),
  transitionBuilder: (context, animation, secondaryAnimation, child) {
    final fade = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    final scale = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: fade,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.82, end: 1).animate(scale),
        alignment: Alignment.topRight,
        child: child,
      ),
    );
  },
);

class _EditSessionDialog extends StatefulWidget {
  const _EditSessionDialog({required this.entry});

  final TimeEntry entry;

  @override
  State<_EditSessionDialog> createState() => _EditSessionDialogState();
}

class _EditSessionDialogState extends State<_EditSessionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _hoursController;
  late final TextEditingController _minutesController;
  late final TextEditingController _secondsController;
  late DateTime _date;
  late TimeOfDay _time;
  late int _endedAtSecond;
  late String _activityId;
  String? _error;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _date = DateTime(
      entry.endedAt.year,
      entry.endedAt.month,
      entry.endedAt.day,
    );
    _time = TimeOfDay.fromDateTime(entry.endedAt);
    _endedAtSecond = entry.endedAt.second;
    _activityId = entry.activityId;
    _hoursController = TextEditingController(text: '${entry.duration.inHours}');
    _minutesController = TextEditingController(
      text: '${entry.duration.inMinutes.remainder(60)}',
    );
    _secondsController = TextEditingController(
      text: '${entry.duration.inSeconds.remainder(60)}',
    );
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null && mounted) setState(() => _date = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _time,
      builder:
          (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
    );
    if (time != null && mounted) setState(() => _time = time);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final duration = Duration(
      hours: int.parse(_hoursController.text),
      minutes: int.parse(_minutesController.text),
      seconds: int.parse(_secondsController.text),
    );
    final endedAt = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
      _endedAtSecond,
    );
    if (endedAt.isAfter(DateTime.now())) {
      setState(() => _error = 'A session cannot end in the future.');
      return;
    }

    setState(() => _error = null);
    final result = await context.read<TimeEntryCubit>().updateEntry(
      entry: widget.entry,
      activityId: _activityId,
      endedAt: endedAt,
      duration: duration,
    );
    if (!mounted) return;
    switch (result) {
      case EntryUpdateResult.success:
        Navigator.of(context).pop(
          widget.entry.copyWith(
            activityId: _activityId,
            startedAt: endedAt.subtract(duration),
            endedAt: endedAt,
            duration: duration,
          ),
        );
      case EntryUpdateResult.notFound:
        setState(() => _error = 'This session no longer exists.');
      case EntryUpdateResult.invalidInput:
        setState(() => _error = 'Enter valid session details.');
      case EntryUpdateResult.failure:
        setState(() => _error = 'Could not update this session.');
    }
  }

  String? _validateHours(String? value) {
    final number = int.tryParse(value ?? '');
    return number == null || number < 0 || number > 999 ? 'Invalid' : null;
  }

  String? _validatePart(String? value) {
    final number = int.tryParse(value ?? '');
    return number == null || number < 0 || number > 59 ? '0–59' : null;
  }

  String? _validateSeconds(String? value) {
    final error = _validatePart(value);
    if (error != null) return error;
    final hours = int.tryParse(_hoursController.text) ?? 0;
    final minutes = int.tryParse(_minutesController.text) ?? 0;
    final seconds = int.tryParse(value ?? '') ?? 0;
    return hours == 0 && minutes == 0 && seconds == 0 ? 'Required' : null;
  }

  @override
  Widget build(BuildContext context) {
    final activityState = context.watch<ActivityCubit>().state;
    final activities = <Activity>[
      ...activityState.activeActivities,
      ...activityState.archivedActivities.where(
        (activity) => activity.id == widget.entry.activityId,
      ),
    ];
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.cyan.withValues(alpha: 0.24)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.22),
                blurRadius: 34,
                offset: const Offset(0, 14),
              ),
              const BoxShadow(
                color: Color(0x99000000),
                blurRadius: 30,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.cyan.withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: AppColors.cyan,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Edit session',
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Correct the recorded activity or time.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const _SectionLabel('ACTIVITY'),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _activityId,
                      isExpanded: true,
                      dropdownColor: AppColors.elevatedSurface,
                      icon: const Icon(Icons.expand_more_rounded),
                      decoration: _fieldDecoration('Choose activity'),
                      items:
                          activities
                              .map(
                                (activity) => DropdownMenuItem(
                                  value: activity.id,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        ActivityVisuals.iconFor(
                                          activity.iconKey,
                                        ),
                                        color: Color(activity.colorValue),
                                        size: 19,
                                      ),
                                      const SizedBox(width: 11),
                                      Text(
                                        activity.isArchived
                                            ? '${activity.name} · Archived'
                                            : activity.name,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged:
                          (value) => setState(() => _activityId = value!),
                    ),
                    const SizedBox(height: 22),
                    const _SectionLabel('COMPLETED AT'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _PickerTile(
                            icon: Icons.calendar_today_rounded,
                            label: _formatDate(_date),
                            onTap: _pickDate,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _PickerTile(
                            icon: Icons.schedule_rounded,
                            label: _formatTime(_time, _endedAtSecond),
                            onTap: _pickTime,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const _SectionLabel('DURATION'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _DurationField(
                            controller: _hoursController,
                            label: 'Hours',
                            validator: _validateHours,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _DurationField(
                            controller: _minutesController,
                            label: 'Minutes',
                            validator: _validatePart,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _DurationField(
                            controller: _secondsController,
                            label: 'Seconds',
                            validator: _validateSeconds,
                          ),
                        ),
                      ],
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xFFFF7A90),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 26),
                    BlocBuilder<TimeEntryCubit, TimeEntryState>(
                      builder:
                          (context, state) => _SaveButton(
                            isSaving: state.isSaving,
                            onTap: _save,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(TimeOfDay time, int second) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}:'
      '${second.toString().padLeft(2, '0')}';
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: AppColors.textSecondary,
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.4,
    ),
  );
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.elevatedSurface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppColors.stroke),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
        child: Row(
          children: [
            Icon(icon, color: AppColors.cyan, size: 18),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DurationField extends StatelessWidget {
  const _DurationField({
    required this.controller,
    required this.label,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    validator: validator,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    style: const TextStyle(color: AppColors.textPrimary),
    decoration: _fieldDecoration(label),
  );
}

InputDecoration _fieldDecoration(String label) => InputDecoration(
  labelText: label,
  labelStyle: const TextStyle(color: AppColors.textSecondary),
  filled: true,
  fillColor: AppColors.elevatedSurface,
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide.none,
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: const BorderSide(color: AppColors.stroke),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: const BorderSide(color: AppColors.cyan),
  ),
);

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.isSaving, required this.onTap});

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
              isSaving ? 'Saving…' : 'Save changes',
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
