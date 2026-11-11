import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

class TimerControls extends StatelessWidget {
  const TimerControls({required this.onManageActivities, super.key});

  final VoidCallback onManageActivities;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _RoundControl(
          icon: Icons.edit_outlined,
          semanticLabel: 'Add manual time',
        ),
        const SizedBox(width: 18),
        Semantics(
          button: true,
          label: 'Start timer',
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF58C8FF), Color(0xFF2865EC)],
              ),
              boxShadow: [
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
                onTap: () {},
                borderRadius: BorderRadius.circular(22),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 35, vertical: 17),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Start focus',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 18),
        _MoreMenu(onManageActivities: onManageActivities),
      ],
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
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;

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
            child: Icon(icon, color: AppColors.textSecondary, size: 21),
          ),
        ),
      ),
    );
  }
}
