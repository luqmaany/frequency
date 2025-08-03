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
                    widget.isHost
                        ? 'Configure your game settings'
                        : 'Game settings (host only)',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (!widget.isHost) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Only the host can modify game settings',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                    onPressed: widget.isHost
                        ? () async {
                            FocusScope.of(context).unfocus();
                            await Future.delayed(
                                const Duration(milliseconds: 150));

                            if (widget.sessionId != null) {
                              // Online mode: Use Firestore settings
                              await FirestoreService.startGame(
                                  widget.sessionId!);
                              // Do not navigate directly; let the navigation service handle it
                            } else {
                              // Local mode: Initialize game state with current config
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
