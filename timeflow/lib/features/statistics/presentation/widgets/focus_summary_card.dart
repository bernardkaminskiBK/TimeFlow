import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

class FocusSummaryCard extends StatelessWidget {
  const FocusSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF183052), Color(0xFF0C192C)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x9A254267)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x52000000),
            blurRadius: 20,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.26),
              ),
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: AppColors.cyan,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL FOCUS TIME',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text('18h 45m', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF49D49D).withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x3849D49D)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_upward_rounded,
                  size: 13,
                  color: Color(0xFF62DEAC),
                ),
                SizedBox(width: 3),
                Text(
                  '12% vs last week',
                  style: TextStyle(
                    color: Color(0xFF62DEAC),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
