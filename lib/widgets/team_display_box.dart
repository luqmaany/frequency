import 'package:flutter/material.dart';
import 'team_color_button.dart';

class TeamDisplayBox extends StatelessWidget {
  final String teamName;
  final List<Widget> children;
  final TeamColor color;

  const TeamDisplayBox({
    super.key,
    required this.teamName,
    required this.children,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Dark mode palette
    // Use alpha blend to pre-compose a translucent overlay onto the
    // scaffold background so the result is fully opaque (no shimmer from
    // animated backgrounds behind it).
    // Match the darker look of home screen buttons: use the strong border tint
    // as the overlay instead of the light background tint.
    final Color baseOverlay = color.border.withOpacity(0.6);
    final Color blended = Color.alphaBlend(
      baseOverlay,
      Theme.of(context).colorScheme.background,
    );
    final Color background = blended; // opaque
    final Color border = color.border.withOpacity(1);
    final Color text = Colors.white.withOpacity(0.95);

    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: border,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              teamName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: text,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...children
                  .map((w) => Padding(
                        padding: const EdgeInsets.fromLTRB(4, 1, 4, 0),
                        child: w,
                      ))
                  .toList(),
            ],
          ),
        ],
      ),
    );
  }
}
