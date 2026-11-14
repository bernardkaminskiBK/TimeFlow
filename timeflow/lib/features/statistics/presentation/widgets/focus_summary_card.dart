import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/statistics_snapshot.dart';

class FocusSummaryCard extends StatelessWidget {
  const FocusSummaryCard({required this.snapshot, super.key});

  final StatisticsSnapshot snapshot;

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
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatStatisticsDuration(snapshot.total),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 132),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: (snapshot.isImproved
                        ? const Color(0xFF49D49D)
                        : const Color(0xFFFF7A90))
                    .withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      snapshot.isImproved
                          ? const Color(0x3849D49D)
                          : const Color(0x38FF7A90),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      snapshot.isImproved
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 13,
                      color:
                          snapshot.isImproved
                              ? const Color(0xFF62DEAC)
                              : const Color(0xFFFF7A90),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      snapshot.comparisonLabel,
                      style: TextStyle(
                        color:
                            snapshot.isImproved
                                ? const Color(0xFF62DEAC)
                                : const Color(0xFFFF7A90),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
