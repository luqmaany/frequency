import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game_setup_provider.dart';
import '../services/game_state_provider.dart';
import '../services/game_navigation_service.dart';
import '../services/online_game_navigation_service.dart';
import '../widgets/game_settings.dart';
import 'package:convey/widgets/team_color_button.dart';

class GameSettingsScreen extends ConsumerWidget {
  final bool isHost;
  final String? sessionId;
  const GameSettingsScreen({super.key, this.isHost = true, this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Set up online navigation listener if in online mode
    if (sessionId != null) {
      OnlineGameNavigationService.navigate(
        context: context,
        ref: ref,
        sessionId: sessionId!,
      );
    }
    final gameConfig = ref.watch(gameSetupProvider);
    final validationState = ref.watch(settingsValidationProvider);

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 48),
                const Center(
                  child: Text(
                    'Game Settings',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Configure your game settings',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GameSettings(readOnly: !isHost, sessionId: sessionId),
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
                    text: 'Teams',
                    icon: Icons.arrow_back,
                    color: uiColors[0], // Blue
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
                    color: uiColors[1], // Green
                    onPressed: isHost && validationState.areAllSettingsValid
                        ? () async {
                            FocusScope.of(context).unfocus();
                            await Future.delayed(
                                const Duration(milliseconds: 150));

                            if (sessionId != null) {
                              // Online mode - only update Firestore, don't initialize local game state
                              await OnlineGameNavigationService.startGame(
                                  sessionId!);
                              // Do not navigate directly; let the navigation service handle it
                            } else {
                              // Local mode - initialize game state with current config
                              ref
                                  .read(gameStateProvider.notifier)
                                  .initializeGame(gameConfig);
                              GameNavigationService.navigateToNextScreen(
                                context,
                                ref,
                              );
                            }
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
