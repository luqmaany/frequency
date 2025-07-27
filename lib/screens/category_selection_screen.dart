import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import 'dart:async';
import 'word_lists_manager_screen.dart';
import '../services/game_navigation_service.dart';
import '../services/game_state_provider.dart';
import '../utils/category_utils.dart';
import 'package:convey/widgets/team_color_button.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CategorySelectionScreen extends ConsumerStatefulWidget {
  final int teamIndex;
  final int roundNumber;
  final int turnNumber;
  final String displayString;
  final String? currentTeamDeviceId;
  final String? sessionId; // Add sessionId for online games

  const CategorySelectionScreen({
    super.key,
    required this.teamIndex,
    required this.roundNumber,
    required this.turnNumber,
    required this.displayString,
    this.currentTeamDeviceId,
    this.sessionId, // Add sessionId for online games
  });

  @override
  ConsumerState<CategorySelectionScreen> createState() =>
      _CategorySelectionScreenState();
}

class _CategorySelectionScreenState
    extends ConsumerState<CategorySelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  bool _isSpinning = false;
  WordCategory? _selectedCategory;
  String _currentCategory = '';
  Timer? _categoryTimer;
  int _spinCount = 0;
  static const int _totalSpins = 30; // More spins for smoother effect
  static const int _initialDelay = 25; // Faster initial speed
  static const int _finalDelay = 120; // Smoother final speed
  String? _currentDeviceId; // Add this to track current device

  @override
  void initState() {
    super.initState();

    // Scale animation controller for tap feedback
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    // Setup animations
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    // Get current device ID
    _getCurrentDeviceId();

    // For online games, listen to spin state changes
    if (widget.sessionId != null) {
      _listenToSpinState();
    }
  }

  Future<void> _getCurrentDeviceId() async {
    // Import StorageService at the top of the file
    final deviceId = await StorageService.getDeviceId();
    setState(() {
      _currentDeviceId = deviceId;
    });
  }

  // Listen to spin state changes from Firestore for synchronized animation
  void _listenToSpinState() {
    if (widget.sessionId == null) return;

    FirebaseFirestore.instance
        .collection('sessions')
        .doc(widget.sessionId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final gameState = data['gameState'] as Map<String, dynamic>?;
      final categorySpin = gameState?['categorySpin'] as Map<String, dynamic>?;

      if (categorySpin != null) {
        final isSpinning = categorySpin['isSpinning'] as bool? ?? false;
        final spinCount = categorySpin['spinCount'] as int? ?? 0;
        final currentCategory =
            categorySpin['currentCategory'] as String? ?? '';
        final selectedCategory =
            categorySpin['selectedCategory'] as String? ?? '';

        setState(() {
          _isSpinning = isSpinning;
          _spinCount = spinCount;
          _currentCategory = currentCategory;
          if (selectedCategory.isNotEmpty) {
            _selectedCategory = _getCategoryFromName(selectedCategory);
          }
        });
      }
    });
  }

  // Check if current device is the active team
  bool get _isCurrentTeamActive {
    // For local games (no sessionId), always allow interaction
    if (widget.sessionId == null) {
      return true;
    }
    // For online games, check if current device matches the active team
    // If no deviceId is stored for the current team, allow all teams to interact (fallback)
    if (widget.currentTeamDeviceId == null) {
      return true;
    }
    return _currentDeviceId != null &&
        _currentDeviceId == widget.currentTeamDeviceId;
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _categoryTimer?.cancel();

    // Clean up spin state for online games
    if (widget.sessionId != null) {
      FirestoreService.updateCategorySpinState(
        widget.sessionId!,
        isSpinning: false,
        currentCategory: '',
        selectedCategory: '',
      );
    }

    super.dispose();
  }

  WordCategory _getCategoryFromName(String categoryName) {
    switch (categoryName) {
      case 'Person':
        return WordCategory.person;
      case 'Action':
        return WordCategory.action;
      case 'World':
        return WordCategory.world;
      case 'Random':
        return WordCategory.random;
      default:
        return WordCategory.person; // fallback
    }
  }

  void _spinCategories() async {
    if (_isSpinning) return;

    // Only the active team can trigger the spin
    if (!_isCurrentTeamActive) return;

    // For online games, sync the spin state to Firestore
    if (widget.sessionId != null) {
      await FirestoreService.updateCategorySpinState(
        widget.sessionId!,
        isSpinning: true,
        spinCount: 0,
        currentCategory: '',
      );
    } else {
      // For local games, just update local state
      setState(() {
        _isSpinning = true;
        _selectedCategory = null;
        _spinCount = 0;
        _currentCategory = '';
      });
    }

    // Add a subtle scale animation for feedback
    _scaleController.forward().then((_) => _scaleController.reverse());

    void updateCategory() async {
      if (_spinCount >= _totalSpins) {
        _categoryTimer?.cancel();

        // Final selection with smooth transition
        final finalCategory = WordCategory
            .values[math.Random().nextInt(WordCategory.values.length)];
        final finalCategoryName = CategoryUtils.getCategoryName(finalCategory);

        if (widget.sessionId != null) {
          // For online games, sync the final result
          await FirestoreService.updateCategorySpinState(
            widget.sessionId!,
            isSpinning: false,
            selectedCategory: finalCategoryName,
            currentCategory: finalCategoryName,
          );
        } else {
          // For local games, just update local state
          setState(() {
            _isSpinning = false;
            _selectedCategory = finalCategory;
            _currentCategory = finalCategoryName;
          });
        }

        // Add a celebration animation
        _scaleController.forward().then((_) => _scaleController.reverse());
        return;
      }

      final newCategory = CategoryUtils.getCategoryName(WordCategory
          .values[math.Random().nextInt(WordCategory.values.length)]);

      if (widget.sessionId != null) {
        // For online games, sync the current category
        await FirestoreService.updateCategorySpinState(
          widget.sessionId!,
          currentCategory: newCategory,
          spinCount: _spinCount + 1,
        );
      } else {
        // For local games, just update local state
        setState(() {
          _currentCategory = newCategory;
        });
      }

      _spinCount++;

      // Use an easing curve for more natural deceleration
      final progress = _spinCount / _totalSpins;
      final easedProgress = Curves.easeInOut.transform(progress);
      final delay =
          (_initialDelay + ((_finalDelay - _initialDelay) * easedProgress))
              .round();

      _categoryTimer = Timer(Duration(milliseconds: delay), updateCategory);
    }

    updateCategory();
  }

  @override
  Widget build(BuildContext context) {
    // Get the team color for the current team
    final gameState = ref.watch(gameStateProvider);
    TeamColor teamColor;
    if (gameState != null) {
      final colorIndex =
          (gameState.config.teamColorIndices.length > widget.teamIndex)
              ? gameState.config.teamColorIndices[widget.teamIndex]
              : widget.teamIndex % teamColors.length;
      teamColor = teamColors[colorIndex];
    } else {
      // Fallback to first team color if game state is not available
      teamColor = teamColors[0];
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.displayString,
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    // Show waiting message for non-active teams in online games
                    if (widget.sessionId != null && !_isCurrentTeamActive) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.hourglass_empty,
                                color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(
                              'Waiting for ${widget.displayString} to select category...',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    GestureDetector(
                      onTap: (_isCurrentTeamActive &&
                              !_isSpinning &&
                              _selectedCategory == null)
                          ? _spinCategories
                          : null,
                      child: AnimatedBuilder(
                        animation: _scaleController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Container(
                              width: 300,
                              height: 300,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _currentCategory.isNotEmpty
                                      ? CategoryUtils.getCategoryColor(
                                          _getCategoryFromName(
                                              _currentCategory))
                                      : teamColor.text,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 150),
                                  transitionBuilder: (Widget child,
                                      Animation<double> animation) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                                  child: Text(
                                    _currentCategory.isEmpty
                                        ? 'TAP TO SPIN\nFOR CATEGORY!'
                                        : _currentCategory,
                                    key: ValueKey<String>(_currentCategory),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .displayLarge
                                        ?.copyWith(
                                          color: _currentCategory.isNotEmpty
                                              ? CategoryUtils.getCategoryColor(
                                                  _getCategoryFromName(
                                                      _currentCategory))
                                              : teamColor.text,
                                          fontSize: _currentCategory.isEmpty
                                              ? 32
                                              : null,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: AnimatedOpacity(
                opacity: _selectedCategory != null ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Row(
                  children: [
                    Expanded(
                      child: TeamColorButton(
                        text: 'Next',
                        icon: Icons.arrow_forward,
                        color: uiColors[1], // Green
                        onPressed:
                            (_isCurrentTeamActive && _selectedCategory != null)
                                ? () async {
                                    if (widget.sessionId != null) {
                                      // For online games, update game state with selected category and change status
                                      await FirestoreService
                                          .updateGameStateForRoleAssignment(
                                        widget.sessionId!,
                                        selectedCategory: _selectedCategory!,
                                      );
                                    } else {
                                      // For local games, use the existing navigation service
                                      GameNavigationService
                                          .navigateFromCategorySelection(
                                        context,
                                        ref,
                                        widget.teamIndex,
                                        widget.roundNumber,
                                        widget.turnNumber,
                                        _selectedCategory!,
                                      );
                                    }
                                  }
                                : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
