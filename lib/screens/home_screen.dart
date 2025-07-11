import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game_navigation_service.dart';
import '../widgets/team_color_button.dart';

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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Welcome back!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Ready to get roasted?',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 48),
              TeamColorButton(
                text: 'Start Game',
                icon: Icons.play_arrow_rounded,
                color: uiColors[0],
                customColor: buttonColors[0],
                onPressed: () =>
                    GameNavigationService.navigateToGameSetup(context),
              ),
              const SizedBox(height: 16),
              TeamColorButton(
                text: 'Last Game Recap',
                icon: Icons.history_rounded,
                color: uiColors[0],
                customColor: buttonColors[1],
                onPressed: () {
                  // TODO: Implement last game recap
                },
              ),
              const SizedBox(height: 16),
              TeamColorButton(
                text: 'Settings',
                icon: Icons.settings_rounded,
                color: uiColors[0],
                customColor: buttonColors[2],
                onPressed: () =>
                    GameNavigationService.navigateToSettings(context),
              ),
              const SizedBox(height: 16),
              TeamColorButton(
                text: 'Word Lists Manager',
                icon: Icons.list_alt_rounded,
                color: uiColors[0],
                customColor: buttonColors[3],
                onPressed: () =>
                    GameNavigationService.navigateToWordListsManager(context),
              ),
              const SizedBox(height: 16),
              TeamColorButton(
                text: 'Stats & History',
                icon: Icons.bar_chart_rounded,
                color: uiColors[0],
                customColor: buttonColors[4],
                onPressed: () {
                  // TODO: Implement stats & history
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
