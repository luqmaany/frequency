import 'package:flutter/material.dart';
import '../widgets/team_color_button.dart';
import 'online_team_setup_screen.dart';
import '../services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../services/storage_service.dart';
import 'online_team_lobby_screen.dart';

class OnlineLobbyScreen extends StatefulWidget {
  const OnlineLobbyScreen({Key? key}) : super(key: key);

  @override
  State<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends State<OnlineLobbyScreen> {
  final TextEditingController _joinCodeController = TextEditingController();
  String? _error;
  bool _loading = false;

  Future<void> _joinSession() async {
    final code = _joinCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = 'Enter join code.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final deviceId = await StorageService.getDeviceId();
      final doc = await FirebaseFirestore.instance
          .collection('sessions')
          .doc(code)
          .get();
      if (!mounted) return;
      if (!doc.exists) {
        setState(() => _error = 'Session not found.');
        return;
      }
      final teams = (doc.data()?['teams'] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final myTeam = teams.firstWhere(
        (t) => t['deviceId'] == deviceId,
        orElse: () => <String, dynamic>{},
      );
      if (myTeam.isNotEmpty) {
        // Rejoin: mark as active and go to team lobby
        await FirestoreService.rejoinTeam(
            code, myTeam['teamId'], List<String>.from(myTeam['players']));
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OnlineTeamLobbyScreen(
              sessionId: code,
              teamName: myTeam['teamName'],
              player1Name: myTeam['players'][0],
              player2Name: myTeam['players'][1],
            ),
          ),
        );
      } else {
        // No team found for this device, proceed to team setup
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OnlineTeamSetupScreen(
              sessionId: code,
              isHost: false,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to join session.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join session: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  Future<bool> _sessionExists(String code) async {
    final docSnap =
        await FirebaseFirestore.instance.collection('sessions').doc(code).get();
    return docSnap.exists;
  }

  Future<void> _createSession() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    String newCode = '';
    bool exists = true;
    int attempts = 0;
    // Try up to 5 times to generate a unique code
    while (exists && attempts < 5) {
      newCode = _generateRandomCode();
      exists = await _sessionExists(newCode);
      attempts++;
    }
    if (exists) {
      setState(() {
        _loading = false;
        _error = 'Failed to generate unique code. Please try again.';
      });
      return;
    }
    try {
      final hostId = await StorageService.getDeviceId();
      // Actually create the session document in Firestore!
      await FirebaseFirestore.instance.collection('sessions').doc(newCode).set({
        'sessionId': newCode,
        'hostId': hostId,
        'teams': [],
        'gameState': {
          'status': 'lobby',
          'gameConfig': {
            'roundTimeSeconds': 60,
            'targetScore': 20,
            'allowedSkips': 3,
          },
          // Add other initial game state fields as needed
        },
      });

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => OnlineTeamSetupScreen(
            sessionId: newCode,
            isHost: true,
          ),
        ),
      );
    } catch (e) {
      setState(() => _error = 'Failed to create session.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create session: $e')),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  String _generateRandomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(6, (i) => chars[rand.nextInt(chars.length)]).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Online Lobby'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _joinCodeController,
              decoration: InputDecoration(
                labelText: 'Join Code',
                border: const OutlineInputBorder(),
                errorText: _error,
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              enabled: !_loading,
            ),
            const SizedBox(height: 16),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (!_loading) ...[
              TeamColorButton(
                text: 'Join Session',
                icon: Icons.login_rounded,
                color: teamColors[0],
                onPressed: _joinSession,
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 32),
              TeamColorButton(
                text: 'Create New Session',
                icon: Icons.add,
                color: teamColors[1],
                onPressed: _createSession,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
