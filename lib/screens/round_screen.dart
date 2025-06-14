import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'dart:async';
import 'dart:math' as math;
import 'word_lists_manager_screen.dart';

class RoundScreen extends ConsumerStatefulWidget {
  final int teamIndex;
  final int roundNumber;
  final int turnNumber;
  final WordCategory category;

  const RoundScreen({
    super.key,
    required this.teamIndex,
    required this.roundNumber,
    required this.turnNumber,
    required this.category,
  });

  @override
  ConsumerState<RoundScreen> createState() => _RoundScreenState();
}

class _RoundScreenState extends ConsumerState<RoundScreen> {
  int _timeLeft = 60; // Default 60 seconds
  int _skipsLeft = 2; // Default 2 skips
  int _correctCount = 0;
  Timer? _timer;
  bool _isRoundOver = false;
  List<Word> _currentWords = [];
  Set<String> _usedWords = {}; // Track used words
  final math.Random _random = math.Random();
  final CardSwiperController _topCardController = CardSwiperController();
  final CardSwiperController _bottomCardController = CardSwiperController();

  @override
  void initState() {
    super.initState();
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
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _endRound();
        }
      });
    });
  }

  void _endRound() {
    _timer?.cancel();
    setState(() {
      _isRoundOver = true;
    });
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
        _isRoundOver = true;
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
    if (_isRoundOver) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Round Over!',
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
                  // TODO: Navigate to scoreboard screen
                },
                child: const Text('Next Round'),
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
                          setState(() {
                            _correctCount++;
                            _incrementWordUsage(_currentWords[0]);
                            _loadNewWord(0);
                          });
                          return true;
                        } else if (direction == CardSwiperDirection.left) {
                          // Skip
                          if (_skipsLeft > 0) {
                            setState(() {
                              _skipsLeft--;
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
                          setState(() {
                            _correctCount++;
                            _incrementWordUsage(_currentWords[1]);
                            _loadNewWord(1);
                          });
                          return true;
                        } else if (direction == CardSwiperDirection.left) {
                          // Skip
                          if (_skipsLeft > 0) {
                            setState(() {
                              _skipsLeft--;
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
            // Instructions
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildInstruction('← Skip', _skipsLeft > 0 ? Colors.orange : Colors.grey),
                  _buildInstruction('→ Correct', Colors.green),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction(String text, Color color) {
    return Row(
      children: [
        Icon(Icons.arrow_forward, color: color),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
} 