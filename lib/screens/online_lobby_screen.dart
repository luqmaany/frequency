import 'package:flutter/material.dart';
import '../widgets/team_color_button.dart';
import 'online_team_lobby_screen.dart';
import '../services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class OnlineLobbyScreen extends StatefulWidget {
  const OnlineLobbyScreen({Key? key}) : super(key: key);

  @override
  State<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends State<OnlineLobbyScreen> {
  final TextEditingController _joinCodeController = TextEditingController();
  final TextEditingController _teamNameController = TextEditingController();
  int _selectedColorIndex = 0;
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
      // Navigate to team lobby for team setup (team name/color)
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => OnlineTeamLobbyScreen(
            sessionId: code,
            teamName: '',
            colorIndex: 0,
          ),
        ),
      );
    } catch (e) {
      setState(() => _error = 'Failed to join session.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join session: $e')),
      );
    } finally {
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
      print('Generated code: $newCode');
      exists = await _sessionExists(newCode);
      print('Does $newCode exist? $exists');
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
      // Actually create the session document in Firestore!
      await FirebaseFirestore.instance.collection('sessions').doc(newCode).set({
        'sessionId': newCode,
        'status': 'lobby',
        'settings': {
          'roundTimeSeconds': 60,
          'targetScore': 20,
          'allowedSkips': 3,
        },
        'teams': [],
        'gameState': null,
      });

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => OnlineTeamLobbyScreen(
            sessionId: newCode,
            teamName: '',
            colorIndex: 0,
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
