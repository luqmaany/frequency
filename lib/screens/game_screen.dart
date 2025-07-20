import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../services/game_setup_provider.dart';
import '../services/game_state_provider.dart';
import '../services/game_navigation_service.dart';
import '../screens/word_lists_manager_screen.dart';
import '../widgets/game_mechanics_mixin.dart';
import '../widgets/game_header.dart';
import '../widgets/game_cards.dart';
import '../widgets/game_countdown.dart';

class GameScreen extends ConsumerStatefulWidget {
  final int teamIndex;
  final int roundNumber;
  final int turnNumber;
  final WordCategory category;

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
  WordCategory get category => widget.category;

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

    return Scaffold(
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
                  category: category,
                  skipsLeft: skipsLeft,
                  isTiebreaker: false,
                ),

                // Word cards with swiping mechanics
                Expanded(
                  child: GameCards(
                    currentWords: currentWords,
                    category: category,
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

            // Left side top red glow effect (for top card)
            Positioned(
              top: 180,
              left: 0,
              child: Container(
                width: 20,
                height: MediaQuery.of(context).size.height * 0.32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(50),
                    bottomRight: Radius.circular(50),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.red.withOpacity(0.4),
                      Colors.red.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Left side bottom red glow effect (for bottom card)
            Positioned(
              bottom: 0,
              left: 0,
              child: Container(
                width: 30,
                height: MediaQuery.of(context).size.height * 0.35,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(50),
                    bottomRight: Radius.circular(50),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.red.withOpacity(0.4),
                      Colors.red.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Right side top green glow effect (for top card)
            Positioned(
              top: 180,
              right: 0,
              child: Container(
                width: 30,
                height: MediaQuery.of(context).size.height * 0.30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50),
                    bottomLeft: Radius.circular(50),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      Colors.green.withOpacity(0.4),
                      Colors.green.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Right side bottom green glow effect (for bottom card)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 30,
                height: MediaQuery.of(context).size.height * 0.35,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50),
                    bottomLeft: Radius.circular(50),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      Colors.green.withOpacity(0.4),
                      Colors.green.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Countdown overlay
            if (_isCountdownActive)
              GameCountdown(
                player1Name: ref.read(currentTeamPlayersProvider)[0],
                player2Name: ref.read(currentTeamPlayersProvider)[1],
                category: category,
                onCountdownComplete: _onCountdownComplete,
              ),
          ],
        ),
      ),
    );
  }
}
