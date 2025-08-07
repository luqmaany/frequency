import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game_setup_provider.dart';
import '../services/game_navigation_service.dart';
import 'package:convey/widgets/team_color_button.dart';
import '../data/category_registry.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';
import '../services/online_game_navigation_service.dart';
import '../providers/session_providers.dart';

class RoleAssignmentScreen extends ConsumerStatefulWidget {
  final int teamIndex;
  final int roundNumber;
  final int turnNumber;
  final String categoryId;

  // Online game parameters
  final String? sessionId;
  final Map<String, dynamic>? onlineTeam;
  final String? currentTeamDeviceId; // Add device ID for interaction control

  const RoleAssignmentScreen({
    super.key,
    required this.teamIndex,
    required this.roundNumber,
    required this.turnNumber,
    required this.categoryId,
    this.sessionId,
    this.onlineTeam,
    this.currentTeamDeviceId,
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
  String? _currentDeviceId;

  // TODO: Make text in swipe tutorial cards smaller to prevent overflow
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
    _selectedConveyor = widget.onlineTeam?['players']?[0];
    _selectedGuesser = widget.onlineTeam?['players']?[1];
    // Get current device ID
    _getCurrentDeviceId();
    _assignRandomRoles();
  }

  Future<void> _getCurrentDeviceId() async {
    final deviceId = await StorageService.getDeviceId();
    setState(() {
      _currentDeviceId = deviceId;
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
    _animationController.dispose();
    super.dispose();
  }

  void _assignRandomRoles() {
    List<String> teamPlayers = [];

    // Always get team players from the widget
    if (widget.onlineTeam != null) {
      // Online game: get team data from widget
      final players = widget.onlineTeam!['players'] as List?;
      if (players != null && players.length >= 2) {
        teamPlayers = players.map((p) => p.toString()).toList();
      }
    } else {
      // Local game: get team data from game setup provider
      final gameConfig = ref.read(gameSetupProvider);
      final teams = gameConfig.teams;

      if (teams.isNotEmpty && widget.teamIndex < teams.length) {
        teamPlayers = teams[widget.teamIndex];
      }
    }

    // Throw error if we don't have enough players
    if (teamPlayers.length < 2) {
      throw Exception(
          'Cannot determine team players. Expected at least 2 players, but got ${teamPlayers.length}');
    }

    final random = teamPlayers.toList()..shuffle();

    if (widget.sessionId != null) {
      // Online game: update Firestore
      _updateRoleAssignment(random[0], random[1], false);
    } else {
      // Local game: update local state
      setState(() {
        _selectedGuesser = random[0];
        _selectedConveyor = random[1];
      });
    }
  }

  void _updateRoleAssignment(
      String guesser, String conveyor, bool isTransitioning) {
    if (widget.sessionId != null) {
      // Online game: update Firestore
      FirestoreService.updateRoleAssignment(
        widget.sessionId!,
        guesser: guesser,
        conveyor: conveyor,
        isTransitioning: isTransitioning,
      );
    } else {
      // Local game: update local state
      setState(() {
        _selectedGuesser = guesser;
        _selectedConveyor = conveyor;
        _isTransitioning = isTransitioning;
      });
    }
  }

  void _showTransitionScreen() {
    if (widget.sessionId != null) {
      // Online game: update Firestore
      _updateRoleAssignment(_selectedGuesser!, _selectedConveyor!, true);
    } else {
      // Local game: update local state
      setState(() {
        _isTransitioning = true;
      });
    }
  }

  void _switchRoles() {
    if (!_isCurrentTeamActive) return; // Only current team can switch roles

    final temp = _selectedGuesser;
    final newGuesser = _selectedConveyor;
    final newConveyor = temp;

    if (widget.sessionId != null) {
      // Online game: update Firestore
      _updateRoleAssignment(newGuesser!, newConveyor!, _isTransitioning);
    } else {
      // Local game: update local state
      setState(() {
        _selectedGuesser = newGuesser;
        _selectedConveyor = newConveyor;
      });
    }

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

    // Set up navigation listener for online games
    if (widget.sessionId != null) {
      ref.listen(sessionStatusProvider(widget.sessionId!), (prev, next) {
        final status = next.value;
        if (status != null) {
          OnlineGameNavigationService.handleNavigation(
            context: context,
            ref: ref,
            sessionId: widget.sessionId!,
            status: status,
          );
        }
      });

      // Listen to role assignment changes from Firestore for synchronized viewing
      ref.listen(sessionRoleAssignmentProvider(widget.sessionId!),
          (prev, next) {
        final roleAssignment = next.value;
        if (roleAssignment != null && mounted) {
          final guesser = roleAssignment['guesser'] as String?;
          final conveyor = roleAssignment['conveyor'] as String?;
          final isTransitioning =
              roleAssignment['isTransitioning'] as bool? ?? false;

          setState(() {
            _selectedGuesser = guesser;
            _selectedConveyor = conveyor;
            _isTransitioning = isTransitioning;
          });
        }
      });
    }

    // Get the team color for the current team
    int colorIndex;
    if (widget.sessionId != null && widget.onlineTeam != null) {
      // Online game: use the provided color index
      colorIndex = widget.onlineTeam!['colorIndex'] as int? ?? 0;
    } else {
      // Local game: get color index from game setup provider
      final gameConfig = ref.watch(gameSetupProvider);
      colorIndex = (gameConfig.teamColorIndices.length > widget.teamIndex)
          ? gameConfig.teamColorIndices[widget.teamIndex]
          : widget.teamIndex % teamColors.length;
    }
    final teamColor = teamColors[colorIndex];

    final Color categoryColor =
        CategoryRegistry.getCategory(widget.categoryId).color;
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
                      // TODO: Change spectator text from "Pass the phone to" to something more appropriate for online games
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
                  child: (_swipeRightDone && _swipeLeftDone) ||
                          !_isCurrentTeamActive
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
                  onPressed: (_swipeRightDone && _swipeLeftDone) &&
                          _isCurrentTeamActive
                      ? () async {
                          if (widget.sessionId != null) {
                            await FirestoreService.fromRoleAssignment(
                              widget.sessionId!,
                              guesser: _selectedGuesser!,
                              conveyor: _selectedConveyor!,
                            );
                          } else {
                            GameNavigationService.navigateToGameScreen(
                              context,
                              widget.teamIndex,
                              widget.roundNumber,
                              widget.turnNumber,
                              widget.categoryId,
                            );
                          }
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
            Align(
              alignment: Alignment.center,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? CategoryRegistry.getCategory(widget.categoryId)
                          .color
                          .withOpacity(0.3)
                      : CategoryRegistry.getCategory(widget.categoryId)
                          .color
                          .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? CategoryRegistry.getCategory(widget.categoryId)
                            .color
                            .withOpacity(0.8)
                        : CategoryRegistry.getCategory(widget.categoryId).color,
                    width: 2,
                  ),
                ),
                child: Text(
                  CategoryRegistry.getCategory(widget.categoryId).displayName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.95)
                            : Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Choose Roles',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            // Show current team info for online games
            if (widget.sessionId != null && widget.onlineTeam != null) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? teamColor.border.withOpacity(0.2)
                      : teamColor.background.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: teamColor.border.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  _isCurrentTeamActive
                      ? 'Your turn to assign roles'
                      : '${widget.onlineTeam!['teamName'] ?? 'Team'}\'s turn',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: teamColor.text,
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
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
                          scale: 1 + (_animation.value * 0.03),
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
                          ? teamColor.border
                              .withOpacity(_isCurrentTeamActive ? 0.2 : 0.1)
                          : teamColor.border
                              .withOpacity(_isCurrentTeamActive ? 0.1 : 0.05),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? teamColor.border
                                .withOpacity(_isCurrentTeamActive ? 0.8 : 0.4)
                            : teamColor.border,
                        width: 2,
                      ),
                    ),
                    child: IconButton(
                      onPressed: _isCurrentTeamActive ? _switchRoles : null,
                      icon: Icon(
                        Icons.swap_vert,
                        size: 32,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? teamColor.border
                                .withOpacity(_isCurrentTeamActive ? 0.9 : 0.4)
                            : teamColor.border
                                .withOpacity(_isCurrentTeamActive ? 1.0 : 0.4),
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
            // Only show "Pick For Us" button for active team in online mode, or always in local mode
            if (_isCurrentTeamActive || widget.sessionId == null)
              Center(
                child: SizedBox(
                  width: 200,
                  child: TeamColorButton(
                    text: _isCurrentTeamActive ? 'Pick For Us' : 'Waiting...',
                    icon: _isCurrentTeamActive
                        ? Icons.shuffle
                        : Icons.hourglass_empty,
                    color: uiColors[0], // Blue
                    onPressed: _isCurrentTeamActive
                        ? () {
                            _assignRandomRoles();
                            _showTransitionScreen();
                          }
                        : null,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              child: TeamColorButton(
                text: _isCurrentTeamActive ? 'Next' : 'Waiting...',
                icon: _isCurrentTeamActive
                    ? Icons.arrow_forward
                    : Icons.hourglass_empty,
                color: uiColors[1], // Green
                onPressed: _isCurrentTeamActive
                    ? () {
                        _showTransitionScreen();
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
