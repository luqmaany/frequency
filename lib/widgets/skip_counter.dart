import 'package:flutter/material.dart';
import '../screens/word_lists_manager_screen.dart';
import '../utils/category_utils.dart';

class SkipCounter extends StatelessWidget {
  final int skipsLeft;
  final WordCategory category;

  const SkipCounter({
    super.key,
    required this.skipsLeft,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: CategoryUtils.getCategoryColor(category).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Skips: $skipsLeft',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.black,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
