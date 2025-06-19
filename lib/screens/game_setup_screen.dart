import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game_setup_provider.dart';
import '../widgets/player_input.dart';
import 'game_settings_screen.dart';

class GameSetupScreen extends ConsumerStatefulWidget {
  const GameSetupScreen({super.key});

  @override
  ConsumerState<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends ConsumerState<GameSetupScreen> {
  @override
  Widget build(BuildContext context) {
    final gameConfig = ref.watch(gameSetupProvider);

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
                  'Add Players to Teams',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap a name to add to a team.',
                  style: TextStyle(
                    color: Colors.grey,
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
                                return Chip(
                                  label: Text(player),
                                  onDeleted: () {
                                    ref
                                        .read(gameSetupProvider.notifier)
                                        .removePlayer(player);
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                if (gameConfig.teams.expand((t) => t).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ref.read(gameSetupProvider.notifier).shuffleTeams();
                        },
                        icon: const Icon(Icons.shuffle),
                        label: const Text('Shuffle Teams'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                        ),
                      ),
                    ),
                  ),
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
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: gameConfig.teams.length >= 2 &&
                            gameConfig.teams.every((team) => team.length == 2)
                        ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const GameSettingsScreen(),
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text(
                      'Next: Game Settings',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
