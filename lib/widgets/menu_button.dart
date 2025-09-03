import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sound_service.dart';

/// A reusable menu button widget with consistent styling and sound effects.
/// Plays button sound on press down for immediate feedback.
class MenuButton extends ConsumerWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;
  final double? width;
  final double? height;

  const MenuButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.color,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HSLColor hsl = HSLColor.fromColor(color);
    final double darkerLightness = (hsl.lightness * 0.25).clamp(0.0, 1.0);
    final Color buttonColor = hsl.withLightness(darkerLightness).toColor();
    final Color borderColor = color.withOpacity(0.7);
    const Color textColor = Color(0xFFE6EEF8);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: GestureDetector(
        onTapDown: (_) {
          print('$text button pressed down - playing sound');
          unawaited(ref.read(soundServiceProvider).playButtonPress());
        },
        onTap: onPressed,
        child: Container(
          width: width,
          height: height ?? 68,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 2.0),
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
