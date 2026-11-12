import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/widgets/timeflow_navigation.dart';
import '../../../activities/domain/models/activity.dart';
import '../../../activities/presentation/activity_visuals.dart';
import '../../../activities/presentation/cubit/activity_cubit.dart';
import '../cubit/time_entry_cubit.dart';

Future<void> showManualTimeEntrySheet(BuildContext context) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const ManualTimeEntrySheet(),
  );
  if (saved != true || !context.mounted) return;

  final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.cyan),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Your manual entry was successfully saved.',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.elevatedSurface,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          bottomInset + TimeFlowNavigation.clearanceHeight,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
    );
}

class ManualTimeEntrySheet extends StatefulWidget {
  const ManualTimeEntrySheet({super.key});

  @override
  State<ManualTimeEntrySheet> createState() => _ManualTimeEntrySheetState();
}

class _ManualTimeEntrySheetState extends State<ManualTimeEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  final _hoursController = TextEditingController(text: '0');
  final _minutesController = TextEditingController(text: '30');
  late DateTime _date;
  late TimeOfDay _time;
  String? _activityId;
  String? _error;

  @override
  void initState() {
    super.initState();
    final suggestedStart = DateTime.now().subtract(const Duration(minutes: 30));
    _date = DateTime(
      suggestedStart.year,
      suggestedStart.month,
      suggestedStart.day,
    );
    _time = TimeOfDay.fromDateTime(suggestedStart);
    _activityId = context.read<ActivityCubit>().state.selectedActivityId;
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
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
    final activityId = _activityId;
    if (activityId == null) {
      setState(() => _error = 'Choose an activity.');
      return;
    }

    final duration = Duration(
      hours: int.parse(_hoursController.text),
      minutes: int.parse(_minutesController.text),
    );
    final startedAt = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    if (startedAt.add(duration).isAfter(DateTime.now())) {
      setState(() => _error = 'A manual entry cannot end in the future.');
      return;
    }

    setState(() => _error = null);
    final result = await context.read<TimeEntryCubit>().addManualEntry(
      activityId: activityId,
      startedAt: startedAt,
      duration: duration,
    );
    if (!mounted) return;
    switch (result) {
      case ManualEntryResult.success:
        Navigator.of(context).pop(true);
      case ManualEntryResult.sessionActive:
        setState(
          () =>
              _error = 'Finish or discard the current tracking session first.',
        );
      case ManualEntryResult.invalidInput:
        setState(() => _error = 'Enter a valid duration.');
      case ManualEntryResult.failure:
        setState(() => _error = 'Could not save this entry. Please try again.');
    }
  }

  String? _validateHours(String? value) {
    final hours = int.tryParse(value ?? '');
    return hours == null || hours < 0 || hours > 999 ? 'Invalid' : null;
  }

  String? _validateMinutes(String? value) {
    final minutes = int.tryParse(value ?? '');
    if (minutes == null || minutes < 0 || minutes > 59) return '0–59';
    final hours = int.tryParse(_hoursController.text) ?? 0;
    return hours == 0 && minutes == 0 ? 'Required' : null;
  }

  @override
  Widget build(BuildContext context) {
    final activities = context.select<ActivityCubit, List<Activity>>(
      (cubit) => cubit.state.activeActivities,
    );
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SheetHandle(),
                  const SizedBox(height: 22),
                  Text(
                    'Add manual entry',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Record time you already completed.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  const _SectionLabel('ACTIVITY'),
                  const SizedBox(height: 10),
                  _ActivityField(
                    activities: activities,
                    value: _activityId,
                    onChanged: (value) => setState(() => _activityId = value),
                  ),
                  const SizedBox(height: 22),
                  const _SectionLabel('WHEN'),
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
                          label: _formatTime(_time),
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
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DurationField(
                          controller: _minutesController,
                          label: 'Minutes',
                          validator: _validateMinutes,
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
                          enabled: activities.isNotEmpty,
                          onTap: _save,
                        ),
                  ),
                ],
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

  String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 42,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.stroke,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
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

class _ActivityField extends StatelessWidget {
  const _ActivityField({
    required this.activities,
    required this.value,
    required this.onChanged,
  });
  final List<Activity> activities;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    value: activities.any((activity) => activity.id == value) ? value : null,
    dropdownColor: AppColors.elevatedSurface,
    icon: const Icon(Icons.expand_more_rounded),
    decoration: _fieldDecoration('Choose activity'),
    items:
        activities
            .map(
              (activity) => DropdownMenuItem(
                value: activity.id,
                child: Row(
                  children: [
                    Icon(
                      ActivityVisuals.iconFor(activity.iconKey),
                      color: Color(activity.colorValue),
                      size: 19,
                    ),
                    const SizedBox(width: 11),
                    Text(activity.name),
                  ],
                ),
              ),
            )
            .toList(),
    onChanged: activities.isEmpty ? null : onChanged,
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
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    style: const TextStyle(color: AppColors.textPrimary),
    decoration: _fieldDecoration(label),
    validator: validator,
  );
}

InputDecoration _fieldDecoration(String label) => InputDecoration(
  labelText: label,
  labelStyle: const TextStyle(color: AppColors.textSecondary),
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
);

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.isSaving,
    required this.enabled,
    required this.onTap,
  });
  final bool isSaving;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = enabled && !isSaving;
    return Container(
      decoration: BoxDecoration(
        color: active ? null : AppColors.elevatedSurface,
        gradient:
            active
                ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF58C8FF), Color(0xFF2865EC)],
                )
                : null,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: active ? const Color(0xFF5A91FA) : AppColors.stroke,
        ),
        boxShadow:
            active
                ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ]
                : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: active ? onTap : null,
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 54,
            child: Center(
              child: Text(
                isSaving ? 'Saving…' : 'Save entry',
                style: TextStyle(
                  color: active ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
