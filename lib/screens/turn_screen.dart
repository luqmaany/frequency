import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'dart:async';
import 'dart:math' as math;
import 'word_lists_manager_screen.dart';
import '../services/game_setup_provider.dart';
import '../services/game_state_provider.dart';
import '../models/game_state.dart';
import 'game_over_screen.dart';
import 'role_assignment_screen.dart';

class TurnScreen extends ConsumerStatefulWidget {
  final int teamIndex;
  final int roundNumber;
  final int turnNumber;
  final WordCategory category;

  const TurnScreen({
    super.key,
    required this.teamIndex,
    required this.roundNumber,
    required this.turnNumber,
    required this.category,
  });

  @override
  ConsumerState<TurnScreen> createState() => _TurnScreenState();
}

class _TurnScreenState extends ConsumerState<TurnScreen> {
  late int _timeLeft;
  late int _skipsLeft;
  int _correctCount = 0;
  Timer? _timer;
  bool _isTurnOver = false;
  List<Word> _currentWords = [];
  Set<String> _usedWords = {};
  final math.Random _random = math.Random();
  final CardSwiperController _topCardController = CardSwiperController();
  final CardSwiperController _bottomCardController = CardSwiperController();
  List<String> _wordsGuessed = [];
  List<String> _wordsSkipped = [];

  @override
  void initState() {
    super.initState();
    final gameConfig = ref.read(gameSetupProvider);
    _timeLeft = gameConfig.roundTimeSeconds;
    _skipsLeft = gameConfig.allowedSkips;
    _startTimer();
    _loadInitialWords();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _topCardController.dispose();
    _bottomCardController.dispose();
    super.dispose();
  }

