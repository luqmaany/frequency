import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  WordCategory _currentCategory = WordCategory.person; // Default value

  @override
  WordCategory get category => _currentCategory;

  @override
  void onTurnEnd() {
    // Use navigation service to navigate to turn over screen
    GameNavigationService.navigateToTurnOver(
      context,
      widget.teamIndex,
      widget.roundNumber,
      widget.turnNumber,
      _currentCategory,
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
    // Start with the widget category
    _currentCategory = widget.category;

    final gameConfig = ref.read(gameSetupProvider);
    initializeGameMechanics(
        gameConfig.roundTimeSeconds, gameConfig.allowedSkips);
    loadInitialWords();

    // Countdown will start automatically and call _onCountdownComplete when done
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Update the category based on tiebreaker status after dependencies are available
    final isTiebreaker = ref.watch(isTiebreakerRoundProvider);
    final tiebreakerCategory = ref.watch(tiebreakerCategoryProvider);

    if (isTiebreaker && tiebreakerCategory != null) {
      _currentCategory = tiebreakerCategory;
    } else {
      _currentCategory = widget.category;
    }
  }

  @override
  void dispose() {
    disposeGameMechanics();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _isCountdownActive = false;
    });
    startTimer();
  }

  void _onCountdownComplete() {
    _startGame();
  }

  @override
  Widget build(BuildContext context) {
    if (currentWords.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show countdown overlay
    if (_isCountdownActive) {
      final currentTeamPlayers = ref.read(currentTeamPlayersProvider);
      return GameCountdown(
        player1Name: currentTeamPlayers[0],
        player2Name: currentTeamPlayers[1],
        category: category,
        onCountdownComplete: _onCountdownComplete,
      );
    }

    final isTiebreaker = ref.watch(isTiebreakerRoundProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Tiebreaker indicator
            if (isTiebreaker)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange, width: 2),
                ),
                child: Text(
                  '🏆 TIEBREAKER ROUND 🏆',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),

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
              isTiebreaker: isTiebreaker,
            ),

            // Word cards with swiping mechanics
            Expanded(
              child: GameCards(
                currentWords: currentWords,
                category: category,
                skipsLeft: skipsLeft,
                onWordGuessed: (word) {
                  handleWordGuessed(word);
                  // Find the word object and increment usage
                  final wordObj =
                      currentWords.firstWhere((w) => w.text == word);
                  incrementWordUsage(wordObj);
                },
                onWordSkipped: (word) {
                  handleWordSkipped(word);
                },
                onLoadNewWord: (index) {
                  // Load new word for the specific card that was swiped
                  loadNewWord(index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
