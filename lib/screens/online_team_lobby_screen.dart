import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/team_color_button.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../providers/session_providers.dart';
import '../services/online_game_navigation_service.dart';

class OnlineTeamLobbyScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final String teamName;
  final String player1Name;
  final String player2Name;
  const OnlineTeamLobbyScreen(
      {Key? key,
      required this.sessionId,
      required this.teamName,
      required this.player1Name,
      required this.player2Name})
      : super(key: key);

  @override
  ConsumerState<OnlineTeamLobbyScreen> createState() =>
      _OnlineTeamLobbyScreenState();
}

class _OnlineTeamLobbyScreenState extends ConsumerState<OnlineTeamLobbyScreen>
    with TickerProviderStateMixin {
  late TextEditingController _teamNameController;
  late TextEditingController _player1Controller;
  late TextEditingController _player2Controller;
  int? _selectedColorIndex;
  bool _ready = false;
  bool _updating = false;
  late Future<String> _deviceIdFuture;
  late AnimationController _animationController;
  @override
  void initState() {
    super.initState();
    _teamNameController = TextEditingController(text: widget.teamName);
    _player1Controller = TextEditingController(text: widget.player1Name);
    _player2Controller = TextEditingController(text: widget.player2Name);
    _selectedColorIndex = null;
    _deviceIdFuture = StorageService.getDeviceId();

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();

    // Initialize color index from existing team data
    _initializeColorIndex();
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    _player1Controller.dispose();
    _player2Controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLeaveAndHostTransfer() async {
    await _removeTeamFromFirestore();
    final deviceId = await StorageService.getDeviceId();
    await FirestoreService.transferHostIfNeeded(widget.sessionId, deviceId);
    // Clear the stream cache when leaving
    FirestoreService.clearSessionStreamCache(widget.sessionId);
  }

  Future<void> _initializeColorIndex() async {
    try {
      final teams =
          await ref.read(sessionTeamsProvider(widget.sessionId).future);

      // Find our team and set the color index
      final colorIndex = await _getMyTeamColorIndex(teams);
      if (colorIndex != null) {
        setState(() {
          _selectedColorIndex = colorIndex;
        });
        // Trigger animation for initial display
        _animationController.forward(from: 0);
      }
    } catch (e) {
      print('Error initializing color index: $e');
    }
  }

  bool get _canPickColor =>
      _teamNameController.text.trim().isNotEmpty &&
      _player1Controller.text.trim().isNotEmpty &&
      _player2Controller.text.trim().isNotEmpty;

  // Helper to get the current team's color index from Firestore
  Future<int?> _getMyTeamColorIndex(List teams) async {
    final deviceId = await _deviceIdFuture;
    for (final t in teams) {
      // Check by device ID first (most reliable)
      if (t['deviceId'] == deviceId) {
        return t['colorIndex'] as int?;
      }
    }
    return null;
  }

  // Helper to build team data with device ID
  Future<Map<String, dynamic>> _getMyTeamDataWithDeviceId() async {
    final deviceId = await _deviceIdFuture;
    return {
      'teamName': _teamNameController.text.trim(),
      'colorIndex': _selectedColorIndex,
      'ready': true,
      'deviceId': deviceId, // Add device ID to team data
      'players': [
        _player1Controller.text.trim(),
        _player2Controller.text.trim(),
      ],
    };
  }

  // Add or update team in Firestore
  Future<void> _syncTeamToFirestore() async {
    if (_canPickColor && _selectedColorIndex != null) {
      final teams =
          await ref.read(sessionTeamsProvider(widget.sessionId).future);

      final deviceId = await _deviceIdFuture;
      // Remove any previous entry for this color or device ID
      teams.removeWhere((t) =>
          t['colorIndex'] == _selectedColorIndex || t['deviceId'] == deviceId);

      // Add team data with device ID
      final teamDataWithDeviceId = await _getMyTeamDataWithDeviceId();
      teams.add(teamDataWithDeviceId);

      await ref.read(updateTeamsProvider({
        'sessionId': widget.sessionId,
        'teams': teams,
      }).future);
    }
  }

  // Remove team from Firestore
  Future<void> _removeTeamFromFirestore() async {
    final teams = await ref.read(sessionTeamsProvider(widget.sessionId).future);

    final deviceId = await _deviceIdFuture;
    teams.removeWhere((t) =>
        t['deviceId'] == deviceId || t['colorIndex'] == _selectedColorIndex);

    await ref.read(updateTeamsProvider({
      'sessionId': widget.sessionId,
      'teams': teams,
    }).future);
  }

  // Watch for changes to color and sync
  void _onColorChanged() {
    if (_ready) {
      // If ready, but color becomes invalid, remove from Firestore and reset ready
      if (_selectedColorIndex == null) {
        _removeTeamFromFirestore();
        setState(() {
          _ready = false;
        });
      }
    }
    setState(() {});
  }

  // Watch for changes to team/player names and reset ready state
  void _onNameChanged() {
    if (_ready) {
      // If names changed while ready, remove from Firestore and reset ready
      _removeTeamFromFirestore();
      setState(() {
        _ready = false;
      });
    }
    setState(() {});
  }

  Future<void> _onReadyPressed() async {
    await _syncTeamToFirestore();
    setState(() {
      _ready = true;
    });
  }

  // Ensure all teams have deviceIds before starting the game
  Future<void> _ensureAllTeamsHaveDeviceIds() async {
    final teams = await ref.read(sessionTeamsProvider(widget.sessionId).future);

    for (final team in teams) {
      if (team['deviceId'] == null) {
        // This team doesn't have a deviceId, but we can't fix it automatically
        // In practice, all teams should have deviceIds when they're ready
        print('Warning: Found team without deviceId: $team');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionStreamProvider(widget.sessionId));

    // Set up navigation listener for online games (only once per widget instance)
    ref.listen(sessionStatusProvider(widget.sessionId), (prev, next) {
      final status = next.value;
      if (status != null) {
        OnlineGameNavigationService.handleNavigation(
          context: context,
          ref: ref,
          sessionId: widget.sessionId,
          status: status,
        );
      }
    });

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          // Manual navigation - always remove team
          await _handleLeaveAndHostTransfer();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Team Lobby'),
        ),
        body: sessionAsync.when(
          data: (sessionSnap) {
            final sessionData = sessionSnap?.data();
            if (sessionData == null) {
              return const Center(child: Text('Session not found'));
            }

            final teams = (sessionData['teams'] as List?) ?? [];

            // Host logic
            final hostId = sessionData['hostId'] as String?;

            return FutureBuilder<String>(
              future: _deviceIdFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return const Center(child: Text('Error loading device ID'));
                }
                final deviceId = snapshot.data;
                final isHost = deviceId != null && deviceId == hostId;
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              const Text('Session Code',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500)),
                              SelectableText(
                                widget.sessionId,
                                style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2),
                              ),
                            ],
                          ),
                        ),
                        // Team Setup Section
                        const SizedBox(height: 10),
                        const Text('Team Setup',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 45,
                          child: TextField(
                            controller: _teamNameController,
                            decoration: const InputDecoration(
                              labelText: 'Team Name',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            onChanged: (value) {
                              _onNameChanged();
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 45,
                                child: TextField(
                                  controller: _player1Controller,
                                  decoration: const InputDecoration(
                                    labelText: 'Player 1 Name',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                  onChanged: (value) {
                                    _onNameChanged();
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 45,
                                child: TextField(
                                  controller: _player2Controller,
                                  decoration: const InputDecoration(
                                    labelText: 'Player 2 Name',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                  onChanged: (value) {
                                    _onNameChanged();
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text('Pick a Team Color:',
                            style: TextStyle(fontSize: 16)),
                        const SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: teamColors.length,
                          itemBuilder: (context, i) {
                            final myColorIndex = _getMyTeamColorIndex(teams);
                            final isSelected = _selectedColorIndex == i;
                            final teamColor = teamColors[i];
                            // Find the team (if any) that owns this color
                            final teamForColor = teams.firstWhere(
                              (team) => team['colorIndex'] == i,
                              orElse: () => null,
                            );
                            final colorTaken = teamForColor != null;
                            final teamIsReady =
                                colorTaken && (teamForColor['ready'] == true);
                            String infoText = '';
                            if (colorTaken) {
                              final tName =
                                  (teamForColor['teamName'] as String?)
                                          ?.trim() ??
                                      '';
                              final players = (teamForColor['players'] as List?)
                                      ?.whereType<String>()
                                      .toList() ??
                                  [];
                              infoText = tName.isNotEmpty
                                  ? tName
                                  : (players.length == 2
                                      ? '${players[0]} & ${players[1]}'
                                      : players.join(' & '));
                            }
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: (colorTaken &&
                                            (!isSelected ||
                                                myColorIndex != i) ||
                                        _updating)
                                    ? null
                                    : () async {
                                        // Unfocus any active text field
                                        FocusScope.of(context).unfocus();
                                        setState(() {
                                          _selectedColorIndex = i;
                                        });
                                        _animationController.forward(from: 0);
                                        if (_ready) {
                                          await _syncTeamToFirestore();
                                        } else {
                                          _onColorChanged();
                                        }
                                      },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: teamColor.background,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? teamColor.border
                                          : teamColor.border.withOpacity(0.5),
                                      width: isSelected ? 2.5 : 1.5,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: teamColor.border
                                                  .withOpacity(0.18),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment
                                            .center, // ensure vertical centering
                                        children: [
                                          Icon(Icons.circle,
                                              color: teamColor.border,
                                              size: 22),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              teamColor.name,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 18,
                                                color: teamColor.text,
                                              ),
                                            ),
                                          ),
                                          if (teamIsReady) ...[
                                            const SizedBox(width: 8),
                                            Icon(Icons.check_circle,
                                                color: Colors.green, size: 22),
                                          ],
                                        ],
                                      ),
                                      if (colorTaken &&
                                          infoText.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          infoText,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 15,
                                            color:
                                                teamColor.text.withOpacity(0.9),
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        if (_updating)
                          const Center(child: CircularProgressIndicator()),
                        // Ready/Waiting/Start Game button logic
                        if (_ready && isHost && teams.length >= 2)
                          TeamColorButton(
                            text: 'Start Game',
                            icon: Icons.play_arrow_rounded,
                            color: _selectedColorIndex != null
                                ? teamColors[_selectedColorIndex!]
                                : teamColors[0],
                            onPressed: () async {
                              // Ensure all teams have deviceIds before starting
                              await _ensureAllTeamsHaveDeviceIds();
                              await ref.read(updateGameStateStatusProvider({
                                'sessionId': widget.sessionId,
                                'status': 'settings',
                              }).future);
                            },
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            iconSize: 28,
                          )
                        else if (_ready)
                          TeamColorButton(
                            text: 'Waiting for Others...',
                            icon: Icons.hourglass_top,
                            color: _selectedColorIndex != null
                                ? teamColors[_selectedColorIndex!]
                                : teamColors[0],
                            onPressed: null,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            iconSize: 28,
                          )
                        else
                          TeamColorButton(
                            text: 'Ready',
                            icon: Icons.check,
                            color: _selectedColorIndex != null
                                ? teamColors[_selectedColorIndex!]
                                : teamColors[0],
                            onPressed: (!_ready &&
                                    _canPickColor &&
                                    _selectedColorIndex != null &&
                                    _teamNameController.text
                                        .trim()
                                        .isNotEmpty &&
                                    !_updating)
                                ? _onReadyPressed
                                : null,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            iconSize: 28,
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }
}
