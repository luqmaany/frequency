import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/category_registry.dart';
import '../models/category.dart';

class CategoryProvider extends StateNotifier<Map<String, Category>> {
  CategoryProvider() : super({}) {
    _initializeCategories();
  }

  void _initializeCategories() {
    // Initialize with all categories from the registry
    state = CategoryRegistry.allCategories;
  }

  // Get a specific category
  Category getCategory(String categoryId) {
    return state[categoryId] ?? CategoryRegistry.getCategory('person');
  }

  // Get all categories
  List<Category> getAllCategories() {
    return state.values.toList();
  }

  // Get words for a specific category
  List<Word> getWordsForCategory(String categoryId) {
    return getCategory(categoryId).words;
  }

  // Get a random word from a category (excluding used words)
  Word? getRandomWord(String categoryId, Set<String> usedWords) {
    return getCategory(categoryId).getRandomWord(usedWords);
  }

  // Get multiple random words from a category
  List<Word> getRandomWords(
      String categoryId, int count, Set<String> usedWords) {
    final category = getCategory(categoryId);
    final unusedWords = category.getUnusedWords(usedWords);
    if (unusedWords.isEmpty) return [];

    unusedWords.shuffle();
    return unusedWords.take(count).toList();
  }

  // Update word stats (appearance, skip, guessed counts)
  void updateWordStats(
    String categoryId,
    String wordText, {
    int? appearanceCount,
    int? skipCount,
    int? guessedCount,
  }) {
    final category = state[categoryId];
    if (category == null) return;

    final updatedWords = category.words.map((word) {
      if (word.text == wordText) {
        return word.copyWith(
          stats: WordStats(
            appearanceCount: appearanceCount ?? word.stats.appearanceCount,
            skipCount: skipCount ?? word.stats.skipCount,
            guessedCount: guessedCount ?? word.stats.guessedCount,
          ),
        );
      }
      return word;
    }).toList();

    final updatedCategory = Category(
      id: category.id,
      displayName: category.displayName,
      color: category.color,
      icon: category.icon,
      description: category.description,
      words: updatedWords,
      type: category.type,
      isUnlocked: category.isUnlocked,
    );

    state = {...state, categoryId: updatedCategory};
  }

  // Increment word appearance count
  void incrementWordAppearance(String categoryId, String wordText) {
    final category = state[categoryId];
    if (category == null) return;

    final word = category.words.firstWhere(
      (w) => w.text == wordText,
      orElse: () => Word(text: wordText, categoryId: categoryId),
    );

    updateWordStats(
      categoryId,
      wordText,
      appearanceCount: word.stats.appearanceCount + 1,
      skipCount: word.stats.skipCount,
      guessedCount: word.stats.guessedCount,
    );
  }

  // Increment word skip count
  void incrementWordSkip(String categoryId, String wordText) {
    final category = state[categoryId];
    if (category == null) return;

    final word = category.words.firstWhere(
      (w) => w.text == wordText,
      orElse: () => Word(text: wordText, categoryId: categoryId),
    );

    updateWordStats(
      categoryId,
      wordText,
      appearanceCount: word.stats.appearanceCount,
      skipCount: word.stats.skipCount + 1,
      guessedCount: word.stats.guessedCount,
    );
  }

  // Increment word guessed count
  void incrementWordGuessed(String categoryId, String wordText) {
    final category = state[categoryId];
    if (category == null) return;

    final word = category.words.firstWhere(
      (w) => w.text == wordText,
      orElse: () => Word(text: wordText, categoryId: categoryId),
    );

    updateWordStats(
      categoryId,
      wordText,
      appearanceCount: word.stats.appearanceCount,
      skipCount: word.stats.skipCount,
      guessedCount: word.stats.guessedCount + 1,
    );
  }

  // Get words sorted by various criteria
  List<Word> getWordsSortedBySkipCount(String categoryId) {
    final words = getWordsForCategory(categoryId);
    final sortedWords = List<Word>.from(words);
    sortedWords.sort((a, b) => b.stats.skipCount.compareTo(a.stats.skipCount));
    return sortedWords;
  }

  List<Word> getWordsSortedByAppearanceCount(String categoryId) {
    final words = getWordsForCategory(categoryId);
    final sortedWords = List<Word>.from(words);
    sortedWords.sort(
        (a, b) => b.stats.appearanceCount.compareTo(a.stats.appearanceCount));
    return sortedWords;
  }

  List<Word> getWordsSortedByGuessedCount(String categoryId) {
    final words = getWordsForCategory(categoryId);
    final sortedWords = List<Word>.from(words);
    sortedWords
        .sort((a, b) => b.stats.guessedCount.compareTo(a.stats.guessedCount));
    return sortedWords;
  }

  List<Word> getWordsSortedByDifficulty(String categoryId) {
    final words = getWordsForCategory(categoryId);
    final sortedWords = List<Word>.from(words);
    sortedWords.sort((a, b) {
      final aTotalAppearances = a.stats.appearanceCount;
      final bTotalAppearances = b.stats.appearanceCount;

      if (aTotalAppearances == 0 && bTotalAppearances == 0) return 0;
      if (aTotalAppearances == 0) return -1;
      if (bTotalAppearances == 0) return 1;

      final aSkipRate = a.stats.skipRate;
      final bSkipRate = b.stats.skipRate;

      return bSkipRate
          .compareTo(aSkipRate); // Higher skip rate = more difficult
    });
    return sortedWords;
  }

