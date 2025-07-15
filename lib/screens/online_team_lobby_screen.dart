import 'package:flutter/material.dart';
import '../widgets/team_color_button.dart';

class OnlineTeamLobbyScreen extends StatefulWidget {
  final String sessionId;
  const OnlineTeamLobbyScreen({Key? key, required this.sessionId})
      : super(key: key);

  @override
  State<OnlineTeamLobbyScreen> createState() => _OnlineTeamLobbyScreenState();
}

class _OnlineTeamLobbyScreenState extends State<OnlineTeamLobbyScreen> {
  final TextEditingController _teamNameController = TextEditingController();
  int _selectedColorIndex = 0;
  bool _ready = false;

  void _selectColor(int index) {
    setState(() {
      _selectedColorIndex = index;
    });
  }

  void _onReady() {
    setState(() {
      _ready = true;
    });
    // TODO: Firestore logic to mark team as ready
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Lobby'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Column(
                children: [
                  const Text('Session Code',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
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
            TextField(
              controller: _teamNameController,
              decoration: const InputDecoration(
                labelText: 'Team Name',
                border: OutlineInputBorder(),
              ),
              maxLength: 16,
              enabled: !_ready,
            ),
            const SizedBox(height: 24),
            const Text('Pick a Team Color:', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                for (int i = 0; i < teamColors.length; i++)
                  TeamColorButton(
                    text: teamColors[i].name,
                    icon: Icons.circle,
                    color: teamColors[i],
                    onPressed: !_ready ? () => _selectColor(i) : null,
                    iconSize: 20,
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            TeamColorButton(
              text: _ready ? 'Waiting for Others...' : 'Ready',
              icon: _ready ? Icons.hourglass_top : Icons.check,
              color: teamColors[_selectedColorIndex],
              onPressed: _ready ? null : _onReady,
              padding: const EdgeInsets.symmetric(vertical: 16),
              iconSize: 28,
            ),
          ],
        ),
      ),
    );
  }
}
