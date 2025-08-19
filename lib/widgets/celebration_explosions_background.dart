import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Celebration background of small, random pulse explosions across the screen.
/// Each burst renders expanding concentric rings with additive blending,
/// evoking small fireworks.
class CelebrationExplosionsBackground extends StatefulWidget {
  /// Target average spawn rate of bursts per second.
  final double burstsPerSecond;

  /// Stroke width for rings.
  final double strokeWidth;

  /// Base opacity for rings (0..1).
  final double baseOpacity;

  /// Additional opacity at the leading ring (0..1).
  final double highlightOpacity;

  /// Logical pixel spacing between adjacent rings.
  final double ringSpacing;

  /// Minimum and maximum lifetime of a burst.
  final Duration minBurstDuration;
  final Duration maxBurstDuration;

  /// Minimum and maximum end radius as a fraction of the shorter side.
  final double minEndRadiusFactor;
  final double maxEndRadiusFactor;

  /// Number of trailing rings behind the leading ring.
  final int trailRings;

  /// Overall opacity multiplier for the entire effect.
  final double globalOpacity;

  /// Total number of equal angular sectors in a ring (for fan effect).
  /// Also used as the default gap width baseline (2π / totalSectors) if
  /// [gapAngleRadians] is 0.
  final int totalSectors;

  /// Number of gaps to remove around the ring. Set to 0 to draw full circles.
  final int removedSectors;

  /// Optional explicit gap angle in radians for each gap. When > 0, this
  /// overrides the default gap width of one sector (2π / [totalSectors]).
  /// Used together with [removedSectors] to create multiple gaps per ring.
  final double gapAngleRadians;

  const CelebrationExplosionsBackground({
    super.key,
    this.burstsPerSecond = 3.0,
    this.strokeWidth = 2.0,
    this.baseOpacity = 0.12,
    this.highlightOpacity = 0.55,
    this.ringSpacing = 8.0,
    this.minBurstDuration = const Duration(milliseconds: 1100),
    this.maxBurstDuration = const Duration(milliseconds: 2000),
    this.minEndRadiusFactor = 0.08,
    this.maxEndRadiusFactor = 0.18,
    this.trailRings = 6,
    this.globalOpacity = 1.0,
    this.totalSectors = 12,
    this.removedSectors = 0,
    this.gapAngleRadians = 0.0,
  });

  @override
  State<CelebrationExplosionsBackground> createState() =>
      _CelebrationExplosionsBackgroundState();
}

class _CelebrationExplosionsBackgroundState
    extends State<CelebrationExplosionsBackground>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final math.Random _rng = math.Random();

  final List<_Burst> _bursts = <_Burst>[];
  double _spawnAccumulator = 0.0;
  int _lastTickMs = DateTime.now().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration _) {
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final double dtSeconds = math.max(0.0, (nowMs - _lastTickMs) / 1000.0);
    _lastTickMs = nowMs;

    _spawnAccumulator += dtSeconds * widget.burstsPerSecond;
    int toSpawn = _spawnAccumulator.floor();
    _spawnAccumulator -= toSpawn;

    for (int i = 0; i < toSpawn; i++) {
      _bursts.add(_createRandomBurst(nowMs));
    }

    _bursts.removeWhere((b) => nowMs - b.startMs > b.durationMs);

    setState(() {});
  }

  _Burst _createRandomBurst(int nowMs) {
    final double x = _rng.nextDouble();
    final double y = _rng.nextDouble();
    final int durMs = _lerpInt(widget.minBurstDuration.inMilliseconds,
        widget.maxBurstDuration.inMilliseconds, _rng.nextDouble());
    final double endRFactor = _lerpDouble(widget.minEndRadiusFactor,
        widget.maxEndRadiusFactor, _rng.nextDouble());

    final double hue = _rng.nextDouble() * 360.0;
    final double sat = 0.65 + _rng.nextDouble() * 0.25;
    final double light = 0.55 + _rng.nextDouble() * 0.10;
    final Color color =
        HSLColor.fromAHSL(1.0, hue, sat.clamp(0.0, 1.0), light.clamp(0.0, 1.0))
            .toColor();

    return _Burst(
      startMs: nowMs,
      durationMs: durMs,
      relCenter: Offset(x, y),
      endRadiusFactor: endRFactor,
      baseColor: color,
      rotationRad: _rng.nextDouble() * math.pi * 2.0,
    );
  }

  int _lerpInt(int a, int b, double t) => a + ((b - a) * t).round();
  double _lerpDouble(double a, double b, double t) => a + (b - a) * t;

  @override
  Widget build(BuildContext context) {
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    return RepaintBoundary(
      child: CustomPaint(
        painter: _CelebrationPainter(
          nowMs: nowMs,
          bursts: List<_Burst>.unmodifiable(_bursts),
          strokeWidth: widget.strokeWidth,
          baseOpacity: widget.baseOpacity * widget.globalOpacity,
          highlightOpacity: widget.highlightOpacity * widget.globalOpacity,
          ringSpacing: widget.ringSpacing,
          trailRings: widget.trailRings,
          totalSectors: widget.totalSectors,
          removedSectors: widget.removedSectors,
          gapAngleRadians: widget.gapAngleRadians,
        ),
      ),
    );
  }
}

