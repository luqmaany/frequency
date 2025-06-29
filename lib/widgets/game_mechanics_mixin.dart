import 'dart:async';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/word_lists_manager_screen.dart';

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
  WordCategory get category;
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

  // End the current turn
  void _endTurn() {
    _timer?.cancel();
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
      onWordSkipped(word);
    }
  }

  // Increment word usage count
  void incrementWordUsage(Word word) {
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

  // Load initial words for the game
  void loadInitialWords() {
    final words = ref.read(wordsProvider);
    final categoryWords =
        words.where((word) => word.category == category).toList();

    if (categoryWords.isEmpty) {
      return;
    }

    // Get two random words from the category
    categoryWords.shuffle();
    _currentWords = categoryWords.take(2).toList();
    _usedWords.addAll(_currentWords.map((w) => w.text));
  }

  // Get next word for a category
  Word? getNextWord(WordCategory category) {
    final words = ref.read(wordsProvider);
    final categoryWords = words
        .where((word) =>
            word.category == category && !_usedWords.contains(word.text))
        .toList();

    if (categoryWords.isEmpty) {
      // If we've used all words, reset the used words set
      _usedWords.clear();
      final availableWords =
          words.where((word) => word.category == category).toList();
      if (availableWords.isNotEmpty) {
        return availableWords.first;
      }
      return null;
    }

    categoryWords.shuffle();
    return categoryWords.first;
  }

  // Load new word at specific index
  void loadNewWord(int index) {
    final newWord = getNextWord(category);
    if (newWord != null) {
      setState(() {
        _currentWords[index] = newWord;
        _usedWords.add(newWord.text);
      });
    }
  }

  // Clean up resources
  void disposeGameMechanics() {
    _timer?.cancel();
  }

  // Get allowed swipe direction based on skips left
  AllowedSwipeDirection getAllowedSwipeDirection() {
    if (_skipsLeft > 0) {
      return AllowedSwipeDirection.symmetric(horizontal: true, vertical: false);
    } else {
      // Only allow right swipes when no skips are left
      return AllowedSwipeDirection.only(right: true);
    }
  }
}
