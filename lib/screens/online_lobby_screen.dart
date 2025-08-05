import 'package:flutter/material.dart';
import '../widgets/team_color_button.dart';
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
      print(
          '🔥 FIRESTORE READ: _joinSession($code) - checking session existence');
      final doc = await FirebaseFirestore.instance
          .collection('sessions')
          .doc(code)
          .get();
      if (!mounted) return;
      if (!doc.exists) {
        setState(() => _error = 'Session not found.');
        return;
      }

      final teams = (doc.data()?['teams'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [];

      // Check if this device already has a team in this session
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
              teamName: myTeam['teamName'] ?? 'Team',
              player1Name: (myTeam['players'] as List?)?[0] ?? 'Player 1',
              player2Name: (myTeam['players'] as List?)?[1] ?? 'Player 2',
            ),
          ),
        );
      } else {
        // New join: go to team lobby to set up team
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OnlineTeamLobbyScreen(
              sessionId: code,
              teamName: '', // Empty - user will set this
              player1Name: '', // Empty - user will set this
              player2Name: '', // Empty - user will set this
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
    try {
      print(
          '🔥 FIRESTORE READ: _sessionExists($code) - checking session existence');
      final docSnap = await FirebaseFirestore.instance
          .collection('sessions')
          .doc(code)
          .get();
      final exists = docSnap.exists;
      print('🔍 Checking session $code: exists=$exists');
      return exists;
    } catch (e) {
      print('❌ Error checking session existence: $e');
      return false; // If there's an error, assume it doesn't exist
    }
  }

  Future<void> _createSession() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    String newCode = '';
    bool exists = true;
    int attempts = 0;
    const maxAttempts = 3;

    // Try up to 3 times to generate a unique code
    while (exists && attempts < maxAttempts) {
      print('another one');
      newCode = _generateRandomCode();
      exists = await _sessionExists(newCode);
      attempts++;
      print('🔍 Session creation attempt $attempts: $newCode exists=$exists');

      // Add a small delay to prevent overwhelming Firestore
      if (attempts < maxAttempts) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    if (exists) {
      setState(() {
        _loading = false;
        _error =
            'Failed to generate unique code after $maxAttempts attempts. Please try again.';
      });
      return;
    }
    try {
      final hostId = await StorageService.getDeviceId();

      // Create session with all initial data in one operation
      print(
          '🔥 FIRESTORE WRITE: _createSession($newCode) - creating new session');
      await FirebaseFirestore.instance.collection('sessions').doc(newCode).set({
        'sessionId': newCode,
        'hostId': hostId,
        'settings': {
          'roundTimeSeconds': 60,
          'targetScore': 20,
          'allowedSkips': 3,
        },
        'teams': [], // Empty teams array - teams will be added manually
        'gameState': {
          'currentTeamIndex': 0,
          'roundNumber': 1,
          'turnNumber': 1,
        },
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Navigate to a team setup screen or show instructions
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => OnlineTeamLobbyScreen(
            sessionId: newCode,
            teamName: '', // Empty - user will set this
            player1Name: '', // Empty - user will set this
            player2Name: '', // Empty - user will set this
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
