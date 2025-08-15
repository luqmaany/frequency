import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game_setup_provider.dart';
import '../services/game_navigation_service.dart';
import '../models/game_config.dart';
import '../widgets/player_input.dart';
import 'package:convey/widgets/team_color_button.dart';
import '../widgets/parallel_pulse_waves_background.dart';

class GameSetupScreen extends ConsumerStatefulWidget {
  const GameSetupScreen({super.key});

  @override
  ConsumerState<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends ConsumerState<GameSetupScreen>
    with TickerProviderStateMixin {
  List<AnimationController> _controllers = [];
  List<Animation<double>> _animations = [];
  List<List<String>> _prevTeams = [];
  bool _dropAcceptedByTeam = false;
  bool _isDraggingTeamChip = false;

  @override
  void initState() {
    super.initState();
    final gameConfig = ref.read(gameSetupProvider);
    _initControllers(gameConfig.teams);
    _prevTeams = gameConfig.teams.map((t) => List<String>.from(t)).toList();

    // Reset setup on entry: return any names to suggestions and clear teams
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(gameSetupProvider.notifier).clearAllPlayers();
    });
  }

  @override
  void didUpdateWidget(covariant GameSetupScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final gameConfig = ref.read(gameSetupProvider);
    _updateTeamControllers(gameConfig.teams);
  }

  void _initControllers(List<List<String>> teams) {
    _controllers = List.generate(
      teams.length,
      (_) => AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );
    _animations = _controllers
        .map((c) => Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: c, curve: Curves.easeInOut),
            ))
        .toList();
    for (final c in _controllers) {
      c.forward(from: 0);
    }
  }

  void _updateTeamControllers(List<List<String>> teams) {
    // If team count increased, add controllers
    if (_controllers.length < teams.length) {
      final toAdd = teams.length - _controllers.length;
      for (int i = 0; i < toAdd; i++) {
        final c = AnimationController(
          duration: const Duration(milliseconds: 300),
          vsync: this,
        );
        _controllers.add(c);
        _animations.add(Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: c, curve: Curves.easeInOut),
        ));
        c.forward(from: 0);
      }
    }
    // If team count decreased, dispose and remove extra controllers
    if (_controllers.length > teams.length) {
      final toRemove = _controllers.length - teams.length;
      for (int i = 0; i < toRemove; i++) {
        _controllers.last.dispose();
        _controllers.removeLast();
        _animations.removeLast();
      }
    }
    // Animate only changed teams
    for (int i = 0; i < teams.length; i++) {
      if (_prevTeams.length <= i || !_listEquals(_prevTeams[i], teams[i])) {
        _controllers[i].forward(from: 0);
      }
    }
    _prevTeams = teams.map((t) => List<String>.from(t)).toList();
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<GameConfig>(gameSetupProvider, (previous, next) {
      _updateTeamControllers(next.teams);
    });
    final gameConfig = ref.watch(gameSetupProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Animated parallel waves background
          const Positioned.fill(
            child: ParallelPulseWavesBackground(
              perRowPhaseOffset: 0.1, // align crests across rows
              baseSpacing: 35.0, // more spacing between waves
            ),
          ),
          // Global DragTarget for removing players (background)
          Positioned.fill(
            child: DragTarget<String>(
              builder: (context, candidateData, rejectedData) {
                return Container(
                  decoration: BoxDecoration(
                    color: candidateData.isNotEmpty
                        ? Colors.red.withOpacity(0.1)
                        : Colors.transparent,
                    border: candidateData.isNotEmpty
                        ? Border.all(
                            color: Colors.red,
                            width: 2,
                            style: BorderStyle.solid)
                        : null,
                  ),
                  child: candidateData.isNotEmpty
                      ? Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Drop to remove player',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      : null,
                );
              },
              onWillAcceptWithDetails: (player) => true,
              onAcceptWithDetails: (details) {
                _dropAcceptedByTeam =
                    true; // Prevent onDragEnd from removing the player
                ref.read(gameSetupProvider.notifier).removePlayer(details.data);
              },
            ),
          ),
          // Main content with pinned header and scrollable content
          Column(
            children: [
              SafeArea(
                bottom: false,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Center(
                    child: Text(
                      'Team Setup',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const SizedBox(height: 8),
                    const PlayerInput(),
                    Column(
                      children: List.generate(teamColors.length, (i) {
                        final teamColor = teamColors[i];
                        final Color background = Color.alphaBlend(
                          teamColor.border.withOpacity(0.6),
                          Theme.of(context).colorScheme.background,
                        );
                        final Color border = teamColor.border.withOpacity(1);
                        final teamIdx = gameConfig.teamColorIndices.indexOf(i);
                        final List<String> players = teamIdx >= 0
                            ? gameConfig.teams[teamIdx]
                                .where((p) => p.isNotEmpty)
                                .toList()
                            : <String>[];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: DragTarget<String>(
                            builder: (context, candidateData, rejectedData) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 10),
                                decoration: BoxDecoration(
                                  color: background,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: border,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Center(
                                          child: Text(
                                            teamColor.name,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 18,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.circle,
                                                  color: border, size: 22),
                                              const SizedBox(width: 8),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (players.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Wrap(
                                        alignment: WrapAlignment.center,
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: players.map((player) {
                                          return DragTarget<String>(
                                            builder:
                                                (context, candidate, rejected) {
                                              return Draggable<String>(
                                                data: player,
                                                dragAnchorStrategy:
                                                    pointerDragAnchorStrategy,
                                                feedback: Transform.translate(
                                                  offset:
                                                      const Offset(-30, -70),
                                                  child: Material(
                                                    color: Colors.transparent,
                                                    child: Chip(
                                                      label: Text(player),
                                                      backgroundColor:
                                                          Colors.grey[800],
                                                      side: const BorderSide(
                                                          color: Colors.white),
                                                      materialTapTargetSize:
                                                          MaterialTapTargetSize
                                                              .shrinkWrap,
                                                      visualDensity:
                                                          VisualDensity.compact,
                                                      labelPadding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                              horizontal: 8,
                                                              vertical: 1),
                                                    ),
                                                  ),
                                                ),
                                                childWhenDragging: Opacity(
                                                  opacity: 0.5,
                                                  child: Chip(
                                                    label: Text(player),
                                                    backgroundColor: teamColor
                                                        .background
                                                        .withOpacity(0.2),
                                                    side: BorderSide(
                                                        color:
                                                            teamColor.border),
                                                    materialTapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                    labelPadding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 8,
                                                            vertical: 1),
                                                  ),
                                                ),
                                                child: Chip(
                                                  label: Text(player),
                                                  backgroundColor: teamColor
                                                      .background
                                                      .withOpacity(0.2),
                                                  side: BorderSide(
                                                      color: teamColor.border),
                                                  materialTapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                  labelPadding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 1),
                                                ),
                                                onDragStarted: () {
                                                  _dropAcceptedByTeam = false;
                                                  setState(() {
                                                    _isDraggingTeamChip = true;
                                                  });
                                                },
                                                onDragEnd: (details) {
                                                  if (!_dropAcceptedByTeam) {
                                                    ref
                                                        .read(gameSetupProvider
                                                            .notifier)
                                                        .removePlayer(player);
                                                  }
                                                  _dropAcceptedByTeam = false;
                                                  setState(() {
                                                    _isDraggingTeamChip = false;
                                                  });
                                                },
                                              );
                                            },
                                            onWillAcceptWithDetails:
                                                (details) => true,
                                            onAcceptWithDetails: (details) {
                                              _dropAcceptedByTeam = true;
                                              ref
                                                  .read(gameSetupProvider
                                                      .notifier)
                                                  .swapWithColorPlayer(
                                                      details.data, player, i);
                                            },
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                            onWillAcceptWithDetails: (details) => true,
                            onAcceptWithDetails: (details) {
                              _dropAcceptedByTeam = true;
                              ref
                                  .read(gameSetupProvider.notifier)
                                  .movePlayerToColor(details.data, i);
                            },
                          ),
                        );
                      }),
                    ),
                    if (gameConfig.teams.expand((t) => t).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 150,
                              child: TeamColorButton(
                                text: 'Clear',
                                icon: Icons.clear,
                                color: uiColors[2],
                                onPressed: () {
                                  ref
                                      .read(gameSetupProvider.notifier)
                                      .clearAllPlayers();
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 150,
                              child: TeamColorButton(
                                text: 'Shuffle',
                                icon: Icons.shuffle,
                                color: uiColors[0],
                                onPressed: () {
                                  ref
                                      .read(gameSetupProvider.notifier)
                                      .shuffleTeams();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                child: _isDraggingTeamChip
                    ? Center(
                        child: TeamColorButton(
                          text: 'Delete',
                          icon: Icons.delete_outline,
                          color: uiColors[2],
                          onPressed: () {},
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: TeamColorButton(
                              text: 'Home',
                              icon: Icons.home,
                              color: uiColors[0],
                              onPressed: () async {
                                await ref
                                    .read(gameSetupProvider.notifier)
                                    .clearAllPlayers();
                                if (mounted) {
                                  Navigator.of(context)
                                      .popUntil((route) => route.isFirst);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TeamColorButton(
                              text: 'Next',
                              icon: Icons.arrow_forward,
                              color: uiColors[1],
                              onPressed: gameConfig.teams.length >= 2 &&
                                      gameConfig.teams.every((team) =>
                                          team
                                              .where(
                                                  (player) => player.isNotEmpty)
                                              .length ==
                                          2)
                                  ? () async {
                                      // Persist current team players to storage
                                      await ref
                                          .read(gameSetupProvider.notifier)
                                          .persistTeamPlayers();
                                      // Also queue them for future suggestions
                                      await ref
                                          .read(gameSetupProvider.notifier)
                                          .addCurrentPlayersToQueue();
                                      // Navigate to game settings
                                      GameNavigationService
                                          .navigateToGameSettings(context);
                                    }
                                  : null,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
