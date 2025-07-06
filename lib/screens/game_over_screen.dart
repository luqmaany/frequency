import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game_state_provider.dart';
import '../widgets/team_color_button.dart';
import '../widgets/podium_display.dart';

class GameOverScreen extends ConsumerWidget {
  const GameOverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);
    if (gameState == null) return const SizedBox.shrink();

    // Sort team indices by total score (descending)
    final sortedTeamIndices = List.generate(
        gameState.teamScores.length, (i) => i)
      ..sort(
          (a, b) => gameState.teamScores[b].compareTo(gameState.teamScores[a]));

    return Scaffold(
      appBar: AppBar(
        title: Text(''),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(27.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PodiumDisplay(
              teams: sortedTeamIndices.map((i) {
                final teamIndex = i;
                final playerNames =
                    gameState.config.teams[teamIndex].join(' & ');
                final totalScore = gameState.teamScores[teamIndex];
                final isWinner = i == 0 && totalScore > 0;

                return {
                  'name': playerNames,
                  'score': totalScore,
                  'isWinner': isWinner,
                  'teamIndex': teamIndex,
                };
              }).toList(),
              teamColors: teamColors,
            ),
            const SizedBox(height: 32),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: TeamColorButton(
                    text: 'New Game',
                    icon: Icons.refresh,
                    color: uiColors[1], // Green
                    onPressed: () {
                      ref.read(gameStateProvider.notifier).resetGame();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TeamColorButton(
                    text: 'Home',
                    icon: Icons.home,
                    color: uiColors[0], // Blue
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
