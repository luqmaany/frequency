import 'dart:math' as math;
import 'package:flutter/material.dart';

class RadialRippleBackground extends StatefulWidget {
  final Alignment centerAlignment;
  final Duration duration;

  const RadialRippleBackground({
    super.key,
    this.centerAlignment = Alignment.center,
    this.duration = const Duration(seconds: 10),
  });

  @override
  State<RadialRippleBackground> createState() => _RadialRippleBackgroundState();
}

class _RadialRippleBackgroundState extends State<RadialRippleBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration)..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => CustomPaint(
          painter: _RadialRipplesPainter(
            t: _controller.value,
            centerAlignment: widget.centerAlignment,
          ),
        ),
      ),
    );
  }
}

class _RadialRipplesPainter extends CustomPainter {
  final double t; // 0..1 loop
  final Alignment centerAlignment;

  _RadialRipplesPainter({required this.t, required this.centerAlignment});

  @override
  void paint(Canvas canvas, Size size) {
    // Dark background gradient to match HomeScreen
    final Paint bg = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0, -0.2),
        radius: 1.2,
        colors: [Color(0xFF0B1020), Color(0xFF0E162A)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    // Determine ripple origin within the canvas based on alignment
    final Offset center = Offset(
      size.width * (0.5 + 0.5 * centerAlignment.x),
      size.height * (0.5 + 0.5 * centerAlignment.y),
    );

    final double maxRadius = _maxDistanceToCorners(center, size);

    // Color palette aligned with HomeScreen hues
    const List<Color> palette = [
      Color(0xFF5EB1FF), // blue
      Color(0xFF7A5CFF), // purple
      Color(0xFFFF6680), // pink/red
      Color(0xFFFFA14A), // orange
      Color(0xFFFFD166), // yellow
      Color(0xFF4CD295), // green
    ];

    // Base spacing and speed
    const double baseSpacing = 22.0;
    const double speedSpacingPerLoop = baseSpacing * 2.0; // outward per loop

    // Start so that rings wrap around seamlessly
    final double shift = t * speedSpacingPerLoop;
    final double start = -baseSpacing * 3 + shift;

    // Draw outward-moving concentric rings
    // Slight frequency variations per ring via i-based adjustment
    final Paint ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    // Cap the number of rings conservatively for performance
    for (int i = 0; i < 120; i++) {
      // Vary spacing slightly per ring to create subtle frequency differences
      final double spacingJitter = 1.0 + 0.06 * math.sin(i * 0.85);
      final double ringSpacing = baseSpacing * spacingJitter;
      final double radius = start + i * ringSpacing;
      if (radius < 0) continue;
      if (radius > maxRadius + baseSpacing * 2) break;

      // Small pulsation to avoid static equal distances
      final double pulsate = 3.0 * math.sin((t * math.pi * 2 * 0.9) + i * 0.55);
      final double r = radius + pulsate;

      // Color selection with slight temporal drift
      final int pi0 = i % palette.length;
      final Color base = palette[pi0];
      final HSLColor hsl = HSLColor.fromColor(base);
      final double hueDrift = (math.sin(i * 0.33 + t * math.pi * 2) * 4.0);
      final double lightness = (hsl.lightness * 0.95).clamp(0.0, 1.0);
      final Color color = hsl
          .withHue((hsl.hue + hueDrift) % 360)
          .withLightness(lightness)
          .toColor()
          .withOpacity(0.75);

      ringPaint.color = color;
      canvas.drawCircle(center, r, ringPaint);
    }
  }

  double _maxDistanceToCorners(Offset c, Size s) {
    final List<Offset> corners = [
      Offset.zero,
      Offset(s.width, 0),
      Offset(0, s.height),
      Offset(s.width, s.height),
    ];
    double maxD = 0;
    for (final corner in corners) {
      final double d = (corner - c).distance;
      if (d > maxD) maxD = d;
    }
    return maxD;
  }

  @override
  bool shouldRepaint(covariant _RadialRipplesPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.centerAlignment != centerAlignment;
}