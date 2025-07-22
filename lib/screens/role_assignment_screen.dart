import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game_setup_provider.dart';
import '../services/game_navigation_service.dart';
import 'word_lists_manager_screen.dart';
import 'package:convey/widgets/team_color_button.dart';
import 'package:convey/utils/category_utils.dart';

class RoleAssignmentScreen extends ConsumerStatefulWidget {
  final int teamIndex;
  final int roundNumber;
  final int turnNumber;
  final WordCategory category;

  const RoleAssignmentScreen({
    super.key,
    required this.teamIndex,
    required this.roundNumber,
    required this.turnNumber,
    required this.category,
  });

  @override
  ConsumerState<RoleAssignmentScreen> createState() =>
      _RoleAssignmentScreenState();
}

class _SwipeTutorialStep {
  final String text;
  final IconData icon;
  final Color color;
  final DismissDirection direction;
  final String directionText;
  _SwipeTutorialStep({
    required this.text,
    required this.icon,
    required this.color,
    required this.direction,
    required this.directionText,
  });
}

class _RoleAssignmentScreenState extends ConsumerState<RoleAssignmentScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedGuesser;
  String? _selectedConveyor;
  bool _isTransitioning = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _swipeStep = 0;
  bool _swipeRightDone = false;
  bool _swipeLeftDone = false;

  final List<_SwipeTutorialStep> _swipeSteps = [
    _SwipeTutorialStep(
      text: 'Swipe right for correct',
      icon: Icons.arrow_forward,
      color: Colors.green,
      direction: DismissDirection.startToEnd, // right swipe
      directionText: 'right',
    ),
    _SwipeTutorialStep(
      text: 'Swipe left to skip',
      icon: Icons.arrow_back,
      color: Colors.red,
      direction: DismissDirection.endToStart, // left swipe
      directionText: 'left',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    // Automatically assign roles at start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _assignRandomRoles();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _assignRandomRoles() {
    final gameConfig = ref.read(gameSetupProvider);
    final teams = gameConfig.teams;

    if (teams.isEmpty || widget.teamIndex >= teams.length) {
      return;
    }

    final team = teams[widget.teamIndex];
    if (team.length < 2) {
      return;
    }

    final random = team.toList()..shuffle();
    setState(() {
      _selectedGuesser = random[0];
      _selectedConveyor = random[1];
    });
  }

  void _showTransitionScreen() {
    setState(() {
      _isTransitioning = true;
    });
  }

  void _switchRoles() {
    setState(() {
      final temp = _selectedGuesser;
      _selectedGuesser = _selectedConveyor;
      _selectedConveyor = temp;
    });
    _animationController.forward(from: 0).then((_) {
      _animationController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedGuesser == null || _selectedConveyor == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Get the team color for the current team
    final gameConfig = ref.watch(gameSetupProvider);
    final colorIndex = (gameConfig.teamColorIndices.length > widget.teamIndex)
        ? gameConfig.teamColorIndices[widget.teamIndex]
        : widget.teamIndex % teamColors.length;
    final teamColor = teamColors[colorIndex];

    final Color categoryColor = CategoryUtils.getCategoryColor(widget.category);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBackground = isDark
        ? categoryColor.withOpacity(0.2)
        : categoryColor.withOpacity(0.1);
    final Color cardBorder =
        isDark ? categoryColor.withOpacity(0.8) : categoryColor;
    final Color cardShadow = isDark
        ? categoryColor.withOpacity(0.3)
        : categoryColor.withOpacity(0.2);

    if (_isTransitioning) {
      return Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(height: 150),
                      Text(
                        'Pass the phone to',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _selectedConveyor!,
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Conveyor',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              // No extra space above the card now
              Expanded(
                child: Center(
                  child: (_swipeRightDone && _swipeLeftDone)
                      ? SizedBox.shrink()
                      : Dismissible(
                          key: ValueKey(_swipeStep),
                          direction: _swipeSteps[_swipeStep].direction,
                          onDismissed: (direction) {
                            setState(() {
                              if (_swipeStep == 0 &&
                                  direction == DismissDirection.startToEnd) {
                                _swipeRightDone = true;
                                _swipeStep = 1;
                              } else if (_swipeStep == 1 &&
                                  direction == DismissDirection.endToStart) {
                                _swipeLeftDone = true;
                              }
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            height: 120,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 0),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 20),
                            decoration: BoxDecoration(
                              color: cardBackground,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: cardBorder,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: cardShadow,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_swipeStep == 1)
                                  Icon(Icons.arrow_back,
                                      color: Colors.red, size: 32),
                                if (_swipeStep == 1) SizedBox(width: 12),
                                Text(
                                  _swipeSteps[_swipeStep].text,
                                  style: TextStyle(
                                    color: _swipeSteps[_swipeStep].color,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_swipeStep == 0) SizedBox(width: 12),
                                if (_swipeStep == 0)
                                  Icon(Icons.arrow_forward,
                                      color: Colors.green, size: 32),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 200,
                child: TeamColorButton(
                  text: 'Start',
                  icon: Icons.play_arrow,
                  color: uiColors[1], // Green
                  onPressed: (_swipeRightDone && _swipeLeftDone)
                      ? () {
                          GameNavigationService.navigateToGameScreen(
                            context,
                            widget.teamIndex,
                            widget.roundNumber,
                            widget.turnNumber,
                            widget.category,
                          );
                        }
                      : null,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            // Category display (like TurnOverScreen)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? CategoryUtils.getCategoryColor(widget.category)
                        .withOpacity(0.3)
                    : CategoryUtils.getCategoryColor(widget.category)
                        .withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? CategoryUtils.getCategoryColor(widget.category)
                          .withOpacity(0.8)
                      : CategoryUtils.getCategoryColor(widget.category),
                  width: 2,
                ),
              ),
              child: Text(
                CategoryUtils.getCategoryName(widget.category),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.95)
                          : Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Choose Roles',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Column(
                children: [
                  // Conveyor Box
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (_animation.value * 0.03),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? teamColor.border.withOpacity(0.4)
                                  : teamColor.background,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? teamColor.background.withOpacity(0.3)
                                    : teamColor.border,
                                width: 2,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Text(
                                    _selectedConveyor!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          fontSize: 32,
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white.withOpacity(0.95)
                                              : Colors.black,
                                        ),
                                  ),
                                ),
                                Positioned(
                                  top: 16,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Text(
                                      'Conveyor',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white.withOpacity(0.95)
                                            : teamColor.text,
                                        fontSize: 22,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Switch Button
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? teamColor.border.withOpacity(0.2)
                          : teamColor.border.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? teamColor.border.withOpacity(0.8)
                            : teamColor.border,
                        width: 2,
                      ),
                    ),
                    child: IconButton(
                      onPressed: _switchRoles,
                      icon: Icon(
                        Icons.swap_vert,
                        size: 32,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? teamColor.border.withOpacity(0.9)
                            : teamColor.border,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Guesser Box
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (_animation.value * 0.03),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? teamColor.border.withOpacity(0.4)
                                  : teamColor.background,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? teamColor.background.withOpacity(0.3)
                                    : teamColor.border,
                                width: 2,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Text(
                                    _selectedGuesser!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          fontSize: 32,
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white.withOpacity(0.95)
                                              : Colors.black,
                                        ),
                                  ),
                                ),
                                Positioned(
                                  top: 16,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Text(
                                      'Guesser',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white.withOpacity(0.95)
                                            : teamColor.text,
                                        fontSize: 22,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                width: 200,
                child: TeamColorButton(
                  text: 'Pick For Us',
                  icon: Icons.shuffle,
                  color: uiColors[0], // Blue
                  onPressed: () {
                    _assignRandomRoles();
                    _showTransitionScreen();
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              child: TeamColorButton(
                text: 'Next',
                icon: Icons.arrow_forward,
                color: uiColors[1], // Green
                onPressed: () {
                  _showTransitionScreen();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
