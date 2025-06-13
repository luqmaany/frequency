import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game_setup_provider.dart';
import '../widgets/player_input.dart';
import '../widgets/team_creation_dialog.dart';
import 'game_settings_screen.dart';

class GameSetupScreen extends ConsumerStatefulWidget {
  const GameSetupScreen({super.key});

  @override
  ConsumerState<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends ConsumerState<GameSetupScreen> {
  bool _isRandomizing = false;

  Future<void> _randomizeTeams() async {
    setState(() {
      _isRandomizing = true;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      ref.read(gameSetupProvider.notifier).randomizeTeams();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRandomizing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameConfig = ref.watch(gameSetupProvider);
    final playerCount = gameConfig.playerNames.length;
    final canCreateTeams = playerCount >= 4 && playerCount % 2 == 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Setup'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Players',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add players to create teams',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                const PlayerInput(),
                const SizedBox(height: 32),
                const Text(
                  'Teams',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: canCreateTeams && !_isRandomizing
                            ? _randomizeTeams
                            : null,
                        icon: _isRandomizing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.shuffle),
                        label: Text(_isRandomizing ? 'Randomizing...' : 'Randomize Teams'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: canCreateTeams
                            ? () {
                                showDialog(
                                  context: context,
                                  builder: (context) => const TeamCreationDialog(),
                                );
                              }
                            : null,
                        icon: const Icon(Icons.group_add),
                        label: const Text('Create Teams'),
                      ),
                    ),
                  ],
                ),
                if (!canCreateTeams) ...[
                  const SizedBox(height: 8),
                  Text(
                    playerCount < 4
                        ? 'Add more players to create teams'
                        : 'Add one more player to create teams',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (gameConfig.teams.isNotEmpty)
                  ...gameConfig.teams.asMap().entries.map((entry) {
                    final index = entry.key;
                    final team = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Team ${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: team.map((player) {
                                return Chip(label: Text(player));
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: canCreateTeams && gameConfig.teams.isNotEmpty
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const GameSettingsScreen(),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                minimumSize: const Size(double.infinity, 56),
              ),
              child: const Text(
                'Next: Game Settings',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 