import 'package:flutter/material.dart';
import '../screens/word_lists_manager_screen.dart';
import '../utils/category_utils.dart';

class WordCard extends StatelessWidget {
  final Word word;
  final WordCategory category;

  const WordCard({
    super.key,
    required this.word,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color categoryColor = CategoryUtils.getCategoryColor(category);

    // Theme-aware colors
    final Color background = isDark
        ? categoryColor.withOpacity(0.2)
        : categoryColor.withOpacity(0.1);
    final Color border =
        isDark ? categoryColor.withOpacity(0.8) : categoryColor;
    final Color text = isDark ? Colors.white.withOpacity(0.95) : Colors.black;
    final Color shadow = isDark
        ? categoryColor.withOpacity(0.3)
        : categoryColor.withOpacity(0.2);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: border,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: shadow,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          word.text,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: text,
                fontWeight: FontWeight.w600,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
