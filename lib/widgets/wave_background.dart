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
      child: SizedBox.expand(
        child: CustomPaint(
          painter: _WavesPainter(t: t, strokeWidth: widget.strokeWidth),
        ),
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
    // Scale factors so visuals look proportionate on phones and tablets
    final double scale =
        (math.min(size.width, size.height) / 400.0).clamp(0.8, 2.0);
    // Background gradient
    final bg = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0, -0.2),
        // Larger radius so gradient reaches the far corners on tall/wide screens
        radius: 1.6,
        colors: [Color(0xFF0B1020), Color(0xFF0E162A)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    // Contour lines: mimic parallel pulse background strategy
    final double spacing = 12.0 * scale;
    final int numRows = math.max(1, (size.height / spacing).ceil() + 3);

    for (int row = 0; row < numRows; row++) {
      final double yBase = row * spacing;
      if (yBase > size.height + spacing) break;

      final Path path = Path();
      final double dx = (size.width / 160.0).clamp(2.0, 6.0);
      double x = -dx;
      double y = yBase +
          (8 * scale) *
              math.sin((x * 0.012) + (t * math.pi * 2 * 1.0) + row * 0.55) +
          (3 * scale) *
              math.sin((x * 0.02) - (t * math.pi * 2 * 2.0) + row * 1.1);
      path.moveTo(x, y);
      for (; x <= size.width + dx; x += dx) {
        y = yBase +
            (8 * scale) *
                math.sin((x * 0.012) + (t * math.pi * 2 * 1.0) + row * 0.55) +
            (3 * scale) *
                math.sin((x * 0.02) - (t * math.pi * 2 * 2.0) + row * 1.1);
        path.lineTo(x, y);
      }

      // Subtle hue shift across lines, with glow-like opacity
      final double hue = (210 + row * 7) % 360.0; // blues → purples → reds
      final Color color = HSLColor.fromAHSL(0.18, hue, 0.65, 0.55).toColor();
      final Paint paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * scale
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true
        ..color = color.withOpacity(0.9);
      canvas.drawPath(path, paint);
    }

    // No bottom-edge safety needed; rows are computed to cover height
  }

  @override
  bool shouldRepaint(covariant _WavesPainter oldDelegate) => oldDelegate.t != t;
}
