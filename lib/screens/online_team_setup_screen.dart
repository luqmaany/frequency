import 'package:flutter/material.dart';
import '../widgets/team_color_button.dart';
import 'online_team_lobby_screen.dart';

class OnlineTeamSetupScreen extends StatefulWidget {
  final String sessionId;
  final bool isHost;

  const OnlineTeamSetupScreen({
    Key? key,
    required this.sessionId,
    required this.isHost,
  }) : super(key: key);

  @override
  State<OnlineTeamSetupScreen> createState() => _OnlineTeamSetupScreenState();
}

class _OnlineTeamSetupScreenState extends State<OnlineTeamSetupScreen> {
  final TextEditingController _teamNameController = TextEditingController();
  final TextEditingController _player1Controller = TextEditingController();
  final TextEditingController _player2Controller = TextEditingController();
  String? _error;

  bool get _canProceed =>
      _player1Controller.text.trim().isNotEmpty &&
      _player2Controller.text.trim().isNotEmpty;

  @override
  void dispose() {
    _teamNameController.dispose();
    _player1Controller.dispose();
    _player2Controller.dispose();
    super.dispose();
  }

  void _proceedToLobby() {
    if (!_canProceed) {
      setState(() => _error = 'Please enter both player names.');
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => OnlineTeamLobbyScreen(
          sessionId: widget.sessionId,
          teamName: _teamNameController.text.trim(),
          player1Name: _player1Controller.text.trim(),
          player2Name: _player2Controller.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Setup'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Column(
                children: [
                  const Text(
                    'Session Code',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  SelectableText(
                    widget.sessionId,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Enter your team information:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _player1Controller,
              decoration: const InputDecoration(
                labelText: 'Player 1 Name *',
                border: OutlineInputBorder(),
                helperText: 'Required',
              ),
              maxLength: 16,
              onChanged: (_) {
                setState(() => _error = null);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _player2Controller,
              decoration: const InputDecoration(
                labelText: 'Player 2 Name *',
                border: OutlineInputBorder(),
                helperText: 'Required',
              ),
              maxLength: 16,
              onChanged: (_) {
                setState(() => _error = null);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _teamNameController,
              decoration: const InputDecoration(
                labelText: 'Team Name (optional)',
                border: OutlineInputBorder(),
                helperText: 'Leave empty to use player names',
              ),
              maxLength: 16,
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),
            TeamColorButton(
              text: 'Continue to Lobby',
              icon: Icons.arrow_forward,
              color: teamColors[0],
              onPressed: _canProceed ? _proceedToLobby : null,
              padding: const EdgeInsets.symmetric(vertical: 16),
              iconSize: 28,
            ),
          ],
        ),
      ),
    );
  }
}
