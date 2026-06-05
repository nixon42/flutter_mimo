import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class ControlWheel extends StatefulWidget {
  final VoidCallback onHome;
  final void Function(String axis, double value) onMove;

  const ControlWheel({
    super.key,
    required this.onHome,
    required this.onMove,
  });

  @override
  State<ControlWheel> createState() => _ControlWheelState();
}

class _ControlWheelState extends State<ControlWheel> {
  String? _activeAxis;
  double? _activeValue;
  Timer? _moveTimer;

  @override
  void dispose() {
    _moveTimer?.cancel();
    super.dispose();
  }

  void _stopMovement() {
    _moveTimer?.cancel();
    _moveTimer = null;
    setState(() {
      _activeAxis = null;
      _activeValue = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        final center = size / 2;
        final rHome = size * 0.15; 
        final rInner = size * 0.35; 
        final rOuter = size * 0.5; 

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            children: [
              // Background Segmented Pad with touch listener
              Positioned.fill(
                child: GestureDetector(
                  onTapDown: (details) {
                    final localPos = details.localPosition;
                    final dx = localPos.dx - center;
                    final dy = localPos.dy - center;
                    final distance = math.sqrt(dx * dx + dy * dy);

                    if (distance < rHome || distance > rOuter) {
                      return; // Inside stop button or outside the wheel
                    }

                    final angle = math.atan2(dy, dx);
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

                    setState(() {
                      _activeAxis = axis;
                      _activeValue = value;
                    });

                    widget.onMove(axis, value);

                    _moveTimer?.cancel();
                    _moveTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
                      widget.onMove(axis, value);
                    });
                  },
                  onTapUp: (_) {
                    _stopMovement();
                  },
                  onTapCancel: () {
                    _stopMovement();
                  },
                  child: CustomPaint(
                    painter: _ControlWheelPainter(
                      rHome: rHome,
                      rInner: rInner,
                      rOuter: rOuter,
                      activeAxis: _activeAxis,
                      activeValue: _activeValue,
                    ),
                  ),
                ),
              ),
              
              // Center Stop Button with InkWell ripple effect
              Center(
                child: ClipOval(
                  child: Material(
                    color: const Color(0xFF28282D),
                    child: InkWell(
                      onTap: widget.onHome,
                      splashColor: Colors.redAccent.withOpacity(0.3),
                      highlightColor: Colors.redAccent.withOpacity(0.15),
                      child: SizedBox(
                        width: rHome * 2,
                        height: rHome * 2,
                        child: Center(
                          child: Icon(
                            Icons.stop,
                            color: Colors.redAccent[400],
                            size: rHome * 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SegmentData {
  final String axis;
  final double value;
  final double startAngle;
  final double sweepAngle;
  final double innerRadius;
  final double outerRadius;

  _SegmentData(this.axis, this.value, this.startAngle, this.sweepAngle, this.innerRadius, this.outerRadius);
}

class _ControlWheelPainter extends CustomPainter {
  final double rHome;
  final double rInner;
  final double rOuter;
  final String? activeAxis;
  final double? activeValue;

  _ControlWheelPainter({
    required this.rHome,
    required this.rInner,
    required this.rOuter,
    required this.activeAxis,
    required this.activeValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final borderPaint = Paint()
      ..color = const Color(0xFF1E1E22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final dividerPaint = Paint()
      ..color = const Color(0xFF1E1E22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Define all 8 segments
    final segments = [
      // Right (X)
      _SegmentData('X', 1.0, -math.pi / 4, math.pi / 2, rHome, rInner),
      _SegmentData('X', 10.0, -math.pi / 4, math.pi / 2, rInner, rOuter),
      // Bottom (-Y / Mundur)
      _SegmentData('Y', -1.0, math.pi / 4, math.pi / 2, rHome, rInner),
      _SegmentData('Y', -10.0, math.pi / 4, math.pi / 2, rInner, rOuter),
      // Left (-X / Kiri)
      _SegmentData('X', -1.0, 3 * math.pi / 4, math.pi / 2, rHome, rInner),
      _SegmentData('X', -10.0, 3 * math.pi / 4, math.pi / 2, rInner, rOuter),
      // Top (Y / Maju)
      _SegmentData('Y', 1.0, -3 * math.pi / 4, math.pi / 2, rHome, rInner),
      _SegmentData('Y', 10.0, -3 * math.pi / 4, math.pi / 2, rInner, rOuter),
    ];

    // Paint each segment
    for (final seg in segments) {
      final isOuter = seg.innerRadius == rInner;
      final isActive = activeAxis == seg.axis && activeValue == seg.value;

      final paint = Paint()
        ..color = isActive
            ? const Color(0xFF5E606A) // Highlighted color
            : (isOuter ? const Color(0xFF38393F) : const Color(0xFF42434A))
        ..style = PaintingStyle.fill;

      final path = _getSegmentPath(center, seg.innerRadius, seg.outerRadius, seg.startAngle, seg.sweepAngle);
      canvas.drawPath(path, paint);
    }

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

    // Draw labels: Maju (Top), Mundur (Bottom), Putar Kanan (Right), Putar Kiri (Left)
    _drawText(canvas, center, "Maju", Offset(0, -(rOuter + rInner) / 2 - 15), fontSize: 12);
    _drawText(canvas, center, "Mundur", Offset(0, (rOuter + rInner) / 2 + 5), fontSize: 12);
    _drawText(canvas, center, "Kanan", Offset((rOuter + rInner) / 2 + 20, -5), fontSize: 10);
    _drawText(canvas, center, "Kiri", Offset(-(rOuter + rInner) / 2 - 20, -5), fontSize: 10);

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

  Path _getSegmentPath(Offset center, double innerRadius, double outerRadius, double startAngle, double sweepAngle) {
    final path = Path();
    
    // Inner arc
    path.arcTo(
      Rect.fromCircle(center: center, radius: innerRadius),
      startAngle,
      sweepAngle,
      true,
    );
    
    // Line to outer arc
    path.lineTo(
      center.dx + outerRadius * math.cos(startAngle + sweepAngle),
      center.dy + outerRadius * math.sin(startAngle + sweepAngle),
    );
    
    // Outer arc (reverse direction)
    path.arcTo(
      Rect.fromCircle(center: center, radius: outerRadius),
      startAngle + sweepAngle,
      -sweepAngle,
      false,
    );
    
    path.close();
    return path;
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
  bool shouldRepaint(covariant _ControlWheelPainter oldDelegate) {
    return oldDelegate.activeAxis != activeAxis || oldDelegate.activeValue != activeValue;
  }
}
