import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Parallel sine-wave background with a moving pulse highlight.
///
/// Styling aligns with the radial ripple backgrounds in this app (same
/// gradient and color handling). The waves are higher-frequency by default
/// (shorter wavelength), and a pulse sweeps across wave rows, brightening
/// trailing rows similarly to `StaticRadialCirclesBackground`.
class ParallelPulseWavesBackground extends StatefulWidget {
  /// Center alignment influences the background gradient center.
  final Alignment centerAlignment;

  /// Duration of a full animation loop.
  final Duration duration;

  /// If provided, all waves use this color (normalized in HSL to match accents).
  final Color? waveColor;

  /// Vertical distance in logical pixels between adjacent wave rows.
  final double baseSpacing;

  /// Stroke width of each wave path.
  final double strokeWidth;

  /// Wave amplitude in logical pixels.
  final double amplitude;

  /// Wavelength in logical pixels (shorter => higher frequency).
  final double wavelength;

  /// How many radians of extra phase between successive rows.
  final double perRowPhaseOffset;

  /// Additional cycles per loop for horizontal wave movement speed.
  final double cyclesPerLoop;

  /// Number of rows over which the pulse fades (triangular falloff).
  final double pulseSpanWaves;

  /// Base opacity (0..1) of non-highlighted waves.
  final double baseOpacity;

  /// Added opacity at pulse center (0..1) on top of baseOpacity.
  final double highlightOpacity;

  const ParallelPulseWavesBackground({
    super.key,
    this.centerAlignment = Alignment.center,
    this.duration = const Duration(seconds: 6),
    this.waveColor,
    this.baseSpacing = 10.0,
    this.strokeWidth = 2.0,
    this.amplitude = 6.0,
    this.wavelength = 40.0,
    this.perRowPhaseOffset = 0.6,
    this.cyclesPerLoop = 2.0,
    this.pulseSpanWaves = 6.0,
    this.baseOpacity = 0.28,
    this.highlightOpacity = 0.92,
  });

  @override
  State<ParallelPulseWavesBackground> createState() =>
      _ParallelPulseWavesBackgroundState();
}

class _ParallelPulseWavesBackgroundState
    extends State<ParallelPulseWavesBackground>
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
    // Absolute-time phase to avoid jumps across navigation
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final int loopMs = widget.duration.inMilliseconds;
    final double t = ((nowMs % loopMs) / loopMs).clamp(0.0, 1.0);

    return RepaintBoundary(
      child: CustomPaint(
        painter: _ParallelWavesPainter(
          t: t,
          centerAlignment: widget.centerAlignment,
          waveColor: widget.waveColor,
          baseSpacing: widget.baseSpacing,
          strokeWidth: widget.strokeWidth,
          amplitude: widget.amplitude,
          wavelength: widget.wavelength,
          perRowPhaseOffset: widget.perRowPhaseOffset,
          cyclesPerLoop: widget.cyclesPerLoop,
          pulseSpanWaves: widget.pulseSpanWaves,
          baseOpacity: widget.baseOpacity,
          highlightOpacity: widget.highlightOpacity,
        ),
      ),
    );
  }
}

class _ParallelWavesPainter extends CustomPainter {
  final double t; // 0..1 loop
  final Alignment centerAlignment;
  final Color? waveColor;
  final double baseSpacing;
  final double strokeWidth;
  final double amplitude;
  final double wavelength;
  final double perRowPhaseOffset;
  final double cyclesPerLoop;
  final double pulseSpanWaves;
  final double baseOpacity;
  final double highlightOpacity;

