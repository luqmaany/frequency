import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game_state_provider.dart';
import '../widgets/team_color_button.dart';
import 'game_insights_screen.dart';
import '../widgets/confirm_on_back.dart';
import '../widgets/quit_dialog.dart';
import '../services/game_navigation_service.dart';
import '../widgets/podium_display.dart';
import '../widgets/celebration_explosions_background.dart';

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

    // Build podium data
    final podiumTeams = sortedTeamIndices.map((teamIndex) {
      final name = gameState.config.teams[teamIndex].join(' & ');
      final score = gameState.teamScores[teamIndex];
      final isWinner = teamIndex == sortedTeamIndices.first && score > 0;
      return {
        'name': name,
        'score': score,
        'isWinner': isWinner,
        'teamIndex': teamIndex,
      };
    }).toList();

    return ConfirmOnBack(
      dialogBuilder: (ctx) => QuitDialog(color: uiColors[0]),
      onConfirmed: (ctx) async {
        await GameNavigationService.quitToHome(ctx, ref);
      },
      child: Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(
              child: CelebrationExplosionsBackground(
                  burstsPerSecond: 5.0,
                  strokeWidth: 2.0,
                  baseOpacity: 0.12,
                  highlightOpacity: 0.55,
                  ringSpacing: 8.0,
                  globalOpacity: 1.0,
                  maxEndRadiusFactor: 0.40),
            ),
            SafeArea(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: const Center(
                      child: Text(
                        'Game Over!',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(27.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),
                          PodiumDisplay(
                            teams: podiumTeams,
                            teamColors: teamColors,
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                  // Bottom section with Game Insights and Home buttons (pinned)
                  Container(
                    padding: const EdgeInsets.all(27.0),
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                    child: Builder(builder: (context) {
                      final bool showInsights =
                          gameState.turnHistory.length > 5;
                      if (!showInsights) {
                        // Single full-width Home button
                        return SizedBox(
                          width: double.infinity,
                          child: TeamColorButton(
                            text: 'Home',
                            icon: Icons.home,
                            color: uiColors[0],
                            onPressed: () {
                              Navigator.of(context)
                                  .popUntil((route) => route.isFirst);
                            },
                          ),
                        );
                      }
                      // Show Insights (left) + Home (right) in a single row
                      return Row(
                        children: [
                          Expanded(
                            child: TeamColorButton(
                              text: 'Insights',
                              icon: Icons.analytics_outlined,
                              color: teamColors[2],
                              variant: TeamButtonVariant.outline,
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const GameInsightsScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TeamColorButton(
                              text: 'Home',
                              icon: Icons.home,
                              color: uiColors[0],
                              onPressed: () {
                                Navigator.of(context)
                                    .popUntil((route) => route.isFirst);
                              },
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
