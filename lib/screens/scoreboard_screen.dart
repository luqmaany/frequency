import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game_state_provider.dart';
import 'category_selection_screen.dart';

class ScoreboardScreen extends ConsumerWidget {
  final int roundNumber;

  const ScoreboardScreen({Key? key, required this.roundNumber})
      : super(key: key);

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
      appBar: AppBar(
        title: Text('Round $roundNumber Scoreboard'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(27.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Team Scores',
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
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 4.0),
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
                                      fontWeight: FontWeight.bold),
                            ),
                          ),
                          CircleAvatar(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            radius: 18,
                            child: Text(
                              totalScore.toString(),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Arrow for leaderboard movement
                          Text(
                            roundNumber == 1
                                ? '–'
                                : currRanks[teamIndex] < prevRanks[teamIndex]
                                    ? '▲'
                                    : currRanks[teamIndex] >
                                            prevRanks[teamIndex]
                                        ? '▼'
                                        : '–',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: roundNumber == 1
                                  ? Colors.grey
                                  : currRanks[teamIndex] < prevRanks[teamIndex]
                                      ? Colors.green
                                      : currRanks[teamIndex] >
                                              prevRanks[teamIndex]
                                          ? Colors.red
                                          : Colors.grey,
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
                  child: ElevatedButton(
                    onPressed: () {
                      // Next round
                      final nextRound = roundNumber + 1;
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => CategorySelectionScreen(
                            teamIndex: gameState.currentTeamIndex,
                            roundNumber: nextRound,
                            turnNumber: 1,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 32),
                      minimumSize: const Size(0, 60), // Only control height
                    ),
                    child: const Text(
                      'Next Round',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
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
