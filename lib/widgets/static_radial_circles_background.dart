import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Concentric circles background styled to match the ripple theme.
/// Supports a pulse animation that lights rings from smallest to largest.
class StaticRadialCirclesBackground extends StatefulWidget {
  final Alignment centerAlignment;
  final Color? ringColor; // When provided, all rings use this color
  final Color? backgroundColor; // When provided, solid background fill
  final double baseSpacing;
  final int maxRings;

  /// Controls the pulse travel speed independent of [maxRings].
  /// The pulse center is computed as (t * pulseBaseRings) % maxRings.
  /// Default: equals [maxRings] to preserve original behavior.
  final int? pulseBaseRings;
  final bool animate;
  final Duration duration;

  /// Number of rings over which the highlight fades out (triangular falloff)
  final double pulseSpanRings;

  /// Base ring opacity (0..1)
  final double baseOpacity;

  /// Additional opacity added at the pulse center (0..1)
  final double highlightOpacity;

  /// If true, draw full circles instead of arc sections
  final bool fullCircles;

  /// Lightness target for base (non-highlighted) rings in HSL space
  final double baseTargetLightness;

  /// Lightness target at pulse peak (brighter than base)
  final double highlightTargetLightness;

  /// Saturation target at pulse peak
  final double highlightSaturationTarget;

  /// Multiplies final ring alpha, useful instead of wrapping in Opacity
  final double globalOpacity;

  /// Stroke width for rings
  final double strokeWidth;

  /// Blend mode for drawing rings (default additive for pop)
  final BlendMode blendMode;

  // Removed spacing variation; spacing is uniform by design

  const StaticRadialCirclesBackground({
    super.key,
    this.centerAlignment = Alignment.center,
    this.ringColor,
    this.backgroundColor,
    this.baseSpacing = 10.0,
    this.maxRings = 30,
    this.pulseBaseRings,
    this.animate = true,
    this.duration = const Duration(seconds: 3),
    this.pulseSpanRings = 6.0,
    this.baseOpacity = 0.28,
    this.highlightOpacity = 0.92,
    this.fullCircles = false,
    this.baseTargetLightness = 0.10,
    this.highlightTargetLightness = 0.10,
    this.highlightSaturationTarget = 1,
    this.globalOpacity = 1.0,
    this.strokeWidth = 2.0,
    this.blendMode = BlendMode.plus,
  });

  @override
  State<StaticRadialCirclesBackground> createState() =>
      _StaticRadialCirclesBackgroundState();
}

class _StaticRadialCirclesBackgroundState
    extends State<StaticRadialCirclesBackground>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _controller = AnimationController(vsync: this, duration: widget.duration)
        ..repeat();
    }
  }

  @override
  void didUpdateWidget(covariant StaticRadialCirclesBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && _controller == null) {
      _controller = AnimationController(vsync: this, duration: widget.duration)
        ..repeat();
    } else if (!widget.animate && _controller != null) {
      _controller!.dispose();
      _controller = null;
    } else if (_controller != null && oldWidget.duration != widget.duration) {
      _controller!.dispose();
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
      child: widget.animate && _controller != null
          ? AnimatedBuilder(
              animation: _controller!,
              builder: (_, __) => CustomPaint(
                painter: _StaticCirclesPainter(
                  centerAlignment: widget.centerAlignment,
                  ringColor: widget.ringColor,
                  backgroundColor: widget.backgroundColor,
                  baseSpacing: widget.baseSpacing,
                  maxRings: widget.maxRings,
                  pulseBaseRings: widget.pulseBaseRings ?? widget.maxRings,
                  t: _controller!.value,
                  pulseSpanRings: widget.pulseSpanRings,
                  baseOpacity: widget.baseOpacity,
                  highlightOpacity: widget.highlightOpacity,
                  fullCircles: widget.fullCircles,
                  baseTargetLightness: widget.baseTargetLightness,
                  highlightTargetLightness: widget.highlightTargetLightness,
                  highlightSaturationTarget: widget.highlightSaturationTarget,
                  globalOpacity: widget.globalOpacity,
                  strokeWidth: widget.strokeWidth,
                  blendMode: widget.blendMode,
                ),
              ),
            )
          : CustomPaint(
              painter: _StaticCirclesPainter(
                centerAlignment: widget.centerAlignment,
                ringColor: widget.ringColor,
                backgroundColor: widget.backgroundColor,
                baseSpacing: widget.baseSpacing,
                maxRings: widget.maxRings,
                pulseBaseRings: widget.pulseBaseRings ?? widget.maxRings,
                t: 0.0,
                pulseSpanRings: widget.pulseSpanRings,
                baseOpacity: widget.baseOpacity,
                highlightOpacity: widget.highlightOpacity,
                fullCircles: widget.fullCircles,
                baseTargetLightness: widget.baseTargetLightness,
                highlightTargetLightness: widget.highlightTargetLightness,
                highlightSaturationTarget: widget.highlightSaturationTarget,
                globalOpacity: widget.globalOpacity,
                strokeWidth: widget.strokeWidth,
                blendMode: widget.blendMode,
              ),
            ),
    );
  }
}

