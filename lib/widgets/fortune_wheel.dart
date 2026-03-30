import 'dart:math';

import 'package:flutter/material.dart';

/// A fortune wheel that animates to land on a specific segment.
/// Access via [GlobalKey<FortuneWheelState>] and call [spin].
class FortuneWheel extends StatefulWidget {
  final List<String> labels;
  final List<Color> segmentColors;

  const FortuneWheel({
    super.key,
    required this.labels,
    required this.segmentColors,
  });

  @override
  State<FortuneWheel> createState() => FortuneWheelState();
}

class FortuneWheelState extends State<FortuneWheel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotation;
  double _baseRotation = 0;
  bool _spinning = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _rotation = AlwaysStoppedAnimation<double>(0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get isSpinning => _spinning;

  /// Resets accumulated rotation back to 0.
  /// Call this after removing a player from the labels list.
  void reset() {
    _baseRotation = 0;
    setState(() {
      _rotation = AlwaysStoppedAnimation<double>(0);
    });
  }

  /// Spins the wheel so that [targetIndex] lands under the top pointer.
  /// Calls [onComplete] when the animation finishes.
  void spin(int targetIndex, {required VoidCallback onComplete}) {
    if (_spinning || widget.labels.isEmpty) return;

    final n = widget.labels.length;
    final segAngle = (2 * pi) / n;
    const minSpins = 5;

    // The centre of segment i is drawn at angle:
    //   α_i = -π/2 + i·segAngle + segAngle/2  (before rotation)
    // After canvas.rotate(r):
    //   visual angle = α_i + r
    // We want this to equal -π/2 (pointer at top):
    //   r = -(targetIndex·segAngle + segAngle/2)  (mod 2π)
    // Choose k large enough that we always spin forward at least minSpins turns.
    final targetAngle = targetIndex * segAngle + segAngle / 2;
    final kMin = ((_baseRotation + minSpins * 2 * pi + targetAngle) / (2 * pi))
        .ceil();
    final endRotation = -targetAngle + 2 * pi * kMin;

    _controller.duration = const Duration(milliseconds: 4500);
    _rotation = Tween<double>(begin: _baseRotation, end: endRotation).animate(
      CurvedAnimation(parent: _controller, curve: const _SlowdownCurve()),
    );

    _spinning = true;
    _controller
      ..reset()
      ..forward().whenCompleteOrCancel(() {
        if (!mounted) return;
        _baseRotation = endRotation;
        setState(() => _spinning = false);
        onComplete();
      });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotation,
      builder: (context, _) => CustomPaint(
        painter: _WheelPainter(
          labels: widget.labels,
          colors: widget.segmentColors,
          rotation: _rotation.value,
        ),
        child: Container(),
      ),
    );
  }
}

// ── Deceleration curve ────────────────────────────────────────────────────────

class _SlowdownCurve extends Curve {
  const _SlowdownCurve();

  @override
  double transformInternal(double t) {
    // Fast start, very slow end.
    return 1 - pow(1 - t, 3).toDouble();
  }
}

// ── Wheel painter ─────────────────────────────────────────────────────────────

class _WheelPainter extends CustomPainter {
  final List<String> labels;
  final List<Color> colors;
  final double rotation;

  const _WheelPainter({
    required this.labels,
    required this.colors,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (labels.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 2;
    final n = labels.length;
    final segAngle = (2 * pi) / n;

    // Outer ring
    canvas.drawCircle(
      center,
      radius + 2,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );

    for (var i = 0; i < n; i++) {
      final startAngle = -pi / 2 + i * segAngle + rotation;
      final color = colors[i % colors.length];

      // Fill
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segAngle,
        true,
        Paint()..color = color,
      );

      // Dividing lines
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segAngle,
        true,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      // Label  ── tangential, reads clockwise around the wheel
      final centerAngle = startAngle + segAngle / 2;
      final textRadius = radius * 0.63;

      final maxWidth = (segAngle * textRadius * 1.1).clamp(40.0, 130.0);
      final fontSize = (radius / n.clamp(4, 20) * 1.5).clamp(9.0, 15.0);

      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            shadows: const [Shadow(blurRadius: 3, color: Colors.black45)],
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: maxWidth);

      canvas
        ..save()
        ..translate(
          center.dx + textRadius * cos(centerAngle),
          center.dy + textRadius * sin(centerAngle),
        )
        ..rotate(centerAngle + pi / 2)
        ..translate(-tp.width / 2, -tp.height / 2);
      tp.paint(canvas, Offset.zero);
      canvas.restore();
    }

    // Centre hub
    canvas.drawCircle(center, 14, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      14,
      Paint()
        ..color = Colors.black12
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      old.rotation != rotation || old.labels != labels;
}
