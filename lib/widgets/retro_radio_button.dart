import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RetroRadioButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final double width;
  final double height;

  const RetroRadioButton({
    super.key,
    required this.label,
    this.onPressed,
    this.width = 120,
    this.height = 50,
  });

  @override
  State<RetroRadioButton> createState() => _RetroRadioButtonState();
}

class _RetroRadioButtonState extends State<RetroRadioButton> {
  bool _isPressed = false;
  static const double _shadowHeight = 6.0;

  @override
  Widget build(BuildContext context) {
    final double height = _isPressed ? 0 : _shadowHeight;

    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: Container(
        width: widget.width,
        height: widget.height + _shadowHeight,
        child: Stack(
          children: [
            // Shadow/Base layer (bottom)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: widget.height,
                decoration: BoxDecoration(
                  color: const Color(0xFF8A8A7A), // Dark shadow color
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            // Main button layer (top)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeIn,
              bottom: height,
              left: 0,
              right: 0,
              child: Container(
                height: widget.height,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5DC), // White/cream color
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.black.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black.withOpacity(0.7),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
