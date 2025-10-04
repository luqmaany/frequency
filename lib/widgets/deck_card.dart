import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/category.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DeckCard extends StatefulWidget {
  final Category category;
  final bool isOwned;
  final VoidCallback? onTap;
  final double height;
  final bool isFlipped;
  final VoidCallback? onFlip;

  const DeckCard({
    super.key,
    required this.category,
    required this.isOwned,
    this.onTap,
    this.height = 80,
    this.isFlipped = false,
    this.onFlip,
  });

  @override
  State<DeckCard> createState() => _DeckCardState();
}

class _DeckCardState extends State<DeckCard> {
  // Helper method to build image widget (supports both assets and network URLs)
  Widget _buildImage(String imagePath, {required Alignment alignment}) {
    // Check if it's a network URL
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        alignment: alignment,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[300],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[300],
          child: Icon(
            widget.category.icon,
            color: Colors.grey[600],
            size: 24,
          ),
        ),
      );
    } else {
      // Local asset
      return Image.asset(
        imagePath,
        alignment: alignment,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(
          widget.category.icon,
          color: Colors.grey[600],
          size: 24,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final Color base = widget.category.color;
    final Color background =
        Color.alphaBlend(base.withOpacity(0.25), scaffoldBg);
    final Color border = base.withOpacity(1.0);
    final Color text = Colors.white.withOpacity(0.95);
    final double titleFontSize =
        (Theme.of(context).textTheme.titleMedium?.fontSize ?? 16) + 2;

    Widget front() {
      return Stack(
        alignment: Alignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.category.imageAsset != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 150,
                    height: 100,
                    child: FittedBox(
                      fit: BoxFit.fitHeight,
                      alignment: Alignment.centerLeft,
                      child: _buildImage(
                        widget.category.imageAsset!,
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  ),
                )
              else
                Icon(widget.category.icon, color: Colors.white, size: 52),
              const SizedBox(width: 12),
              const Spacer(),
              if (!widget.isOwned) ...[
                const SizedBox(width: 12),
                const _RightBadge(isOwned: false),
              ],
            ],
          ),
          Center(
            child: Text(
              widget.category.displayName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: text,
                    fontWeight: FontWeight.w700,
                    fontSize: titleFontSize,
                  ),
            ),
          ),
        ],
      );
    }

    Widget back() {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (widget.category.imageAsset != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 56,
                height: 56,
                child: FittedBox(
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  child: _buildImage(
                    widget.category.imageAsset!,
                    alignment: Alignment.center,
                  ),
                ),
              ),
            )
          else
            Icon(widget.category.icon, color: Colors.white70, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.category.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.category.wordCount < 100
                      ? '<100 words'
                      : '${((widget.category.wordCount / 100).ceil() * 100)}+ words',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: text,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          if (!widget.isOwned) ...[
            const SizedBox(width: 12),
            const _RightBadge(isOwned: false),
          ],
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: widget.isFlipped ? 1 : 0),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          final angle = value * math.pi;
          final isBack = angle > math.pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(angle),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                widget.onFlip?.call();
                widget.onTap?.call();
              },
              child: Container(
                height: widget.height,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: border, width: 2),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: isBack
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateX(math.pi),
                        child: back(),
                      )
                    : front(),
              ),
            ),
          );
        },
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
