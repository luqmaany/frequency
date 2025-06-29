import 'package:flutter/material.dart';
import '../screens/word_lists_manager_screen.dart';
import '../utils/category_utils.dart';

class GameTimer extends StatelessWidget {
  final int timeLeft;
  final WordCategory category;

  const GameTimer({
    super.key,
    required this.timeLeft,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: CategoryUtils.getCategoryColor(category),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: CategoryUtils.getCategoryColor(category).withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          timeLeft.toString(),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 36,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
