import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/team_color_button.dart';
import '../services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/storage_service.dart';

// StreamProvider to listen to session changes
final sessionStreamProvider =
    StreamProvider.family<DocumentSnapshot<Map<String, dynamic>>?, String>(
        (ref, sessionId) {
  return FirestoreService.sessionStream(sessionId);
});

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

class _OnlineTeamLobbyScreenState extends ConsumerState<OnlineTeamLobbyScreen> {
  late TextEditingController _teamNameController;
  late TextEditingController _player1Controller;
  late TextEditingController _player2Controller;
  int? _selectedColorIndex;
  bool _ready = false;
  bool _updating = false;
  late Future<String> _deviceIdFuture;

  @override
  void initState() {
    super.initState();
    _teamNameController = TextEditingController(text: widget.teamName);
    _player1Controller = TextEditingController(text: widget.player1Name);
    _player2Controller = TextEditingController(text: widget.player2Name);
    _selectedColorIndex = null;
    _deviceIdFuture = StorageService.getDeviceId();
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    _player1Controller.dispose();
    _player2Controller.dispose();
    _removeTeamFromFirestore();
    super.dispose();
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

  Future<void> _selectColor(int index) async {
    setState(() {
      _selectedColorIndex = index;
    });
    await _updateTeamInfo();
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

    return WillPopScope(
      onWillPop: () async {
        await _removeTeamFromFirestore();
        return true;
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
                        // Team info display (read-only)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: Colors.grey.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your Team:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('Player 1: ${widget.player1Name}'),
                              Text('Player 2: ${widget.player2Name}'),
                              if (widget.teamName.isNotEmpty)
                                Text('Team: ${widget.teamName}'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text('Pick a Team Color:',
                            style: TextStyle(fontSize: 16)),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 180,
                          child: GridView.builder(
                            scrollDirection: Axis.vertical,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 8,
                              childAspectRatio: 3.2,
                            ),
                            itemCount: teamColors.length,
                            itemBuilder: (context, i) {
                              final myColorIndex = _getMyTeamColorIndex(teams);
                              final takenByOther =
                                  usedColors.contains(i) && i != myColorIndex;
                              return TeamColorButton(
                                text: teamColors[i].name,
                                icon: Icons.circle,
                                color: teamColors[i],
                                onPressed: (takenByOther || _updating)
                                    ? null
                                    : () async {
                                        setState(() {
                                          _selectedColorIndex = i;
                                        });
                                        if (_ready) {
                                          // If already ready, update Firestore with new color
                                          await _syncTeamToFirestore();
                                        } else {
                                          _onColorChanged();
                                        }
                                      },
                                iconSize: 20,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 10),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (teams.isNotEmpty) ...[
                          const Text('Teams in Session:',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          ...teams.map((team) {
                            final hasTeamName = (team['teamName'] as String?)
                                    ?.trim()
                                    .isNotEmpty ==
                                true;
                            final players = (team['players'] as List?)
                                    ?.whereType<String>()
                                    .toList() ??
                                [];
                            final displayName = hasTeamName
                                ? team['teamName']
                                : (players.length == 2
                                    ? '${players[0]} & ${players[1]}'
                                    : players.join(' & '));
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: teamColors[team['colorIndex'] ?? 0]
                                          .background,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: teamColors[
                                                  team['colorIndex'] ?? 0]
                                              .border),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(displayName ?? 'Unknown'),
                                  const Spacer(),
                                  if (team['ready'] == true)
                                    const Icon(Icons.check_circle,
                                        color: Colors.green, size: 20)
                                  else
                                    const Icon(Icons.schedule,
                                        color: Colors.grey, size: 20),
                                ],
                              ),
                            );
                          }),
                        ],
                        const SizedBox(height: 32),
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
                                  .update({'status': 'in-progress'});
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
