import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game_setup_provider.dart';
import '../services/game_state_provider.dart';
import '../services/game_navigation_service.dart';
import '../widgets/game_settings.dart';
import 'package:convey/widgets/team_color_button.dart';

class GameSettingsScreen extends ConsumerWidget {
  const GameSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameConfig = ref.watch(gameSetupProvider);
    final validationState = ref.watch(settingsValidationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Settings'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Game Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Configure your game settings',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                const GameSettings(),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TeamColorButton(
                    text: 'Back to Teams',
                    icon: Icons.arrow_back,
                    color: teamColors[1], // Blue
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TeamColorButton(
                    text: 'Start Game',
                    icon: Icons.play_arrow_rounded,
                    color: teamColors[2], // Green
                    onPressed: validationState.areAllSettingsValid
                        ? () async {
                            FocusScope.of(context).unfocus();
                            await Future.delayed(
                                const Duration(milliseconds: 150));
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              // Initialize game state with current config
                              ref
                                  .read(gameStateProvider.notifier)
                                  .initializeGame(gameConfig);

                              // Use navigation service to navigate to the first screen
                              GameNavigationService.navigateToNextScreen(
                                context,
                                ref,
                              );
                            });
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
