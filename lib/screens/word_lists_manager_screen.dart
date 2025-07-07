import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/word_lists.dart';

// TODO: Move these to a separate models file later
enum WordCategory {
  person,
  action,
  world,
  random,
}

class Word {
  final String text;
  final WordCategory category;
  int usageCount;
  int skipCount;

  Word({
    required this.text,
    required this.category,
    this.usageCount = 0,
    this.skipCount = 0,
  });
}

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
      ...WordLists.people
          .map((word) => Word(text: word, category: WordCategory.person)),
      ...WordLists.actions
          .map((word) => Word(text: word, category: WordCategory.action)),
      ...WordLists.locations
          .map((word) => Word(text: word, category: WordCategory.world)),
      ...WordLists.random
          .map((word) => Word(text: word, category: WordCategory.random)),
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
          category: existing.category,
          usageCount: existing.usageCount + word.usageCount,
          skipCount: existing.skipCount + word.skipCount,
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
            usageCount: w.usageCount,
            skipCount: w.skipCount,
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

  void resetUsageCounts() {
    state = state
        .map((word) => Word(
              text: word.text,
              category: word.category,
              usageCount: 0,
              skipCount: word.skipCount,
            ))
        .toList();
  }

  void resetSkipCounts() {
    state = state
        .map((word) => Word(
              text: word.text,
              category: word.category,
              usageCount: word.usageCount,
              skipCount: 0,
            ))
        .toList();
  }

  void resetAllCounts() {
    state = state
        .map((word) => Word(
              text: word.text,
              category: word.category,
              usageCount: 0,
              skipCount: 0,
            ))
        .toList();
  }

  void incrementWordSkip(String wordText) {
    state = state.map((word) {
      if (word.text == wordText) {
        return Word(
          text: word.text,
          category: word.category,
          usageCount: word.usageCount,
          skipCount: word.skipCount + 1,
        );
      }
      return word;
    }).toList();
  }

  void purgeLowFrequencyWords(int threshold) {
    state = state.where((word) => word.usageCount >= threshold).toList();
  }

  void updateWords(List<Word> updatedWords) {
    state = updatedWords;
  }

  int removeDuplicates() {
    final originalCount = state.length;
    final uniqueWords = <String, Word>{};
    for (final word in state) {
      if (!uniqueWords.containsKey(word.text)) {
        uniqueWords[word.text] = word;
      } else {
        // If duplicate found, merge the counts
        final existing = uniqueWords[word.text]!;
        uniqueWords[word.text] = Word(
          text: existing.text,
          category: existing.category,
          usageCount: existing.usageCount + word.usageCount,
          skipCount: existing.skipCount + word.skipCount,
        );
      }
    }
    state = uniqueWords.values.toList();
    return originalCount - state.length;
  }

  List<Word> getWordsSortedBySkipCount() {
    final sortedWords = List<Word>.from(state);
    sortedWords.sort((a, b) => b.skipCount.compareTo(a.skipCount));
    return sortedWords;
  }

  List<Word> getWordsSortedByDifficulty() {
    final sortedWords = List<Word>.from(state);
    sortedWords.sort((a, b) {
      // Calculate difficulty score: skip rate (skips / total uses)
      final aTotalUses = a.usageCount + a.skipCount;
      final bTotalUses = b.usageCount + b.skipCount;

      if (aTotalUses == 0 && bTotalUses == 0) return 0;
      if (aTotalUses == 0) return -1;
      if (bTotalUses == 0) return 1;

      final aSkipRate = a.skipCount / aTotalUses;
      final bSkipRate = b.skipCount / bTotalUses;

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
  String _sortBy = 'name'; // 'name', 'usage', 'skips', 'difficulty'

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
      case 'usage':
        filteredWords.sort((a, b) => b.usageCount.compareTo(a.usageCount));
        break;
      case 'skips':
        filteredWords.sort((a, b) => b.skipCount.compareTo(a.skipCount));
        break;
      case 'difficulty':
        filteredWords.sort((a, b) {
          final aTotalUses = a.usageCount + a.skipCount;
          final bTotalUses = b.usageCount + b.skipCount;

          if (aTotalUses == 0 && bTotalUses == 0) return 0;
          if (aTotalUses == 0) return -1;
          if (bTotalUses == 0) return 1;

          final aSkipRate = a.skipCount / aTotalUses;
          final bSkipRate = b.skipCount / bTotalUses;

          return bSkipRate.compareTo(aSkipRate);
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
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            tooltip: 'Remove Duplicates',
            onPressed: () => _showRemoveDuplicatesDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Purge Low Frequency Words',
            onPressed: () => _showPurgeDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Usage Counts',
            onPressed: () => _showResetDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.skip_next),
            tooltip: 'Reset Skip Counts',
            onPressed: () => _showResetSkipDialog(context),
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
                    DropdownMenuItem(value: 'usage', child: Text('Most Used')),
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
                      'Used ${word.usageCount} times, Skipped ${word.skipCount} times'),
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
            const Text('Enter minimum usage count threshold:'),
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

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Usage Counts'),
        content: const Text(
            'Are you sure you want to reset all word usage counts to zero?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(wordsProvider.notifier).resetUsageCounts();
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

  void _showRemoveDuplicatesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Duplicates'),
        content:
            const Text('Are you sure you want to remove all duplicate words?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final duplicatesRemoved =
                  ref.read(wordsProvider.notifier).removeDuplicates();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('${duplicatesRemoved} duplicates removed')),
              );
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(Word word) {
    final totalUses = word.usageCount + word.skipCount;
    if (totalUses == 0) return Colors.transparent;

    final skipRate = word.skipCount / totalUses;
    if (skipRate < 0.25) return Colors.green.withOpacity(0.1);
    if (skipRate < 0.5) return Colors.yellow.withOpacity(0.1);
    if (skipRate < 0.75) return Colors.orange.withOpacity(0.1);
    return Colors.red.withOpacity(0.1);
  }
}
