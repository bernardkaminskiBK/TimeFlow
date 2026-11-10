import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

const _programmingColor = AppColors.cyan;
const _englishColor = Color(0xFF8B7CFF);
const _workoutColor = Color(0xFFFF7A90);
const _readingColor = Color(0xFFFFB85C);

class ActivityBreakdownCard extends StatelessWidget {
  const ActivityBreakdownCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.stroke.withValues(alpha: 0.7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x47000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Activity breakdown',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              const Text(
                'THIS WEEK',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox.square(
              dimension: 190,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size.square(190),
                    painter: _DonutChartPainter(),
                  ),
                  const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '18h 45m',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'TOTAL TIME',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          const _LegendItem(
            color: _programmingColor,
            activity: 'Programming',
            duration: '9h 30m',
            percentage: '51%',
          ),
          const SizedBox(height: 12),
          const _LegendItem(
            color: _englishColor,
            activity: 'English',
            duration: '5h 15m',
            percentage: '28%',
          ),
          const SizedBox(height: 12),
          const _LegendItem(
            color: _workoutColor,
            activity: 'Workout',
            duration: '2h 30m',
            percentage: '13%',
          ),
          const SizedBox(height: 12),
          const _LegendItem(
            color: _readingColor,
            activity: 'Reading',
            duration: '1h 30m',
            percentage: '8%',
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.activity,
    required this.duration,
    required this.percentage,
  });

  final Color color;
  final String activity;
  final String duration;
  final String percentage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 7),
            ],
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            activity,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          duration,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 14),
        SizedBox(
          width: 30,
          child: Text(
            percentage,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  static const _segments = [
    (0.51, _programmingColor),
    (0.28, _englishColor),
    (0.13, _workoutColor),
    (0.08, _readingColor),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.39;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const strokeWidth = 22.0;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFF192A40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    var startAngle = -math.pi / 2;
    const gap = 0.045;
    for (final segment in _segments) {
      final sweep = math.pi * 2 * segment.$1;
      final color = segment.$2;
      canvas.drawArc(
        rect,
        startAngle + gap / 2,
        sweep - gap,
        false,
        Paint()
          ..color = color.withValues(alpha: 0.17)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 8
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
      );
      canvas.drawArc(
        rect,
        startAngle + gap / 2,
        sweep - gap,
        false,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withValues(alpha: 0.72), color],
          ).createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
      startAngle += sweep;
    }

    canvas.drawCircle(
      center,
      radius - strokeWidth / 2 - 5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.stroke.withValues(alpha: 0.65),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
