import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/category_registry.dart';
import '../models/category.dart';
import '../widgets/deck_card.dart';
import '../widgets/team_color_button.dart';
import '../services/purchase_service.dart';
import '../services/storage_service.dart';

class DecksStoreScreen extends ConsumerWidget {
  const DecksStoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Category> all = CategoryRegistry.getAllCategories();

    // Merge built-in unlocked flag with locally purchased entitlements
    // so we correctly show offline ownership
    // We'll read local storage synchronously via a FutureBuilder

    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<String>>(
          future: StorageService.getUnlockedCategoryIds(),
          builder: (context, snapshot) {
            final purchased = snapshot.data ?? const <String>[];
            final List<Category> owned = all
                .where((c) => c.isUnlocked || purchased.contains(c.id))
                .toList();
            final List<Category> more = all
                .where((c) => !(c.isUnlocked || purchased.contains(c.id)))
                .toList();

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            'Decks',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
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
                            ),
                          ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
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
            );
          },
        ),
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
