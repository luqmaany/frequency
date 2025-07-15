import 'package:flutter/material.dart';
import '../widgets/team_color_button.dart';
import 'online_team_lobby_screen.dart';

class OnlineLobbyScreen extends StatefulWidget {
  const OnlineLobbyScreen({Key? key}) : super(key: key);

  @override
  State<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends State<OnlineLobbyScreen> {
  final TextEditingController _joinCodeController = TextEditingController();
  String? _error;

  void _joinSession() {
    final code = _joinCodeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Please enter a join code.');
      return;
    }
    // TODO: Validate code with Firestore
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OnlineTeamLobbyScreen(sessionId: code),
      ),
    );
  }

  void _createSession() {
    // TODO: Actually create session in Firestore and get code
    final newCode = _generateRandomCode();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OnlineTeamLobbyScreen(sessionId: newCode),
      ),
    );
  }

  String _generateRandomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(
        6,
        (i) => chars[(chars.length *
                (i + DateTime.now().millisecondsSinceEpoch) %
                chars.length) %
            chars.length]).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Online Lobby'),
      ),
      body: Padding(
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
            ),
            const SizedBox(height: 16),
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
        ),
      ),
    );
  }
}
