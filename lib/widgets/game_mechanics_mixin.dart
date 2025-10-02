import 'dart:async';
import 'dart:math';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game_state_provider.dart';
import '../services/game_setup_provider.dart';
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
  Map<String, DateTime> _wordLoadTimes = {}; // Track when each word was loaded
  Map<String, double> _finalWordTimings =
      {}; // Store finalized durations at action time

  // Getters for accessing the state
  int get timeLeft => _timeLeft;
  int get skipsLeft => _skipsLeft;
  int get correctCount => _correctCount;
  List<Word> get currentWords => _currentWords;
  List<String> get wordsGuessed => _wordsGuessed;
  List<String> get wordsSkipped => _wordsSkipped;
  Set<String> get disputedWords => _disputedWords;

  // Build final word timings map (word -> seconds visible before action)
  Map<String, double> get wordTimings {
    // Start with finalized timings captured at action moments
    final timings = Map<String, double>.from(_finalWordTimings);
    final now = DateTime.now();

    // Add timings for words left on screen (compute at end)
    for (final word in _currentWords) {
      if (_wordLoadTimes.containsKey(word.text) &&
          !timings.containsKey(word.text)) {
        timings[word.text] =
            now.difference(_wordLoadTimes[word.text]!).inMilliseconds / 1000.0;
      }
    }

    return timings;
  }

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
    _wordLoadTimes = {};
    _finalWordTimings = {};
  }

  // Reset word timings (called when countdown ends and gameplay actually starts)
  void resetWordTimings() {
    final now = DateTime.now();
    for (final word in _currentWords) {
      _wordLoadTimes[word.text] = now;
    }
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
    // Capture timing at the moment of guess
    if (_wordLoadTimes.containsKey(word)) {
      final seconds =
          DateTime.now().difference(_wordLoadTimes[word]!).inMilliseconds /
              1000.0;
      _finalWordTimings[word] = seconds;
    }
    setState(() {
      _correctCount++;
      _wordsGuessed.add(word);
    });
    onWordGuessed(word);
  }

  // Handle word skipped
  void handleWordSkipped(String word) {
    if (_skipsLeft > 0) {
      // Capture timing at the moment of skip
      if (_wordLoadTimes.containsKey(word)) {
        final seconds =
            DateTime.now().difference(_wordLoadTimes[word]!).inMilliseconds /
                1000.0;
        _finalWordTimings[word] = seconds;
      }
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

    // Get two random words from the category that haven't been used in this category
    final categoryUsedWords =
        ref.read(gameStateProvider.notifier).getCategoryUsedWords(categoryId);
    final unusedCategoryWords = categoryWords
        .where((word) => !categoryUsedWords.contains(word.text))
        .toList();

    if (unusedCategoryWords.isEmpty) {
      // If no unused words available, end the turn immediately
      Future.microtask(() {
        _endTurn();
      });
      return;
    }

    // Get two words using weighted selection (if enabled) to favor words with fewer appearances
    final gameConfig = ref.read(gameSetupProvider);
    final selectedWords = <Word>[];

    if (gameConfig.useWeightedWordSelection) {
      // Use weighted selection
      for (int i = 0; i < 2 && unusedCategoryWords.isNotEmpty; i++) {
        final selectedWord = _selectWordWithWeights(unusedCategoryWords);
        if (selectedWord != null) {
          selectedWords.add(selectedWord);
          // Remove the selected word from the pool to avoid duplicates
          unusedCategoryWords.removeWhere((w) => w.text == selectedWord.text);
        }
      }
    } else {
      // Use traditional random selection
      unusedCategoryWords.shuffle();
      selectedWords.addAll(unusedCategoryWords.take(2));
    }

    _currentWords = selectedWords;
    _usedWords.addAll(_currentWords.map((w) => w.text));

    // Add to category-specific used words
    ref
        .read(gameStateProvider.notifier)
        .addUsedWords(categoryId, _currentWords.map((w) => w.text).toList());

    // Defer appearance count updates until after build
    Future.microtask(() {
      for (final word in _currentWords) {
        incrementWordAppearance(word);
      }
    });
  }

  // Get next word for a category using weighted selection
  Word? getNextWord(String categoryId) {
    final categories = ref.read(categoryProvider);
    final category = categories[categoryId];
    if (category == null) return null;

    final categoryUsedWords =
        ref.read(gameStateProvider.notifier).getCategoryUsedWords(categoryId);

    // Get words that haven't been used in this category yet
    final categoryWords = category.words
        .where((word) => !categoryUsedWords.contains(word.text))
        .toList();

    if (categoryWords.isEmpty) {
      // If we've used all words in this category for this game, return null
      // This will prevent the game from continuing with repeated words
      return null;
    }

    // Use weighted selection (if enabled) to favor words with fewer appearances
    final gameConfig = ref.read(gameSetupProvider);
    if (gameConfig.useWeightedWordSelection) {
      return _selectWordWithWeights(categoryWords);
    } else {
      // Use traditional random selection
      categoryWords.shuffle();
      return categoryWords.first;
    }
  }

  // Load new word at specific index
  void loadNewWord(int index) {
    final newWord = getNextWord(categoryId);
    if (newWord != null) {
      setState(() {
        _currentWords[index] = newWord;
        _usedWords.add(newWord.text);
      });

      // Track when this word was loaded
      _wordLoadTimes[newWord.text] = DateTime.now();

      // Add to category-specific used words
      ref
          .read(gameStateProvider.notifier)
          .addUsedWords(categoryId, [newWord.text]);

      // Defer appearance count update until after build
      Future.microtask(() {
        incrementWordAppearance(newWord);
      });
    } else {
      // No more words available - end the turn
      _endTurn();
    }
  }

  // Helper method to select a word using weighted random selection
  // Words with fewer appearances have higher probability of being selected
  Word? _selectWordWithWeights(List<Word> words) {
    if (words.isEmpty) return null;
    if (words.length == 1) return words.first;

    // Calculate weights (inverse of appearance count + 1 to avoid division by zero)
    final weights = words.map((word) => _calculateWordWeight(word)).toList();
    final totalWeight = weights.fold(0.0, (sum, weight) => sum + weight);

    if (totalWeight == 0) {
      // Fallback to random selection if all weights are zero
      words.shuffle();
      return words.first;
    }

    // Generate random number between 0 and totalWeight
    final random = Random();
    final randomValue = random.nextDouble() * totalWeight;

    // Find the word corresponding to this random value
    double cumulativeWeight = 0.0;
    for (int i = 0; i < words.length; i++) {
      cumulativeWeight += weights[i];
      if (randomValue <= cumulativeWeight) {
        return words[i];
      }
    }

    // Fallback (should not reach here, but just in case)
    return words.last;
  }

  // Calculate weight for a word (higher weight = higher probability)
  // Uses inverse relationship: fewer appearances = higher weight
  double _calculateWordWeight(Word word) {
    final appearanceCount = word.stats.appearanceCount;

    // Base weight calculation: 1 / (appearances + 1)
    // +1 to avoid division by zero and give new words the highest weight
    final baseWeight = 1.0 / (appearanceCount + 1);

    // Apply exponential scaling to make the difference more pronounced
    // Words with 0 appearances get weight ~2.0
    // Words with 1 appearance get weight ~1.0
    // Words with 5+ appearances get weight ~0.16 or less
    return baseWeight * 2.0;
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
