import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/widgets/timeflow_navigation.dart';
import '../../../activities/presentation/cubit/activity_cubit.dart';
import '../../../time_entries/presentation/widgets/manual_time_entry_sheet.dart';
import '../cubit/stopwatch_cubit.dart';
import '../cubit/stopwatch_state.dart';

class TimerControls extends StatelessWidget {
  const TimerControls({required this.onManageActivities, super.key});

  final VoidCallback onManageActivities;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StopwatchCubit, StopwatchState>(
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child:
              state.status == StopwatchStatus.ready
                  ? _ReadyControls(
                    key: const ValueKey('ready-controls'),
                    onManageActivities: onManageActivities,
                  )
                  : _SessionControls(
                    key: ValueKey(state.status),
                    state: state,
                    onManageActivities: onManageActivities,
                  ),
        );
      },
    );
  }
}

class _ReadyControls extends StatelessWidget {
  const _ReadyControls({required this.onManageActivities, super.key});

  final VoidCallback onManageActivities;

  @override
  Widget build(BuildContext context) {
    final selectedActivityId = context.select<ActivityCubit, String?>(
      (cubit) => cubit.state.selectedActivityId,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _RoundControl(
          icon: Icons.edit_outlined,
          semanticLabel: 'Add manual time',
          onTap: () => showManualTimeEntrySheet(context),
        ),
        const SizedBox(width: 18),
        _PrimaryControl(
          icon: Icons.play_arrow_rounded,
          label: 'Start focus',
          onTap:
              selectedActivityId == null
                  ? null
                  : () =>
                      context.read<StopwatchCubit>().start(selectedActivityId),
        ),
        const SizedBox(width: 18),
        _MoreMenu(onManageActivities: onManageActivities),
      ],
    );
  }
}

class _SessionControls extends StatelessWidget {
  const _SessionControls({
    required this.state,
    required this.onManageActivities,
    super.key,
  });

  final StopwatchState state;
  final VoidCallback onManageActivities;

  Future<void> _save(BuildContext context) async {
    final result = await context.read<StopwatchCubit>().save();
    if (!context.mounted || result != StopwatchCommandResult.success) return;

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
                  'Your session was successfully saved.',
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
            bottomInset + TimeFlowNavigation.snackBarClearanceHeight,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<StopwatchCubit>();
    if (state.status == StopwatchStatus.stopped) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _RoundControl(
            icon: Icons.delete_outline_rounded,
            semanticLabel: 'Discard session',
            iconColor: const Color(0xFFFF7A90),
            onTap: cubit.discard,
          ),
          const SizedBox(width: 10),
          _CompactControl(
            icon: Icons.play_arrow_rounded,
            label: 'Resume',
            onTap: cubit.resume,
          ),
          const SizedBox(width: 10),
          _CompactControl(
            icon: Icons.check_rounded,
            label: 'Save',
            primary: true,
            onTap: () => _save(context),
          ),
        ],
      );
    }

    final (secondaryLabel, secondaryIcon, secondaryAction) = switch (state
        .status) {
      StopwatchStatus.running => ('Pause', Icons.pause_rounded, cubit.pause),
      StopwatchStatus.paused => (
        'Resume',
        Icons.play_arrow_rounded,
        cubit.resume,
      ),
      StopwatchStatus.stopped =>
        throw StateError('Stopped uses separate controls'),
      StopwatchStatus.ready => throw StateError('Ready uses separate controls'),
    };
    const primaryLabel = 'Stop';
    const primaryIcon = Icons.stop_rounded;
    final primaryAction = cubit.stop;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CompactControl(
          icon: secondaryIcon,
          label: secondaryLabel,
          onTap: secondaryAction,
        ),
        const SizedBox(width: 10),
        _CompactControl(
          icon: primaryIcon,
          label: primaryLabel,
          primary: true,
          onTap: primaryAction,
        ),
        const SizedBox(width: 10),
        _MoreMenu(onManageActivities: onManageActivities),
      ],
    );
  }
}

class _PrimaryControl extends StatelessWidget {
  const _PrimaryControl({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient:
            enabled
                ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF58C8FF), Color(0xFF2865EC)],
                )
                : const LinearGradient(
                  colors: [AppColors.elevatedSurface, AppColors.surface],
                ),
        boxShadow:
            enabled
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
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 17),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: enabled ? Colors.white : AppColors.textSecondary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: enabled ? Colors.white : AppColors.textSecondary,
                    fontSize: 15,
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

class _CompactControl extends StatelessWidget {
  const _CompactControl({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: primary ? null : AppColors.surface,
        gradient:
            primary
                ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF58C8FF), Color(0xFF2865EC)],
                )
                : null,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: primary ? const Color(0xFF5A91FA) : AppColors.stroke,
        ),
        boxShadow:
            primary
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
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 6),
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

class _MoreMenu extends StatelessWidget {
  const _MoreMenu({required this.onManageActivities});

  final VoidCallback onManageActivities;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      alignmentOffset: const Offset(-150, 8),
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(AppColors.surface),
        elevation: const WidgetStatePropertyAll(12),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.stroke),
          ),
        ),
      ),
      menuChildren: [
        MenuItemButton(
          onPressed: onManageActivities,
          leadingIcon: const Icon(
            Icons.tune_rounded,
            color: AppColors.cyan,
            size: 20,
          ),
          child: const Text('Manage Activities'),
        ),
      ],
      builder:
          (context, controller, child) => _RoundControl(
            icon: Icons.more_horiz_rounded,
            semanticLabel: 'More options',
            onTap: controller.isOpen ? controller.close : controller.open,
          ),
    );
  }
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({
    required this.icon,
    required this.semanticLabel,
    this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: AppColors.surface,
        shape: CircleBorder(
          side: BorderSide(color: AppColors.stroke.withValues(alpha: 0.8)),
        ),
        child: InkWell(
          onTap: onTap ?? () {},
          customBorder: const CircleBorder(),
          child: SizedBox.square(
            dimension: 48,
            child: Icon(
              icon,
              color: iconColor ?? AppColors.textSecondary,
              size: 21,
            ),
          ),
        ),
      ),
    );
  }
}
