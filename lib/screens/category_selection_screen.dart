import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderBox;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import 'dart:async';
import '../services/game_navigation_service.dart';
import '../services/game_state_provider.dart';
import '../data/category_registry.dart';
import 'package:convey/widgets/team_color_button.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';
import '../services/online_game_navigation_service.dart';
import '../providers/session_providers.dart';
import '../widgets/radial_ripple_background.dart';
import '../widgets/confirm_on_back.dart';
import '../widgets/quit_dialog.dart';

class CategorySelectionScreen extends ConsumerStatefulWidget {
  final int teamIndex;
  final int roundNumber;
  final int turnNumber;
  final String displayString;
  final String? currentTeamDeviceId;
  final String? sessionId; // Add sessionId for online games
  final Map<String, dynamic>?
      onlineTeam; // Add online team data for remote team checking

  const CategorySelectionScreen({
    super.key,
    required this.teamIndex,
    required this.roundNumber,
    required this.turnNumber,
    required this.displayString,
    this.currentTeamDeviceId,
    this.sessionId, // Add sessionId for online games
    this.onlineTeam, // Add online team data for remote team checking
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

  // Keys and alignment to keep background ripples centered to the circle
  final GlobalKey _stackKey = GlobalKey();
  final GlobalKey _circleKey = GlobalKey();
  Alignment _bgCenterAlignment = Alignment.center;

  void _updateBackgroundCenter() {
    if (!mounted) return;
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final circleBox =
        _circleKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null || circleBox == null) return;

    final Offset stackOriginGlobal = stackBox.localToGlobal(Offset.zero);
    final Offset circleOriginGlobal = circleBox.localToGlobal(Offset.zero);
    final Size circleSize = circleBox.size;
    final Offset circleCenterGlobal = circleOriginGlobal +
        Offset(circleSize.width / 2, circleSize.height / 2);

    // Convert to stack-local coordinates
    final Offset circleCenterLocal = circleCenterGlobal - stackOriginGlobal;
    final Size stackSize = stackBox.size;
    if (stackSize.width == 0 || stackSize.height == 0) return;

    final double xFraction =
        (circleCenterLocal.dx / stackSize.width).clamp(0.0, 1.0);
    final double yFraction =
        (circleCenterLocal.dy / stackSize.height).clamp(0.0, 1.0);
    final Alignment computed = Alignment(xFraction * 2 - 1, yFraction * 2 - 1);

    if (_bgCenterAlignment != computed) {
      setState(() {
        _bgCenterAlignment = computed;
      });
    }
  }

  bool _isSpinning = false;
  bool _hasSpun = false; // Track if spin has been used
  String? _selectedCategory;
  String _currentCategory = '';
  Timer? _categoryTimer;
  int _spinCount = 0;
  static const int _totalSpins = 30; // More spins for smoother effect
  static const int _initialDelay = 25; // Faster initial speed
  static const int _finalDelay = 120; // Smoother final speed
  String? _currentDeviceId; // Add this to track current device
  List<String> _unlockedCategoryIds = []; // Track unlocked categories

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

    // Load unlocked categories
    _loadUnlockedCategories();
  }

  Future<void> _getCurrentDeviceId() async {
    // Import StorageService at the top of the file
    final deviceId = await StorageService.getDeviceId();
    setState(() {
      _currentDeviceId = deviceId;
    });
  }

  Future<void> _loadUnlockedCategories() async {
    final unlockedCategories = await StorageService.getUnlockedCategoryIds();
    setState(() {
      _unlockedCategoryIds = unlockedCategories;
    });
  }

  // Check if current device is part of the active team (supports both couch and remote modes)
  bool get _isCurrentTeamActive {
    // For local games (no sessionId), always allow interaction
    if (widget.sessionId == null) {
      return true;
    }

    // For online games, check team mode
    if (widget.onlineTeam == null || _currentDeviceId == null) {
      return false;
    }

    final teamMode = widget.onlineTeam!['teamMode'] as String? ?? 'couch';

    if (teamMode == 'couch') {
      // Couch mode: check if current device matches the team's device
      return _currentDeviceId == widget.currentTeamDeviceId;
    } else if (teamMode == 'remote') {
      // Remote mode: check if current device is in the team's devices array
      final devices = widget.onlineTeam!['devices'] as List?;
      if (devices != null) {
        return devices.any((device) => device['deviceId'] == _currentDeviceId);
      }
    }

    return false;
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _categoryTimer?.cancel();

    super.dispose();
  }

