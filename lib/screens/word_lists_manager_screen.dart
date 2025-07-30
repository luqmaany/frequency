import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/word_lists.dart';
import '../models/category.dart';

// TODO: Move to a separate providers file later
final wordsProvider = StateNotifierProvider<WordsNotifier, List<Word>>((ref) {
  return WordsNotifier();
});

class WordsNotifier extends StateNotifier<List<Word>> {
  WordsNotifier() : super([]) {
    _initializeWords();
  }

  void _initializeWords() {
    // Add all words to state
    final allWords = [
      ...WordLists.people.map((word) => Word(text: word, categoryId: 'person')),
      ...WordLists.actions
          .map((word) => Word(text: word, categoryId: 'action')),
      ...WordLists.locations
          .map((word) => Word(text: word, categoryId: 'world')),
      ...WordLists.random.map((word) => Word(text: word, categoryId: 'random')),
    ];

    // Remove duplicates by keeping the first occurrence of each word
    final uniqueWords = <String, Word>{};
    for (final word in allWords) {
      if (!uniqueWords.containsKey(word.text)) {
        uniqueWords[word.text] = word;
      } else {
        // If duplicate found, merge the counts (though they should be 0 initially)
        final existing = uniqueWords[word.text]!;
        uniqueWords[word.text] = Word(
          text: existing.text,
          categoryId: existing.categoryId,
          stats: WordStats(
            appearanceCount:
                existing.stats.appearanceCount + word.stats.appearanceCount,
            skipCount: existing.stats.skipCount + word.stats.skipCount,
            guessedCount: existing.stats.guessedCount + word.stats.guessedCount,
          ),
        );
      }
    }

    state = uniqueWords.values.toList();
  }

  void addWord(Word word) {
    // Check if word already exists to prevent duplicates
    final existingWord = state.where((w) => w.text == word.text).firstOrNull;
    if (existingWord != null) {
      // Update the existing word instead of adding a duplicate
      state = state.map((w) {
        if (w.text == word.text) {
          return Word(
            text: w.text,
            category: word.category, // Use the new category if different
            appearanceCount: w.appearanceCount,
            skipCount: w.skipCount,
            guessedCount: w.guessedCount,
          );
        }
        return w;
      }).toList();
    } else {
      state = [...state, word];
    }
  }

  void deleteWord(Word word) {
    state = state.where((w) => w.text != word.text).toList();
  }

  void resetAppearanceCounts() {
    state = state
        .map((word) => Word(
              text: word.text,
              category: word.category,
              appearanceCount: 0,
              skipCount: word.skipCount,
              guessedCount: word.guessedCount,
            ))
        .toList();
  }

  void resetSkipCounts() {
    state = state
        .map((word) => Word(
              text: word.text,
              category: word.category,
              appearanceCount: word.appearanceCount,
              skipCount: 0,
              guessedCount: word.guessedCount,
            ))
        .toList();
  }

  void resetGuessedCounts() {
    state = state
        .map((word) => Word(
              text: word.text,
              category: word.category,
              appearanceCount: word.appearanceCount,
              skipCount: word.skipCount,
              guessedCount: 0,
            ))
        .toList();
  }

  void resetAllCounts() {
    state = state
        .map((word) => Word(
              text: word.text,
              category: word.category,
              appearanceCount: 0,
              skipCount: 0,
              guessedCount: 0,
            ))
        .toList();
  }

  void incrementWordSkip(String wordText) {
    state = state.map((word) {
      if (word.text == wordText) {
        return Word(
          text: word.text,
          category: word.category,
          appearanceCount: word.appearanceCount,
          skipCount: word.skipCount + 1,
          guessedCount: word.guessedCount,
        );
      }
      return word;
    }).toList();
  }

  void incrementWordAppearance(String wordText) {
    state = state.map((word) {
      if (word.text == wordText) {
        return Word(
          text: word.text,
          category: word.category,
          appearanceCount: word.appearanceCount + 1,
          skipCount: word.skipCount,
          guessedCount: word.guessedCount,
        );
      }
      return word;
    }).toList();
  }

  void incrementWordGuessed(String wordText) {
    state = state.map((word) {
      if (word.text == wordText) {
        return Word(
          text: word.text,
          category: word.category,
          appearanceCount: word.appearanceCount,
          skipCount: word.skipCount,
          guessedCount: word.guessedCount + 1,
        );
      }
      return word;
    }).toList();
  }

  void purgeLowFrequencyWords(int threshold) {
    state = state.where((word) => word.appearanceCount >= threshold).toList();
  }

