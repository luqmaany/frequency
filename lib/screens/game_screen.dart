import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game_setup_provider.dart';
import '../services/game_state_provider.dart';
import '../services/game_navigation_service.dart';
import '../widgets/game_mechanics_mixin.dart';
import '../widgets/game_header.dart';
import '../widgets/game_cards.dart';
import '../widgets/game_countdown.dart';
import '../services/sound_service.dart';
import '../widgets/team_color_button.dart'; // Added import for TeamColorButton
import '../widgets/confirm_on_back.dart';
import '../widgets/quit_dialog.dart';
import 'zen_summary_screen.dart';

class GameScreen extends ConsumerStatefulWidget {
  final int teamIndex;
  final int roundNumber;
  final int turnNumber;
  final String category;
  final bool zenMode;

  const GameScreen({
    super.key,
    required this.teamIndex,
    required this.roundNumber,
    required this.turnNumber,
    required this.category,
    this.zenMode = false,
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
    // Play turn end sound
    try {
      ref.read(soundServiceProvider).playTurnEnd();
    } catch (_) {}
    if (widget.zenMode) {
      // In Zen mode, skip team/role flow and show a lightweight summary
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ZenSummaryScreen(
            categoryId: widget.category,
            correctCount: correctCount,
            skipsLeft: skipsLeft,
            wordsGuessed: wordsGuessed,
            wordsSkipped: wordsSkipped,
            wordsLeftOnScreen: currentWords.map((w) => w.text).toList(),
            wordTimings: wordTimings,
          ),
        ),
      );
    } else {
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
        currentWords.map((w) => w.text).toList(),
        disputedWords,
        wordTimings,
      );
    }
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
    // Ensure menu music stops when gameplay starts
    ref.read(soundServiceProvider).stopMenuMusic();
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
    // Reset word timings so countdown time isn't counted
    resetWordTimings();
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

    return ConfirmOnBack(
      dialogBuilder: (ctx) => QuitDialog(color: teamColor),
      onConfirmed: (ctx) async {
        await GameNavigationService.quitToHome(ctx, ref);
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // Title (hide player names in Zen mode)
                  if (!widget.zenMode)
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
                  player1Name: widget.zenMode
                      ? 'Ready'
                      : ref.read(currentTeamPlayersProvider)[0],
                  player2Name: widget.zenMode
                      ? ''
                      : ref.read(currentTeamPlayersProvider)[1],
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
