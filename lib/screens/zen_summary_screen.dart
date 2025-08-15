import 'package:flutter/material.dart';
import '../data/category_registry.dart';
import 'package:convey/widgets/team_color_button.dart';

class ZenSummaryScreen extends StatelessWidget {
  final String categoryId;
  final int correctCount;
  final int skipsLeft;
  final List<String> wordsGuessed;
  final List<String> wordsSkipped;
  final List<String> wordsLeftOnScreen;

  const ZenSummaryScreen({
    super.key,
    required this.categoryId,
    required this.correctCount,
    required this.skipsLeft,
    required this.wordsGuessed,
    required this.wordsSkipped,
    required this.wordsLeftOnScreen,
  });

  @override
  Widget build(BuildContext context) {
    final category = CategoryRegistry.getCategory(categoryId);
    final TeamColor zenButtonColor = TeamColor(
      'Zen',
      category.color.withOpacity(0.15),
      category.color,
      Colors.white,
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: category.color,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                category.displayName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Score: $correctCount',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (wordsGuessed.isNotEmpty) ...[
                      Text(
                        'Words Guessed',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      for (final word in wordsGuessed)
                        _wordChip(context, word,
                            category.color.withOpacity(0.12), category.color),
                      const SizedBox(height: 16),
                    ],
                    if (wordsSkipped.isNotEmpty) ...[
                      Text(
                        'Words Skipped',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      for (final word in wordsSkipped)
                        _wordChip(
                            context,
                            word,
                            category.color.withOpacity(0.06),
                            category.color.withOpacity(0.4)),
                      const SizedBox(height: 16),
                    ],
                    if (wordsLeftOnScreen.isNotEmpty) ...[
                      Text(
                        'Words Left On Screen',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      for (final word in wordsLeftOnScreen)
                        _wordChip(
                          context,
                          word,
                          Theme.of(context).brightness == Brightness.dark
                              ? category.color.withOpacity(0.08)
                              : category.color.withOpacity(0.04),
                          Theme.of(context).brightness == Brightness.dark
                              ? category.color.withOpacity(0.6)
                              : category.color.withOpacity(0.3),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TeamColorButton(
                      text: 'Play Again',
                      icon: Icons.replay_rounded,
                      color: zenButtonColor,
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
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

  Widget _wordChip(BuildContext context, String text, Color bg, Color border) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
