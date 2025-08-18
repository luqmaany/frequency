import 'dart:async';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game_state_provider.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';

mixin GameMechanicsMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  late int _timeLeft;
  late int _skipsLeft;
  int _correctCount = 0;
  Timer? _timer;
  List<Word> _currentWords = [];
  Set<String> _usedWords = {};
  List<String> _wordsGuessed = [];
  List<String> _wordsSkipped = [];
  Set<String> _disputedWords = {};

  // Getters for accessing the state
  int get timeLeft => _timeLeft;
  int get skipsLeft => _skipsLeft;
  int get correctCount => _correctCount;
  List<Word> get currentWords => _currentWords;
  List<String> get wordsGuessed => _wordsGuessed;
  List<String> get wordsSkipped => _wordsSkipped;
  Set<String> get disputedWords => _disputedWords;

  // Abstract methods that must be implemented by the using class
  String get categoryId;
  void onTurnEnd();
  void onWordGuessed(String word);
  void onWordSkipped(String word);

  // Initialize game mechanics
  void initializeGameMechanics(int roundTimeSeconds, int allowedSkips) {
    _timeLeft = roundTimeSeconds;
    _skipsLeft = allowedSkips;
    _correctCount = 0;
    _currentWords = [];
    _usedWords = {};
    _wordsGuessed = [];
    _wordsSkipped = [];
    _disputedWords = {};
  }

  // Start the game timer
  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _endTurn();
      }
    });
  }

  // Pause the game timer
  void pauseTimer() {
    _timer?.cancel();
  }

  // Resume the game timer
  void resumeTimer() {
    if (_timer == null || !_timer!.isActive) {
      startTimer();
    }
  }

  // End the current turn
  void _endTurn() {
    _timer?.cancel();
    try {
      // Avoid direct provider usage here since mixin lacks ref. Consumers can call playTurnEnd in onTurnEnd.
    } catch (_) {}
    onTurnEnd();
  }

  // Handle word guessed
  void handleWordGuessed(String word) {
    setState(() {
      _correctCount++;
      _wordsGuessed.add(word);
    });
    onWordGuessed(word);
  }

  // Handle word skipped
  void handleWordSkipped(String word) {
    if (_skipsLeft > 0) {
      setState(() {
        _skipsLeft--;
        _wordsSkipped.add(word);
      });
      // Increment skip count for the word
      ref.read(categoryProvider.notifier).incrementWordSkip(categoryId, word);
      onWordSkipped(word);
    }
  }

  // Increment word appearance count
  void incrementWordAppearance(Word word) {
    ref
        .read(categoryProvider.notifier)
        .incrementWordAppearance(categoryId, word.text);
  }

  // Increment word guessed count
  void incrementWordGuessed(Word word) {
    ref
        .read(categoryProvider.notifier)
        .incrementWordGuessed(categoryId, word.text);
  }

  // Load initial words for the game
  void loadInitialWords() {
    final categories = ref.read(categoryProvider);
    final category = categories[categoryId];
    if (category == null) return;

    final categoryWords = category.words;

    if (categoryWords.isEmpty) {
      return;
    }

    // Get two random words from the category that haven't been used in this game
    final gameUsedWords = ref.read(gameStateProvider.notifier).gameUsedWords;
    final unusedCategoryWords = categoryWords
        .where((word) => !gameUsedWords.contains(word.text))
        .toList();

    if (unusedCategoryWords.isEmpty) {
      // If no unused words available, end the turn immediately
      Future.microtask(() {
        _endTurn();
      });
      return;
    }

    // Get two random words from the unused category words
    unusedCategoryWords.shuffle();
    _currentWords = unusedCategoryWords.take(2).toList();
    _usedWords.addAll(_currentWords.map((w) => w.text));

    // Add to global game used words
    ref
        .read(gameStateProvider.notifier)
        .addUsedWords(_currentWords.map((w) => w.text).toList());

    // Defer appearance count updates until after build
    Future.microtask(() {
      for (final word in _currentWords) {
        incrementWordAppearance(word);
      }
    });
  }

  // Get next word for a category
  Word? getNextWord(String categoryId) {
    final categories = ref.read(categoryProvider);
    final category = categories[categoryId];
    if (category == null) return null;

    final gameUsedWords = ref.read(gameStateProvider.notifier).gameUsedWords;

    // Get words that haven't been used in this game yet
    final categoryWords = category.words
        .where((word) => !gameUsedWords.contains(word.text))
        .toList();

    if (categoryWords.isEmpty) {
      // If we've used all words in this category for this game, return null
      // This will prevent the game from continuing with repeated words
      return null;
    }

    categoryWords.shuffle();
    return categoryWords.first;
  }

  // Load new word at specific index
  void loadNewWord(int index) {
    final newWord = getNextWord(categoryId);
    if (newWord != null) {
      setState(() {
        _currentWords[index] = newWord;
        _usedWords.add(newWord.text);
      });

      // Add to global game used words
      ref.read(gameStateProvider.notifier).addUsedWords([newWord.text]);

      // Defer appearance count update until after build
      Future.microtask(() {
        incrementWordAppearance(newWord);
      });
    } else {
      // No more words available - end the turn
      _endTurn();
    }
  }

  // Clean up resources
  void disposeGameMechanics() {
    _timer?.cancel();
  }

  // Get allowed swipe direction based on skips left
  AllowedSwipeDirection getAllowedSwipeDirection() {
    if (_skipsLeft > 0) {
      return const AllowedSwipeDirection.symmetric(
          horizontal: true, vertical: false);
    } else {
      // Only allow right swipes when no skips are left
      return const AllowedSwipeDirection.only(right: true);
    }
  }
}
