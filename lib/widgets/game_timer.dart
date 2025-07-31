import 'package:flutter/material.dart';
import '../data/category_registry.dart';

class GameTimer extends StatelessWidget {
  final int timeLeft;
  final String categoryId;

  const GameTimer({
    super.key,
    required this.timeLeft,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: CategoryRegistry.getCategory(categoryId).color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                CategoryRegistry.getCategory(categoryId).color.withOpacity(0.4),
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
