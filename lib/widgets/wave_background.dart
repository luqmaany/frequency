import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Animated wave background used on the home screen.
/// Extracted from `HomeScreen` for reuse and clarity.
class WaveBackground extends StatefulWidget {
  final double strokeWidth;

  const WaveBackground({super.key, this.strokeWidth = 2.0});

  @override
  State<WaveBackground> createState() => _WaveBackgroundState();
}

class _WaveBackgroundState extends State<WaveBackground>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  static const Duration _loop = Duration(seconds: 10);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) => setState(() {}))..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Absolute-time phase 0..1 so there is no visual jump across navigation
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final double t =
        ((nowMs % _loop.inMilliseconds) / _loop.inMilliseconds).clamp(0.0, 1.0);

    return RepaintBoundary(
      child: CustomPaint(
        painter: _WavesPainter(t: t, strokeWidth: widget.strokeWidth),
      ),
    );
  }
}

class _WavesPainter extends CustomPainter {
  final double t;
  final double strokeWidth;
  _WavesPainter({required this.t, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    // Background gradient
    final bg = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0, -0.2),
        // Larger radius so gradient reaches the far corners on tall/wide screens
        radius: 1.6,
        colors: [Color(0xFF0B1020), Color(0xFF0E162A)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    // Contour lines (higher = tighter spacing)
    // Scale the number of lines with height so it feels proportional on tablets
    final int lines = (size.height / 20).clamp(26, 72).floor();
    for (int i = 0; i < lines; i++) {
      final yBase = size.height * (i / (lines - 1));
      final path = Path();
      // Scale sampling step with width to keep smoothness consistent
      final double step = (size.width / 120).clamp(3.0, 8.0);
      for (double x = 0; x <= size.width; x += step) {
        // Two sine layers + slow drift for "radio" feel
        // Use integer multiples of 2π for time terms so the loop is seamless when t resets
        final y = yBase +
            10 * math.sin((x * 0.012) + (t * math.pi * 2 * 1.0) + i * 0.55) +
            4 * math.sin((x * 0.02) - (t * math.pi * 2 * 2.0) + i * 1.1);
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      // Subtle hue shift across lines, with glow-like opacity
      final hue = (210 + i * 7) % 360.0; // blues → purples → reds
      final color = HSLColor.fromAHSL(0.20, hue, 0.65, 0.55).toColor();
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true
        ..color = color.withOpacity(0.9);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavesPainter oldDelegate) => oldDelegate.t != t;
}
