import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/session_providers.dart';
import '../widgets/team_color_button.dart';
import '../widgets/podium_display.dart';
import '../widgets/celebration_explosions_background.dart';
import 'game_insights_screen.dart';

class OnlineGameOverScreen extends ConsumerWidget {
  final String sessionId;
  const OnlineGameOverScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionStreamProvider(sessionId));
    return sessionAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        body: Center(child: Text('Error: $err')),
      ),
      data: (docSnap) {
        final data = docSnap?.data();
        if (data == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final List<Map<String, dynamic>> teams =
            ((data['teams'] as List?) ?? const [])
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
        final gameState = (data['gameState'] as Map<String, dynamic>?) ?? {};
        final List<Map<String, dynamic>> turnHistory =
            ((gameState['turnHistory'] as List?) ?? const [])
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();

        // Compute total scores by team
        final Map<int, int> totals = {};
        for (final tr in turnHistory) {
          final int teamIndex = (tr['teamIndex'] as int?) ?? 0;
          final int score = (tr['correctCount'] as int?) ?? 0;
          totals[teamIndex] = (totals[teamIndex] ?? 0) + score;
        }

        final sortedTeamIndices = List.generate(teams.length, (i) => i)
          ..sort((a, b) => (totals[b] ?? 0).compareTo(totals[a] ?? 0));

        // Build podium data
        final podiumTeams = sortedTeamIndices.map((teamIndex) {
          final String teamName =
              (teams[teamIndex]['teamName'] as String?) ?? '';
          final totalScore = totals[teamIndex] ?? 0;
          final isWinner =
              teamIndex == sortedTeamIndices.first && totalScore > 0;
          return {
            'name': teamName,
            'score': totalScore,
            'isWinner': isWinner,
            'teamIndex': teamIndex,
          };
        }).toList();

        return Scaffold(
          body: Stack(
            children: [
              const Positioned.fill(
                child: CelebrationExplosionsBackground(
                  burstsPerSecond: 7.0,
                  strokeWidth: 2.0,
                  baseOpacity: 0.12,
                  highlightOpacity: 0.55,
                  ringSpacing: 8.0,
                  globalOpacity: 1.0,
                  totalSectors: 12,
                  removedSectors: 6,
                  gapAngleRadians: 0.8,
                ),
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
                              showOthers: false,
                            ),
                            const SizedBox(height: 10),
                            // Standings from 4th place onward styled like the scoreboard rows
                            if (sortedTeamIndices.length > 3)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: List.generate(
                                  sortedTeamIndices.length - 3,
                                  (i) {
                                    final teamIndex = sortedTeamIndices[i + 3];
                                    final String teamName = (teams[teamIndex]
                                            ['teamName'] as String?) ??
                                        '';
                                    final int colorIndex = (teams[teamIndex]
                                            ['colorIndex'] as int?) ??
                                        (teamIndex % teamColors.length);
                                    final colorDef = teamColors[
                                        colorIndex % teamColors.length];
                                    final totalScore = totals[teamIndex] ?? 0;

                                    final Color fillColor = colorDef.border;
                                    final Color outlineColor =
                                        colorDef.background.withOpacity(0.3);

                                    return Container(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 8.0),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10.0, horizontal: 10.0),
                                      decoration: BoxDecoration(
                                        color: fillColor,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: outlineColor,
                                          width: 2,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              teamName,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge
                                                  ?.copyWith(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white
                                                        .withOpacity(0.95),
                                                  ),
                                            ),
                                          ),
                                          CircleAvatar(
                                            backgroundColor: colorDef.border
                                                .withOpacity(0.8),
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
                        final bool showInsights = turnHistory.length > 5;
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
        );
      },
    );
  }
}
