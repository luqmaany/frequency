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
    final Color background = color.border.withOpacity(0.4);
    final Color border = color.background.withOpacity(0.3);
    final Color text = Colors.white.withOpacity(0.95);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
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
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
