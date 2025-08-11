import 'dart:math' as math;
import 'package:flutter/material.dart';

class RadialRippleBackground extends StatefulWidget {
  final Alignment centerAlignment;
  final Duration duration;
  final Color? ringColor; // When provided, all rings use this color

  const RadialRippleBackground({
    super.key,
    this.centerAlignment = Alignment.center,
    this.duration = const Duration(seconds: 10),
    this.ringColor,
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
            ringColor: widget.ringColor,
          ),
        ),
      ),
    );
  }
}

class _RadialRipplesPainter extends CustomPainter {
  final double t; // 0..1 loop
  final Alignment centerAlignment;
  final Color? ringColor;

  _RadialRipplesPainter(
      {required this.t, required this.centerAlignment, this.ringColor});

  @override
  void paint(Canvas canvas, Size size) {
    // Dark background gradient, smoother and centered on ripple origin
    final Paint bg = Paint()
      ..shader = RadialGradient(
        center: centerAlignment,
        radius: 1.2,
        colors: const [
          Color(0xFF0A0F1E),
          Color(0xFF0C1326),
          Color(0xFF0E162A),
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    // Determine ripple origin within the canvas based on alignment
    final Offset center = Offset(
      size.width * (0.5 + 0.5 * centerAlignment.x),
      size.height * (0.5 + 0.5 * centerAlignment.y),
    );

    final double maxRadius = 2 * _maxDistanceToCorners(center, size);

    // Base palette aligned with HomeScreen hues
    const List<Color> baseColors = [
      Color(0xFF5EB1FF), // blue
      Color(0xFF7A5CFF), // purple
      Color(0xFFFF6680), // pink/red
      Color(0xFFFFA14A), // orange
      Color(0xFF4CD295), // green
    ];

    // Helper: HSL interpolation with hue wrap for smoother transitions
    double hueLerp(double a, double b, double t) {
      final double delta = ((b - a + 540) % 360) - 180; // shortest path
      return (a + delta * t) % 360;
    }

    Color lerpHsl(Color a, Color b, double t) {
      final HSLColor ha = HSLColor.fromColor(a);
      final HSLColor hb = HSLColor.fromColor(b);
      final double h = hueLerp(ha.hue, hb.hue, t);
      final double s = ha.saturation + (hb.saturation - ha.saturation) * t;
      final double l = ha.lightness + (hb.lightness - ha.lightness) * t;
      return HSLColor.fromAHSL(1.0, h, s.clamp(0.0, 1.0), l.clamp(0.0, 1.0))
          .toColor();
    }

    // Build expanded palette by inserting intermediate colors between base stops
    const int stepsBetween =
        3; // in-between colors per segment for smoother transition
    final List<Color> palette = <Color>[];
    for (int i = 0; i < baseColors.length; i++) {
      final Color start = baseColors[i];
      final Color end = baseColors[(i + 1) % baseColors.length];
      for (int s = 0; s < stepsBetween; s++) {
        final double tt = s / stepsBetween; // 0.0 .. <1.0
        palette.add(lerpHsl(start, end, tt));
      }
    }

    // Normalize ring brightness (HSL lightness) to align with Home screen accents
    const double targetLightness = 0.50; // tweak as needed to match Home

    // Base spacing and speed
    const double baseSpacing = 22.0;
    const double speedSpacingPerLoop =
        baseSpacing * 10; // outward per loop (faster waves)

    // Distance travelled by the innermost ring so that a ring always starts at center
    final double travelled = t * speedSpacingPerLoop;

    // Draw outward-moving concentric rings (seamless loop)
    final Paint ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0;

    // Cap the number of rings conservatively for performance
    for (int i = 0; i < 120; i++) {
      // Fixed spacing ensures shifting by an integer multiple of baseSpacing loops seamlessly
      const double ringSpacing = baseSpacing;
      final double radius = travelled + i * ringSpacing;
      if (radius > maxRadius + baseSpacing * 2) break;

      // Small pulsation with exactly 1 cycle per animation loop (seamless)
      final double pulsate = 3.0 * math.sin((t * math.pi * 2 * 1.0) + i * 0.55);
      final double r = radius + pulsate;

      // Determine ring color
      Color color;
      if (ringColor != null) {
        // Use override color normalized to target lightness
        final HSLColor hslOverride = HSLColor.fromColor(ringColor!);
        final double radialFade =
            (1.0 - (r / (maxRadius + baseSpacing)).clamp(0.0, 1.0)) * 0.6 +
                0.25;
        color = hslOverride
            .withLightness(targetLightness)
            .toColor()
            .withOpacity((0.62 * radialFade).clamp(0.06, 0.82));
      } else {
        // Default: expanded palette with subtle, seamless hue drift
        final int pi0 = i % palette.length;
        final Color base = palette[pi0];
        final HSLColor hsl = HSLColor.fromColor(base);
        final double hueDrift =
            (math.sin(i * 0.33 + t * math.pi * 2 * 1.0) * 2.0);
        const double lightness = targetLightness;
        final double radialFade =
            (1.0 - (r / (maxRadius + baseSpacing)).clamp(0.0, 1.0)) * 0.6 +
                0.25;
        color = hsl
            .withHue((hsl.hue + hueDrift) % 360)
            .withSaturation((hsl.saturation).clamp(0.5, 1.0))
            .withLightness(lightness)
            .toColor()
            .withOpacity((0.62 * radialFade).clamp(0.06, 0.82));
      }

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
