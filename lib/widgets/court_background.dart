import 'dart:math';
import 'package:flutter/material.dart';
import '../models/sport.dart';

/// Full-bleed sport-court background.
/// Wrap this together with your scrollable content inside a [Stack].
class CourtBackground extends StatelessWidget {
  final Sport sport;
  const CourtBackground({super.key, required this.sport});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(child: CustomPaint(painter: _courtPainter(sport)));
  }

  static CustomPainter _courtPainter(Sport sport) {
    return switch (sport) {
      Sport.soccer => _SoccerPainter(),
      Sport.volleyball => _VolleyballPainter(),
      Sport.basketball => _BasketballPainter(),
      Sport.custom => _NeutralPainter(),
    };
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

Paint _fill(Color c) => Paint()..color = c;

Paint _line(Color c, double width) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = width;

/// Base painter that transparently rotates the canvas 90° clockwise in portrait
/// mode so all subclasses only ever implement a landscape drawing.
abstract class _OrientedPainter extends CustomPainter {
  const _OrientedPainter();

  /// Implement your court drawing here, always assuming [size.width >= size.height].
  void paintLandscape(Canvas canvas, Size size);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.height > size.width) {
      // Portrait → rotate 90° clockwise and swap dimensions
      canvas.save();
      canvas.translate(size.width, 0);
      canvas.rotate(pi / 2);
      paintLandscape(canvas, Size(size.height, size.width));
      canvas.restore();
    } else {
      paintLandscape(canvas, size);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Soccer ────────────────────────────────────────────────────────────────────

class _SoccerPainter extends _OrientedPainter {
  @override
  void paintLandscape(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Pitch fill – two alternating grass bands
    const dark = Color(0xFF2E7D32);
    const light = Color(0xFF388E3C);
    const bands = 8;
    final bw = w / bands;
    for (var i = 0; i < bands; i++) {
      canvas.drawRect(
        Rect.fromLTWH(i * bw, 0, bw, h),
        _fill(i.isEven ? dark : light),
      );
    }

    final lp = _line(Colors.white.withValues(alpha: 0.55), w * 0.005);

    // Outer border
    canvas.drawRect(Rect.fromLTRB(w * 0.04, h * 0.04, w * 0.96, h * 0.96), lp);

    // Centre line
    canvas.drawLine(Offset(w / 2, h * 0.04), Offset(w / 2, h * 0.96), lp);

    // Centre circle
    canvas.drawCircle(Offset(w / 2, h / 2), min(w, h) * 0.13, lp);

    // Centre spot
    canvas.drawCircle(
      Offset(w / 2, h / 2),
      w * 0.008,
      _fill(Colors.white.withValues(alpha: 0.55)),
    );

    // Penalty areas (left & right)
    final paW = w * 0.13;
    final paH = h * 0.44;
    final paTop = (h - paH) / 2;
    // Left
    canvas.drawRect(Rect.fromLTWH(w * 0.04, paTop, paW, paH), lp);
    // Right
    canvas.drawRect(Rect.fromLTWH(w * 0.96 - paW, paTop, paW, paH), lp);

    // Goal areas
    final gaW = w * 0.055;
    final gaH = h * 0.20;
    final gaTop = (h - gaH) / 2;
    canvas.drawRect(Rect.fromLTWH(w * 0.04, gaTop, gaW, gaH), lp);
    canvas.drawRect(Rect.fromLTWH(w * 0.96 - gaW, gaTop, gaW, gaH), lp);

    // Penalty spots
    canvas.drawCircle(
      Offset(w * 0.04 + w * 0.09, h / 2),
      w * 0.006,
      _fill(Colors.white.withValues(alpha: 0.55)),
    );
    canvas.drawCircle(
      Offset(w * 0.96 - w * 0.09, h / 2),
      w * 0.006,
      _fill(Colors.white.withValues(alpha: 0.55)),
    );

    // Corner arcs
    final ca = min(w, h) * 0.04;
    final corners = [
      Offset(w * 0.04, h * 0.04),
      Offset(w * 0.96, h * 0.04),
      Offset(w * 0.04, h * 0.96),
      Offset(w * 0.96, h * 0.96),
    ];
    final startAngles = [0.0, pi / 2, -pi / 2, pi];
    for (var i = 0; i < 4; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: corners[i], radius: ca),
        startAngles[i],
        pi / 2,
        false,
        lp,
      );
    }
  }
}

// ── Volleyball ────────────────────────────────────────────────────────────────

