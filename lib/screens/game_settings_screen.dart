import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game_setup_provider.dart';
import '../services/game_state_provider.dart';
import '../services/game_navigation_service.dart';
import '../services/online_game_navigation_service.dart';
import '../services/firestore_service.dart';
import '../widgets/game_settings.dart';
import 'package:convey/widgets/team_color_button.dart';
import '../providers/session_providers.dart';

class GameSettingsScreen extends ConsumerStatefulWidget {
  final bool isHost;
  final String? sessionId;
  const GameSettingsScreen({super.key, this.isHost = true, this.sessionId});

  @override
  ConsumerState<GameSettingsScreen> createState() => _GameSettingsScreenState();
}

class _GameSettingsScreenState extends ConsumerState<GameSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final gameConfig = ref.watch(gameSetupProvider);
    final validationState = ref.watch(settingsValidationProvider);

    // Set up navigation listener for online games (only once per widget instance)
    if (widget.sessionId != null) {
      ref.listen(sessionStatusProvider(widget.sessionId!), (prev, next) {
        final status = next.value;
        if (status != null) {
          OnlineGameNavigationService.handleNavigation(
            context: context,
            ref: ref,
            sessionId: widget.sessionId!,
            status: status,
          );
        }
      });
    }

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
                GameSettings(
                    readOnly: !widget.isHost, sessionId: widget.sessionId),
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
                    onPressed:
                        widget.isHost && validationState.areAllSettingsValid
                            ? () async {
                                FocusScope.of(context).unfocus();
                                await Future.delayed(
                                    const Duration(milliseconds: 150));
                                // Initialize game state with current config (local only)
                                ref
                                    .read(gameStateProvider.notifier)
                                    .initializeGame(gameConfig);

                                if (widget.sessionId != null) {
                                  // Centralized online game state update
                                  await FirestoreService.startGame(
                                      widget.sessionId!);
                                  // Do not navigate directly; let the navigation service handle it
                                } else {
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
