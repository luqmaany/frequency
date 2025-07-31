import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game_setup_provider.dart';
import '../services/game_state_provider.dart';
import '../services/game_navigation_service.dart';
import '../widgets/game_mechanics_mixin.dart';
import '../widgets/game_header.dart';
import '../widgets/game_cards.dart';
import '../widgets/game_countdown.dart';
import '../widgets/team_color_button.dart'; // Added import for TeamColorButton

class GameScreen extends ConsumerStatefulWidget {
  final int teamIndex;
  final int roundNumber;
  final int turnNumber;
  final String category;

  const GameScreen({
    super.key,
    required this.teamIndex,
    required this.roundNumber,
    required this.turnNumber,
    required this.category,
  });

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with GameMechanicsMixin<GameScreen> {
  bool _isCountdownActive = true;

  @override
  String get categoryId => widget.category;

  @override
  void onTurnEnd() {
    // Use navigation service to navigate to turn over screen
    GameNavigationService.navigateToTurnOver(
      context,
      widget.teamIndex,
      widget.roundNumber,
      widget.turnNumber,
      widget.category,
      correctCount,
      skipsLeft,
      wordsGuessed,
      wordsSkipped,
      disputedWords,
    );
  }

  @override
  void onWordGuessed(String word) {
    // Word usage is handled in the GameCards widget
  }

  @override
  void onWordSkipped(String word) {
    // Skip logic is handled in the GameCards widget
  }

  @override
  void initState() {
    super.initState();
    final gameConfig = ref.read(gameSetupProvider);
    initializeGameMechanics(
        gameConfig.roundTimeSeconds, gameConfig.allowedSkips);
    loadInitialWords();

    // Pause timer during countdown
    pauseTimer();
  }

  @override
  void dispose() {
    disposeGameMechanics();
    super.dispose();
  }

  void _onCountdownComplete() {
    setState(() {
      _isCountdownActive = false;
    });
    // Resume timer when countdown completes
    resumeTimer();
  }

  @override
  Widget build(BuildContext context) {
    if (currentWords.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sentiment_dissatisfied,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No more words available!',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'All words in this category have been used.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final gameConfig = ref.watch(gameSetupProvider);
    final colorIndex = (gameConfig.teamColorIndices.length > widget.teamIndex)
        ? gameConfig.teamColorIndices[widget.teamIndex]
        : widget.teamIndex % teamColors.length;
    final teamColor = teamColors[colorIndex];

    return WillPopScope(
      onWillPop: () async {
        final shouldQuit = await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (context) => Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).dialogBackgroundColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: teamColor.border, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: teamColor.border, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Quit Game?',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: teamColor.text,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You sure you want to be a quitter?',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: TeamColorButton(
                          text: 'Cancel',
                          icon: Icons.close,
                          color: teamColor,
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TeamColorButton(
                          text: 'Quit',
                          icon: Icons.exit_to_app,
                          color: teamColor,
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
        return shouldQuit == true;
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // Title showing current players
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "${ref.read(currentTeamPlayersProvider)[0]} & ${ref.read(currentTeamPlayersProvider)[1]}'s Turn",
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Game header with timer, category, and skips
                  GameHeader(
                    timeLeft: timeLeft,
                    categoryId: categoryId,
                    skipsLeft: skipsLeft,
                    isTiebreaker: false,
                  ),

                  // Word cards with swiping mechanics
                  Expanded(
                    child: GameCards(
                      currentWords: currentWords,
                      categoryId: categoryId,
                      skipsLeft: skipsLeft,
                      showBlankCards: _isCountdownActive,
                      onWordGuessed: (word) {
                        if (!_isCountdownActive) {
                          handleWordGuessed(word);
                        }
                      },
                      onWordSkipped: (word) {
                        if (!_isCountdownActive) {
                          handleWordSkipped(word);
                        }
                      },
                      onLoadNewWord: (index) {
                        if (!_isCountdownActive) {
                          // Load new word for the specific card that was swiped
                          loadNewWord(index);
                        }
                      },
                    ),
                  ),
                ],
              ),

              // Countdown overlay
              if (_isCountdownActive)
                GameCountdown(
                  player1Name: ref.read(currentTeamPlayersProvider)[0],
                  player2Name: ref.read(currentTeamPlayersProvider)[1],
                  categoryId: categoryId,
                  onCountdownComplete: _onCountdownComplete,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