  void _spinCategories() async {
    if (_isSpinning || _hasSpun) return; // Prevent spinning if already spun

    // Only the active team can trigger the spin
    if (!_isCurrentTeamActive) return;

    // For online games, no need to sync spinning state - keep it local only

    // Update local state for both local and online games
    setState(() {
      _isSpinning = true;
      _hasSpun = true; // Mark that spin has been used
      _selectedCategory = null;
      _spinCount = 0;
      _currentCategory = '';
    });

    // Add a subtle scale animation for feedback
    _scaleController.forward().then((_) => _scaleController.reverse());

    void updateCategory() async {
      if (_spinCount >= _totalSpins) {
        _categoryTimer?.cancel();

        // Final selection with smooth transition
        final unlockedCategories =
            CategoryRegistry.getUnlockedCategories(_unlockedCategoryIds);
        final finalCategory = unlockedCategories[
            math.Random().nextInt(unlockedCategories.length)];
        final finalCategoryName = finalCategory.displayName;

        // Always update local state so the active team sees Next immediately
        setState(() {
          _isSpinning = false;
          _selectedCategory = finalCategory.displayName;
          _currentCategory = finalCategoryName;
        });

        if (widget.sessionId != null) {
          // For online games, sync only the final result
          await FirestoreService.updateCategorySpinState(
            widget.sessionId!,
            selectedCategory: finalCategoryName,
          );
        }

        // Add a celebration animation
        _scaleController.forward().then((_) => _scaleController.reverse());
        return;
      }

      // Update the current category display for both local and online games
      final unlockedCategories =
          CategoryRegistry.getUnlockedCategories(_unlockedCategoryIds);
      final newCategory =
          unlockedCategories[math.Random().nextInt(unlockedCategories.length)];
      setState(() {
        _currentCategory = newCategory.displayName;
      });

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
    // After layout, measure circle position and align background center to it
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _updateBackgroundCenter());
    // Set up navigation listener for online games (only once per widget instance)
    if (widget.sessionId != null) {
      ref.listen(sessionStatusProvider(widget.sessionId!), (prev, next) {
        final status = next.value;
        if (status != null) {
          print(
              '🧭 CATEGORY SELECTION: Status changed to $status, navigating...');
          OnlineGameNavigationService.handleNavigation(
            context: context,
            ref: ref,
            sessionId: widget.sessionId!,
            status: status,
          );
        }
      });

      // Listen to category selection changes from Firestore
      ref.listen(sessionSelectedCategoryProvider(widget.sessionId!),
          (prev, next) {
        final selectedCategory = next.value;

        if (selectedCategory != null &&
            selectedCategory.isNotEmpty &&
            mounted) {
          print(
              '🎯 CATEGORY SELECTION: Received final category: $selectedCategory');
          setState(() {
            _selectedCategory = selectedCategory;
            _currentCategory = selectedCategory;
            _isSpinning =
                false; // Stop local spinning when category is selected
            _hasSpun = true; // Mark as spun when category is received
          });
        }
      });
    }

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

    return ConfirmOnBack(
      dialogBuilder: (ctx) => QuitDialog(color: teamColor),
      onConfirmed: (ctx) async {
        await GameNavigationService.quitToHome(ctx, ref);
      },
      child: Scaffold(
        body: Stack(
          key: _stackKey,
          children: [
            Positioned.fill(
              child: RadialRippleBackground(
                centerAlignment: _bgCenterAlignment,
                duration: const Duration(seconds: 100),
                ringColor: _selectedCategory != null
                    ? CategoryRegistry.getCategoryByDisplayName(
                            _selectedCategory!)
                        .color
                    : null,
              ),
            ),
            SafeArea(
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
                          GestureDetector(
                            onTap: (_isCurrentTeamActive &&
                                    !_isSpinning &&
                                    !_hasSpun)
                                ? _spinCategories
                                : null,
                            child: AnimatedBuilder(
                              animation: _scaleController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _scaleAnimation.value,
                                  child: Container(
                                    key: _circleKey,
                                    width: 300,
                                    height: 300,
                                    margin: const EdgeInsets.only(top: 0),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF0A0F1E),
                                      border: Border.all(
                                        color: _currentCategory.isNotEmpty
                                            ? CategoryRegistry
                                                    .getCategoryByDisplayName(
                                                        _currentCategory)
                                                .color
                                            : teamColor.text,
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 150),
                                        transitionBuilder: (Widget child,
                                            Animation<double> animation) {
                                          return FadeTransition(
                                            opacity: animation,
                                            child: child,
                                          );
                                        },
                                        child: Text(
                                          _currentCategory.isEmpty
                                              ? (_isCurrentTeamActive
                                                  ? (_hasSpun
                                                      ? 'SPINNING...'
                                                      : 'TAP TO SPIN\nFOR CATEGORY!')
                                                  : 'WAITING...')
                                              : _currentCategory,
                                          key: ValueKey<String>(
                                              _currentCategory),
                                          textAlign: TextAlign.center,
                                          style:
                                              Theme.of(context)
                                                  .textTheme
                                                  .displayLarge
                                                  ?.copyWith(
                                                    color: _currentCategory.isNotEmpty
                                                        ? CategoryRegistry
                                                                .getCategoryByDisplayName(
                                                                    _currentCategory)
                                                            .color
                                                        : teamColor.text,
                                                    fontSize:
                                                        _currentCategory.isEmpty
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
                              text:
                                  _isCurrentTeamActive ? 'Next' : 'Waiting...',
                              icon: _isCurrentTeamActive
                                  ? Icons.arrow_forward
                                  : Icons.hourglass_top,
                              color: _isCurrentTeamActive
                                  ? uiColors[1] // Green
                                  : uiColors[0], // Blue for waiting
                              onPressed: (_isCurrentTeamActive &&
                                      _selectedCategory != null)
                                  ? () async {
                                      if (widget.sessionId != null) {
                                        // For online games, update game state with selected category and change status
                                        await FirestoreService
                                            .fromCategorySelection(
                                          widget.sessionId!,
                                          selectedCategory: _selectedCategory!,
                                        );
                                      } else {
                                        // For local games, convert display name to ID before navigation
                                        final categoryId = CategoryRegistry
                                            .getCategoryFromDisplayName(
                                                _selectedCategory!);
                                        GameNavigationService
                                            .navigateFromCategorySelection(
                                          context,
                                          ref,
                                          widget.teamIndex,
                                          widget.roundNumber,
                                          widget.turnNumber,
                                          categoryId,
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
          ],
        ),
      ),
    );
  }
}