  _ParallelWavesPainter({
    required this.t,
    required this.centerAlignment,
    required this.waveColor,
    required this.baseSpacing,
    required this.strokeWidth,
    required this.amplitude,
    required this.wavelength,
    required this.perRowPhaseOffset,
    required this.cyclesPerLoop,
    required this.pulseSpanWaves,
    required this.baseOpacity,
    required this.highlightOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background gradient consistent with other backgrounds
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

    // Palette consistent with app hues
    const List<Color> baseColors = [
      Color(0xFF5EB1FF), // blue
      Color(0xFF8287FF), // blue-purple midpoint
      Color(0xFF7A5CFF), // purple
      Color(0xFFFF85BF), // purple-pink midpoint
      Color(0xFFFF6680), // pink/red
      Color(0xFFFF8572), // pink-orange midpoint
      Color(0xFFFFA14A), // orange
      Color(0xFFBEE1A8), // orange-green midpoint
      Color(0xFF4CD295), // green
      Color(0xFF6FE8C6), // green-blue midpoint
    ];

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

    // Expanded palette for smoother transitions
    const int stepsBetween = 3;
    final List<Color> palette = <Color>[];
    for (int i = 0; i < baseColors.length; i++) {
      final Color start = baseColors[i];
      final Color end = baseColors[(i + 1) % baseColors.length];
      for (int s = 0; s < stepsBetween; s++) {
        final double tt = s / stepsBetween;
        palette.add(lerpHsl(start, end, tt));
      }
    }

    final Paint wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth;

    // Normalize lightness to align with other widgets
    const double baseTargetLightness = 0.50;

    // Determine number of rows covering the height
    final int numWaves = math.max(1, (size.height / baseSpacing).ceil() + 2);

    // Pulse center across rows, 0..numWaves
    final double pulseCenter = (t * numWaves) % numWaves;

    // Horizontal wave motion phase (multiple cycles per loop)
    final double phase = t * math.pi * 2 * cyclesPerLoop;
    final double k = (2 * math.pi) / wavelength; // spatial frequency

    // Build each row path
    for (int row = 0; row < numWaves; row++) {
      final double y = row * baseSpacing;
      if (y > size.height + baseSpacing) break;

      // Base color (override or palette with subtle drift)
      HSLColor baseHsl;
      if (waveColor != null) {
        baseHsl =
            HSLColor.fromColor(waveColor!).withLightness(baseTargetLightness);
      } else {
        final Color base = palette[row % palette.length];
        final HSLColor hsl = HSLColor.fromColor(base);
        final double hueOffset = math.sin(row * 0.33 + t * math.pi * 2) * 2.0;
        baseHsl = hsl
            .withHue((hsl.hue + hueOffset) % 360)
            .withSaturation(hsl.saturation.clamp(0.5, 1.0))
            .withLightness(baseTargetLightness);
      }

      // Pulse falloff behind the moving pulse center (circular over rows)
      double falloff = 0.0;
      final double rowAsDouble = row.toDouble();
      final double trailingDistance = rowAsDouble <= pulseCenter
          ? (pulseCenter - rowAsDouble)
          : (pulseCenter + (numWaves - rowAsDouble));
      if (trailingDistance <= pulseSpanWaves) {
        falloff = (1.0 - (trailingDistance / pulseSpanWaves)).clamp(0.0, 1.0);
      }

      // Brighten and increase saturation toward the pulse center
      const double targetLightness = 0.60;
      final double l =
          (baseHsl.lightness + (targetLightness - baseHsl.lightness) * falloff)
              .clamp(0.0, 1.0);
      final double s =
          (baseHsl.saturation + (0.90 - baseHsl.saturation) * falloff)
              .clamp(0.0, 1.0);
      final Color brightColor =
          baseHsl.withLightness(l).withSaturation(s).toColor();

      final double opacity =
          (baseOpacity + highlightOpacity * falloff).clamp(0.0, 1.0);
      wavePaint.color = brightColor.withOpacity(opacity);

      final Path path = Path();
      // Slight per-row phase offset so rows are not perfectly in phase
      final double rowPhase = row * perRowPhaseOffset;

      // Start slightly before and after to avoid clipping at edges
      // Smaller dx -> smoother curves. Tie to wavelength to keep stable detail.
      final double dx = math.max(1.5, wavelength / 28.0);
      double x = -dx;
      double yOffset = amplitude * math.sin(k * x + phase + rowPhase);
      path.moveTo(x, y + yOffset);
      for (; x <= size.width + dx; x += dx) {
        yOffset = amplitude * math.sin(k * x + phase + rowPhase);
        path.lineTo(x, y + yOffset);
      }

      canvas.drawPath(path, wavePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParallelWavesPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.centerAlignment != centerAlignment ||
      oldDelegate.waveColor != waveColor ||
      oldDelegate.baseSpacing != baseSpacing ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.amplitude != amplitude ||
      oldDelegate.wavelength != wavelength ||
      oldDelegate.perRowPhaseOffset != perRowPhaseOffset ||
      oldDelegate.cyclesPerLoop != cyclesPerLoop ||
      oldDelegate.pulseSpanWaves != pulseSpanWaves ||
      oldDelegate.baseOpacity != baseOpacity ||
      oldDelegate.highlightOpacity != highlightOpacity;
}
