import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:math' as math;
import 'category_selection_screen.dart' as category_screen;
import 'word_lists_manager_screen.dart';

class RoundScreen extends ConsumerStatefulWidget {
  final int teamIndex;
  final int roundNumber;
  final int turnNumber;
  final category_screen.WordCategory category;

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
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _startTimer();
    _loadNewWords();
  }

  @override
  void dispose() {
    _timer?.cancel();
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

  void _handleSwipe(DragEndDetails details) {
    if (_isRoundOver) return;

    final velocity = details.primaryVelocity ?? 0;
    if (velocity > 0) {
      // Swipe right - Correct
      setState(() {
        _correctCount++;
        _incrementWordUsage(_currentWords[0]);
        _loadNewWords();
      });
    } else if (velocity < 0) {
      // Swipe left - Skip
      if (_skipsLeft > 0) {
        setState(() {
          _skipsLeft--;
          _loadNewWords();
        });
      }
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

  void _loadNewWords() {
    final words = ref.read(wordsProvider);
    final categoryWords = words.where((word) => word.category == widget.category).toList();
    
    if (categoryWords.length < 2) {
      // If we don't have enough words in the category, use random words
      final allWords = words.toList()..shuffle();
      _currentWords = allWords.take(2).toList();
    } else {
      // Get two random words from the category
      categoryWords.shuffle();
      _currentWords = categoryWords.take(2).toList();
    }
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
            // Top bar with timer and skips
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
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
            ),
            // Word cards
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: _handleSwipe,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Top card
                    Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: MediaQuery.of(context).size.height * 0.25,
                      margin: const EdgeInsets.only(bottom: 20),
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
                          _currentWords[0].text,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                    ),
                    // Bottom card
                    Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: MediaQuery.of(context).size.height * 0.25,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _currentWords[1].text,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                    ),
                  ],
                ),
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