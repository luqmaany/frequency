import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game_state_provider.dart';
import '../widgets/team_color_button.dart';
import 'game_insights_screen.dart';

class GameOverScreen extends ConsumerStatefulWidget {
  const GameOverScreen({super.key});

  @override
  ConsumerState<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends ConsumerState<GameOverScreen> {
  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    if (gameState == null) return const SizedBox.shrink();

    // Sort team indices by total score (descending)
    final sortedTeamIndices = List.generate(
        gameState.teamScores.length, (i) => i)
      ..sort(
          (a, b) => gameState.teamScores[b].compareTo(gameState.teamScores[a]));

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(27.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Game Over!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple.withOpacity(0.8),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: List.generate(
                        sortedTeamIndices.length,
                        (i) {
                          final teamIndex = sortedTeamIndices[i];
                          final playerNames =
                              gameState.config.teams[teamIndex].join(' & ');
                          final totalScore = gameState.teamScores[teamIndex];
                          final isWinner = i == 0 && totalScore > 0;

                          final Color backgroundColor = teamColors[gameState
                                          .config.teamColorIndices.length >
                                      teamIndex
                                  ? gameState.config.teamColorIndices[teamIndex]
                                  : teamIndex % teamColors.length]
                              .background;
                          final Color borderColor = teamColors[gameState
                                          .config.teamColorIndices.length >
                                      teamIndex
                                  ? gameState.config.teamColorIndices[teamIndex]
                                  : teamIndex % teamColors.length]
                              .border;
                          // Text color is unified in dark mode; keep for future light mode support if re-enabled

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12.0, horizontal: 10.0),
                            decoration: BoxDecoration(
                              color: borderColor.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: backgroundColor.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    isWinner ? '$playerNames 🏆' : playerNames,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                Colors.white.withOpacity(0.95)),
                                  ),
                                ),
                                CircleAvatar(
                                  backgroundColor: borderColor.withOpacity(0.8),
                                  radius: 18,
                                  child: Text(
                                    totalScore.toString(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          // Bottom section with Game Insights and Home buttons (pinned)
          Container(
            padding: const EdgeInsets.all(27.0),
            decoration: BoxDecoration(
              color: const Color(0xFF3A3A3A),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TeamColorButton(
                    text: 'Insights',
                    icon: Icons.analytics,
                    color: teamColors[2], // Violet (Purple)
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const GameInsightsScreen(),
                        ),
                      );
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
          ),
        ],
      ),
    );
  }
}