  // Add a word to a category
  void addWord(Word word) {
    final category = state[word.categoryId];
    if (category == null) return;

    // Check if word already exists to prevent duplicates
    final existingWord =
        category.words.where((w) => w.text == word.text).firstOrNull;
    if (existingWord != null) {
      // Update the existing word instead of adding a duplicate
      final updatedWords = category.words.map((w) {
        if (w.text == word.text) {
          return Word(
            text: w.text,
            categoryId: word.categoryId, // Use the new category if different
            stats: w.stats,
          );
        }
        return w;
      }).toList();

      final updatedCategory = Category(
        id: category.id,
        displayName: category.displayName,
        color: category.color,
        icon: category.icon,
        description: category.description,
        words: updatedWords,
        type: category.type,
        isUnlocked: category.isUnlocked,
      );

      state = {...state, word.categoryId: updatedCategory};
    } else {
      // Add new word
      final updatedWords = List<Word>.from(category.words)..add(word);
      final updatedCategory = Category(
        id: category.id,
        displayName: category.displayName,
        color: category.color,
        icon: category.icon,
        description: category.description,
        words: updatedWords,
        type: category.type,
        isUnlocked: category.isUnlocked,
      );

      state = {...state, word.categoryId: updatedCategory};
    }
  }

  // Delete a word from a category
  void deleteWord(Word word) {
    final category = state[word.categoryId];
    if (category == null) return;

    final updatedWords =
        category.words.where((w) => w.text != word.text).toList();
    final updatedCategory = Category(
      id: category.id,
      displayName: category.displayName,
      color: category.color,
      icon: category.icon,
      description: category.description,
      words: updatedWords,
      type: category.type,
      isUnlocked: category.isUnlocked,
    );

    state = {...state, word.categoryId: updatedCategory};
  }

  // Reset appearance counts for all words in a category
  void resetAppearanceCounts(String categoryId) {
    final category = state[categoryId];
    if (category == null) return;

    final updatedWords = category.words
        .map((word) => word.copyWith(
              stats: WordStats(
                appearanceCount: 0,
                skipCount: word.stats.skipCount,
                guessedCount: word.stats.guessedCount,
              ),
            ))
        .toList();

    final updatedCategory = Category(
      id: category.id,
      displayName: category.displayName,
      color: category.color,
      icon: category.icon,
      description: category.description,
      words: updatedWords,
      type: category.type,
      isUnlocked: category.isUnlocked,
    );

    state = {...state, categoryId: updatedCategory};
  }

  // Reset skip counts for all words in a category
  void resetSkipCounts(String categoryId) {
    final category = state[categoryId];
    if (category == null) return;

    final updatedWords = category.words
        .map((word) => word.copyWith(
              stats: WordStats(
                appearanceCount: word.stats.appearanceCount,
                skipCount: 0,
                guessedCount: word.stats.guessedCount,
              ),
            ))
        .toList();

    final updatedCategory = Category(
      id: category.id,
      displayName: category.displayName,
      color: category.color,
      icon: category.icon,
      description: category.description,
      words: updatedWords,
      type: category.type,
      isUnlocked: category.isUnlocked,
    );

    state = {...state, categoryId: updatedCategory};
  }

  // Reset guessed counts for all words in a category
  void resetGuessedCounts(String categoryId) {
    final category = state[categoryId];
    if (category == null) return;

    final updatedWords = category.words
        .map((word) => word.copyWith(
              stats: WordStats(
                appearanceCount: word.stats.appearanceCount,
                skipCount: word.stats.skipCount,
                guessedCount: 0,
              ),
            ))
        .toList();

    final updatedCategory = Category(
      id: category.id,
      displayName: category.displayName,
      color: category.color,
      icon: category.icon,
      description: category.description,
      words: updatedWords,
      type: category.type,
      isUnlocked: category.isUnlocked,
    );

    state = {...state, categoryId: updatedCategory};
  }

  // Reset all counts for all words in a category
  void resetAllCounts(String categoryId) {
    final category = state[categoryId];
    if (category == null) return;

    final updatedWords = category.words
        .map((word) => word.copyWith(
              stats: const WordStats(),
            ))
        .toList();

    final updatedCategory = Category(
      id: category.id,
      displayName: category.displayName,
      color: category.color,
      icon: category.icon,
      description: category.description,
      words: updatedWords,
      type: category.type,
      isUnlocked: category.isUnlocked,
    );

    state = {...state, categoryId: updatedCategory};
  }

  // Purge low frequency words from a category
  void purgeLowFrequencyWords(String categoryId, int threshold) {
    final category = state[categoryId];
    if (category == null) return;

    final updatedWords = category.words
        .where((word) => word.stats.appearanceCount >= threshold)
        .toList();
    final updatedCategory = Category(
      id: category.id,
      displayName: category.displayName,
      color: category.color,
      icon: category.icon,
      description: category.description,
      words: updatedWords,
      type: category.type,
      isUnlocked: category.isUnlocked,
    );

    state = {...state, categoryId: updatedCategory};
  }

  // Update all words in a category
  void updateWords(String categoryId, List<Word> updatedWords) {
    final category = state[categoryId];
    if (category == null) return;

    final updatedCategory = Category(
      id: category.id,
      displayName: category.displayName,
      color: category.color,
      icon: category.icon,
      description: category.description,
      words: updatedWords,
      type: category.type,
      isUnlocked: category.isUnlocked,
    );

    state = {...state, categoryId: updatedCategory};
  }
}

// Provider instance
final categoryProvider =
    StateNotifierProvider<CategoryProvider, Map<String, Category>>((ref) {
  return CategoryProvider();
});