class _Burst {
  final int startMs;
  final int durationMs;
  final Offset relCenter; // 0..1 in both axes
  final double endRadiusFactor; // fraction of min(size)
  final Color baseColor;
  final double rotationRad; // orientation for fan gap

  _Burst({
    required this.startMs,
    required this.durationMs,
    required this.relCenter,
    required this.endRadiusFactor,
    required this.baseColor,
    required this.rotationRad,
  });
}

class _CelebrationPainter extends CustomPainter {
  final int nowMs;
  final List<_Burst> bursts;
  final double strokeWidth;
  final double baseOpacity;
  final double highlightOpacity;
  final double ringSpacing;
  final int trailRings;
  final int totalSectors;
  final int removedSectors;
  final double gapAngleRadians;

  _CelebrationPainter({
    required this.nowMs,
    required this.bursts,
    required this.strokeWidth,
    required this.baseOpacity,
    required this.highlightOpacity,
    required this.ringSpacing,
    required this.trailRings,
    required this.totalSectors,
    required this.removedSectors,
    required this.gapAngleRadians,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint bg = Paint()
      ..shader = const RadialGradient(
        center: Alignment.center,
        radius: 1.2,
        colors: [
          Color(0xFF0A0F1E),
          Color(0xFF0C1326),
          Color(0xFF0E162A),
        ],
        stops: [0.0, 0.65, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    final double minSide = math.min(size.width, size.height);
    final Paint ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..blendMode = BlendMode.plus;

    for (final _Burst b in bursts) {
      final double elapsed =
          (nowMs - b.startMs).clamp(0, b.durationMs).toDouble();
      final double f =
          (b.durationMs <= 0) ? 1.0 : (elapsed / b.durationMs).clamp(0.0, 1.0);

      final Offset c =
          Offset(b.relCenter.dx * size.width, b.relCenter.dy * size.height);
      final double endR = b.endRadiusFactor * minSide;
      final double leadingRadius = f * endR;

      final double fadeEnvelope = math.sin(f * math.pi).clamp(0.0, 1.0);
      final Color ringColor = _normalizeLightness(b.baseColor, 0.50);

      for (int k = 0; k <= trailRings; k++) {
        final double radius = leadingRadius - k * ringSpacing;
        if (radius <= 0) break;

        final double localFade = 1.0 - (k / (trailRings + 1));
        final double opacity =
            (baseOpacity + highlightOpacity * localFade) * fadeEnvelope;
        ringPaint.color = ringColor.withOpacity(opacity.clamp(0.0, 1.0));
        final bool useFan = totalSectors > 0 && removedSectors > 0;
        if (!useFan) {
          canvas.drawCircle(c, radius, ringPaint);
        } else {
          final Rect rect = Rect.fromCircle(center: c, radius: radius);
          final int numGaps = removedSectors;
          final double sectorAngle = 2.0 * math.pi / totalSectors;
          final double period = (2.0 * math.pi) / numGaps;
          final double gapAngle = (gapAngleRadians > 0.0)
              ? gapAngleRadians
              : sectorAngle; // default: one sector wide
          final double paintedSweep = period - gapAngle;
          if (paintedSweep > 0) {
            final double gapHalf = gapAngle / 2.0;
            for (int i = 0; i < numGaps; i++) {
              final double gapCenter = b.rotationRad + i * period;
              final double arcStart = gapCenter + gapHalf;
              canvas.drawArc(rect, arcStart, paintedSweep, false, ringPaint);
            }
          }
        }
      }
    }
  }

  Color _normalizeLightness(Color color, double targetLightness) {
    final HSLColor hsl = HSLColor.fromColor(color);
    return HSLColor.fromAHSL(
            1.0, hsl.hue, hsl.saturation, targetLightness.clamp(0.0, 1.0))
        .toColor();
  }

  @override
  bool shouldRepaint(covariant _CelebrationPainter oldDelegate) {
    return nowMs != oldDelegate.nowMs ||
        bursts != oldDelegate.bursts ||
        strokeWidth != oldDelegate.strokeWidth ||
        baseOpacity != oldDelegate.baseOpacity ||
        highlightOpacity != oldDelegate.highlightOpacity ||
        ringSpacing != oldDelegate.ringSpacing ||
        trailRings != oldDelegate.trailRings ||
        totalSectors != oldDelegate.totalSectors ||
        removedSectors != oldDelegate.removedSectors ||
        gapAngleRadians != oldDelegate.gapAngleRadians;
  }
}
