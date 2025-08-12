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
    final Color scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    // Theme-aware colors
    final Color background =
        Color.alphaBlend(categoryColor.withOpacity(0.25), scaffoldBg);
    final Color border = categoryColor.withOpacity(1);
    final Color text = Colors.white.withOpacity(0.95);
    // Removed drop shadow for flatter look

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 30),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: border,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
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
      ),
    );
  }
}