  void updateWords(List<Word> updatedWords) {
    state = updatedWords;
  }

  List<Word> getWordsSortedBySkipCount() {
    final sortedWords = List<Word>.from(state);
    sortedWords.sort((a, b) => b.skipCount.compareTo(a.skipCount));
    return sortedWords;
  }

  List<Word> getWordsSortedByAppearanceCount() {
    final sortedWords = List<Word>.from(state);
    sortedWords.sort((a, b) => b.appearanceCount.compareTo(a.appearanceCount));
    return sortedWords;
  }

  List<Word> getWordsSortedByGuessedCount() {
    final sortedWords = List<Word>.from(state);
    sortedWords.sort((a, b) => b.guessedCount.compareTo(a.guessedCount));
    return sortedWords;
  }

  List<Word> getWordsSortedByDifficulty() {
    final sortedWords = List<Word>.from(state);
    sortedWords.sort((a, b) {
      // Calculate difficulty score: skip rate (skips / total appearances)
      final aTotalAppearances = a.appearanceCount;
      final bTotalAppearances = b.appearanceCount;

      if (aTotalAppearances == 0 && bTotalAppearances == 0) return 0;
      if (aTotalAppearances == 0) return -1;
      if (bTotalAppearances == 0) return 1;

      final aSkipRate = a.skipCount / aTotalAppearances;
      final bSkipRate = b.skipCount / bTotalAppearances;

      return bSkipRate
          .compareTo(aSkipRate); // Higher skip rate = more difficult
    });
    return sortedWords;
  }
}

class WordListsManagerScreen extends ConsumerStatefulWidget {
  const WordListsManagerScreen({super.key});

  @override
  ConsumerState<WordListsManagerScreen> createState() =>
      _WordListsManagerScreenState();
}

