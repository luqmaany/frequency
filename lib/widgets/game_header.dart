import 'package:flutter/material.dart';
import 'game_timer.dart';
import 'category_display.dart';
import 'skip_counter.dart';

class GameHeader extends StatelessWidget {
  final int timeLeft;
  final String categoryId;
  final int skipsLeft;
  final bool isTiebreaker;

  const GameHeader({
    super.key,
    required this.timeLeft,
    required this.categoryId,
    required this.skipsLeft,
    this.isTiebreaker = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          // Timer - on the left
          Expanded(
            flex: 1,
            child: GameTimer(
              timeLeft: timeLeft,
              categoryId: categoryId,
            ),
          ),
          const SizedBox(width: 12),
          // Right side - stacked category and skips
          Expanded(
            flex: 2,
            child: Column(
              children: [
                CategoryDisplay(
                  categoryId: categoryId,
                  isTiebreaker: isTiebreaker,
                ),
                const SizedBox(height: 4),
                SkipCounter(
                  skipsLeft: skipsLeft,
                  categoryId: categoryId,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
