import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game_state_provider.dart';
import '../services/game_navigation_service.dart';
import 'package:convey/widgets/team_color_button.dart';

class ScoreboardScreen extends ConsumerWidget {
  final int roundNumber;
  final bool isTiebreaker;
  final List<int>? tiedTeamIndices;

  const ScoreboardScreen({
    Key? key,
    required this.roundNumber,
    this.isTiebreaker = false,
    this.tiedTeamIndices,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);
    if (gameState == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Find each team's score for this round
    final teamsCount = gameState.teamScores.length;
    final roundScores = List<int>.filled(teamsCount, 0);
    for (final turn in gameState.turnHistory
        .where((turn) => turn.roundNumber == roundNumber)) {
      roundScores[turn.teamIndex] += turn.score;
    }
    final topRoundScore = roundScores.isNotEmpty
        ? roundScores.reduce((a, b) => a > b ? a : b)
        : 0;

    // Calculate total scores up to previous round and up to current round
    final totalScoresPrev = List<int>.filled(teamsCount, 0);
    final totalScoresCurr = List<int>.filled(teamsCount, 0);
    for (final turn in gameState.turnHistory) {
      if (turn.roundNumber < roundNumber) {
        totalScoresPrev[turn.teamIndex] += turn.score;
      }
      if (turn.roundNumber <= roundNumber) {
        totalScoresCurr[turn.teamIndex] += turn.score;
      }
    }
    // Get rankings: higher score = higher rank (lower index)
    List<int> getRankings(List<int> scores) {
      final indexed =
          List.generate(scores.length, (i) => MapEntry(i, scores[i]));
      indexed.sort((a, b) => b.value.compareTo(a.value));
      final ranks = List<int>.filled(scores.length, 0);
      for (int rank = 0; rank < indexed.length; rank++) {
        ranks[indexed[rank].key] = rank;
      }
      return ranks;
    }

    final prevRanks = getRankings(totalScoresPrev);
    final currRanks = getRankings(totalScoresCurr);

    // Sort team indices by total score (descending)
    final sortedTeamIndices = List.generate(teamsCount, (i) => i)
      ..sort((a, b) => totalScoresCurr[b].compareTo(totalScoresCurr[a]));

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(27.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isTiebreaker) ...[
              Text(
                'Tiebreaker! Teams in a tie are highlighted.',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.deepOrange.withOpacity(0.8)
                        : Colors.deepOrange,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              'Round $roundNumber',
              style: Theme.of(context).textTheme.headlineMedium,
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
                    final totalScore = totalScoresCurr[teamIndex];
                    final isTopThisRound =
                        roundScores[teamIndex] == topRoundScore &&
                            topRoundScore > 0;
                    // Tiebreaker coloring logic
                    final bool isTied = isTiebreaker &&
                        (tiedTeamIndices?.contains(teamIndex) ?? false);
                    final Color backgroundColor = isTiebreaker && !isTied
                        ? Colors.grey.shade300
                        : teamColors[gameState.config.teamColorIndices.length >
                                    teamIndex
                                ? gameState.config.teamColorIndices[teamIndex]
                                : teamIndex % teamColors.length]
                            .background;
                    final Color borderColor = isTiebreaker && !isTied
                        ? Colors.grey
                        : teamColors[gameState.config.teamColorIndices.length >
                                    teamIndex
                                ? gameState.config.teamColorIndices[teamIndex]
                                : teamIndex % teamColors.length]
                            .border;
                    final Color textColor = isTiebreaker && !isTied
                        ? Colors.grey.shade600
                        : teamColors[gameState.config.teamColorIndices.length >
                                    teamIndex
                                ? gameState.config.teamColorIndices[teamIndex]
                                : teamIndex % teamColors.length]
                            .text;
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 10.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? borderColor.withOpacity(0.4)
                            : backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? backgroundColor.withOpacity(0.3)
                              : borderColor,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              isTopThisRound ? '$playerNames 🏆' : playerNames,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white.withOpacity(0.95)
                                          : textColor),
                            ),
                          ),
                          CircleAvatar(
                            backgroundColor:
                                Theme.of(context).brightness == Brightness.dark
                                    ? borderColor.withOpacity(0.8)
                                    : borderColor,
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
                          const SizedBox(width: 12),
                          // Arrow for leaderboard movement
                          Text(
                            roundNumber == 1
                                ? ''
                                : currRanks[teamIndex] < prevRanks[teamIndex]
                                    ? '▲'
                                    : currRanks[teamIndex] >
                                            prevRanks[teamIndex]
                                        ? '▼'
                                        : '',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: roundNumber == 1
                                  ? Colors.transparent
                                  : currRanks[teamIndex] < prevRanks[teamIndex]
                                      ? Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.green.withOpacity(0.8)
                                          : Colors.green
                                      : currRanks[teamIndex] >
                                              prevRanks[teamIndex]
                                          ? Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.red.withOpacity(0.8)
                                              : Colors.red
                                          : Colors.transparent,
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
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: TeamColorButton(
                    text: 'Next Round',
                    icon: Icons.arrow_forward,
                    color: teamColors[2], // Green
                    onPressed: () {
                      // Use navigation service to navigate to next round
                      GameNavigationService.navigateToNextRound(
                          context, ref, roundNumber + 1);
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
