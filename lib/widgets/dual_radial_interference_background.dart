import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Two offscreen circular wave sources (left and right) whose rings overlap to
/// create a bright "interference" pattern. Visually aligned with other ripple
/// backgrounds in the app. Rings are static; a pulse highlight animates across
/// ring indices for subtle motion without moving geometry.
class DualRadialInterferenceBackground extends StatefulWidget {
  /// Duration of one pulse loop.
  final Duration duration;

  /// If provided, both sources use this color (normalized in HSL).
  final Color? ringColor;

  /// Uniform distance in logical pixels between adjacent rings.
  final double baseSpacing;

  /// Base ring opacity (0..1).
  final double baseOpacity;

  /// Additional opacity added at the pulse center (0..1).
  final double highlightOpacity;

  /// Number of rings over which the highlight fades out.
  final double pulseSpanRings;

  /// Stroke width of rings.
  final double strokeWidth;

  /// Horizontal source offset as a fraction of width beyond each side.
  /// For example, 0.35 means centers are at -0.35*w (left) and 1.35*w (right).
  final double sourcesHorizontalOffsetFactor;

  /// Vertical alignment of sources along height (0 = top, 1 = bottom).
  final double verticalPositionFactor;

  /// Shifts both sources together horizontally as a fraction of width.
  /// Positive moves the interference pattern to the right.
  final double horizontalShiftFactor;

  /// How many full color cycles occur per animation loop (t from 0..1).
  /// Smaller values = slower color change.
  final double colorCyclesPerLoop;

  const DualRadialInterferenceBackground({
    super.key,
    this.duration = const Duration(seconds: 10),
    this.ringColor,
    this.baseSpacing = 14.0,
    this.baseOpacity = 0.0,
    this.highlightOpacity = 0.4,
    this.pulseSpanRings = 20.0,
    this.strokeWidth = 2.0,
    this.sourcesHorizontalOffsetFactor = 0.9,
    this.verticalPositionFactor = 0.5,
    this.horizontalShiftFactor = 0.01,
    this.colorCyclesPerLoop = 0.05,
  });

  @override
  State<DualRadialInterferenceBackground> createState() =>
      _DualRadialInterferenceBackgroundState();
}

class _DualRadialInterferenceBackgroundState
    extends State<DualRadialInterferenceBackground>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void didUpdateWidget(covariant DualRadialInterferenceBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller?.dispose();
      _controller = AnimationController(vsync: this, duration: widget.duration)
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller!,
        builder: (_, __) {
          final double timeSeconds =
              DateTime.now().millisecondsSinceEpoch.toDouble() / 1000.0;
          final double loopSeconds =
              widget.duration.inMilliseconds.toDouble() / 1000.0;
          return CustomPaint(
            painter: _DualRadialInterferencePainter(
              t: _controller!.value,
              ringColor: widget.ringColor,
              baseSpacing: widget.baseSpacing,
              baseOpacity: widget.baseOpacity,
              highlightOpacity: widget.highlightOpacity,
              pulseSpanRings: widget.pulseSpanRings,
              strokeWidth: widget.strokeWidth,
              sourcesHorizontalOffsetFactor:
                  widget.sourcesHorizontalOffsetFactor,
              verticalPositionFactor: widget.verticalPositionFactor,
              horizontalShiftFactor: widget.horizontalShiftFactor,
              colorCyclesPerLoop: widget.colorCyclesPerLoop,
              timeSeconds: timeSeconds,
              loopSeconds: loopSeconds,
            ),
          );
        },
      ),
    );
  }
}

class _DualRadialInterferencePainter extends CustomPainter {
  final double t; // 0..1 animation phase
  final Color? ringColor;
  final double baseSpacing;
  final double baseOpacity;
  final double highlightOpacity;
  final double pulseSpanRings;
  final double strokeWidth;
  final double sourcesHorizontalOffsetFactor;
  final double verticalPositionFactor;
  final double horizontalShiftFactor;
  final double colorCyclesPerLoop;
  final double timeSeconds;
  final double loopSeconds;

