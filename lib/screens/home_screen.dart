import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game_navigation_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Define a list of colors for the buttons
    final List<Color> buttonColors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];
    return Scaffold(
      backgroundColor: Colors.white, // Default background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Color picker removed
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'Welcome back!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Center(
                child: Text(
                  'Ready to get roasted?',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 48),
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
                'Last Game Recap',
                Icons.history_rounded,
                () {
                  // TODO: Implement last game recap
                },
                buttonColors[1],
              ),
              const SizedBox(height: 16),
              _buildMenuButton(
                context,
                'Settings',
                Icons.settings_rounded,
                () => GameNavigationService.navigateToSettings(context),
                buttonColors[2],
              ),
              const SizedBox(height: 16),
              _buildMenuButton(
                context,
                'Word Lists Manager',
                Icons.list_alt_rounded,
                () => GameNavigationService.navigateToWordListsManager(context),
                buttonColors[3],
              ),
              const SizedBox(height: 16),
              _buildMenuButton(
                context,
                'Stats & History',
                Icons.bar_chart_rounded,
                () {
                  // TODO: Implement stats & history
                },
                buttonColors[4],
              ),
            ],
          ),
        ),
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
    final Color buttonColor = color.withOpacity(0.35);
    final Color borderColor = isDark ? color.withOpacity(0.7) : color;
    final Color iconColor = borderColor;
    final Color textColor = isDark ? const Color(0xFFE0E0E0) : Colors.black;
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
            border: Border.all(
              color: borderColor,
              width: 1.5,
            ),
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
