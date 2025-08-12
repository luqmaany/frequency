import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/storage_service.dart';

class TeamColor {
  final String name;
  final Color background;
  final Color border;
  final Color text;
  TeamColor(this.name, this.background, this.border, this.text);
}

final List<TeamColor> uiColors = [
  TeamColor('Blue', Colors.blue.shade100, Colors.blue, Colors.blue.shade900),
  TeamColor(
      'Green', Colors.green.shade100, Colors.green, Colors.green.shade900),
  TeamColor('Red', Colors.red.shade100, Colors.red, Colors.red.shade900),
];

final List<TeamColor> teamColors = [
  TeamColor('Turquoise', const Color.fromARGB(255, 153, 229, 210),
      const Color(0xFF00BFAE), const Color(0xFF00695C)),
  TeamColor('Magenta', const Color(0xFFF8BBD0), const Color(0xFFE91E63),
      const Color(0xFF880E4F)),
  TeamColor(
      'Violet', Colors.purple.shade100, Colors.purple, Colors.purple.shade900),
  TeamColor(
      'Coral', Colors.orange.shade100, Colors.orange, Colors.orange.shade900),
  TeamColor(
      'Indigo', Colors.indigo.shade100, Colors.indigo, Colors.indigo.shade900),
  TeamColor('Olive', const Color.fromARGB(255, 227, 224, 158),
      const Color(0xFF808000), const Color(0xFF556B2F)),
];

class TeamColorButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final TeamColor color;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry padding;
  final double iconSize;

  const TeamColorButton({
    super.key,
    required this.text,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.padding = const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    this.iconSize = 24,
  });

  @override
  State<TeamColorButton> createState() => _TeamColorButtonState();
}

class _TeamColorButtonState extends State<TeamColorButton> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _scale = 0.97; // adjust to taste
    });
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _scale = 1.0;
    });
  }

  void _onTapCancel() {
    setState(() {
      _scale = 1.0;
    });
  }

  Future<void> _handleTap() async {
    // Check vibration setting
    final prefs = await StorageService.loadAppPreferences();
    if (prefs['vibrationEnabled'] == true) {
      HapticFeedback.lightImpact();
    }
    if (widget.onPressed != null) {
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null;
    // Compose an opaque dark button color by alpha blending the strong border
    // tint over the app background, matching the look of other dark buttons.
    final Color baseBg = Theme.of(context).colorScheme.background;
    final Color overlayEnabled = widget.color.border.withOpacity(0.6);
    final Color overlayDisabled = widget.color.border.withOpacity(0.2);
    final Color backgroundEnabled = Color.alphaBlend(overlayEnabled, baseBg);
    final Color backgroundDisabled = Color.alphaBlend(overlayDisabled, baseBg);
    final Color border = widget.color.border.withOpacity(1);
    final Color text = enabled ? Colors.white : Colors.white.withOpacity(0.1);
    final Color iconColor = enabled ? border : border.withOpacity(0.2);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Material(
          color: enabled ? backgroundEnabled : backgroundDisabled,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: enabled ? _handleTap : null,
            onTapDown: enabled ? _onTapDown : null,
            onTapUp: enabled ? _onTapUp : null,
            onTapCancel: enabled ? _onTapCancel : null,
            child: Container(
              padding: widget.padding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: enabled ? border : border.withOpacity(0.2),
                  width: 1.5, // match other buttons' stroke width
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon, size: widget.iconSize, color: iconColor),
                  const SizedBox(width: 12),
                  Text(
                    widget.text,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: enabled ? text : Colors.grey.shade400,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
