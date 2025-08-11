import 'package:flutter/material.dart';
import '../models/category.dart';
import '../data/category_registry.dart';

class WordCard extends StatelessWidget {
  final Word word;

  const WordCard({
    super.key,
    required this.word,
  });

  @override
  Widget build(BuildContext context) {
    final category = CategoryRegistry.getCategory(word.categoryId);
    final Color categoryColor = category.color;

    // Theme-aware colors
    final Color background = categoryColor.withOpacity(0.2);
    final Color border = categoryColor.withOpacity(0.8);
    final Color text = Colors.white.withOpacity(0.95);
    final Color shadow = categoryColor.withOpacity(0.3);

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
