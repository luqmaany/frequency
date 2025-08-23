import 'package:flutter/material.dart';
import 'dart:math' as math;

enum AppTransitionStyle {
  material,
  fade,
  slideFromRight,
  slideFromBottom,
  scale,
  rotation,
  circularReveal,
}

class TransitionService {
  static PageRoute<T> buildRoute<T>(
    Widget page, {
    AppTransitionStyle style = AppTransitionStyle.material,
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = Curves.easeOutCubic,
    Offset? revealCenterFraction,
  }) {
    switch (style) {
      case AppTransitionStyle.material:
        return MaterialPageRoute<T>(builder: (_) => page);
      case AppTransitionStyle.fade:
        return _buildFadeRoute<T>(page, duration, curve);
      case AppTransitionStyle.slideFromRight:
        return _buildSlideRoute<T>(page, const Offset(1, 0), duration, curve);
      case AppTransitionStyle.slideFromBottom:
        return _buildSlideRoute<T>(page, const Offset(0, 1), duration, curve);
      case AppTransitionStyle.scale:
        return _buildScaleRoute<T>(page, duration, curve);
      case AppTransitionStyle.rotation:
        return _buildRotationRoute<T>(page, duration, curve);
      case AppTransitionStyle.circularReveal:
        return _buildCircularRevealRoute<T>(
          page,
          duration,
          curve,
          revealCenterFraction,
        );
    }
  }

  static PageRoute<T> _buildFadeRoute<T>(
      Widget page, Duration duration, Curve curve) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: duration,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: curve),
          child: child,
        );
      },
    );
  }

  static PageRoute<T> _buildSlideRoute<T>(
      Widget page, Offset begin, Duration duration, Curve curve) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: duration,
      transitionsBuilder: (_, animation, __, child) {
        final tween = Tween<Offset>(begin: begin, end: Offset.zero)
            .chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  static PageRoute<T> _buildScaleRoute<T>(
      Widget page, Duration duration, Curve curve) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: duration,
      transitionsBuilder: (_, animation, __, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: curve),
          child: child,
        );
      },
    );
  }

  static PageRoute<T> _buildRotationRoute<T>(
      Widget page, Duration duration, Curve curve) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: duration,
      transitionsBuilder: (_, animation, __, child) {
        return RotationTransition(
          turns: CurvedAnimation(parent: animation, curve: curve),
          child: FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          ),
        );
      },
    );
  }

  static PageRoute<T> _buildCircularRevealRoute<T>(
    Widget page,
    Duration duration,
    Curve curve,
    Offset? centerFraction,
  ) {
    // Pick a themed random border color for the reveal ring
    const palette = <Color>[
      Color(0xFF5EB1FF), // blue
      Color(0xFF7A5CFF), // purple
      Color(0xFFFF6680), // pink/red
      Color(0xFFFFA14A), // orange
      Color(0xFFFFD166), // yellow
      Color(0xFF4CD295), // green
    ];
    final Color borderColor = palette[math.Random().nextInt(palette.length)];

    return PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, __, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            final Offset fraction = centerFraction ?? const Offset(0.5, 0.5);
            final Offset center = Offset(
              size.width * fraction.dx,
              size.height * fraction.dy,
            );
            final double maxRadius = _maxRadiusToCover(size, center);
            final Animation<double> radius = Tween<double>(
              begin: 0,
              end: maxRadius,
            ).chain(CurveTween(curve: curve)).animate(animation);

            return AnimatedBuilder(
              animation: radius,
              builder: (context, _) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipPath(
                      clipper: _CircleRevealClipper(
                        center: center,
                        radius: radius.value,
                      ),
                      child: child,
                    ),
                    IgnorePointer(
                      child: CustomPaint(
                        painter: _CircleBorderPainter(
                          center: center,
                          radius: radius.value,
                          color: borderColor,
                          strokeWidth: 5.5,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  static double _maxRadiusToCover(Size size, Offset center) {
    final distances = <double>[
      (center - const Offset(0, 0)).distance,
      (center - Offset(size.width, 0)).distance,
      (center - Offset(0, size.height)).distance,
      (center - Offset(size.width, size.height)).distance,
    ];
    distances.sort();
    return distances.last;
  }
}

class _CircleRevealClipper extends CustomClipper<Path> {
  final Offset center;
  final double radius;

  _CircleRevealClipper({required this.center, required this.radius});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    return path;
  }

  @override
  bool shouldReclip(covariant _CircleRevealClipper oldClipper) {
    return oldClipper.radius != radius || oldClipper.center != center;
  }
}

class _CircleBorderPainter extends CustomPainter {
  final Offset center;
  final double radius;
  final double strokeWidth;
  final Color color;

  _CircleBorderPainter({
    required this.center,
    required this.radius,
    required this.color,
    this.strokeWidth = 6.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (radius <= 0) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color.withOpacity(0.95)
      ..isAntiAlias = true;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _CircleBorderPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.center != center ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
