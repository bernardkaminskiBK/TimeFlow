import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/models/activity.dart';
import '../../domain/repositories/activity_repository.dart';
import '../activity_visuals.dart';
import '../cubit/activity_cubit.dart';
import '../cubit/activity_state.dart';
import '../widgets/activity_editor_sheet.dart';

class ManageActivitiesScreen extends StatefulWidget {
  const ManageActivitiesScreen({super.key});

  @override
  State<ManageActivitiesScreen> createState() => _ManageActivitiesScreenState();
}

class _ManageActivitiesScreenState extends State<ManageActivitiesScreen> {
  static const _destructiveColor = Color(0xFFFF6B7D);

  final Set<String> _deletingActivityIds = {};
  var _showArchived = false;

  void _openEditor([Activity? activity]) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => BlocProvider.value(
            value: context.read<ActivityCubit>(),
            child: ActivityEditorSheet(activity: activity),
          ),
    );
  }

  Future<void> _confirmDelete(Activity activity) async {
    if (_deletingActivityIds.contains(activity.id)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: AppColors.elevatedSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: const BorderSide(color: AppColors.stroke),
            ),
            title: const Text('Delete activity?'),
            content: const Text(
              'This activity will be permanently deleted. This action cannot be undone.',
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
                    color: _destructiveColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deletingActivityIds.add(activity.id));
    try {
      final result = await context.read<ActivityCubit>().deleteActivity(
        activity.id,
      );
      if (!mounted) return;

      final message = switch (result) {
        ActivityDeletionResult.deleted => 'Activity deleted.',
        ActivityDeletionResult.referenced =>
          'This activity has recorded sessions and cannot be permanently deleted.',
        ActivityDeletionResult.notFound => 'This activity no longer exists.',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: AppColors.elevatedSurface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not delete this activity.',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: AppColors.elevatedSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _deletingActivityIds.remove(activity.id));
      }
    }
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
          'Manage Activities',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.6, -0.7),
            radius: 1.15,
            colors: [Color(0xFF10264A), AppColors.background],
            stops: [0, 0.7],
          ),
        ),
        child: SafeArea(
          child: BlocBuilder<ActivityCubit, ActivityState>(
            builder: (context, state) {
              final activities =
                  _showArchived
                      ? state.archivedActivities
                      : state.activeActivities;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                    child: _ActivityFilter(
                      showArchived: _showArchived,
                      activeCount: state.activeActivities.length,
                      archivedCount: state.archivedActivities.length,
                      onChanged:
                          (value) => setState(() => _showArchived = value),
                    ),
                  ),
                  Expanded(
                    child: switch (state.status) {
                      ActivityStatus.loading => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      ActivityStatus.failure when activities.isEmpty =>
                        const _EmptyState(
                          icon: Icons.error_outline_rounded,
                          title: 'Activities unavailable',
                          message: 'Please try again.',
                        ),
                      _ when activities.isEmpty => _EmptyState(
                        icon:
                            _showArchived
                                ? Icons.inventory_2_outlined
                                : Icons.bolt_rounded,
                        title:
                            _showArchived
                                ? 'No archived activities'
                                : 'No active activities',
                        message:
                            _showArchived
                                ? 'Archived activities will appear here.'
                                : 'Add an activity to begin your flow.',
                      ),
                      _ => ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
                        itemCount: activities.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder:
                            (context, index) => _ActivityCard(
                              activity: activities[index],
                              isArchived: _showArchived,
                              onEdit: () => _openEditor(activities[index]),
                              onArchive:
                                  () => context
                                      .read<ActivityCubit>()
                                      .archiveActivity(activities[index]),
                              onRestore:
                                  () => context
                                      .read<ActivityCubit>()
                                      .restoreActivity(activities[index]),
                              onDelete: () => _confirmDelete(activities[index]),
                              isDeleting: _deletingActivityIds.contains(
                                activities[index].id,
                              ),
                            ),
                      ),
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton:
          _showArchived
              ? null
              : Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.32),
                      blurRadius: 22,
                      offset: const Offset(0, 9),
                    ),
                  ],
                ),
                child: FloatingActionButton.extended(
                  onPressed: _openEditor,
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'Add Activity',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
    );
  }
}

class _ActivityFilter extends StatelessWidget {
  const _ActivityFilter({
    required this.showArchived,
    required this.activeCount,
    required this.archivedCount,
    required this.onChanged,
  });

  final bool showArchived;
  final int activeCount;
  final int archivedCount;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: [
          Expanded(
            child: _FilterOption(
              label: 'Active',
              count: activeCount,
              selected: !showArchived,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _FilterOption(
              label: 'Archived',
              count: archivedCount,
              selected: showArchived,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterOption extends StatelessWidget {
  const _FilterOption({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.elevatedSurface : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color:
                      selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      selected
                          ? AppColors.primary.withValues(alpha: 0.16)
                          : AppColors.stroke.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: selected ? AppColors.cyan : AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.activity,
    required this.isArchived,
    required this.onEdit,
    required this.onArchive,
    required this.onRestore,
    required this.onDelete,
    required this.isDeleting,
  });

  final Activity activity;
  final bool isArchived;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback onRestore;
  final VoidCallback onDelete;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    final accent = Color(activity.colorValue);
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 14, 8, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF11233D), AppColors.surface],
        ),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x42000000),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: accent.withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(color: accent.withValues(alpha: 0.1), blurRadius: 12),
              ],
            ),
            child: Icon(
              ActivityVisuals.iconFor(activity.iconKey),
              color: accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              activity.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (!isArchived)
            IconButton(
              tooltip: 'Edit',
              onPressed: onEdit,
              icon: const Icon(
                Icons.edit_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
          IconButton(
            tooltip: isArchived ? 'Restore' : 'Archive',
            onPressed: isArchived ? onRestore : onArchive,
            icon: Icon(
              isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
              color: isArchived ? AppColors.cyan : AppColors.textSecondary,
              size: 21,
            ),
          ),
          if (isArchived)
            IconButton(
              tooltip: 'Delete',
              onPressed: isDeleting ? null : onDelete,
              icon:
                  isDeleting
                      ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(
                        Icons.delete_outline_rounded,
                        color: _ManageActivitiesScreenState._destructiveColor,
                        size: 21,
                      ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Icon(icon, color: AppColors.cyan, size: 28),
            ),
            const SizedBox(height: 18),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