class _WordListsManagerScreenState
    extends ConsumerState<WordListsManagerScreen> {
  WordCategory _selectedCategory = WordCategory.person;
  String _searchQuery = '';
  String _sortBy =
      'name'; // 'name', 'appearances', 'guessed', 'skips', 'difficulty'

  @override
  Widget build(BuildContext context) {
    final words = ref.watch(wordsProvider);
    final filteredWords = words.where((word) {
      final matchesCategory = word.category == _selectedCategory;
      final matchesSearch =
          word.text.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    // Apply sorting
    switch (_sortBy) {
      case 'appearances':
        filteredWords.sort((a, b) {
          final appearanceComparison =
              b.appearanceCount.compareTo(a.appearanceCount);
          return appearanceComparison != 0
              ? appearanceComparison
              : a.text.compareTo(b.text);
        });
        break;
      case 'guessed':
        filteredWords.sort((a, b) {
          final guessedComparison = b.guessedCount.compareTo(a.guessedCount);
          return guessedComparison != 0
              ? guessedComparison
              : a.text.compareTo(b.text);
        });
        break;
      case 'skips':
        filteredWords.sort((a, b) {
          final skipComparison = b.skipCount.compareTo(a.skipCount);
          return skipComparison != 0
              ? skipComparison
              : a.text.compareTo(b.text);
        });
        break;
      case 'difficulty':
        filteredWords.sort((a, b) {
          final aTotalAppearances = a.appearanceCount;
          final bTotalAppearances = b.appearanceCount;

          if (aTotalAppearances == 0 && bTotalAppearances == 0) {
            return a.text.compareTo(b.text);
          }
          if (aTotalAppearances == 0) return -1;
          if (bTotalAppearances == 0) return 1;

          final aSkipRate = a.skipCount / aTotalAppearances;
          final bSkipRate = b.skipCount / bTotalAppearances;

          final difficultyComparison = bSkipRate.compareTo(aSkipRate);
          return difficultyComparison != 0
              ? difficultyComparison
              : a.text.compareTo(b.text);
        });
        break;
      default: // 'name'
        filteredWords.sort((a, b) => a.text.compareTo(b.text));
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Word Lists Manager'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Word Management Options',
            onSelected: (value) {
              switch (value) {
                case 'purge':
                  _showPurgeDialog(context);
                  break;
                case 'reset_appearances':
                  _showResetAppearanceDialog(context);
                  break;
                case 'reset_skips':
                  _showResetSkipDialog(context);
                  break;
                case 'reset_guessed':
                  _showResetGuessedDialog(context);
                  break;
                case 'reset_all':
                  _showResetAllDialog(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'purge',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep),
                    SizedBox(width: 8),
                    Text('Purge Low Frequency Words'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset_appearances',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Reset Appearance Counts'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset_skips',
                child: Row(
                  children: [
                    Icon(Icons.skip_next),
                    SizedBox(width: 8),
                    Text('Reset Skip Counts'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset_guessed',
                child: Row(
                  children: [
                    Icon(Icons.check_circle),
                    SizedBox(width: 8),
                    Text('Reset Guessed Counts'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Reset All Counts'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Category selector
                SegmentedButton<WordCategory>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: WordCategory.person,
                      label: Text('Person'),
                    ),
                    ButtonSegment(
                      value: WordCategory.action,
                      label: Text('Action'),
                    ),
                    ButtonSegment(
                      value: WordCategory.world,
                      label: Text('World'),
                    ),
                    ButtonSegment(
                      value: WordCategory.random,
                      label: Text('Random'),
                    ),
                  ],
                  selected: {_selectedCategory},
                  onSelectionChanged: (Set<WordCategory> selected) {
                    setState(() {
                      _selectedCategory = selected.first;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Search bar
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search words...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Sort dropdown
                DropdownButtonFormField<String>(
                  value: _sortBy,
                  decoration: const InputDecoration(
                    labelText: 'Sort by',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'name', child: Text('Name')),
                    DropdownMenuItem(
                        value: 'appearances', child: Text('Most Appeared')),
                    DropdownMenuItem(
                        value: 'guessed', child: Text('Most Guessed')),
                    DropdownMenuItem(
                        value: 'skips', child: Text('Most Skipped')),
                    DropdownMenuItem(
                        value: 'difficulty', child: Text('Most Difficult')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _sortBy = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          // Word list
          Expanded(
            child: ListView.builder(
              itemCount: filteredWords.length,
              itemBuilder: (context, index) {
                final word = filteredWords[index];
                return ListTile(
                  title: Text(word.text),
                  subtitle: Text(
                      'Appeared: ${word.appearanceCount}, Guessed: ${word.guessedCount}, Skipped: ${word.skipCount}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _showDeleteDialog(context, word),
                  ),
                  tileColor: _getDifficultyColor(word),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddWordDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddWordDialog(BuildContext context) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Word'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                labelText: 'Word',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<WordCategory>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: WordCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category.toString().split('.').last),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                ref.read(wordsProvider.notifier).addWord(
                      Word(
                        text: textController.text,
                        category: _selectedCategory,
                      ),
                    );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Word word) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Word'),
        content: Text('Are you sure you want to delete "${word.text}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(wordsProvider.notifier).deleteWord(word);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showPurgeDialog(BuildContext context) {
    final thresholdController = TextEditingController(text: '3');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Purge Low Frequency Words'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter minimum appearance count threshold:'),
            const SizedBox(height: 16),
            TextField(
              controller: thresholdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final threshold = int.tryParse(thresholdController.text) ?? 3;
              ref
                  .read(wordsProvider.notifier)
                  .purgeLowFrequencyWords(threshold);
              Navigator.pop(context);
            },
            child: const Text('Purge'),
          ),
        ],
      ),
    );
  }

  void _showResetAppearanceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Appearance Counts'),
        content: const Text(
            'Are you sure you want to reset all word appearance counts to zero?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(wordsProvider.notifier).resetAppearanceCounts();
              Navigator.pop(context);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showResetSkipDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Skip Counts'),
        content: const Text(
            'Are you sure you want to reset all word skip counts to zero?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(wordsProvider.notifier).resetSkipCounts();
              Navigator.pop(context);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showResetGuessedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Guessed Counts'),
        content: const Text(
            'Are you sure you want to reset all word guessed counts to zero?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(wordsProvider.notifier).resetGuessedCounts();
              Navigator.pop(context);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showResetAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Counts'),
        content: const Text(
            'Are you sure you want to reset all word counts (appearances, guessed, and skips) to zero?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(wordsProvider.notifier).resetAllCounts();
              Navigator.pop(context);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(Word word) {
    final totalAppearances = word.appearanceCount;
    if (totalAppearances == 0) return Colors.transparent;

    final skipRate = word.skipCount / totalAppearances;
    if (skipRate < 0.25) return Colors.green.withOpacity(0.1);
    if (skipRate < 0.5) return Colors.yellow.withOpacity(0.1);
    if (skipRate < 0.75) return Colors.orange.withOpacity(0.1);
    return Colors.red.withOpacity(0.1);
  }
}