  void _startTimer() {
    debugPrint('Starting timer for round ${widget.roundNumber}, turn ${widget.turnNumber}');
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
          if (_timeLeft % 5 == 0) {  // Print every 5 seconds
            debugPrint('Time left: $_timeLeft seconds');
          }
        } else {
          debugPrint('Timer reached zero, ending turn');
          _endTurn();
        }
      });
    });
  }

  void _endTurn() {
    debugPrint('\n=== TURN ENDED ===');
    debugPrint('Round ${widget.roundNumber}, Turn ${widget.turnNumber}');
    debugPrint('Final Score: $_correctCount');
    debugPrint('Skips Remaining: $_skipsLeft');
    
    _timer?.cancel();
    setState(() {
      _isTurnOver = true;
    });

    // Record the turn in game state
    final currentTeamPlayers = ref.read(currentTeamPlayersProvider);
    if (currentTeamPlayers.length >= 2) {
      final turnRecord = TurnRecord(
        teamIndex: widget.teamIndex,
        roundNumber: widget.roundNumber,
        turnNumber: widget.turnNumber,
        conveyor: currentTeamPlayers[0],
        guesser: currentTeamPlayers[1],
        category: widget.category.toString(),
        score: _correctCount,
        skipsUsed: ref.read(gameSetupProvider).allowedSkips - _skipsLeft,
        wordsGuessed: _wordsGuessed,
        wordsSkipped: _wordsSkipped,
      );

      ref.read(gameStateProvider.notifier).recordTurn(turnRecord);
      
      // Log detailed score information with a small delay to ensure visibility
      Future.delayed(const Duration(milliseconds: 100), () {
        final gameState = ref.read(gameStateProvider);
        if (gameState != null) {
          debugPrint('\n=== Turn ${widget.turnNumber} Results ===');
          debugPrint('Team ${widget.teamIndex + 1} Turn Details:');
          debugPrint('- Correct Guesses: $_correctCount');
          debugPrint('- Skips Used: ${ref.read(gameSetupProvider).allowedSkips - _skipsLeft}');
          debugPrint('- Words Guessed: ${_wordsGuessed.join(", ")}');
          debugPrint('- Words Skipped: ${_wordsSkipped.join(", ")}');
          debugPrint('\nCurrent Team Scores:');
          for (var i = 0; i < gameState.teamScores.length; i++) {
            debugPrint('Team ${i + 1}: ${gameState.teamScores[i]} points');
          }
          debugPrint('===========================\n');
        }
      });
    }
  }

  void _onWordGuessed(String word) {
    setState(() {
      _correctCount++;
      _wordsGuessed.add(word);
    });
  }

  void _onWordSkipped(String word) {
    if (_skipsLeft > 0) {
      setState(() {
        _skipsLeft--;
        _wordsSkipped.add(word);
      });
    }
  }

  void _incrementWordUsage(Word word) {
    final words = ref.read(wordsProvider);
    final updatedWords = words.map((w) {
      if (w.text == word.text) {
        return Word(
          text: w.text,
          category: w.category,
          usageCount: w.usageCount + 1,
        );
      }
      return w;
    }).toList();
    ref.read(wordsProvider.notifier).state = updatedWords;
  }

  void _loadInitialWords() {
    final words = ref.read(wordsProvider);
    final categoryWords = words.where((word) => word.category == widget.category).toList();
    
    if (categoryWords.isEmpty) {
      setState(() {
        _isTurnOver = true;
      });
      return;
    }
    
    // Get two random words from the category
    categoryWords.shuffle();
    _currentWords = categoryWords.take(2).toList();
    _usedWords.addAll(_currentWords.map((w) => w.text));
  }

  Word? _getNextWord(WordCategory category) {
    final words = ref.read(wordsProvider);
    final categoryWords = words.where((word) => 
      word.category == category && !_usedWords.contains(word.text)
    ).toList();
    
    if (categoryWords.isEmpty) {
      // If we've used all words, reset the used words set
      _usedWords.clear();
      return words.firstWhere((word) => word.category == category);
    }
    
    categoryWords.shuffle();
    return categoryWords.first;
  }

  void _loadNewWord(int index) {
    final newWord = _getNextWord(widget.category);
    if (newWord != null) {
      setState(() {
        _currentWords[index] = newWord;
        _usedWords.add(newWord.text);
      });
    }
  }

  String _getCategoryName(WordCategory category) {
    switch (category) {
      case WordCategory.person:
        return 'Person';
      case WordCategory.action:
        return 'Action';
      case WordCategory.world:
        return 'World';
      case WordCategory.random:
        return 'Random';
    }
  }

  Widget _buildCard(Word word) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Text(
          word.text,
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final isGameOver = ref.watch(isGameOverProvider);

    if (isGameOver) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Game Over!',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 20),
              Text(
                'Final Scores:',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              ...gameState!.teamScores.asMap().entries.map((entry) {
                final teamIndex = entry.key;
                final score = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Team ${teamIndex + 1}: $score points',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                );
              }),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  ref.read(gameStateProvider.notifier).resetGame();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('New Game'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isTurnOver) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Turn Over!',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 20),
              Text(
                'Correct Guesses: $_correctCount',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  final gameState = ref.read(gameStateProvider);
                  if (gameState == null) {
                    // If no game state, go back to home
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    return;
                  }

                  // Navigate to next team's turn or end game
                  if (gameState.isGameOver) {
                    // Navigate to game over screen
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const GameOverScreen(),
                      ),
                    );
                  } else {
                    // Navigate to next team's turn
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => RoleAssignmentScreen(
                          teamIndex: gameState.currentTeamIndex,
                          roundNumber: gameState.currentRound,
                          turnNumber: gameState.currentTurn,
                          category: widget.category,
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Next Turn'),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentWords.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Title showing current players
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "${ref.read(currentTeamPlayersProvider)[0]} & ${ref.read(currentTeamPlayersProvider)[1]}'s Turn",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // Top bar with timer, skips, and category
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Score indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      'Score: $_correctCount',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Category indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Category: ${_getCategoryName(widget.category)}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Timer and skips
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Timer
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$_timeLeft s',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      // Skip counter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Skips: $_skipsLeft',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Word cards with Swiper
            Expanded(
              child: Column(
                children: [
                  // Top card
                  Expanded(
                    child: CardSwiper(
                      controller: _topCardController,
                      cardsCount: 1,
                      cardBuilder: (context, index, horizontalThresholdPercentage, verticalThresholdPercentage) {
                        return _buildCard(_currentWords[0]);
                      },
                      onSwipe: (previousIndex, currentIndex, direction) {
                        if (direction == CardSwiperDirection.right) {
                          // Correct guess
                          _onWordGuessed(_currentWords[0].text);
                          _incrementWordUsage(_currentWords[0]);
                          _loadNewWord(0);
                          return true;
                        } else if (direction == CardSwiperDirection.left) {
                          // Skip
                          _onWordSkipped(_currentWords[0].text);
                          if (_skipsLeft > 0) {
                            setState(() {
                              _loadNewWord(0);
                            });
                            return true;
                          } else {
                            // Show feedback for no skips left
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('No skips left!'),
                                backgroundColor: Theme.of(context).colorScheme.error,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        }
                        return false;
                      },
                      allowedSwipeDirection: AllowedSwipeDirection.symmetric(horizontal: true, vertical: false),
                      numberOfCardsDisplayed: 1,
                      padding: const EdgeInsets.all(24.0),
                    ),
                  ),
                  // Bottom card
                  Expanded(
                    child: CardSwiper(
                      controller: _bottomCardController,
                      cardsCount: 1,
                      cardBuilder: (context, index, horizontalThresholdPercentage, verticalThresholdPercentage) {
                        return _buildCard(_currentWords[1]);
                      },
                      onSwipe: (previousIndex, currentIndex, direction) {
                        if (direction == CardSwiperDirection.right) {
                          // Correct guess
                          _onWordGuessed(_currentWords[1].text);
                          _incrementWordUsage(_currentWords[1]);
                          _loadNewWord(1);
                          return true;
                        } else if (direction == CardSwiperDirection.left) {
                          // Skip
                          _onWordSkipped(_currentWords[1].text);
                          if (_skipsLeft > 0) {
                            setState(() {
                              _loadNewWord(1);
                            });
                            return true;
                          } else {
                            // Show feedback for no skips left
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('No skips left!'),
                                backgroundColor: Theme.of(context).colorScheme.error,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        }
                        return false;
                      },
                      allowedSwipeDirection: AllowedSwipeDirection.symmetric(horizontal: true, vertical: false),
                      numberOfCardsDisplayed: 1,
                      padding: const EdgeInsets.all(24.0),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 