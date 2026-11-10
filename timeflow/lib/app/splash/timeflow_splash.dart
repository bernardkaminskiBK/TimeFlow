import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class TimeFlowSplash extends StatefulWidget {
  const TimeFlowSplash({required this.onFinished, super.key});

  final VoidCallback onFinished;

  @override
  State<TimeFlowSplash> createState() => _TimeFlowSplashState();
}

class _TimeFlowSplashState extends State<TimeFlowSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  var _didFinish = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..addStatusListener(_handleStatus);
    _controller.forward();
  }

  void _handleStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _didFinish) return;
    _didFinish = true;
    widget.onFinished();
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_handleStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entrance = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.72, curve: Curves.easeOutCubic),
    );
    final copyFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 0.9, curve: Curves.easeOut),
    );

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.35, -0.12),
            radius: 1.05,
            colors: [Color(0xFF102744), AppColors.background],
            stops: [0, 0.72],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: entrance.value,
                  child: Transform.scale(
                    scale: 0.88 + entrance.value * 0.12,
                    child: child,
                  ),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox.square(
                    dimension: 226,
                    child: CustomPaint(
                      painter: _TimeFlowMarkPainter(_controller),
                    ),
                  ),
                  const SizedBox(height: 28),
                  FadeTransition(
                    opacity: copyFade,
                    child: const Column(
                      children: [
                        Text(
                          'TIMEFLOW',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 4.6,
                          ),
                        ),
                        SizedBox(height: 9),
                        Text(
                          'FLOW INTO FOCUS',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.1,
                          ),
                        ),
                      ],
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

class _TimeFlowMarkPainter extends CustomPainter {
  _TimeFlowMarkPainter(this.progress) : super(repaint: progress);

  final Animation<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.38;
    final ringProgress = Curves.easeInOutCubic.transform(
      const Interval(0.05, 0.58).transform(progress.value),
    );
    final flowProgress = Curves.easeOutCubic.transform(
      const Interval(0.3, 0.82).transform(progress.value),
    );

    canvas.drawCircle(
      center,
      radius * 0.92,
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.14 * ringProgress)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
    );

    final ringRect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      ringRect,
      -math.pi / 2,
      math.pi * 2 * ringProgress,
      false,
      Paint()
        ..shader = const SweepGradient(
          colors: [Color(0xFF183D83), Color(0xFF8FC8FF), Color(0xFF2053A6)],
        ).createShader(ringRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round,
    );

    if (ringProgress > 0.55) {
      final tickOpacity = ((ringProgress - 0.55) / 0.45).clamp(0.0, 1.0);
      final tickPaint =
          Paint()
            ..color = AppColors.cyan.withValues(alpha: tickOpacity)
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round;
      for (var index = 0; index < 8; index++) {
        final angle = index * math.pi / 4 - math.pi / 2;
        final start =
            center + Offset(math.cos(angle), math.sin(angle)) * (radius * 0.71);
        final end =
            center + Offset(math.cos(angle), math.sin(angle)) * (radius * 0.81);
        canvas.drawLine(start, end, tickPaint);
      }
    }

    final wave =
        Path()
          ..moveTo(size.width * 0.18, size.height * 0.61)
          ..cubicTo(
            size.width * 0.38,
            size.height * 0.76,
            size.width * 0.48,
            size.height * 0.35,
            size.width * 0.68,
            size.height * 0.43,
          )
          ..cubicTo(
            size.width * 0.79,
            size.height * 0.47,
            size.width * 0.84,
            size.height * 0.32,
            size.width * 0.91,
            size.height * 0.38,
          );
    final metric = wave.computeMetrics().first;
    final visibleWave = metric.extractPath(0, metric.length * flowProgress);

    canvas.drawPath(
      visibleWave,
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.28 * flowProgress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 28
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 13),
    );
    canvas.drawPath(
      visibleWave,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF1E5EF4), AppColors.cyan],
        ).createShader(Offset.zero & size)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 17
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _TimeFlowMarkPainter oldDelegate) => false;
}