  _DualRadialInterferencePainter({
    required this.t,
    required this.ringColor,
    required this.baseSpacing,
    required this.baseOpacity,
    required this.highlightOpacity,
    required this.pulseSpanRings,
    required this.strokeWidth,
    required this.sourcesHorizontalOffsetFactor,
    required this.verticalPositionFactor,
    required this.horizontalShiftFactor,
    required this.colorCyclesPerLoop,
    required this.timeSeconds,
    required this.loopSeconds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Scale to keep spacing and thickness proportional on tablets/phones
    final double scale =
        (math.min(size.width, size.height) / 400.0).clamp(0.8, 2.0);
    // Background gradient consistent with other ripple widgets
    final Paint bg = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.2,
        colors: const [
          Color(0xFF0A0F1E),
          Color(0xFF0C1326),
          Color(0xFF0E162A),
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    // Source centers offscreen left and right
    final double cxShift = horizontalShiftFactor * size.width;
    final double cxLeft = -sourcesHorizontalOffsetFactor * size.width + cxShift;
    final double cxRight =
        (1.0 + sourcesHorizontalOffsetFactor) * size.width + cxShift;
    final double cy = (verticalPositionFactor.clamp(0.0, 1.0)) * size.height;
    final Offset leftCenter = Offset(cxLeft, cy);
    final Offset rightCenter = Offset(cxRight, cy);

    // Base hues used to cycle the single scene color over time
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
      final double delta = ((b - a + 540) % 360) - 180;
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

    // Compute one scene color for all rings using absolute time so the loop is seamless
    Color sceneColor;
    if (ringColor != null) {
      sceneColor = ringColor!;
    } else {
      final double cyclesPerSecond =
          colorCyclesPerLoop / (loopSeconds <= 0.0 ? 1.0 : loopSeconds);
      final double colorPhase = (timeSeconds * cyclesPerSecond) % 1.0;
      final double scaled = colorPhase * baseColors.length;
      final int i0 = scaled.floor() % baseColors.length;
      final int i1 = (i0 + 1) % baseColors.length;
      final double ft = scaled - scaled.floor();
      sceneColor = lerpHsl(baseColors[i0], baseColors[i1], ft);
    }

    const double baseTargetLightness = 0.50;

    final Paint ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth * scale
      ..blendMode = BlendMode.plus; // additive for brighter overlaps

    // Determine ring range for each source: start when circle touches the rect
    final double spacing = baseSpacing * scale;

    int startIndexFor(Offset c) {
      final double dMin = _distancePointToRect(c, size);
      final int start = math.max(0, (dMin / spacing).floor() - 1);
      return start;
    }

    int maxIndexFor(Offset c) {
      final double dMax = _maxDistanceToRectCorners(c, size);
      return (dMax / spacing).ceil() + 2;
    }

    final int startLeft = startIndexFor(leftCenter);
    final int startRight = startIndexFor(rightCenter);
    final int maxLeft = maxIndexFor(leftCenter);
    final int maxRight = maxIndexFor(rightCenter);

    // Pulsing highlight centers travel from before the first visible ring
    // to beyond the last visible ring so the tail fully exits before reset.
    final double travelLeft = (maxLeft - startLeft) + 2.0 * pulseSpanRings;
    final double travelRight = (maxRight - startRight) + 2.0 * pulseSpanRings;
    final double pulseLeft = (startLeft - pulseSpanRings) + (t * travelLeft);
    final double pulseRight = (startRight - pulseSpanRings) + (t * travelRight);

    void drawSource(Offset center, int iStart, int iEnd, double pulseCenter,
        double colorPhaseOffset) {
      for (int i = iStart; i <= iEnd; i++) {
        final double radius = i * spacing.toDouble();

        // Base HSL color (override or palette-based with subtle per-ring hue drift)
        HSLColor baseHsl;
        baseHsl = HSLColor.fromColor(sceneColor)
            .withSaturation(
                HSLColor.fromColor(sceneColor).saturation.clamp(0.5, 1.0))
            .withLightness(baseTargetLightness);

        // Highlight falloff behind the pulse center, no wrap.
        double falloff = 0.0;
        final double trailingDistance = pulseCenter - i.toDouble();
        if (trailingDistance >= 0.0 && trailingDistance <= pulseSpanRings) {
          falloff = (1.0 - (trailingDistance / pulseSpanRings)).clamp(0.0, 1.0);
        }

        const double targetLightness = 0.60;
        final double l = (baseHsl.lightness +
                (targetLightness - baseHsl.lightness) * falloff)
            .clamp(0.0, 1.0);
        final double s =
            (baseHsl.saturation + (0.90 - baseHsl.saturation) * falloff)
                .clamp(0.0, 1.0);
        final Color brightColor =
            baseHsl.withLightness(l).withSaturation(s).toColor();

        final double opacity =
            (baseOpacity + highlightOpacity * falloff).clamp(0.0, 1.0);
        ringPaint.color = brightColor.withOpacity(opacity);

        canvas.drawCircle(center, radius, ringPaint);
      }
    }

    // Draw both sources with slight different hue drift phases to diversify colors
    drawSource(leftCenter, startLeft, maxLeft, pulseLeft, 0.0);
    drawSource(rightCenter, startRight, maxRight, pulseRight, math.pi * 0.5);
  }

  // Shortest distance from a point to the rectangle [0,w]x[0,h]
  double _distancePointToRect(Offset p, Size s) {
    final double dx =
        p.dx < 0 ? -p.dx : (p.dx > s.width ? p.dx - s.width : 0.0);
    final double dy =
        p.dy < 0 ? -p.dy : (p.dy > s.height ? p.dy - s.height : 0.0);
    return math.sqrt(dx * dx + dy * dy);
  }

  // Farthest distance from a point to any of the rectangle's corners
  double _maxDistanceToRectCorners(Offset p, Size s) {
    final List<Offset> corners = [
      Offset.zero,
      Offset(s.width, 0),
      Offset(0, s.height),
      Offset(s.width, s.height),
    ];
    double maxD = 0;
    for (final c in corners) {
      final double d = (c - p).distance;
      if (d > maxD) maxD = d;
    }
    return maxD;
  }

  @override
  bool shouldRepaint(covariant _DualRadialInterferencePainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.ringColor != ringColor ||
      oldDelegate.baseSpacing != baseSpacing ||
      oldDelegate.baseOpacity != baseOpacity ||
      oldDelegate.highlightOpacity != highlightOpacity ||
      oldDelegate.pulseSpanRings != pulseSpanRings ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.sourcesHorizontalOffsetFactor !=
          sourcesHorizontalOffsetFactor ||
      oldDelegate.verticalPositionFactor != verticalPositionFactor ||
      oldDelegate.horizontalShiftFactor != horizontalShiftFactor ||
      oldDelegate.colorCyclesPerLoop != colorCyclesPerLoop;
}
