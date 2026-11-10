import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

class StopwatchDial extends StatelessWidget {
  const StopwatchDial({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = math.min(constraints.maxWidth, 330.0);
          return SizedBox.square(
            dimension: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(size: Size.square(size), painter: _DialPainter()),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '00:00:00',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 13),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _StatusDot(),
                        SizedBox(width: 8),
                        Text(
                          'READY TO TRACK',
                          style: TextStyle(
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
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.cyan,
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: 0.7),
            blurRadius: 8,
          ),
        ],
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    canvas.drawCircle(
      center,
      radius * 0.9,
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.18)
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
    canvas.drawArc(
      arcRect,
      -math.pi * 0.72,
      math.pi * 0.8,
      false,
      Paint()
        ..shader = const SweepGradient(
          colors: [AppColors.primary, AppColors.cyan, AppColors.primary],
        ).createShader(arcRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.06
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6),
    );

    final tickPaint =
        Paint()
          ..color = AppColors.textSecondary.withValues(alpha: 0.42)
          ..strokeWidth = 1;
    for (var index = 0; index < 36; index++) {
      final angle = (index / 36) * math.pi * 2 - math.pi / 2;
      final outer = radius * 0.71;
      final inner = outer - (index % 3 == 0 ? 6 : 3);
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
