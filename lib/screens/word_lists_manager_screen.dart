import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';

class WordListsManagerScreen extends ConsumerStatefulWidget {
  const WordListsManagerScreen({super.key});

  @override
  ConsumerState<WordListsManagerScreen> createState() =>
      _WordListsManagerScreenState();
}

class _WordListsManagerScreenState
    extends ConsumerState<WordListsManagerScreen> {
  String _selectedCategory = 'person';
  String _searchQuery = '';
  String _sortBy =
      'name'; // 'name', 'appearances', 'guessed', 'skips', 'difficulty'

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryProvider);
    final allCategories = categories.values.toList();

    // Get words from the selected category
    final selectedCategory = categories[_selectedCategory];
    final words = selectedCategory?.words ?? [];

    final filteredWords = words.where((word) {
      final matchesSearch =
          word.text.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();

    // Apply sorting
    switch (_sortBy) {
      case 'appearances':
        filteredWords.sort((a, b) {
          final appearanceComparison =
              b.stats.appearanceCount.compareTo(a.stats.appearanceCount);
          return appearanceComparison != 0
              ? appearanceComparison
              : a.text.compareTo(b.text);
        });
        break;
      case 'guessed':
        filteredWords.sort((a, b) {
          final guessedComparison =
              b.stats.guessedCount.compareTo(a.stats.guessedCount);
          return guessedComparison != 0
              ? guessedComparison
              : a.text.compareTo(b.text);
        });
        break;
      case 'skips':
        filteredWords.sort((a, b) {
          final skipComparison = b.stats.skipCount.compareTo(a.stats.skipCount);
          return skipComparison != 0
              ? skipComparison
              : a.text.compareTo(b.text);
        });
        break;
      case 'difficulty':
        filteredWords.sort((a, b) {
          final aTotalAppearances = a.stats.appearanceCount;
          final bTotalAppearances = b.stats.appearanceCount;

          if (aTotalAppearances == 0 && bTotalAppearances == 0) {
            return a.text.compareTo(b.text);
          }
          if (aTotalAppearances == 0) return -1;
          if (bTotalAppearances == 0) return 1;

          final aSkipRate = a.stats.skipCount / aTotalAppearances;
          final bSkipRate = b.stats.skipCount / bTotalAppearances;

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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 48),
                Center(
                  child: Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Category selector - dynamic dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: allCategories.map((category) {
                    return DropdownMenuItem(
                      value: category.id,
                      child: Row(
                        children: [
                          Icon(category.icon, color: category.color, size: 20),
                          const SizedBox(width: 8),
                          Text(category.displayName),
                        ],
                      ),
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
                // Controls row - Sort dropdown and Actions
                Row(
                  children: [
                    // Sort dropdown
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _sortBy,
                        decoration: const InputDecoration(
                          labelText: 'Sort by',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'name', child: Text('Name')),
                          DropdownMenuItem(
                              value: 'appearances',
                              child: Text('Most Appeared')),
                          DropdownMenuItem(
                              value: 'guessed', child: Text('Most Guessed')),
                          DropdownMenuItem(
                              value: 'skips', child: Text('Most Skipped')),
                          DropdownMenuItem(
                              value: 'difficulty',
                              child: Text('Most Difficult')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _sortBy = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Actions button
                    Expanded(
                      flex: 1,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.more_vert),
                        label: const Text('Actions'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () => _showActionsBottomSheet(context),
                      ),
                    ),
                  ],
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
                      'Appeared: ${word.stats.appearanceCount}, Guessed: ${word.stats.guessedCount}, Skipped: ${word.stats.skipCount}'),
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
    final categories = ref.read(categoryProvider);
    final allCategories = categories.values.toList();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 560),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blueGrey.shade700, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add New Word',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  labelText: 'Word',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: allCategories.map((category) {
                  return DropdownMenuItem(
                    value: category.id,
                    child: Row(
                      children: [
                        Icon(category.icon, color: category.color, size: 20),
                        const SizedBox(width: 8),
                        Text(category.displayName),
                      ],
                    ),
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
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        if (textController.text.isNotEmpty) {
                          ref.read(categoryProvider.notifier).addWord(
                                Word(
                                  text: textController.text,
                                  categoryId: _selectedCategory,
                                ),
                              );
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Add'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Word word) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 560),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Delete Word',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text('Are you sure you want to delete "${word.text}"?'),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        ref.read(categoryProvider.notifier).deleteWord(word);
                        Navigator.pop(context);
                      },
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPurgeDialog(BuildContext context) {
    final thresholdController = TextEditingController(text: '3');
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 560),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orange, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Purge Low Frequency Words',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text('Enter minimum appearance count threshold:'),
              const SizedBox(height: 16),
              TextField(
                controller: thresholdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final threshold =
                            int.tryParse(thresholdController.text) ?? 3;
                        ref
                            .read(categoryProvider.notifier)
                            .purgeLowFrequencyWords(
                                _selectedCategory, threshold);
                        Navigator.pop(context);
                      },
                      child: const Text('Purge'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResetAppearanceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 560),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blueGrey.shade700, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Reset Appearance Counts',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                  'Are you sure you want to reset all word appearance counts to zero?'),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        ref
                            .read(categoryProvider.notifier)
                            .resetAppearanceCounts(_selectedCategory);
                        Navigator.pop(context);
                      },
                      child: const Text('Reset'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResetSkipDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 560),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blueGrey.shade700, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Reset Skip Counts',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                  'Are you sure you want to reset all word skip counts to zero?'),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        ref
                            .read(categoryProvider.notifier)
                            .resetSkipCounts(_selectedCategory);
                        Navigator.pop(context);
                      },
                      child: const Text('Reset'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResetGuessedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 560),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blueGrey.shade700, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Reset Guessed Counts',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                  'Are you sure you want to reset all word guessed counts to zero?'),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        ref
                            .read(categoryProvider.notifier)
                            .resetGuessedCounts(_selectedCategory);
                        Navigator.pop(context);
                      },
                      child: const Text('Reset'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResetAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 560),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blueGrey.shade700, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Reset All Counts',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                  'Are you sure you want to reset all word counts (appearances, guessed, and skips) to zero?'),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        ref
                            .read(categoryProvider.notifier)
                            .resetAllCounts(_selectedCategory);
                        Navigator.pop(context);
                      },
                      child: const Text('Reset'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Word Management Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildActionTile(
              'Purge Low Frequency Words',
              Icons.delete_sweep,
              Colors.orange,
              () {
                Navigator.pop(context);
                _showPurgeDialog(context);
              },
            ),
            _buildActionTile(
              'Reset Appearance Counts',
              Icons.refresh,
              Colors.blue,
              () {
                Navigator.pop(context);
                _showResetAppearanceDialog(context);
              },
            ),
            _buildActionTile(
              'Reset Skip Counts',
              Icons.skip_next,
              Colors.purple,
              () {
                Navigator.pop(context);
                _showResetSkipDialog(context);
              },
            ),
            _buildActionTile(
              'Reset Guessed Counts',
              Icons.check_circle,
              Colors.green,
              () {
                Navigator.pop(context);
                _showResetGuessedDialog(context);
              },
            ),
            _buildActionTile(
              'Reset All Counts',
              Icons.clear_all,
              Colors.red,
              () {
                Navigator.pop(context);
                _showResetAllDialog(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Color _getDifficultyColor(Word word) {
    final totalAppearances = word.stats.appearanceCount;
    if (totalAppearances == 0) return Colors.transparent;

    final skipRate = word.stats.skipCount / totalAppearances;
    if (skipRate < 0.25) return Colors.green.withOpacity(0.1);
    if (skipRate < 0.5) return Colors.yellow.withOpacity(0.1);
    if (skipRate < 0.75) return Colors.orange.withOpacity(0.1);
    return Colors.red.withOpacity(0.1);
  }
}
