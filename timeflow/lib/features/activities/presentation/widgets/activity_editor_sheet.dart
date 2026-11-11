import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/models/activity.dart';
import '../activity_visuals.dart';
import '../cubit/activity_cubit.dart';

class ActivityEditorSheet extends StatefulWidget {
  const ActivityEditorSheet({this.activity, super.key});

  final Activity? activity;

  @override
  State<ActivityEditorSheet> createState() => _ActivityEditorSheetState();
}

class _ActivityEditorSheetState extends State<ActivityEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _iconKey;
  late int _colorValue;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.activity?.name);
    _iconKey = widget.activity?.iconKey ?? ActivityVisuals.icons.keys.first;
    _colorValue = widget.activity?.colorValue ?? ActivityVisuals.colors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    setState(() => _isSaving = true);

    final cubit = context.read<ActivityCubit>();
    final activity = widget.activity;
    if (activity == null) {
      await cubit.addActivity(
        name: _nameController.text,
        colorValue: _colorValue,
        iconKey: _iconKey,
      );
    } else {
      await cubit.updateActivity(
        activity: activity,
        name: _nameController.text,
        colorValue: _colorValue,
        iconKey: _iconKey,
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
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
            child: Form(
              key: _formKey,
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
                  Text(
                    widget.activity == null ? 'Add activity' : 'Edit activity',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 22),
                  TextFormField(
                    controller: _nameController,
                    autofocus: widget.activity == null,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Activity name',
                      labelStyle: const TextStyle(
                        color: AppColors.textSecondary,
                      ),
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
                    validator:
                        (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Enter an activity name'
                                : null,
                    onFieldSubmitted: (_) => _save(),
                  ),
                  const SizedBox(height: 24),
                  const _SectionLabel('ICON'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children:
                        ActivityVisuals.icons.entries.map((entry) {
                          final selected = entry.key == _iconKey;
                          return _SelectionTile(
                            selected: selected,
                            color: Color(_colorValue),
                            onTap: () => setState(() => _iconKey = entry.key),
                            child: Icon(
                              entry.value,
                              color:
                                  selected
                                      ? Color(_colorValue)
                                      : AppColors.textSecondary,
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 24),
                  const _SectionLabel('COLOR'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children:
                        ActivityVisuals.colors.map((value) {
                          final color = Color(value);
                          return _SelectionTile(
                            selected: value == _colorValue,
                            color: color,
                            onTap: () => setState(() => _colorValue = value),
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.35),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 30),
                  FilledButton(
                    onPressed: _isSaving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      _isSaving
                          ? 'Saving…'
                          : widget.activity == null
                          ? 'Add activity'
                          : 'Save changes',
                      style: const TextStyle(fontWeight: FontWeight.w700),
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
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _SelectionTile extends StatelessWidget {
  const _SelectionTile({
    required this.selected,
    required this.color,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          selected ? color.withValues(alpha: 0.12) : AppColors.elevatedSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: selected ? color : AppColors.stroke),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: SizedBox.square(dimension: 50, child: Center(child: child)),
      ),
    );
  }
}
