import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game_setup_provider.dart';
import '../services/game_navigation_service.dart';
import 'package:convey/widgets/team_color_button.dart';
import 'package:convey/widgets/static_radial_circles_background.dart';
import '../data/category_registry.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';
import '../services/online_game_navigation_service.dart';
import '../providers/session_providers.dart';
import '../widgets/confirm_on_back.dart';
import '../widgets/quit_dialog.dart';

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
    with TickerProviderStateMixin {
  String? _selectedGuesser;
  String? _selectedConveyor;
  bool _isTransitioning = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  late AnimationController _fadeController; // controls fade-out of pre UI
  late Animation<double> _preOpacity; // 1 -> 0 during fade
  double _postOpacity = 0.0; // 0 -> 1 when post UI appears
  int _swipeStep = 0;
  bool _swipeRightDone = false;
  bool _swipeLeftDone = false;
  String? _currentDeviceId;

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
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _preOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _selectedConveyor = widget.onlineTeam?['players']?[0];
    _selectedGuesser = widget.onlineTeam?['players']?[1];
    // Get current device ID
    _getCurrentDeviceId();

    // Initialize roles for local gameplay (no sessionId). Use current team from setup provider.
    if (widget.sessionId == null) {
      final gameConfig = ref.read(gameSetupProvider);
      if (gameConfig.teams.isNotEmpty &&
          widget.teamIndex < gameConfig.teams.length) {
        final teamPlayers = gameConfig.teams[widget.teamIndex]
            .where((p) => p.isNotEmpty)
            .toList();
        if (teamPlayers.length >= 2) {
          _selectedConveyor = teamPlayers[0];
          _selectedGuesser = teamPlayers[1];
        }
      }
    }
  }

  Future<void> _getCurrentDeviceId() async {
    final deviceId = await StorageService.getDeviceId();
    setState(() {
      _currentDeviceId = deviceId;
    });
  }

  // Check if current device should show the swipe tutorial (only conveyor)
  bool get _shouldShowSwipeTutorial {
    // For local games, always show if it's the active team
    if (widget.sessionId == null) {
      return _isCurrentTeamActive;
    }

    // For online games, only show to the conveyor's device
    if (!_isCurrentTeamActive || _selectedConveyor == null) {
      return false;
    }

    final teamMode = widget.onlineTeam!['teamMode'] as String? ?? 'couch';

    if (teamMode == 'couch') {
      // Couch mode: show tutorial (both players on same device)
      return true;
    } else if (teamMode == 'remote') {
      // Remote mode: only show to the conveyor's device
      final devices = widget.onlineTeam!['devices'] as List?;
      if (devices != null && _currentDeviceId != null) {
        for (final device in devices) {
          if (device['deviceId'] == _currentDeviceId &&
              device['playerName'] == _selectedConveyor) {
            return true;
          }
        }
      }
    }

    return false;
  }

  // Check if current user is the guesser (for navigation routing)
  bool get _isCurrentUserGuesser {
    // For local games, this doesn't apply (both players see game screen)
    if (widget.sessionId == null) {
      return false;
    }

    // For online games, check if current user is the guesser
    if (!_isCurrentTeamActive ||
        _selectedGuesser == null ||
        _currentDeviceId == null) {
      return false;
    }

    final teamMode = widget.onlineTeam!['teamMode'] as String? ?? 'couch';

    if (teamMode == 'couch') {
      // Couch mode: both players see game screen, so no guesser routing needed
      return false;
    } else if (teamMode == 'remote') {
      // Remote mode: check if current device belongs to the guesser
      final devices = widget.onlineTeam!['devices'] as List?;
      if (devices != null) {
        for (final device in devices) {
          if (device['deviceId'] == _currentDeviceId &&
              device['playerName'] == _selectedGuesser) {
            return true;
          }
        }
      }
    }

    return false;
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
    _animationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _assignRandomRoles() {
    List<String> teamPlayers = [];

    if (widget.onlineTeam != null) {
      final players = widget.onlineTeam!['players'] as List?;
      if (players != null && players.length >= 2) {
        teamPlayers = players.map((p) => p.toString()).toList();
      }
    } else {
      final gameConfig = ref.read(gameSetupProvider);
      final teams = gameConfig.teams;
      if (teams.isNotEmpty && widget.teamIndex < teams.length) {
        teamPlayers = teams[widget.teamIndex];
      }
    }

    if (teamPlayers.length < 2) {
      throw Exception(
          'Cannot determine team players. Expected at least 2 players, but got ${teamPlayers.length}');
    }

    final random = teamPlayers.toList()..shuffle();

    if (widget.sessionId != null) {
      _updateRoleAssignment(random[0], random[1], false);
    } else {
      setState(() {
        _selectedGuesser = random[0];
        _selectedConveyor = random[1];
      });
    }
  }

  void _updateRoleAssignment(
      String guesser, String conveyor, bool isTransitioning) {
    if (widget.sessionId != null) {
      FirestoreService.updateRoleAssignment(
        widget.sessionId!,
        guesser: guesser,
        conveyor: conveyor,
        isTransitioning: isTransitioning,
      );
    } else {
      setState(() {
        _selectedGuesser = guesser;
        _selectedConveyor = conveyor;
        _isTransitioning = isTransitioning;
      });
    }
  }

  void _showTransitionScreen() {
    // Fade out pre UI, then flip to transitioning and fade in post UI
    _fadeController.forward(from: 0).then((_) {
      setState(() {
        _isTransitioning = true;
        _postOpacity = 0.0;
      });
      // small delay to ensure rebuild completes before animating in
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _postOpacity = 1.0;
        });
      });
      if (widget.sessionId != null) {
        _updateRoleAssignment(_selectedGuesser!, _selectedConveyor!, true);
      }
    });
  }

  void _switchRoles() {
    if (!_isCurrentTeamActive) return;

    final temp = _selectedGuesser;
    final newGuesser = _selectedConveyor;
    final newConveyor = temp;

    if (widget.sessionId != null) {
      _updateRoleAssignment(newGuesser!, newConveyor!, _isTransitioning);
    } else {
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
    // For online games, wait for role data; for local games, continue rendering.
    if (widget.sessionId != null &&
        (_selectedGuesser == null || _selectedConveyor == null)) {
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
            // Once transitioning, keep it true to prevent flicker back to the role UI
            _isTransitioning = _isTransitioning || isTransitioning;
            if (isTransitioning) {
              // Ensure non-active devices reveal post UI as well
              _postOpacity = 1.0;
            }
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
    final Color scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    // Blend category color with app background to emulate translucent effect
    final Color cardBackground =
        Color.alphaBlend(categoryColor.withOpacity(0.25), scaffoldBg);
    final Color cardBorder = categoryColor;
    // final Color cardShadow = isDark
    //     ? categoryColor.withOpacity(0.3)
    //     : categoryColor.withOpacity(0.2);

    // Unified single-scaffold design (no separate transitioning scaffold)

    return ConfirmOnBack(
      dialogBuilder: (ctx) => QuitDialog(color: teamColor),
      onConfirmed: (ctx) async {
        await GameNavigationService.quitToHome(ctx, ref);
      },
      onWillPopOverride: (ctx) async {
        if (_isTransitioning) {
          setState(() {
            _isTransitioning = false;
            _swipeStep = 0;
            _swipeRightDone = false;
            _swipeLeftDone = false;
            _fadeController.reset();
            _postOpacity = 0.0;
          });
          return false; // intercept: go back to pre-next UI without dialog
        }
        return true; // normal flow (show dialog)
      },
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: StaticRadialCirclesBackground(
                centerAlignment: const Alignment(0, -0.22),
                ringColor: teamColor.border,
                baseOpacity: 0.22,
                highlightOpacity: 1,
                strokeWidth: 2.0,
                blendMode: BlendMode.srcOver,
                globalOpacity: 0.25,
                fullCircles: _isTransitioning,
                maxRings: _isTransitioning ? 60 : 27,
                pulseBaseRings: _isTransitioning ? 60 : 27,
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      'Choose Roles',
                      style: Theme.of(context).textTheme.headlineLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
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
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? CategoryRegistry.getCategory(
                                            widget.categoryId)
                                        .color
                                        .withOpacity(0.8)
                                    : CategoryRegistry.getCategory(
                                            widget.categoryId)
                                        .color,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          CategoryRegistry.getCategory(widget.categoryId)
                              .displayName,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white.withOpacity(0.95)
                                        : Colors.black,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    // Fixed positioning content area to prevent transmitter movement
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 75, 10, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Fixed transmitter section - always at top of content area
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: Text(
                                'Transmitter',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontSize: 26,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                              ),
                            ),
                            SizedBox(
                              height: 90,
                              child: AnimatedBuilder(
                                animation: _animation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: 1 + (_animation.value * 0.03),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _isTransitioning
                                            ? Colors.transparent
                                            : Color.alphaBlend(
                                                teamColor.border
                                                    .withOpacity(0.3),
                                                Theme.of(context)
                                                    .scaffoldBackgroundColor,
                                              ),
                                        borderRadius: BorderRadius.circular(
                                            _isTransitioning ? 10 : 12),
                                        border: Border.all(
                                          color: _isTransitioning
                                              ? Colors.transparent
                                              : Color.alphaBlend(
                                                  teamColor.border
                                                      .withOpacity(1),
                                                  Theme.of(context)
                                                      .scaffoldBackgroundColor,
                                                ),
                                          width: 2,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        _selectedConveyor!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .displayLarge,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Flexible content area for the rest
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (!_isTransitioning) ...[
                                    FadeTransition(
                                      opacity: _preOpacity,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          // Swap Button
                                          Center(
                                            child: IconButton(
                                              onPressed: _isCurrentTeamActive
                                                  ? _switchRoles
                                                  : null,
                                              icon: Icon(
                                                Icons.swap_vert,
                                                size: 48,
                                                color: _isCurrentTeamActive
                                                    ? teamColor.border
                                                        .withOpacity(0.95)
                                                    : teamColor.border
                                                        .withOpacity(0.4),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          // Receiver card with title beneath
                                          SizedBox(
                                            height: 90,
                                            child: AnimatedBuilder(
                                              animation: _animation,
                                              builder: (context, child) {
                                                return Transform.scale(
                                                  scale: 1.0 +
                                                      (_animation.value * 0.03),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Color.alphaBlend(
                                                        teamColor.border
                                                            .withOpacity(0.3),
                                                        Theme.of(context)
                                                            .scaffoldBackgroundColor,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      border: Border.all(
                                                        color: Color.alphaBlend(
                                                          teamColor.border
                                                              .withOpacity(1),
                                                          Theme.of(context)
                                                              .scaffoldBackgroundColor,
                                                        ),
                                                        width: 2,
                                                      ),
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      _selectedGuesser!,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .displayLarge,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Receiver',
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineSmall
                                                ?.copyWith(
                                                  fontSize: 26,
                                                  color: Colors.white
                                                      .withOpacity(0.9),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else ...[
                                    AnimatedOpacity(
                                      duration:
                                          const Duration(milliseconds: 250),
                                      opacity: _postOpacity,
                                      child: Center(
                                        child: (_shouldShowSwipeTutorial &&
                                                !(_swipeRightDone &&
                                                    _swipeLeftDone))
                                            ? Dismissible(
                                                key: ValueKey(_swipeStep),
                                                direction:
                                                    _swipeSteps[_swipeStep]
                                                        .direction,
                                                onDismissed: (direction) {
                                                  setState(() {
                                                    if (_swipeStep == 0 &&
                                                        direction ==
                                                            DismissDirection
                                                                .startToEnd) {
                                                      _swipeRightDone = true;
                                                      _swipeStep = 1;
                                                    } else if (_swipeStep ==
                                                            1 &&
                                                        direction ==
                                                            DismissDirection
                                                                .endToStart) {
                                                      _swipeLeftDone = true;
                                                    }
                                                  });
                                                },
                                                child: Container(
                                                  width: double.infinity,
                                                  height: 120,
                                                  margin: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 16,
                                                      vertical: 0),
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 24,
                                                      vertical: 20),
                                                  decoration: BoxDecoration(
                                                    color: cardBackground,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                    border: Border.all(
                                                      color: cardBorder,
                                                      width: 2,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      if (_swipeStep == 1)
                                                        const Icon(
                                                            Icons.arrow_back,
                                                            color: Colors.red,
                                                            size: 32),
                                                      if (_swipeStep == 1)
                                                        const SizedBox(
                                                            width: 12),
                                                      Flexible(
                                                        child: Text(
                                                          _swipeSteps[
                                                                  _swipeStep]
                                                              .text,
                                                          textAlign:
                                                              TextAlign.center,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          maxLines: 2,
                                                          style: TextStyle(
                                                            color: _swipeSteps[
                                                                    _swipeStep]
                                                                .color,
                                                            fontSize: 18,
                                                            height: 1.2,
                                                          ),
                                                        ),
                                                      ),
                                                      if (_swipeStep == 0)
                                                        const SizedBox(
                                                            width: 12),
                                                      if (_swipeStep == 0)
                                                        const Icon(
                                                            Icons.arrow_forward,
                                                            color: Colors.green,
                                                            size: 32),
                                                    ],
                                                  ),
                                                ),
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (!_isTransitioning) ...[
                      // Bottom actions row (pre-next)
                      FadeTransition(
                        opacity: _preOpacity,
                        child: Row(
                          children: [
                            if (_isCurrentTeamActive) ...[
                              IconOnlyColorButton(
                                icon: Icons.shuffle,
                                color: uiColors[0],
                                onPressed: () {
                                  _assignRandomRoles();
                                },
                                size: 56,
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: TeamColorButton(
                                text: _isCurrentTeamActive &&
                                        _shouldShowSwipeTutorial
                                    ? 'Next'
                                    : _isCurrentTeamActive
                                        ? 'Waiting for conveyor...'
                                        : 'Waiting...',
                                icon: _isCurrentTeamActive
                                    ? Icons.arrow_forward
                                    : Icons.hourglass_empty,
                                color: uiColors[1],
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 8),
                                onPressed: _isCurrentTeamActive &&
                                        _shouldShowSwipeTutorial
                                    ? () {
                                        _showTransitionScreen();
                                      }
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 250),
                        opacity: _postOpacity,
                        child: SizedBox(
                          width: double.infinity,
                          child: TeamColorButton(
                            text: _shouldShowSwipeTutorial
                                ? 'Start'
                                : 'Waiting...',
                            icon: _shouldShowSwipeTutorial
                                ? Icons.play_arrow
                                : Icons.hourglass_empty,
                            color: uiColors[1],
                            padding: const EdgeInsets.symmetric(
                                vertical: 18, horizontal: 12),
                            onPressed: _shouldShowSwipeTutorial &&
                                    (_swipeRightDone && _swipeLeftDone)
                                ? () async {
                                    if (widget.sessionId != null) {
                                      await FirestoreService.fromRoleAssignment(
                                        widget.sessionId!,
                                        guesser: _selectedGuesser!,
                                        conveyor: _selectedConveyor!,
                                      );
                                    } else {
                                      GameNavigationService
                                          .navigateToGameScreen(
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
                      ),
                    ],
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

class IconOnlyColorButton extends StatelessWidget {
  final IconData icon;
  final TeamColor color;
  final VoidCallback? onPressed;
  final double size;
  const IconOnlyColorButton(
      {super.key,
      required this.icon,
      required this.color,
      required this.onPressed,
      this.size = 40});

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    final Color background = color.border.withOpacity(0.4);
    final Color border = color.background.withOpacity(0.3);
    final Color iconColor = enabled ? border : Colors.grey.shade400;
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: enabled ? background : background.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: enabled ? onPressed : null,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: enabled ? border : Colors.grey.shade300, width: 1.5),
            ),
            child: Center(
              child: Icon(icon, size: size * 0.48, color: iconColor),
            ),
          ),
        ),
      ),
    );
  }
}