class _VolleyballPainter extends _OrientedPainter {
  @override
  void paintLandscape(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Floor fill
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), _fill(const Color(0xFF1565C0)));
    // Free zone (lighter)
    canvas.drawRect(
      Rect.fromLTRB(w * 0.08, h * 0.06, w * 0.92, h * 0.94),
      _fill(const Color(0xFF1976D2)),
    );
    // Court surface
    canvas.drawRect(
      Rect.fromLTRB(w * 0.08, h * 0.06, w * 0.92, h * 0.94),
      _fill(const Color(0xFF1565C0)),
    );

    final lW = _line(Colors.white.withValues(alpha: 0.6), w * 0.006);
    final lY = _line(Colors.yellow.withValues(alpha: 0.55), w * 0.006);

    // Outer boundary
    canvas.drawRect(Rect.fromLTRB(w * 0.08, h * 0.06, w * 0.92, h * 0.94), lW);

    // Centre / net line (thick yellow)
    canvas.drawLine(
      Offset(w / 2, h * 0.06),
      Offset(w / 2, h * 0.94),
      _line(Colors.yellow.withValues(alpha: 0.70), w * 0.012),
    );

    // Attack lines (3 m from net) — ~28% of court half-width
    final atk = w * 0.15;
    canvas.drawLine(
      Offset(w / 2 - atk, h * 0.06),
      Offset(w / 2 - atk, h * 0.94),
      lY,
    );
    canvas.drawLine(
      Offset(w / 2 + atk, h * 0.06),
      Offset(w / 2 + atk, h * 0.94),
      lY,
    );

    // Service zone markers on back lines
    final svc = h * 0.28;
    final sL = _line(Colors.white.withValues(alpha: 0.45), w * 0.004);
    canvas.drawLine(
      Offset(w * 0.08, h * 0.06 + svc),
      Offset(w * 0.08 - w * 0.03, h * 0.06 + svc),
      sL,
    );
    canvas.drawLine(
      Offset(w * 0.92, h * 0.06 + svc),
      Offset(w * 0.92 + w * 0.03, h * 0.06 + svc),
      sL,
    );
    canvas.drawLine(
      Offset(w * 0.08, h * 0.94 - svc),
      Offset(w * 0.08 - w * 0.03, h * 0.94 - svc),
      sL,
    );
    canvas.drawLine(
      Offset(w * 0.92, h * 0.94 - svc),
      Offset(w * 0.92 + w * 0.03, h * 0.94 - svc),
      sL,
    );
  }
}

// ── Basketball ────────────────────────────────────────────────────────────────

class _BasketballPainter extends _OrientedPainter {
  @override
  void paintLandscape(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Hardwood floor
    const wood = Color(0xFFB5651D);
    const woodLight = Color(0xFFCD853F);
    const strips = 10;
    final sw = w / strips;
    for (var i = 0; i < strips; i++) {
      canvas.drawRect(
        Rect.fromLTWH(i * sw, 0, sw, h),
        _fill(i.isEven ? wood : woodLight),
      );
    }
    // Wood grain lines
    final grain = _line(Colors.black.withValues(alpha: 0.06), 1);
    for (var i = 0; i < strips + 1; i++) {
      canvas.drawLine(Offset(i * sw, 0), Offset(i * sw, h), grain);
    }

    final lW = _line(Colors.white.withValues(alpha: 0.65), w * 0.005);

    // Outer boundary
    canvas.drawRect(Rect.fromLTRB(w * 0.03, h * 0.04, w * 0.97, h * 0.96), lW);

    // Half-court line
    canvas.drawLine(Offset(w / 2, h * 0.04), Offset(w / 2, h * 0.96), lW);

    // Centre circle
    canvas.drawCircle(Offset(w / 2, h / 2), min(w, h) * 0.10, lW);

    // Paint/key areas
    final keyW = w * 0.18;
    final keyH = h * 0.50;
    final keyTop = (h - keyH) / 2;
    // Left key
    canvas.drawRect(Rect.fromLTWH(w * 0.03, keyTop, keyW, keyH), lW);
    // Right key
    canvas.drawRect(Rect.fromLTWH(w * 0.97 - keyW, keyTop, keyW, keyH), lW);

    // Free-throw circles
    final ftR = min(w, h) * 0.085;
    canvas.drawCircle(Offset(w * 0.03 + keyW, h / 2), ftR, lW);
    canvas.drawCircle(Offset(w * 0.97 - keyW, h / 2), ftR, lW);

    // Three-point arcs (semicircle from near baseline)
    final tpR = min(w, h) * 0.38;
    final rect3L = Rect.fromCircle(
      center: Offset(w * 0.03 + w * 0.045, h / 2),
      radius: tpR,
    );
    final rect3R = Rect.fromCircle(
      center: Offset(w * 0.97 - w * 0.045, h / 2),
      radius: tpR,
    );
    canvas.drawArc(rect3L, -pi / 2, pi, false, lW);
    canvas.drawArc(rect3R, pi / 2, pi, false, lW);

    // Backboard lines
    final bbH = h * 0.18;
    final bbTop = (h - bbH) / 2;
    final bbW = w * 0.008;
    canvas.drawRect(Rect.fromLTWH(w * 0.03, bbTop, bbW, bbH), lW);
    canvas.drawRect(Rect.fromLTWH(w * 0.97 - bbW, bbTop, bbW, bbH), lW);

    // Restricted arc under basket
    final raR = min(w, h) * 0.055;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w * 0.03 + w * 0.045, h / 2), radius: raR),
      -pi / 2,
      pi,
      false,
      lW,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w * 0.97 - w * 0.045, h / 2), radius: raR),
      pi / 2,
      pi,
      false,
      lW,
    );
  }
}

// ── Custom / neutral ──────────────────────────────────────────────────────────

class _NeutralPainter extends _OrientedPainter {
  @override
  void paintLandscape(Canvas canvas, Size size) {
    // Subtle diagonal grid
    final w = size.width;
    final h = size.height;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      _fill(const Color(0xFF1A237E).withValues(alpha: 0.08)),
    );
    final lp = _line(const Color(0xFF1565C0).withValues(alpha: 0.08), 1);
    const step = 40.0;
    for (var x = -h; x < w + h; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x + h, h), lp);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