class _StaticCirclesPainter extends CustomPainter {
  final Alignment centerAlignment;
  final Color? ringColor;
  final Color? backgroundColor;
  final double baseSpacing;
  final int maxRings;
  final int pulseBaseRings;
  final double t; // 0..1 animation phase
  final double pulseSpanRings;
  final double baseOpacity;
  final double highlightOpacity;
  final bool fullCircles;
  final double baseTargetLightness;
  final double highlightTargetLightness;
  final double highlightSaturationTarget;
  final double globalOpacity;
  final double strokeWidth;
  final BlendMode blendMode;

  _StaticCirclesPainter({
    required this.centerAlignment,
    required this.ringColor,
    required this.backgroundColor,
    required this.baseSpacing,
    required this.maxRings,
    required this.pulseBaseRings,
    required this.t,
    required this.pulseSpanRings,
    required this.baseOpacity,
    required this.highlightOpacity,
    required this.fullCircles,
    required this.baseTargetLightness,
    required this.highlightTargetLightness,
    required this.highlightSaturationTarget,
    required this.globalOpacity,
    required this.strokeWidth,
    required this.blendMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background fill: solid color when provided, otherwise gradient
    // Always paint the default gradient background; waves are colored by ringColor
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

    final Offset center = Offset(
      size.width * (0.5 + 0.5 * centerAlignment.x),
      size.height * (0.5 + 0.5 * centerAlignment.y),
    );

    const List<Color> baseColors = [
      Color(0xFF5EB1FF), // blue
      Color(0xFF7A5CFF), // purple
      Color(0xFFFF6680), // pink/red
      Color(0xFFFFA14A), // orange
      Color(0xFF4CD295), // green
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

    // Build expanded palette for smoother gradients between base colors
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

    // Determine rings outwards until we exceed bounds
    final Paint ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth
      ..blendMode = blendMode; // additive default for brighter overlaps

    // Lightness baseline matches ParallelPulseWavesBackground
    const double baseTargetLightness = 0.50;

    // Draw static rings with pulse; either full circles or selected arc segment
    const double startAngle = 7 * math.pi / 3;
    const double sweepAngle = math.pi / 3;

    // Pulse center ring index advances with t based on pulseBaseRings,
    // wrapping by the actual ring count to cover the full set
    final double pulseCenter = (t * pulseBaseRings) % maxRings;
    for (int i = 0; i < maxRings; i++) {
      // Uniform spacing only
      final double radius = i * baseSpacing;
      if (radius > size.longestSide) break;

      // Base HSL color (override or palette-based with slight per-ring hue drift)
      HSLColor baseHsl;
      if (ringColor != null) {
        baseHsl =
            HSLColor.fromColor(ringColor!).withLightness(baseTargetLightness);
      } else {
        final Color base = palette[i % palette.length];
        final HSLColor hsl = HSLColor.fromColor(base);
        // Subtle hue shift with time, similar to parallel waves
        final double hueOffset = math.sin(i * 0.33 + t * math.pi * 2) * 2.0;
        baseHsl = hsl
            .withHue((hsl.hue + hueOffset) % 360)
            .withSaturation(hsl.saturation.clamp(0.5, 1.0))
            .withLightness(baseTargetLightness);
      }

      // Compute pulse intensity with trailing fade: brightest at pulseCenter,
      // decreasing opacity for smaller rings behind it. Rings ahead stay at base.
      double falloff = 0.0;
      // Treat rings in a circular list; compute trailing distance behind pulseCenter
      final double iAsDouble = i.toDouble();
      final double trailingDistance = iAsDouble <= pulseCenter
          ? (pulseCenter - iAsDouble)
          : (pulseCenter + (maxRings - iAsDouble));
      if (trailingDistance <= pulseSpanRings) {
        falloff = (1.0 - (trailingDistance / pulseSpanRings)).clamp(0.0, 1.0);
      }
      // Brighten and saturate toward the pulse peak, matching ParallelPulseWaves defaults
      const double highlightTargetLightness = 0.60;
      const double highlightSaturationTarget = 0.90;
      final double l = (baseHsl.lightness +
              (highlightTargetLightness - baseHsl.lightness) * falloff)
          .clamp(0.0, 1.0);
      final double s = (baseHsl.saturation +
              (highlightSaturationTarget - baseHsl.saturation) * falloff)
          .clamp(0.0, 1.0);
      final Color brightColor =
          baseHsl.withLightness(l).withSaturation(s).toColor();

      final double opacity =
          ((baseOpacity + highlightOpacity * falloff) * globalOpacity)
              .clamp(0.0, 1.0);
      ringPaint.color = brightColor.withOpacity(opacity);
      if (fullCircles) {
        canvas.drawCircle(center, radius, ringPaint);
      } else {
        final Rect rect = Rect.fromCircle(center: center, radius: radius);
        canvas.drawArc(rect, startAngle, sweepAngle, false, ringPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StaticCirclesPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.centerAlignment != centerAlignment ||
      oldDelegate.ringColor != ringColor ||
      oldDelegate.baseSpacing != baseSpacing ||
      oldDelegate.maxRings != maxRings ||
      oldDelegate.pulseSpanRings != pulseSpanRings ||
      oldDelegate.baseOpacity != baseOpacity ||
      oldDelegate.highlightOpacity != highlightOpacity;
}
