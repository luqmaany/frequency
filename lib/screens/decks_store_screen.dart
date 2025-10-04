import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/category_registry.dart';
import '../models/category.dart';
import '../widgets/deck_card.dart';
import '../widgets/team_color_button.dart';
import '../services/purchase_service.dart';
import '../services/storage_service.dart';

class DecksStoreScreen extends ConsumerStatefulWidget {
  const DecksStoreScreen({super.key});

  @override
  ConsumerState<DecksStoreScreen> createState() => _DecksStoreScreenState();
}

class _DecksStoreScreenState extends ConsumerState<DecksStoreScreen> {
  String? _flippedDeckId;

  void _onDeckTap(String deckId) {
    setState(() {
      _flippedDeckId = _flippedDeckId == deckId ? null : deckId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Category> all = CategoryRegistry.getAllCategories();

    // Merge built-in unlocked flag with locally purchased entitlements
    // so we correctly show offline ownership
    // We'll read local storage synchronously via a FutureBuilder

    return Scaffold(
      body: FutureBuilder<List<String>>(
        future: StorageService.getUnlockedCategoryIds(),
        builder: (context, snapshot) {
          final purchased = snapshot.data ?? const <String>[];
          final List<Category> owned = all
              .where((c) => c.isUnlocked || purchased.contains(c.id))
              .toList();
          final List<Category> more = all
              .where((c) => !(c.isUnlocked || purchased.contains(c.id)))
              .toList();

          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                        left: 16, right: 16, top: 12, bottom: 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            'Decks',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _SectionHeader(text: 'Owned', isPrimary: true),
                        const SizedBox(height: 8),
                        if (owned.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Text(
                              'No owned decks yet',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.white70),
                            ),
                          )
                        else
                          ...owned.map(
                            (cat) => DeckCard(
                              category: cat,
                              isOwned: true,
                              onTap: () {},
                              height: 100,
                              isFlipped: _flippedDeckId == cat.id,
                              onFlip: () => _onDeckTap(cat.id),
                            ),
                          ),
                        const SizedBox(height: 20),
                        _SectionHeader(text: 'More'),
                        const SizedBox(height: 8),
                        if (more.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Text(
                              'More decks coming soon',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.white70),
                            ),
                          )
                        else
                          ...more.map(
                            (cat) => DeckCard(
                              category: cat,
                              isOwned: false,
                              onTap: () async {
                                final products =
                                    await PurchaseService.loadProducts();
                                final sku = cat.sku;
                                if (sku == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Not available yet.')),
                                  );
                                  return;
                                }
                                final pd = products.firstWhere(
                                  (p) => p.id == sku,
                                  orElse: () => (products.isNotEmpty
                                      ? products.first
                                      : (throw Exception('Product not found'))),
                                );
                                await PurchaseService.buyCategory(
                                  categoryId: cat.id,
                                  product: pd,
                                );
                                // After purchase stream updates, rebuild by popping a snack
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Purchase requested for ${cat.displayName}')),
                                );
                              },
                              height: 104,
                              isFlipped: _flippedDeckId == cat.id,
                              onFlip: () => _onDeckTap(cat.id),
                            ),
                          ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TeamColorButton(
                          text: 'Home',
                          icon: Icons.home,
                          color: uiColors[0],
                          onPressed: () {
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TeamColorButton(
                          text: 'Restore',
                          icon: Icons.refresh,
                          color: uiColors[1],
                          onPressed: () async {
                            await PurchaseService.restorePurchases();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Restoring purchases...')),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  final bool isPrimary;
  const _SectionHeader({required this.text, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme;
    final style = base.titleLarge?.copyWith(
      fontWeight: FontWeight.w800,
      color: Colors.white,
      letterSpacing: 0.6,
    );
    return Center(
      child: Text(
        text,
        style: style,
        textAlign: TextAlign.center,
      ),
    );
  }
}
