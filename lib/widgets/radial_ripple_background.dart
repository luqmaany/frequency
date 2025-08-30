import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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
  late final Ticker _ticker;

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) => setState(() {}))..start();
  }

  @override
  Widget build(BuildContext context) {
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final int loopMs = widget.duration.inMilliseconds;
    final double t = ((nowMs % loopMs) / loopMs).clamp(0.0, 1.0);

    return RepaintBoundary(
      child: CustomPaint(
        painter: _RadialRipplesPainter(
          t: t,
          centerAlignment: widget.centerAlignment,
          ringColor: widget.ringColor,
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
    // Scale so ring spacing and thickness feel proportional across devices
    final double scale =
        (math.min(size.width, size.height) / 400.0).clamp(0.8, 2.0);
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
    final double baseSpacing = 22.0 * scale;
    final double cycleDistance =
        maxRadius + baseSpacing * 2; // Total distance for one complete cycle

    // Distance travelled by the innermost ring
    final double travelled = t * cycleDistance;

    // Draw outward-moving concentric rings (seamless loop)
    final Paint ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0 * scale;

    // Calculate how many rings we need to fill the entire space seamlessly
    final int numRings = (cycleDistance / baseSpacing).ceil() + 2;

    for (int i = 0; i < numRings; i++) {
      // Calculate ring position with wrapping
      final double baseRadius = travelled + i * baseSpacing;
      final double radius = baseRadius % cycleDistance;

      // Skip rings that are outside visible area and not about to wrap
      if (radius > maxRadius + baseSpacing) continue;

      // Small pulsation with exactly 1 cycle per animation loop (seamless)
      final double pulsate = 3.0 * math.sin((t * math.pi * 2 * 1.0) + i * 0.55);
      final double r = radius + pulsate;

      // Skip if ring is not visible (too far out)
      if (r < 0 || r > maxRadius + baseSpacing) continue;

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
        // Use original ring index for consistent color progression
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
