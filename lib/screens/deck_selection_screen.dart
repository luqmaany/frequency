import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/category_registry.dart';
import '../models/category.dart';
import '../widgets/team_color_button.dart';
import '../services/purchase_service.dart';
import '../services/storage_service.dart';

class DeckSelectionScreen extends ConsumerStatefulWidget {
  final List<String>? initialSelectedDecks;

  const DeckSelectionScreen({
    super.key,
    this.initialSelectedDecks,
  });

  @override
  ConsumerState<DeckSelectionScreen> createState() =>
      _DeckSelectionScreenState();
}

class _DeckSelectionScreenState extends ConsumerState<DeckSelectionScreen>
    with TickerProviderStateMixin {
  Set<String> _selectedDecks = {};
  List<String> _ownedDecks = [];
  bool _isLoading = true;
  late AnimationController _arrowController;
  late Animation<double> _arrowAnimation;
  final ScrollController _scrollController = ScrollController();
  bool _showArrow = false;

  @override
  void initState() {
    super.initState();
    _loadOwnedDecks();

    // Initialize arrow animation
    _arrowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _arrowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _arrowController,
      curve: Curves.easeInOut,
    ));

    // Add scroll listener to hide arrow when scrolled to premium section
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadOwnedDecks() async {
    final allCategories = CategoryRegistry.getAllCategories();
    final purchased = await StorageService.getUnlockedCategoryIds();

    setState(() {
      _ownedDecks = allCategories
          .where((c) => c.isUnlocked || purchased.contains(c.id))
          .map((c) => c.id)
          .toList();

      // Initialize selection with owned decks by default
      _selectedDecks = Set.from(_ownedDecks);

      // Override with initial selection if provided
      if (widget.initialSelectedDecks != null) {
        _selectedDecks = Set.from(widget.initialSelectedDecks!);
      }

      _isLoading = false;

      // Show arrow if there are locked categories and user has less than 4 decks selected
      final lockedCategories =
          allCategories.where((c) => !_ownedDecks.contains(c.id)).toList();
      _showArrow = lockedCategories.isNotEmpty && _selectedDecks.length < 4;

      if (_showArrow) {
        _arrowController.repeat(reverse: true);
      }
    });
  }

  void _toggleDeck(String deckId) {
    setState(() {
      if (_selectedDecks.contains(deckId)) {
        _selectedDecks.remove(deckId);
      } else {
        _selectedDecks.add(deckId);
      }

      // Update arrow visibility based on selection
      final allCategories = CategoryRegistry.getAllCategories();
      final lockedCategories =
          allCategories.where((c) => !_ownedDecks.contains(c.id)).toList();
      _showArrow = lockedCategories.isNotEmpty && _selectedDecks.length < 4;

      if (_showArrow && !_arrowController.isAnimating) {
        _arrowController.repeat(reverse: true);
      } else if (!_showArrow) {
        _arrowController.stop();
      }
    });
  }

  void _selectAllOwned() {
    setState(() {
      _selectedDecks = Set.from(_ownedDecks);
      _updateArrowVisibility();
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedDecks.clear();
      _updateArrowVisibility();
    });
  }

  void _updateArrowVisibility() {
    final allCategories = CategoryRegistry.getAllCategories();
    final lockedCategories =
        allCategories.where((c) => !_ownedDecks.contains(c.id)).toList();
    _showArrow = lockedCategories.isNotEmpty && _selectedDecks.length < 4;

    if (_showArrow && !_arrowController.isAnimating) {
      _arrowController.repeat(reverse: true);
    } else if (!_showArrow) {
      _arrowController.stop();
    }
  }

  void _onScroll() {
    // Hide arrow when user scrolls near the premium section
    if (_scrollController.position.pixels > 200) {
      setState(() {
        _showArrow = false;
      });
      _arrowController.stop();
    }
  }

  void _scrollToPremiumSection() {
    _scrollController.animateTo(
      300, // Scroll to premium section
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _purchaseDeck(Category category) async {
    try {
      final products = await PurchaseService.loadProducts();
      final sku = category.sku;

      if (sku == null) {
        _showSnackBar('This deck is not available for purchase yet.');
        return;
      }

      final product = products.firstWhere(
        (p) => p.id == sku,
        orElse: () => throw Exception('Product not found'),
      );

      await PurchaseService.buyCategory(
        categoryId: category.id,
        product: product,
      );

      _showSnackBar('Purchase requested for ${category.displayName}');

      // Refresh owned decks after purchase
      await _loadOwnedDecks();
    } catch (e) {
      _showSnackBar('Purchase failed: ${e.toString()}');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _arrowController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _previewDeck(Category category) {
    showDialog(
      context: context,
      builder: (context) => _PreviewDialog(category: category),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final allCategories = CategoryRegistry.getAllCategories();
    final ownedCategories =
        allCategories.where((c) => _ownedDecks.contains(c.id)).toList();
    final lockedCategories =
        allCategories.where((c) => !_ownedDecks.contains(c.id)).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Choose Decks',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_selectedDecks.length} deck${_selectedDecks.length == 1 ? '' : 's'} selected',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _selectedDecks.length >= 4
                              ? Colors.green
                              : Colors.orange,
                          fontWeight: _selectedDecks.length >= 4
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                  ),
                  if (_selectedDecks.length < 4)
                    Text(
                      'Select at least 4 decks to start',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange,
                          ),
                    ),
                  const SizedBox(height: 16),
                  // Quick selection buttons
                  Row(
                    children: [
                      Expanded(
                        child: TeamColorButton(
                          text: 'Select All',
                          icon: Icons.check_circle_outline,
                          color: uiColors[1], // Green
                          onPressed: ownedCategories.isNotEmpty
                              ? _selectAllOwned
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TeamColorButton(
                          text: 'Clear All',
                          icon: Icons.clear,
                          color: uiColors[2], // Orange
                          onPressed:
                              _selectedDecks.isNotEmpty ? _deselectAll : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Owned Decks Section
                        if (ownedCategories.isNotEmpty) ...[
                          _SectionHeader(
                            text: 'Your Decks',
                            isPrimary: true,
                            count: ownedCategories.length,
                          ),
                          const SizedBox(height: 8),
                          ...ownedCategories
                              .map((category) => _SelectableDeckCard(
                                    category: category,
                                    isOwned: true,
                                    isSelected:
                                        _selectedDecks.contains(category.id),
                                    onTap: () => _toggleDeck(category.id),
                                    onPreview: () => _previewDeck(category),
                                  )),
                          const SizedBox(height: 24),
                        ],

                        // Upselling Section
                        if (lockedCategories.isNotEmpty) ...[
                          _SectionHeader(
                            text: 'More Decks Available',
                            isPrimary: false,
                            count: lockedCategories.length,
                          ),
                          const SizedBox(height: 8),

                          // Upselling banner
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.purple.withOpacity(0.3),
                                  Colors.blue.withOpacity(0.3),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.purple.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '🎯 Unlock Premium Decks',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add ${lockedCategories.length} more decks to your game for endless variety!',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Colors.white70,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Locked decks
                          ...lockedCategories
                              .map((category) => _SelectableDeckCard(
                                    category: category,
                                    isOwned: false,
                                    isSelected: false,
                                    onTap: () => _purchaseDeck(category),
                                    onPreview: () => _previewDeck(category),
                                    showPurchaseButton: true,
                                  )),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),

                  // Floating Arrow
                  if (_showArrow)
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: AnimatedBuilder(
                        animation: _arrowAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, 10 * _arrowAnimation.value),
                            child: GestureDetector(
                              onTap: _scrollToPremiumSection,
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.orange.withOpacity(0.9),
                                      Colors.purple.withOpacity(0.9),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),

            // Bottom Actions
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
                      text: 'Back',
                      icon: Icons.arrow_back,
                      color: uiColors[0], // Blue
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TeamColorButton(
                      text: _selectedDecks.length < 4
                          ? 'Select At Least 4'
                          : 'Start Game (${_selectedDecks.length})',
                      icon: Icons.play_arrow,
                      color: _selectedDecks.length >= 4
                          ? uiColors[1]
                          : uiColors[0],
                      onPressed: _selectedDecks.length >= 4
                          ? () {
                              Navigator.of(context)
                                  .pop(_selectedDecks.toList());
                            }
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  final bool isPrimary;
  final int count;

  const _SectionHeader({
    required this.text,
    this.isPrimary = false,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme;
    final style = base.titleLarge?.copyWith(
      fontWeight: FontWeight.w800,
      color: isPrimary ? Colors.white : Colors.white70,
      letterSpacing: 0.6,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          text,
          style: style,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: (isPrimary ? Colors.green : Colors.orange).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  (isPrimary ? Colors.green : Colors.orange).withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Text(
            '$count',
            style: base.labelMedium?.copyWith(
              color: isPrimary ? Colors.green : Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectableDeckCard extends StatelessWidget {
  final Category category;
  final bool isOwned;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onPreview;
  final bool showPurchaseButton;

  const _SelectableDeckCard({
    required this.category,
    required this.isOwned,
    required this.isSelected,
    required this.onTap,
    required this.onPreview,
    this.showPurchaseButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final Color base = category.color;
    final Color background =
        Color.alphaBlend(base.withOpacity(0.25), scaffoldBg);
    final Color border =
        isSelected ? base.withOpacity(1.0) : base.withOpacity(0.5);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border, width: isSelected ? 2 : 1),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: base.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              // Selection indicator
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? base : Colors.white54,
                    width: 2,
                  ),
                  color: isSelected ? base : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
              const SizedBox(width: 12),

              // Deck image/icon
              if (category.imageAsset != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Image.asset(
                      category.imageAsset!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        category.icon,
                        color: Colors.white70,
                        size: 24,
                      ),
                    ),
                  ),
                )
              else
                Icon(category.icon, color: Colors.white70, size: 32),
              const SizedBox(width: 12),

              // Deck info
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${category.wordCount} words',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ],
                ),
              ),

              // Action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Preview button
                  IconButton(
                    onPressed: onPreview,
                    icon: const Icon(Icons.visibility_outlined,
                        color: Colors.white70),
                    tooltip: 'Preview words',
                  ),

                  // Purchase button (for locked decks)
                  if (showPurchaseButton && !isOwned)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      child: ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Get'),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewDialog extends StatelessWidget {
  final Category category;

  const _PreviewDialog({required this.category});

  @override
  Widget build(BuildContext context) {
    // Show 3 random words from the category
    final allWords = category.words.toList();
    allWords.shuffle();
    final sampleWords = allWords.take(3).toList();

    return AlertDialog(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      title: Row(
        children: [
          Icon(category.icon, color: category.color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              category.displayName,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sample words (${category.wordCount} total):',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ...sampleWords.map((word) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: category.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: category.color.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        word.text,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                    )),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '+${category.wordCount - 3} more',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
