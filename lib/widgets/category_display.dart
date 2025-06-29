import 'package:flutter/material.dart';
import '../screens/word_lists_manager_screen.dart';
import '../utils/category_utils.dart';

class CategoryDisplay extends StatelessWidget {
  final WordCategory category;
  final bool isTiebreaker;

  const CategoryDisplay({
    super.key,
    required this.category,
    this.isTiebreaker = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: CategoryUtils.getCategoryColor(category).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CategoryUtils.getCategoryColor(category),
          width: 1,
        ),
      ),
      child: Text(
        isTiebreaker
            ? 'TIEBREAKER: ${CategoryUtils.getCategoryName(category)}'
            : CategoryUtils.getCategoryName(category),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
