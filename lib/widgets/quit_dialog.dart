import 'package:flutter/material.dart';
import 'team_color_button.dart';

class QuitDialog extends StatelessWidget {
  final TeamColor color;
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;

  const QuitDialog({
    super.key,
    required this.color,
    this.title = 'Quit Game?',
    this.message = 'You sure you want to be a quitter?',
    this.confirmText = 'Quit',
    this.cancelText = 'Cancel',
  });

  @override
  Widget build(BuildContext context) {
    // Always-red styling
    const Color dangerFill = Color(0xFF2B0C0C);
    const Color dangerBorder = Color(0xFFFF5252);
    const Color dangerText = Color(0xFFFFCDD2);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: dangerFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: dangerBorder, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: dangerBorder, size: 48),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: dangerText,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: dangerText.withOpacity(0.9)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: TeamColorButton(
                    text: cancelText,
                    icon: Icons.close,
                    color: TeamColor(
                        'Red', dangerText, dangerBorder, Colors.white),
                    variant: TeamButtonVariant.outline,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TeamColorButton(
                    text: confirmText,
                    icon: Icons.exit_to_app,
                    color: TeamColor(
                        'Red', dangerText, dangerBorder, Colors.white),
                    variant: TeamButtonVariant.filled,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
