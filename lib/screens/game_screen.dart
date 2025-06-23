import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'dart:async';
import 'word_lists_manager_screen.dart';
import '../services/game_setup_provider.dart';
import '../services/game_state_provider.dart';
import '../models/game_state.dart';
import 'game_over_screen.dart';
import 'category_selection_screen.dart';
import 'scoreboard_screen.dart';
import 'turn_over_screen.dart';

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
    with TickerProviderStateMixin {
  late int _timeLeft;
  late int _skipsLeft;
  int _correctCount = 0;
  Timer? _timer;
  bool _isTurnOver = false;
  List<Word> _currentWords = [];
  Set<String> _usedWords = {};
  final CardSwiperController _topCardController = CardSwiperController();
  final CardSwiperController _bottomCardController = CardSwiperController();
  List<String> _wordsGuessed = [];
  List<String> _wordsSkipped = [];
  Set<String> _disputedWords = {};

  // Animation controllers for fade-in effects
  late AnimationController _topCardAnimationController;
  late AnimationController _bottomCardAnimationController;
  late Animation<double> _topCardAnimation;
  late Animation<double> _bottomCardAnimation;

  @override
  void initState() {
    super.initState();
    final gameConfig = ref.read(gameSetupProvider);
    _timeLeft = gameConfig.roundTimeSeconds;
    _skipsLeft = gameConfig.allowedSkips;

    // Initialize animation controllers
    _topCardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _bottomCardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _topCardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _topCardAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _bottomCardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _bottomCardAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _startTimer();
    _loadInitialWords();

    // Start initial fade-in animations
    _topCardAnimationController.forward();
    _bottomCardAnimationController.forward();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _topCardController.dispose();
    _bottomCardController.dispose();
    _topCardAnimationController.dispose();
    _bottomCardAnimationController.dispose();
    super.dispose();
  }

  void _startTimer() {
    debugPrint(
        'Starting timer for round ${widget.roundNumber}, turn ${widget.turnNumber}');
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
          if (_timeLeft % 5 == 0) {
            // Print every 5 seconds
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
    debugPrint('Final Score: ${_correctCount - _disputedWords.length}');
    debugPrint('Skips Remaining: $_skipsLeft');

    _timer?.cancel();
    setState(() {
      _isTurnOver = true;
    });

    // Navigate to TurnOverScreen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => TurnOverScreen(
          teamIndex: widget.teamIndex,
          roundNumber: widget.roundNumber,
          turnNumber: widget.turnNumber,
          category: widget.category,
          correctCount: _correctCount,
          skipsLeft: _skipsLeft,
          wordsGuessed: _wordsGuessed,
          wordsSkipped: _wordsSkipped,
          disputedWords: _disputedWords,
        ),
      ),
    );

    // Log detailed score information with a small delay to ensure visibility
    Future.delayed(const Duration(milliseconds: 100), () {
      final gameState = ref.read(gameStateProvider);
      if (gameState != null) {
        debugPrint('\n=== Turn ${widget.turnNumber} Results ===');
        debugPrint('Team ${widget.teamIndex + 1} Turn Details:');
        debugPrint(
            '- Correct Guesses: ${_correctCount - _disputedWords.length}');
        debugPrint('- Disputed Words: ${_disputedWords.join(", ")}');
        debugPrint(
            '- Skips Used: ${ref.read(gameSetupProvider).allowedSkips - _skipsLeft}');
        debugPrint(
            '- Words Guessed: ${_wordsGuessed.where((word) => !_disputedWords.contains(word)).join(", ")}');
        debugPrint('- Words Skipped: ${_wordsSkipped.join(", ")}');
        debugPrint('\nCurrent Team Scores:');
        for (var i = 0; i < gameState.teamScores.length; i++) {
          debugPrint('Team ${i + 1}: ${gameState.teamScores[i]} points');
        }
        debugPrint('===========================\n');
      }
    });
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
    ref.read(wordsProvider.notifier).updateWords(updatedWords);
  }

  void _loadInitialWords() {
    final words = ref.read(wordsProvider);
    final categoryWords =
        words.where((word) => word.category == widget.category).toList();

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
    final categoryWords = words
        .where((word) =>
            word.category == category && !_usedWords.contains(word.text))
        .toList();

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

      // Trigger fade-in animation for the new card
      if (index == 0) {
        _topCardAnimationController.reset();
        _topCardAnimationController.forward();
      } else {
        _bottomCardAnimationController.reset();
        _bottomCardAnimationController.forward();
      }
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

  AllowedSwipeDirection _getAllowedSwipeDirection() {
    if (_skipsLeft > 0) {
      return AllowedSwipeDirection.symmetric(horizontal: true, vertical: false);
    } else {
      // Only allow right swipes when no skips are left
      return AllowedSwipeDirection.only(right: true);
    }
  }

  Widget _buildCard(Word word) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 2,
        ),
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
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
            ),
            // Top bar with timer, skips, and category
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  // Timer - on the left
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '$_timeLeft',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 36,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Right side - stacked category, score, and skips
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        // Category
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getCategoryName(widget.category),
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Skips
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Skips: $_skipsLeft',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Word cards with Swiper
            Expanded(
              child: Stack(
                children: [
                  Column(
                    children: [
                      // Top card
                      Expanded(
                        child: AnimatedBuilder(
                          animation: _topCardAnimation,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _topCardAnimation.value,
                              child: CardSwiper(
                                controller: _topCardController,
                                cardsCount: 1,
                                cardBuilder: (context,
                                    index,
                                    horizontalThresholdPercentage,
                                    verticalThresholdPercentage) {
                                  return _buildCard(_currentWords[0]);
                                },
                                onSwipe:
                                    (previousIndex, currentIndex, direction) {
                                  if (direction == CardSwiperDirection.right) {
                                    // Correct guess
                                    _onWordGuessed(_currentWords[0].text);
                                    _incrementWordUsage(_currentWords[0]);
                                    _loadNewWord(0);
                                    return true;
                                  } else if (direction ==
                                      CardSwiperDirection.left) {
                                    // Skip
                                    if (_skipsLeft > 0) {
                                      _onWordSkipped(_currentWords[0].text);
                                      setState(() {
                                        _loadNewWord(0);
                                      });
                                      return true;
                                    } else {
                                      // Prevent the swipe and show feedback
                                      return false;
                                    }
                                  }
                                  return false;
                                },
                                allowedSwipeDirection:
                                    _getAllowedSwipeDirection(),
                                numberOfCardsDisplayed: 1,
                                padding: const EdgeInsets.all(24.0),
                              ),
                            );
                          },
                        ),
                      ),
                      // Bottom card
                      Expanded(
                        child: AnimatedBuilder(
                          animation: _bottomCardAnimation,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _bottomCardAnimation.value,
                              child: CardSwiper(
                                controller: _bottomCardController,
                                cardsCount: 1,
                                cardBuilder: (context,
                                    index,
                                    horizontalThresholdPercentage,
                                    verticalThresholdPercentage) {
                                  return _buildCard(_currentWords[1]);
                                },
                                onSwipe:
                                    (previousIndex, currentIndex, direction) {
                                  if (direction == CardSwiperDirection.right) {
                                    // Correct guess
                                    _onWordGuessed(_currentWords[1].text);
                                    _incrementWordUsage(_currentWords[1]);
                                    _loadNewWord(1);
                                    return true;
                                  } else if (direction ==
                                      CardSwiperDirection.left) {
                                    // Skip
                                    if (_skipsLeft > 0) {
                                      _onWordSkipped(_currentWords[1].text);
                                      setState(() {
                                        _loadNewWord(1);
                                      });
                                      return true;
                                    } else {
                                      // Prevent the swipe and show feedback
                                      return false;
                                    }
                                  }
                                  return false;
                                },
                                allowedSwipeDirection:
                                    _getAllowedSwipeDirection(),
                                numberOfCardsDisplayed: 1,
                                padding: const EdgeInsets.all(24.0),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  // Skip icon positioned between cards on the left
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: const Text(
                        '🚫',
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  // Tick icon positioned between cards on the right
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: const Text(
                        '✔️',
                        style: const TextStyle(fontSize: 24),
                      ),
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
