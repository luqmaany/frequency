import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game_state_provider.dart';
import '../widgets/team_color_button.dart';
import '../models/game_state.dart';

class GameInsightsScreen extends ConsumerWidget {
  const GameInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);
    if (gameState == null) return const SizedBox.shrink();

    // Calculate game insights
    final insights = _calculateGameInsights(gameState);

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(27.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Game Insights Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Game Insights',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),

                        // Best Turn
                        if (insights['bestTurn'] != null) ...[
                          _buildInsightCard(
                            'Best Turn',
                            insights['bestTurn']['description'],
                            Icons.star,
                            Colors.amber,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Most Efficient Team
                        if (insights['mostEfficient'] != null) ...[
                          _buildInsightCard(
                            'Most Efficient Team',
                            insights['mostEfficient']['description'],
                            Icons.trending_up,
                            Colors.green,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Category Champions
                        if (insights['categoryChampions'].isNotEmpty) ...[
                          _buildInsightCard(
                            'Category Champions',
                            insights['categoryChampions'].join('\n'),
                            Icons.category,
                            Colors.blue,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Game Statistics
                        _buildInsightCard(
                          'Game Statistics',
                          insights['gameStats'],
                          Icons.bar_chart,
                          Colors.purple,
                        ),
                        const SizedBox(height: 16),

                        // Star Conveyor
                        if (insights['starConveyor'] != null) ...[
                          _buildInsightCard(
                            'Star Conveyor',
                            insights['starConveyor']['description'],
                            Icons.mic,
                            Colors.blue,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Star Guesser
                        if (insights['starGuesser'] != null) ...[
                          _buildInsightCard(
                            'Star Guesser',
                            insights['starGuesser']['description'],
                            Icons.psychology,
                            Colors.green,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          // Bottom section with Home button (pinned)
          Container(
            padding: const EdgeInsets.all(27.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
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
                    text: 'Leaderboard',
                    icon: Icons.leaderboard,
                    color: teamColors[1], // Green
                    onPressed: () {
                      Navigator.of(context).pop();
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

  Widget _buildInsightCard(
      String title, String content, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateGameInsights(gameState) {
    final insights = <String, dynamic>{};

    // Best Turn
    if (gameState.turnHistory.isNotEmpty) {
      final bestTurn = gameState.turnHistory
          .reduce((TurnRecord a, TurnRecord b) => a.score > b.score ? a : b);
      insights['bestTurn'] = {
        'description':
            '${bestTurn.conveyor} & ${bestTurn.guesser} scored ${bestTurn.score} points in ${bestTurn.category}',
      };
    }

    // Most Efficient Team
    final teamEfficiency = <int, double>{};
    for (int i = 0; i < gameState.teamScores.length; i++) {
      final teamTurns =
          gameState.turnHistory.where((turn) => turn.teamIndex == i).length;
      if (teamTurns > 0) {
        teamEfficiency[i] = gameState.teamScores[i] / teamTurns;
      }
    }
    if (teamEfficiency.isNotEmpty) {
      final mostEfficientTeam = teamEfficiency.entries.reduce(
          (MapEntry<int, double> a, MapEntry<int, double> b) =>
              a.value > b.value ? a : b);
      final teamNames =
          gameState.config.teams[mostEfficientTeam.key].join(' & ');
      insights['mostEfficient'] = {
        'description':
            '$teamNames averaged ${mostEfficientTeam.value.toStringAsFixed(1)} points per turn',
      };
    }

    // Category Champions
    final categoryScores = <String, Map<int, int>>{};
    for (final turn in gameState.turnHistory) {
      categoryScores.putIfAbsent(turn.category, () => {});
      categoryScores[turn.category]![turn.teamIndex] =
          (categoryScores[turn.category]![turn.teamIndex] ?? 0) + turn.score
              as int;
    }

    final categoryChampions = <String>[];
    for (final category in categoryScores.keys) {
      final scores = categoryScores[category]!;
      if (scores.isNotEmpty) {
        final winner = scores.entries.reduce(
            (MapEntry<int, int> a, MapEntry<int, int> b) =>
                a.value > b.value ? a : b);
        final teamNames = gameState.config.teams[winner.key].join(' & ');
        categoryChampions.add('$category: $teamNames (${winner.value} pts)');
      }
    }
    insights['categoryChampions'] = categoryChampions;

    // Game Statistics
    final totalTurns = gameState.turnHistory.length;
    final totalWords = gameState.turnHistory
        .fold(0, (sum, turn) => sum + turn.wordsGuessed.length);
    final totalSkips =
        gameState.turnHistory.fold(0, (sum, turn) => sum + turn.skipsUsed);
    final avgScorePerTurn = totalTurns > 0
        ? gameState.teamScores.reduce((int a, int b) => a + b) / totalTurns
        : 0;

    insights['gameStats'] = '''
Total Turns: $totalTurns
Total Words Guessed: $totalWords
Total Skips Used: $totalSkips
Average Score per Turn: ${avgScorePerTurn.toStringAsFixed(1)} points
Game Duration: ${gameState.currentRound} rounds''';

    // Star Conveyor and Star Guesser
    final playerStats = <String, Map<String, num>>{};
    for (final turn in gameState.turnHistory) {
      // Conveyor stats
      playerStats.putIfAbsent(
          turn.conveyor, () => {'wordsConveyed': 0, 'wordsGuessed': 0});
      playerStats[turn.conveyor]!['wordsConveyed'] =
          (playerStats[turn.conveyor]!['wordsConveyed'] ?? 0) +
              turn.wordsGuessed.length;

      // Guesser stats
      playerStats.putIfAbsent(
          turn.guesser, () => {'wordsConveyed': 0, 'wordsGuessed': 0});
      playerStats[turn.guesser]!['wordsGuessed'] =
          (playerStats[turn.guesser]!['wordsGuessed'] ?? 0) +
              turn.wordsGuessed.length;
    }

    if (playerStats.isNotEmpty) {
      // Find best conveyor
      String starConveyor = '';
      num maxWordsConveyed = 0;

      for (final player in playerStats.keys) {
        final wordsConveyed = playerStats[player]!['wordsConveyed'] ?? 0;
        if (wordsConveyed > maxWordsConveyed) {
          maxWordsConveyed = wordsConveyed;
          starConveyor = player;
        }
      }

      if (starConveyor.isNotEmpty) {
        final wordsConveyed =
            (playerStats[starConveyor]!['wordsConveyed'] ?? 0).toInt();
        insights['starConveyor'] = {
          'description': '$starConveyor: $wordsConveyed words conveyed',
        };
      }

      // Find best guesser
      String starGuesser = '';
      num maxWordsGuessed = 0;

      for (final player in playerStats.keys) {
        final wordsGuessed = playerStats[player]!['wordsGuessed'] ?? 0;
        if (wordsGuessed > maxWordsGuessed) {
          maxWordsGuessed = wordsGuessed;
          starGuesser = player;
        }
      }

      if (starGuesser.isNotEmpty) {
        final wordsGuessed =
            (playerStats[starGuesser]!['wordsGuessed'] ?? 0).toInt();
        insights['starGuesser'] = {
          'description': '$starGuesser: $wordsGuessed words guessed',
        };
      }
    }

    return insights;
  }
}
