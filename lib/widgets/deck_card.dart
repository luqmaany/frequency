import 'package:flutter/material.dart';
import '../models/category.dart';

class DeckCard extends StatelessWidget {
  final Category category;
  final bool isOwned;
  final VoidCallback? onTap;

  const DeckCard({
    super.key,
    required this.category,
    required this.isOwned,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final Color base = category.color;
    final Color background =
        Color.alphaBlend(base.withOpacity(0.25), scaffoldBg);
    final Color border = base.withOpacity(1.0);
    final Color text = Colors.white.withOpacity(0.95);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border, width: 2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (category.imageAsset != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: 3 / 2,
                    child: Image.asset(
                      category.imageAsset!,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                  ),
                )
              else
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: base.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: border, width: 1.5),
                  ),
                  child: Icon(category.icon, color: Colors.white, size: 30),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      category.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: text,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ],
                ),
              ),
              if (!isOwned) ...[
                const SizedBox(width: 12),
                const _RightBadge(isOwned: false),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RightBadge extends StatelessWidget {
  final bool isOwned;
  const _RightBadge({required this.isOwned});

  @override
  Widget build(BuildContext context) {
    final Color badgeBg =
        isOwned ? const Color(0xFF4CD295) : const Color(0xFFFF6680);
    final String label = isOwned ? 'Owned' : 'Get';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: badgeBg.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeBg, width: 1.5),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
