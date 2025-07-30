import 'package:flutter/material.dart';
import '../data/category_registry.dart';

class SkipCounter extends StatelessWidget {
  final int skipsLeft;
  final String category;

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
        color: CategoryRegistry.getCategory(category).color.withOpacity(0.1),
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
