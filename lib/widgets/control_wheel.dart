import 'dart:math' as math;
import 'package:flutter/material.dart';

class ControlWheel extends StatelessWidget {
  final VoidCallback onHome;
  final void Function(String axis, double value) onMove;

  const ControlWheel({
    super.key,
    required this.onHome,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        final center = size / 2;
        final rHome = size * 0.15; 
        final rInner = size * 0.35; 
        final rOuter = size * 0.5; 

        return GestureDetector(
          onTapDown: (details) {
            final localPos = details.localPosition;
            final dx = localPos.dx - center;
            final dy = localPos.dy - center;
            final distance = math.sqrt(dx * dx + dy * dy);

            if (distance < rHome) {
              onHome();
              return;
            }

            if (distance > rOuter) {
              return; // Tapped outside the circle
            }

            final angle = math.atan2(dy, dx);
            // Angle ranges:
            // Right (X): -pi/4 to pi/4
            // Bottom (-Y): pi/4 to 3*pi/4
            // Left (-X): 3*pi/4 to pi or -pi to -3*pi/4
            // Top (Y): -3*pi/4 to -pi/4

            String axis;
            double multiplier;

            if (angle >= -math.pi / 4 && angle < math.pi / 4) {
              axis = 'X';
              multiplier = 1.0;
            } else if (angle >= math.pi / 4 && angle < 3 * math.pi / 4) {
              axis = 'Y';
              multiplier = -1.0;
            } else if (angle >= -3 * math.pi / 4 && angle < -math.pi / 4) {
              axis = 'Y';
              multiplier = 1.0;
            } else {
              axis = 'X';
              multiplier = -1.0;
            }

            final isInner = distance < rInner;
            final value = (isInner ? 1.0 : 10.0) * multiplier;

            onMove(axis, value);
          },
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ControlWheelPainter(
                      rHome: rHome,
                      rInner: rInner,
                      rOuter: rOuter,
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: rHome * 2,
                    height: rHome * 2,
                    decoration: const BoxDecoration(
                      color: Color(0xFF28282D),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.home,
                      color: Colors.greenAccent[400],
                      size: rHome * 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ControlWheelPainter extends CustomPainter {
  final double rHome;
  final double rInner;
  final double rOuter;

  _ControlWheelPainter({
    required this.rHome,
    required this.rInner,
    required this.rOuter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Paints
    final bgPaint = Paint()
      ..color = const Color(0xFF38393F)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF1E1E22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final dividerPaint = Paint()
      ..color = const Color(0xFF1E1E22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Draw background outer circle
    canvas.drawCircle(center, rOuter, bgPaint);

    // Draw inner ring shading
    final innerRingPaint = Paint()
      ..color = const Color(0xFF42434A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, rInner, innerRingPaint);

    // Draw home ring background
    canvas.drawCircle(center, rHome, bgPaint);

    // Draw concentric ring outlines
    canvas.drawCircle(center, rOuter, borderPaint);
    canvas.drawCircle(center, rInner, borderPaint);
    canvas.drawCircle(center, rHome, borderPaint);

    // Draw diagonal dividers
    for (int i = 0; i < 4; i++) {
      final angle = math.pi / 4 + i * math.pi / 2;
      final start = Offset(
        center.dx + rHome * math.cos(angle),
        center.dy + rHome * math.sin(angle),
      );
      final end = Offset(
        center.dx + rOuter * math.cos(angle),
        center.dy + rOuter * math.sin(angle),
      );
      canvas.drawLine(start, end, dividerPaint);
    }

    // Draw labels: Y (Top), -Y (Bottom), X (Right), -X (Left)
    _drawText(canvas, center, "Y", Offset(0, -(rOuter + rInner) / 2 - 15));
    _drawText(canvas, center, "-Y", Offset(0, (rOuter + rInner) / 2 + 5));
    _drawText(canvas, center, "X", Offset((rOuter + rInner) / 2 + 10, -5));
    _drawText(canvas, center, "-X", Offset(-(rOuter + rInner) / 2 - 20, -5));

    // Step labels
    final xAngle = -math.pi / 8;
    final pPlus1 = Offset(
      (rInner + rHome) / 2 * math.cos(xAngle),
      (rInner + rHome) / 2 * math.sin(xAngle) - 6,
    );
    final pPlus10 = Offset(
      (rOuter + rInner) / 2 * math.cos(xAngle),
      (rOuter + rInner) / 2 * math.sin(xAngle) - 6,
    );
    _drawText(canvas, center, "+1", pPlus1, fontSize: 11, color: Colors.white38);
    _drawText(canvas, center, "+10", pPlus10, fontSize: 11, color: Colors.white38);

    final yAngle = 3 * math.pi / 8;
    final pMinus1 = Offset(
      (rInner + rHome) / 2 * math.cos(yAngle) - 10,
      (rInner + rHome) / 2 * math.sin(yAngle),
    );
    final pMinus10 = Offset(
      (rOuter + rInner) / 2 * math.cos(yAngle) - 15,
      (rOuter + rInner) / 2 * math.sin(yAngle) - 5,
    );
    _drawText(canvas, center, "-1", pMinus1, fontSize: 11, color: Colors.white38);
    _drawText(canvas, center, "-10", pMinus10, fontSize: 11, color: Colors.white38);
  }

  void _drawText(Canvas canvas, Offset center, String text, Offset offset, {double fontSize = 14, Color color = Colors.white70}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx + offset.dx - textPainter.width / 2, center.dy + offset.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
