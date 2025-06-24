import 'package:flutter/material.dart';

class TeamColor {
  final String name;
  final Color background;
  final Color border;
  final Color text;
  TeamColor(this.name, this.background, this.border, this.text);
}

final List<TeamColor> teamColors = [
  TeamColor('Red', Colors.red.shade100, Colors.red, Colors.red.shade900),
  TeamColor('Blue', Colors.blue.shade100, Colors.blue, Colors.blue.shade900),
  TeamColor(
      'Green', Colors.green.shade100, Colors.green, Colors.green.shade900),
  TeamColor(
      'Orange', Colors.orange.shade100, Colors.orange, Colors.orange.shade900),
  TeamColor(
      'Purple', Colors.purple.shade100, Colors.purple, Colors.purple.shade900),
  TeamColor(
      'Brown', Colors.brown.shade100, Colors.brown, Colors.brown.shade900),
];

class TeamColorButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onPressed : null,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color:
                enabled ? color.background : color.background.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled ? color.border : Colors.grey.shade300,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (enabled ? color.border : Colors.grey.shade300)
                    .withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: iconSize,
                  color: enabled ? color.border : Colors.grey.shade400),
              const SizedBox(width: 12),
              Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: enabled ? color.text : Colors.grey.shade400,
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
