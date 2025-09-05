import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/team_color_button.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../providers/session_providers.dart';
import '../services/online_game_navigation_service.dart';
import '../widgets/parallel_pulse_waves_background.dart';

// Note: Color change logic updated to not interfere with ready/start game
// Prevents color changes from unready-ing other teams and enforces unique colors
class OnlineTeamLobbyScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final String player1Name;
  final String player2Name;
  const OnlineTeamLobbyScreen(
      {Key? key,
      required this.sessionId,
      required this.player1Name,
      required this.player2Name})
      : super(key: key);

  @override
  ConsumerState<OnlineTeamLobbyScreen> createState() =>
      _OnlineTeamLobbyScreenState();
}

class _OnlineTeamLobbyScreenState extends ConsumerState<OnlineTeamLobbyScreen>
    with TickerProviderStateMixin {
  late TextEditingController _player1Controller;
  late TextEditingController _player2Controller;
  late TextEditingController _myPlayerNameController; // For split mode
  int? _selectedColorIndex;
  bool _ready = false;
  final bool _updating = false;
  late Future<String> _deviceIdFuture;
  late AnimationController _animationController;

  // Team mode state
  String _teamMode = 'couch'; // 'couch' or 'remote'
  @override
  void initState() {
    super.initState();

    // Generate random names for testing if the provided names are empty
    String player1Name = widget.player1Name;
    String player2Name = widget.player2Name;

    if (player1Name.isEmpty) {
      final randomNames = [
        'Alex',
        'Jordan',
        'Taylor',
        'Casey',
        'Riley',
        'Morgan',
        'Quinn',
        'Avery',
        'Parker',
        'Drew',
        'Blake',
        'Cameron',
        'Jamie',
        'Reese',
        'Dakota'
      ];
      player1Name =
          randomNames[DateTime.now().millisecond % randomNames.length];
    }

    if (player2Name.isEmpty) {
      final randomNames = [
        'Sam',
        'Kai',
        'Rowan',
        'Sage',
        'River',
        'Skyler',
        'Phoenix',
        'Indigo',
        'Wren',
        'Aspen',
        'Cedar',
        'Juniper',
        'Willow',
        'Oak',
        'Maple'
      ];
      player2Name =
          randomNames[(DateTime.now().millisecond + 1) % randomNames.length];
    }

    _player1Controller = TextEditingController(text: player1Name);
    _player2Controller = TextEditingController(text: player2Name);
    _myPlayerNameController = TextEditingController(
        text: player1Name); // Default to first player name for split mode
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
    _player1Controller.dispose();
    _player2Controller.dispose();
    _myPlayerNameController.dispose();
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

  bool get _canPickColor {
    if (_teamMode == 'couch') {
      return _player1Controller.text.trim().isNotEmpty &&
          _player2Controller.text.trim().isNotEmpty;
    } else {
      // Remote mode: only need own player name
      return _myPlayerNameController.text.trim().isNotEmpty;
    }
  }

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
    final teamName = _selectedColorIndex != null
        ? teamColors[_selectedColorIndex!].name
        : 'Team';

    if (_teamMode == 'couch') {
      // Couch mode: existing logic
      return {
        'teamName': teamName,
        'colorIndex': _selectedColorIndex,
        'ready': true,
        'teamMode': 'couch',
        'deviceId': deviceId,
        'players': [
          _player1Controller.text.trim(),
          _player2Controller.text.trim(),
        ],
      };
    } else {
      // Remote mode: single player per device
      return {
        'teamName': teamName,
        'colorIndex': _selectedColorIndex,
        'ready': true,
        'teamMode': 'remote',
        'deviceId': deviceId,
        'playerName': _myPlayerNameController.text.trim(),
      };
    }
  }

  // Add or update team in Firestore
  Future<void> _syncTeamToFirestore() async {
    if (_canPickColor && _selectedColorIndex != null) {
      final teams =
          await ref.read(sessionTeamsProvider(widget.sessionId).future);

      final deviceId = await _deviceIdFuture;
      // If another device already owns this color, do not override it
      final bool colorTakenByOther = teams.any((t) =>
          t['colorIndex'] == _selectedColorIndex && t['deviceId'] != deviceId);
      if (colorTakenByOther) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('That color is already taken')),
        );
        return;
      }

      // Atomic upsert via service to avoid race conditions
      final teamDataWithDeviceId = await _getMyTeamDataWithDeviceId();
      try {
        await FirestoreService.upsertTeamByDeviceId(
            widget.sessionId, teamDataWithDeviceId);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  // Remove team from Firestore
  Future<void> _removeTeamFromFirestore() async {
    final deviceId = await _deviceIdFuture;
    await FirestoreService.removeTeamByDeviceId(widget.sessionId, deviceId);
  }

  // Watch for changes to color and sync
  void _onColorChanged() {
    // Do not mutate Firestore here to avoid race conditions affecting other teams
    if (_ready && _selectedColorIndex == null) {
      setState(() {
        _ready = false;
      });
    } else {
      setState(() {});
    }
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
        body: Stack(
          children: [
            const Positioned.fill(
              child: ParallelPulseWavesBackground(
                perRowPhaseOffset: 0.0,
                baseSpacing: 35.0,
              ),
            ),
            Column(
              children: [
                const SizedBox(height: 48),
                Center(
                  child: Text(
                    'Team Lobby',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: sessionAsync.when(
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
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError || !snapshot.hasData) {
                            return const Center(
                                child: Text('Error loading device ID'));
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

                                  // Team Mode Selector
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surface
                                          .withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline
                                            .withOpacity(0.3),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          'Team Mode',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 12),
                                        SegmentedButton<String>(
                                          segments: const [
                                            ButtonSegment(
                                              value: 'couch',
                                              label: Text('Couch Team'),
                                              icon: Icon(Icons.devices),
                                            ),
                                            ButtonSegment(
                                              value: 'remote',
                                              label: Text('Remote Team'),
                                              icon: Icon(Icons.group_outlined),
                                            ),
                                          ],
                                          selected: {_teamMode},
                                          onSelectionChanged:
                                              (Set<String> selection) {
                                            setState(() {
                                              _teamMode = selection.first;
                                              // Reset ready state when changing modes
                                              if (_ready) {
                                                _removeTeamFromFirestore();
                                                _ready = false;
                                              }
                                            });
                                          },
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _teamMode == 'couch'
                                              ? '2 players on this device'
                                              : '1 player per device (2 devices total)',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.7),
                                              ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Player input fields - different layout based on mode
                                  if (_teamMode == 'couch') ...[
                                    // Couch mode: two player fields side by side
                                    Row(
                                      children: [
                                        Expanded(
                                          child: SizedBox(
                                            height: 45,
                                            child: TextField(
                                              controller: _player1Controller,
                                              textAlign: TextAlign.center,
                                              decoration: InputDecoration(
                                                labelText: 'Player 1',
                                                border:
                                                    const OutlineInputBorder(),
                                                filled: true,
                                                fillColor: Theme.of(context)
                                                    .scaffoldBackgroundColor,
                                                floatingLabelAlignment:
                                                    FloatingLabelAlignment
                                                        .center,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8),
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
                                              textAlign: TextAlign.center,
                                              decoration: InputDecoration(
                                                labelText: 'Player 2',
                                                border:
                                                    const OutlineInputBorder(),
                                                filled: true,
                                                fillColor: Theme.of(context)
                                                    .scaffoldBackgroundColor,
                                                floatingLabelAlignment:
                                                    FloatingLabelAlignment
                                                        .center,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8),
                                              ),
                                              onChanged: (value) {
                                                _onNameChanged();
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ] else ...[
                                    // Remote mode: single player field
                                    SizedBox(
                                      height: 45,
                                      child: TextField(
                                        controller: _myPlayerNameController,
                                        textAlign: TextAlign.center,
                                        decoration: InputDecoration(
                                          labelText: 'Your Name',
                                          border: const OutlineInputBorder(),
                                          filled: true,
                                          fillColor: Theme.of(context)
                                              .scaffoldBackgroundColor,
                                          floatingLabelAlignment:
                                              FloatingLabelAlignment.center,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 12, vertical: 8),
                                        ),
                                        onChanged: (value) {
                                          _onNameChanged();
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceVariant
                                            .withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            size: 16,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'A teammate will join this team from another device',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    clipBehavior: Clip.none,
                                    itemCount: teamColors.length,
                                    itemBuilder: (context, i) {
                                      final isSelected =
                                          _selectedColorIndex == i;
                                      final teamColor = teamColors[i];
                                      // Find the team (if any) that owns this color
                                      final teamForColor = teams.firstWhere(
                                        (team) => team['colorIndex'] == i,
                                        orElse: () => null,
                                      );
                                      final colorTaken = teamForColor != null;
                                      bool takenByOther = false;
                                      bool canJoinSplitTeam = false;

                                      if (colorTaken) {
                                        if (teamForColor['teamMode'] ==
                                            'remote') {
                                          final devices =
                                              (teamForColor['devices']
                                                      as List?) ??
                                                  [];
                                          final deviceInTeam = devices.any(
                                              (d) => d['deviceId'] == deviceId);
                                          takenByOther = !deviceInTeam &&
                                              devices.length >= 2;
                                          canJoinSplitTeam = !deviceInTeam &&
                                              devices.length == 1 &&
                                              _teamMode == 'remote';
                                        } else {
                                          // Couch team
                                          takenByOther =
                                              teamForColor['deviceId'] !=
                                                  deviceId;
                                        }
                                      }

                                      final teamIsReady = colorTaken &&
                                          (teamForColor['ready'] == true);
                                      String infoText = '';
                                      String statusText = '';

                                      if (colorTaken) {
                                        final tName = (teamForColor['teamName']
                                                    as String?)
                                                ?.trim() ??
                                            '';

                                        if (teamForColor['teamMode'] ==
                                            'remote') {
                                          final devices =
                                              (teamForColor['devices']
                                                      as List?) ??
                                                  [];
                                          if (devices.length == 1) {
                                            final firstPlayer = devices[0]
                                                ['playerName'] as String;
                                            infoText =
                                                firstPlayer; // Will be handled by RichText
                                            statusText = '';
                                          } else if (devices.length == 2) {
                                            final players = devices
                                                .map((d) => d['playerName'])
                                                .toList();
                                            infoText =
                                                '${players[0]} & ${players[1]}';
                                            statusText = '';
                                          }
                                        } else {
                                          // Couch team
                                          final players =
                                              (teamForColor['players'] as List?)
                                                      ?.whereType<String>()
                                                      .toList() ??
                                                  [];
                                          infoText = players.length == 2
                                              ? '${players[0]} & ${players[1]}'
                                              : players.join(' & ');
                                          statusText = '';
                                        }
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4),
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          splashColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          onTap: ((takenByOther &&
                                                      !canJoinSplitTeam) ||
                                                  _updating)
                                              ? null
                                              : () async {
                                                  // Unfocus any active text field
                                                  FocusScope.of(context)
                                                      .unfocus();
                                                  setState(() {
                                                    _selectedColorIndex = i;
                                                  });
                                                  _animationController.forward(
                                                      from: 0);
                                                  if (_ready) {
                                                    await _syncTeamToFirestore();
                                                  } else {
                                                    _onColorChanged();
                                                  }
                                                },
                                          child: AnimatedScale(
                                              scale: isSelected ? 1 : 0.98,
                                              duration: const Duration(
                                                  milliseconds: 120),
                                              curve: Curves.easeOut,
                                              child: Container(
                                                clipBehavior: Clip.none,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8,
                                                        horizontal: 10),
                                                decoration: BoxDecoration(
                                                  // Dark opaque background matching setup screen boxes
                                                  color: Color.alphaBlend(
                                                    teamColor.border
                                                        .withOpacity(isSelected
                                                            ? 0.85
                                                            : 0.6),
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .background,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: isSelected
                                                        ? teamColor.border
                                                        : teamColor.border
                                                            .withOpacity(0.5),
                                                    width:
                                                        isSelected ? 3.0 : 2.0,
                                                  ),
                                                  boxShadow: isSelected
                                                      ? [
                                                          BoxShadow(
                                                            color: teamColor
                                                                .border
                                                                .withOpacity(
                                                                    0.18),
                                                            blurRadius: 8,
                                                            offset:
                                                                const Offset(
                                                                    0, 2),
                                                          ),
                                                        ]
                                                      : [],
                                                ),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center, // ensure vertical centering
                                                      children: [
                                                        Icon(Icons.circle,
                                                            color: teamColor
                                                                .border,
                                                            size: 22),
                                                        const SizedBox(
                                                            width: 8),
                                                        Expanded(
                                                          child: Text(
                                                            teamColor.name,
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              fontSize: 18,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                        if (teamIsReady) ...[
                                                          const SizedBox(
                                                              width: 8),
                                                          const Icon(
                                                              Icons
                                                                  .check_circle,
                                                              color:
                                                                  Colors.green,
                                                              size: 22),
                                                        ] else if (canJoinSplitTeam) ...[
                                                          const SizedBox(
                                                              width: 8),
                                                          Icon(
                                                            Icons.person_add,
                                                            color:
                                                                Colors.orange,
                                                            size: 22,
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                    if (colorTaken &&
                                                        infoText
                                                            .isNotEmpty) ...[
                                                      const SizedBox(height: 4),
                                                      // Handle remote team single player with mixed formatting
                                                      if (teamForColor[
                                                                  'teamMode'] ==
                                                              'remote' &&
                                                          (teamForColor['devices']
                                                                      as List?)
                                                                  ?.length ==
                                                              1)
                                                        RichText(
                                                          textAlign:
                                                              TextAlign.center,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          maxLines: 1,
                                                          text: TextSpan(
                                                            children: [
                                                              TextSpan(
                                                                text: (teamForColor[
                                                                            'devices']
                                                                        as List)[0]
                                                                    [
                                                                    'playerName'] as String,
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 15,
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                              TextSpan(
                                                                text:
                                                                    ' - waiting for teammate',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 15,
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w400,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        )
                                                      else
                                                        Text(
                                                          infoText,
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          maxLines: 1,
                                                        ),
                                                      if (statusText
                                                          .isNotEmpty) ...[
                                                        const SizedBox(
                                                            height: 2),
                                                        Text(
                                                          statusText,
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            color: Colors.white
                                                                .withOpacity(
                                                                    0.8),
                                                            fontWeight:
                                                                FontWeight.w400,
                                                          ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          maxLines: 1,
                                                        ),
                                                      ],
                                                    ],
                                                  ],
                                                ),
                                              )),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  if (_updating)
                                    const Center(
                                        child: CircularProgressIndicator()),
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
                                        await ref.read(
                                            updateGameStateStatusProvider({
                                          'sessionId': widget.sessionId,
                                          'status': 'settings',
                                        }).future);
                                      },
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
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
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
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
                                              !_updating)
                                          ? _onReadyPressed
                                          : null,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      iconSize: 28,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) =>
                        Center(child: Text('Error: $error')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
