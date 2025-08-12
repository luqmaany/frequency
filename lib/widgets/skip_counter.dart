import 'package:flutter/material.dart';
import '../data/category_registry.dart';

class SkipCounter extends StatelessWidget {
  final int skipsLeft;
  final String categoryId;

  const SkipCounter({
    super.key,
    required this.skipsLeft,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: CategoryRegistry.getCategory(categoryId).color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Skips: $skipsLeft',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.95),
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
