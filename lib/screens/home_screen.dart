import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game_navigation_service.dart';
import 'online_lobby_screen.dart';

/// --- Animated gradient text (unchanged except default text now "FREQUENCY") ---
class AnimatedGradientText extends StatefulWidget {
  final String text;
  final double fontSize;
  const AnimatedGradientText({
    super.key,
    required this.text,
    this.fontSize = 72,
  });

  @override
  State<AnimatedGradientText> createState() => _AnimatedGradientTextState();
}

class _AnimatedGradientTextState extends State<AnimatedGradientText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double shift = _controller.value;
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final gradientWidth = width * 2;
            final double animatedOffset = -gradientWidth * 0.5 * shift;
            return ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  colors: [
                    Color(0xFF5EB1FF), // blue
                    Color(0xFF7A5CFF), // purple
                    Color(0xFFFF6680), // pink/red
                    Color(0xFFFFA14A), // orange
                    Color(0xFFFFD166), // yellow
                    Color(0xFF4CD295), // green
                    Color(0xFF5EB1FF), // loop
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ).createShader(Rect.fromLTWH(
                  animatedOffset,
                  0,
                  gradientWidth,
                  bounds.height,
                ));
              },
              child: Text(
                widget.text,
                style: TextStyle(
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// --- Animated wave background ----------------------------------------------
/// Lightweight CustomPainter with animated contour-like lines.
/// Looks best on dark backgrounds.
class WaveBackground extends StatefulWidget {
  const WaveBackground({super.key});

  @override
  State<WaveBackground> createState() => _WaveBackgroundState();
}

class _WaveBackgroundState extends State<WaveBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(seconds: 10))
        ..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          painter: _WavesPainter(t: _ctrl.value),
        ),
      ),
    );
  }
}

class _WavesPainter extends CustomPainter {
  final double t;
  _WavesPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    // Background gradient
    final bg = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0, -0.2),
        radius: 1.2,
        colors: [Color(0xFF0B1020), Color(0xFF0E162A)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    // Contour lines
    const lines = 26;
    for (int i = 0; i < lines; i++) {
      final yBase = size.height * (i / (lines - 1));
      final path = Path();
      for (double x = 0; x <= size.width; x += 6) {
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
        ..strokeWidth = 1.3
        ..color = color.withOpacity(0.9);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavesPainter oldDelegate) => oldDelegate.t != t;
}

/// --- HomeScreen with animated background + new title ------------------------
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Palette aligned with the animated background hues
    final List<Color> buttonColors = const [
      Color(0xFF5EB1FF), // blue
      Color(0xFF7A5CFF), // purple
      Color(0xFFFF6680), // pink/red
      Color(0xFFFFA14A), // orange
      Color(0xFF4CD295), // green
    ];

    final Color bgColor = const Color(0xFF0B1020);
    return Scaffold(
      // Dark base so the waves pop
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Animated waves
          const Positioned.fill(child: WaveBackground()),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 30),
                  Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double width = constraints.maxWidth;
                        final double computed = width * 0.16; // 16% of width
                        final double fontSize = computed.clamp(44.0, 96.0);
                        final baseStyle = Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontSize: fontSize,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            );
                        return Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.diagonal3Values(1.0, 1.5, 1.0),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Purple outline behind
                              Text(
                                'FREQUENCY',
                                textAlign: TextAlign.center,
                                style: baseStyle?.copyWith(
                                  foreground: (Paint()
                                    ..style = PaintingStyle.stroke
                                    ..strokeWidth = 3.0
                                    ..color =
                                        const Color.fromARGB(255, 255, 56, 56)),
                                ),
                              ),
                              // Fill that matches the background color on top
                              Text(
                                'FREQUENCY',
                                textAlign: TextAlign.center,
                                style: baseStyle?.copyWith(
                                  color: bgColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const Spacer(),
                  _buildMenuButton(
                    context,
                    'Start Game',
                    Icons.play_arrow_rounded,
                    () => GameNavigationService.navigateToGameSetup(context),
                    buttonColors[0],
                  ),
                  const SizedBox(height: 16),
                  _buildMenuButton(
                    context,
                    'Online',
                    Icons.public_rounded,
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const OnlineLobbyScreen(),
                        ),
                      );
                    },
                    buttonColors.length > 5
                        ? buttonColors[5 % buttonColors.length]
                        : buttonColors[1],
                  ),
                  const SizedBox(height: 16),
                  // Removed 'Stats & History' button
                  _buildMenuButton(
                    context,
                    'Categories',
                    Icons.list_alt_rounded,
                    () => GameNavigationService.navigateToWordListsManager(
                        context),
                    buttonColors[3],
                  ),
                  const SizedBox(height: 16),
                  _buildMenuButton(
                    context,
                    'Settings',
                    Icons.settings_rounded,
                    () => GameNavigationService.navigateToSettings(context),
                    buttonColors[2],
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String text,
    IconData icon,
    VoidCallback onPressed,
    Color color,
  ) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final HSLColor hsl = HSLColor.fromColor(color);
    final double darkerLightness = (hsl.lightness * 0.25).clamp(0.0, 1.0);
    final Color buttonColor = hsl.withLightness(darkerLightness).toColor();
    final Color borderColor = isDark ? color.withOpacity(0.7) : color;
    final Color iconColor = borderColor;
    final Color textColor = const Color(0xFFE6EEF8);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: borderColor.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: iconColor),
              const SizedBox(width: 12),
              Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
