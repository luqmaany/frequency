import 'package:flutter/material.dart';
import '../data/category_registry.dart';

class CategoryDisplay extends StatelessWidget {
  final String category;
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
        color: CategoryRegistry.getCategory(category).color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CategoryRegistry.getCategory(category).color,
          width: 1,
        ),
      ),
      child: Text(
        isTiebreaker
            ? 'TIEBREAKER: ${CategoryRegistry.getCategory(category).displayName}'
            : CategoryRegistry.getCategory(category).displayName,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
