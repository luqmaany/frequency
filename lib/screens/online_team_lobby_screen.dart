import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/team_color_button.dart';
import '../services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  late Animation<double> _animation;

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
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Initialize color index from existing team data
    _initializeColorIndex();

    // Set up navigation listener after the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      OnlineGameNavigationService.navigate(
        context: context,
        ref: ref,
        sessionId: widget.sessionId,
      );
    });
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    _player1Controller.dispose();
    _player2Controller.dispose();
    _animationController.dispose();
    _handleLeaveAndHostTransfer();
    super.dispose();
  }

  Future<void> _handleLeaveAndHostTransfer() async {
    await _removeTeamFromFirestore();
    final deviceId = await StorageService.getDeviceId();
    await FirestoreService.transferHostIfNeeded(widget.sessionId, deviceId);
  }

  Future<void> _initializeColorIndex() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('sessions')
          .doc(widget.sessionId)
          .get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      final teams = (data['teams'] as List?) ?? [];

      // Find our team and set the color index
      for (final team in teams) {
        if (team['players'] is List &&
            (team['players'] as List).join(',') ==
                [widget.player1Name.trim(), widget.player2Name.trim()]
                    .join(',')) {
          final colorIndex = team['colorIndex'] as int?;
          if (colorIndex != null) {
            setState(() {
              _selectedColorIndex = colorIndex;
            });
            // Trigger animation for initial display
            _animationController.forward(from: 0);
          }
          break;
        }
      }
    } catch (e) {
      print('Error initializing color index: $e');
    }
  }

  bool get _canPickColor =>
      widget.player1Name.trim().isNotEmpty &&
      widget.player2Name.trim().isNotEmpty;

  Future<void> _updateTeamInfo() async {
    if (_updating) return;
    setState(() => _updating = true);
    try {
      await FirestoreService.updateTeam(
        widget.sessionId,
        _teamNameController.text.trim(),
        {
          'teamName': _teamNameController.text.trim(),
          'colorIndex': _selectedColorIndex,
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update team info: $e')),
      );
    } finally {
      setState(() => _updating = false);
    }
  }

  Future<void> _onReady() async {
    if (_updating) return;
    setState(() => _updating = true);
    try {
      await FirestoreService.updateTeam(
        widget.sessionId,
        _teamNameController.text.trim(),
        {'ready': true},
      );
      setState(() => _ready = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark as ready: $e')),
      );
    } finally {
      setState(() => _updating = false);
    }
  }

  List<int> _getUsedColors(List<dynamic> teams) {
    final myPlayers = [
      widget.player1Name.trim(),
      widget.player2Name.trim(),
    ];
    return teams
        .where((team) => !(team['players'] is List &&
            (team['players'] as List).join(',') == myPlayers.join(',')))
        .map((team) => team['colorIndex'] as int)
        .toList();
  }

  // Helper to get the current team's color index from Firestore
  int? _getMyTeamColorIndex(List teams) {
    for (final t in teams) {
      if (t['players'] is List &&
          (t['players'] as List).join(',') ==
              [widget.player1Name.trim(), widget.player2Name.trim()]
                  .join(',')) {
        return t['colorIndex'] as int?;
      }
    }
    return null;
  }

  // Helper to build team data
  Map<String, dynamic> get _myTeamData => {
        'teamName': widget.teamName.trim(),
        'colorIndex': _selectedColorIndex,
        'ready': true,
        'players': [
          widget.player1Name.trim(),
          widget.player2Name.trim(),
        ],
      };

  // Add or update team in Firestore
  Future<void> _syncTeamToFirestore() async {
    if (_canPickColor && _selectedColorIndex != null) {
      final doc = await FirebaseFirestore.instance
          .collection('sessions')
          .doc(widget.sessionId)
          .get();
      if (!doc.exists) return;
      final data = doc.data() as Map<String, dynamic>;
      final teams = (data['teams'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [];
      // Remove any previous entry for this color or these players
      teams.removeWhere((t) =>
          t['colorIndex'] == _selectedColorIndex ||
          (t['players'] is List &&
              (t['players'] as List).join(',') ==
                  [widget.player1Name.trim(), widget.player2Name.trim()]
                      .join(',')));
      teams.add(_myTeamData);
      await FirebaseFirestore.instance
          .collection('sessions')
          .doc(widget.sessionId)
          .update({'teams': teams});
    }
  }

  // Remove team from Firestore
  Future<void> _removeTeamFromFirestore() async {
    final doc = await FirebaseFirestore.instance
        .collection('sessions')
        .doc(widget.sessionId)
        .get();
    if (!doc.exists) return;
    final data = doc.data() as Map<String, dynamic>;
    final teams = (data['teams'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        [];
    teams.removeWhere((t) =>
        (t['players'] is List &&
            (t['players'] as List).join(',') ==
                [widget.player1Name.trim(), widget.player2Name.trim()]
                    .join(',')) ||
        t['colorIndex'] == _selectedColorIndex);
    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(widget.sessionId)
        .update({'teams': teams});
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

  Future<void> _onReadyPressed() async {
    await _syncTeamToFirestore();
    setState(() {
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionStreamProvider(widget.sessionId));

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
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
            final usedColors = _getUsedColors(teams);
            final myTeam = teams.firstWhere(
              (team) => team['teamName'] == _teamNameController.text.trim(),
              orElse: () => {'ready': false},
            );
            final isReady = myTeam['ready'] ?? false;

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
                        const SizedBox(height: 32),
                        // Team info display with animation
                        if (_selectedColorIndex != null) ...[
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: AnimatedBuilder(
                              animation: _animation,
                              builder: (context, child) {
                                final teamColor =
                                    teamColors[_selectedColorIndex!];
                                final teamName =
                                    _teamNameController.text.trim();
                                final displayTitle = teamName.isNotEmpty
                                    ? teamName
                                    : '${teamColor.name} Team';

                                return Transform.scale(
                                  scale: 0.9 + (_animation.value * 0.1),
                                  child: Container(
                                    height: 80,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? teamColor.border.withOpacity(0.4)
                                          : teamColor.background,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? teamColor.background
                                                .withOpacity(0.3)
                                            : teamColor.border,
                                        width: 2,
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                displayTitle,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headlineMedium
                                                    ?.copyWith(
                                                      fontSize: 20,
                                                      color: Theme.of(context)
                                                                  .brightness ==
                                                              Brightness.dark
                                                          ? Colors.white
                                                              .withOpacity(0.95)
                                                          : Colors.black,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${widget.player1Name} & ${widget.player2Name}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge
                                                    ?.copyWith(
                                                      color: Theme.of(context)
                                                                  .brightness ==
                                                              Brightness.dark
                                                          ? Colors.white
                                                              .withOpacity(0.8)
                                                          : Colors.black87,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
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
                              await FirebaseFirestore.instance
                                  .collection('sessions')
                                  .doc(widget.sessionId)
                                  .update({
                                'gameState.status': 'settings'
                              }); // <-- update gameState.status
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
