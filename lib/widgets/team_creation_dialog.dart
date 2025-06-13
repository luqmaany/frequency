import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game_setup_provider.dart';

class TeamCreationDialog extends ConsumerStatefulWidget {
  const TeamCreationDialog({super.key});

  @override
  ConsumerState<TeamCreationDialog> createState() => _TeamCreationDialogState();
}

class _TeamCreationDialogState extends ConsumerState<TeamCreationDialog> {
  late List<List<String>> teams;
  late List<String> unassignedPlayers;

  @override
  void initState() {
    super.initState();
    final gameConfig = ref.read(gameSetupProvider);
    unassignedPlayers = List.from(gameConfig.playerNames);
    teams = List.generate(
      (gameConfig.playerNames.length / 2).ceil(),
      (_) => <String>[],
    );
  }

  void _addPlayerToTeam(String player, int teamIndex) {
    if (teams[teamIndex].length < 2) {
      setState(() {
        teams[teamIndex].add(player);
        unassignedPlayers.remove(player);
      });
    }
  }

  void _removePlayerFromTeam(String player, int teamIndex) {
    setState(() {
      teams[teamIndex].remove(player);
      unassignedPlayers.add(player);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Create Teams',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Unassigned Players',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: unassignedPlayers.map((player) {
                return Draggable<String>(
                  data: player,
                  feedback: Material(
                    elevation: 4,
                    child: Chip(label: Text(player)),
                  ),
                  childWhenDragging: const SizedBox.shrink(),
                  child: Chip(
                    label: Text(player),
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            ...teams.asMap().entries.map((entry) {
              final index = entry.key;
              final team = entry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Team ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DragTarget<String>(
                    builder: (context, candidateData, rejectedData) {
                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: candidateData.isNotEmpty
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ...team.map((player) {
                              return Chip(
                                label: Text(player),
                                onDeleted: () => _removePlayerFromTeam(player, index),
                              );
                            }),
                            if (team.length < 2)
                              const Chip(
                                label: Text('Drop player here'),
                                backgroundColor: Colors.transparent,
                              ),
                          ],
                        ),
                      );
                    },
                    onAccept: (player) => _addPlayerToTeam(player, index),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: unassignedPlayers.isEmpty
                      ? () {
                          ref.read(gameSetupProvider.notifier).createTeams(teams);
                          Navigator.of(context).pop();
                        }
                      : null,
                  child: const Text('Save Teams'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 