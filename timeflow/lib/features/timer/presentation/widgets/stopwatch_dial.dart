import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../activities/presentation/activity_visuals.dart';
import '../cubit/stopwatch_cubit.dart';
import '../cubit/stopwatch_state.dart';

class StopwatchDial extends StatelessWidget {
  const StopwatchDial({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StopwatchCubit, StopwatchState>(
      builder: (context, state) {
        final progress = (state.elapsed.inMilliseconds % 60000) / 60000.0;
        return Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = math.min(constraints.maxWidth, 330.0);
              return SizedBox.square(
                dimension: size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: Size.square(size),
                      painter: _DialPainter(
                        progress: progress,
                        completedMinutes: state.elapsed.inMinutes,
                        isActive: state.hasSession,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatDuration(state.elapsed),
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        const SizedBox(height: 13),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _StatusDot(status: state.status),
                            const SizedBox(width: 8),
                            Text(
                              _statusLabel(state.status),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String _statusLabel(StopwatchStatus status) {
    return switch (status) {
      StopwatchStatus.ready => 'READY TO TRACK',
      StopwatchStatus.running => 'FOCUS IN PROGRESS',
      StopwatchStatus.paused => 'PAUSED',
      StopwatchStatus.stopped => 'SESSION COMPLETE',
    };
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

  final StopwatchStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      StopwatchStatus.paused => const Color(0xFFFFB85C),
      StopwatchStatus.stopped => const Color(0xFF49D49D),
      _ => AppColors.cyan,
    };
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 8),
        ],
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  const _DialPainter({
    required this.progress,
    required this.completedMinutes,
    required this.isActive,
  });

  final double progress;
  final int completedMinutes;
  final bool isActive;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final cycleIndex = completedMinutes ~/ 60;
    final minuteInCycle = completedMinutes % 60;
    final currentColor = Color(
      ActivityVisuals.colors[cycleIndex % ActivityVisuals.colors.length],
    );
    final previousColor = Color(
      ActivityVisuals.colors[(cycleIndex - 1) % ActivityVisuals.colors.length],
    );

    canvas.drawCircle(
      center,
      radius * 0.9,
      Paint()
        ..color = AppColors.primary.withValues(alpha: isActive ? 0.24 : 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
    );
    canvas.drawCircle(
      center,
      radius * 0.94,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2B4668), Color(0xFF060A12), Color(0xFF172C48)],
          stops: [0, 0.48, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center,
      radius * 0.865,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.22, -0.28),
          radius: 1.05,
          colors: [Color(0xFF172D4E), Color(0xFF08111F), Color(0xFF03070E)],
          stops: [0, 0.62, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    final arcRect = Rect.fromCircle(center: center, radius: radius * 0.79);
    canvas.drawArc(
      arcRect,
      -math.pi * 0.72,
      math.pi * 1.44,
      false,
      Paint()
        ..color = const Color(0xFF1B2B42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.055
        ..strokeCap = StrokeCap.round,
    );
    if (progress > 0) {
      canvas.drawArc(
        arcRect,
        -math.pi * 0.72,
        math.pi * 1.44 * progress,
        false,
        Paint()
          ..shader = SweepGradient(
            colors: [
              currentColor.withValues(alpha: 0.72),
              currentColor,
              currentColor.withValues(alpha: 0.86),
            ],
          ).createShader(arcRect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.06
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6),
      );
    }

    for (var index = 0; index < 60; index++) {
      final isCompletedThisCycle = index < minuteInCycle;
      final color = switch ((cycleIndex, isCompletedThisCycle)) {
        (0, true) => currentColor,
        (0, false) => AppColors.textSecondary.withValues(alpha: 0.3),
        (_, true) => currentColor,
        (_, false) => previousColor.withValues(alpha: 0.72),
      };
      final isLatestCompleted = minuteInCycle > 0 && index == minuteInCycle - 1;
      final tickPaint =
          Paint()
            ..color = color
            ..strokeWidth = isLatestCompleted ? 2.4 : 1.35
            ..strokeCap = StrokeCap.round;
      final angle = (index / 60) * math.pi * 2 - math.pi / 2;
      final outer = radius * 0.71;
      final inner = outer - (index % 5 == 0 ? 7 : 3.5);
      canvas.drawLine(
        center + Offset(math.cos(angle), math.sin(angle)) * inner,
        center + Offset(math.cos(angle), math.sin(angle)) * outer,
        tickPaint,
      );
    }

    canvas.drawCircle(
      center,
      radius * 0.61,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFF1A304D),
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.9),
      math.pi * 1.12,
      math.pi * 0.52,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = AppColors.cyan.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      completedMinutes != oldDelegate.completedMinutes ||
      isActive != oldDelegate.isActive;
}
