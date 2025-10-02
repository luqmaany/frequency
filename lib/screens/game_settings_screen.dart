import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game_setup_provider.dart';
import '../services/game_navigation_service.dart';
import '../services/online_game_navigation_service.dart';
import '../services/firestore_service.dart';
import '../widgets/game_settings.dart';
import '../widgets/parallel_pulse_waves_background.dart';
import 'package:convey/widgets/team_color_button.dart';
import '../providers/session_providers.dart';
import 'deck_selection_screen.dart';

class GameSettingsScreen extends ConsumerStatefulWidget {
  final bool isHost;
  final String? sessionId;
  const GameSettingsScreen({super.key, this.isHost = true, this.sessionId});

  @override
  ConsumerState<GameSettingsScreen> createState() => _GameSettingsScreenState();
}

class _GameSettingsScreenState extends ConsumerState<GameSettingsScreen> {
  Future<void> _navigateToOnlineDeckSelection() async {
    final sessionId = widget.sessionId;
    if (sessionId == null) return;

    // Get current settings to get existing selected decks (if any)
    final sessionAsync = ref.read(sessionStreamProvider(sessionId));
    final sessionSnap = sessionAsync.value;
    final sessionData = sessionSnap?.data();
    final settings = sessionData?['settings'] as Map<String, dynamic>?;
    final currentSelectedDecks = (settings?['selectedDeckIds'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    // Navigate to deck selection screen
    final selectedDecks = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (context) => DeckSelectionScreen(
          initialSelectedDecks: currentSelectedDecks,
        ),
      ),
    );

    // If decks were selected, update Firestore and start the game
    if (selectedDecks != null && selectedDecks.isNotEmpty && mounted) {
      try {
        // Update selected decks in Firestore settings
        await ref.read(updateSelectedDecksProvider({
          'sessionId': sessionId,
          'selectedDeckIds': selectedDecks,
        }).future);

        // Start the game
        await FirestoreService.startGame(sessionId);
      } catch (e) {
        print('Error starting online game with decks: $e');
        // Handle error - maybe show a snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error starting game: ${e.toString()}')),
          );
        }
      }
    }
  }

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
      body: Stack(
        children: [
          const Positioned.fill(
            child: ParallelPulseWavesBackground(
              perRowPhaseOffset: 0.0,
              baseSpacing: 35.0,
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 48),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Center(
                  child: Text(
                    'Game Settings',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (!widget.isHost) ...[
                                SizedBox(
                                  width: double.infinity,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.orange.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.info_outline,
                                          color: Colors.orange,
                                          size: 20,
                                        ),
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
                                ),
                              ],
                              GameSettings(
                                readOnly: !widget.isHost,
                                sessionId: widget.sessionId,
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
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
                                    // Online mode: Navigate to deck selection first
                                    _navigateToOnlineDeckSelection();
                                  } else {
                                    // Local mode: Navigate to deck selection first
                                    GameNavigationService
                                        .navigateToDeckSelection(
                                      context,
                                      gameConfig,
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}
