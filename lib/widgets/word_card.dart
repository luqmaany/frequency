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
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CategoryUtils.getCategoryColor(category).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CategoryUtils.getCategoryColor(category),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: CategoryUtils.getCategoryColor(category).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          word.text,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
