import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
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

                        // Most Decisive Player
                        if (insights['mostDecisive'] != null) ...[
                          _buildInsightCard(
                            'Most Decisive',
                            insights['mostDecisive']['description'],
                            Icons.flash_on,
                            Colors.orange,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Skip Master
                        if (insights['skipMaster'] != null) ...[
                          _buildInsightCard(
                            'Skip Master',
                            insights['skipMaster']['description'],
                            Icons.fast_forward,
                            Colors.red,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Comeback King
                        if (insights['comebackKing'] != null) ...[
                          _buildInsightCard(
                            'Comeback King',
                            insights['comebackKing']['description'],
                            Icons.trending_up,
                            Colors.green,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Early Bird
                        if (insights['earlyBird'] != null) ...[
                          _buildInsightCard(
                            'Early Bird',
                            insights['earlyBird']['description'],
                            Icons.wb_sunny,
                            Colors.amber,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Category Specialist
                        if (insights['categorySpecialist'] != null) ...[
                          _buildInsightCard(
                            'Category Specialist',
                            insights['categorySpecialist']['description'],
                            Icons.psychology,
                            Colors.purple,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Category Struggler
                        if (insights['categoryStruggler'] != null) ...[
                          _buildInsightCard(
                            'Category Struggler',
                            insights['categoryStruggler']['description'],
                            Icons.help_outline,
                            Colors.orange,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Efficiency Paradox
                        if (insights['efficiencyParadox'] != null) ...[
                          _buildInsightCard(
                            'Efficiency Paradox',
                            insights['efficiencyParadox']['description'],
                            Icons.auto_awesome,
                            Colors.indigo,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Late Game Hero
                        if (insights['lateGameHero'] != null) ...[
                          _buildInsightCard(
                            'Late Game Hero',
                            insights['lateGameHero']['description'],
                            Icons.sports_esports,
                            Colors.deepPurple,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Pressure Player
                        if (insights['pressurePlayer'] != null) ...[
                          _buildInsightCard(
                            'Pressure Player',
                            insights['pressurePlayer']['description'],
                            Icons.whatshot,
                            Colors.red,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Dynamic Duo
                        if (insights['dynamicDuo'] != null) ...[
                          _buildInsightCard(
                            'Dynamic Duo',
                            insights['dynamicDuo']['description'],
                            Icons.favorite,
                            Colors.pink,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Steady Eddie
                        if (insights['steadyEddie'] != null) ...[
                          _buildInsightCard(
                            'Steady Eddie',
                            insights['steadyEddie']['description'],
                            Icons.straighten,
                            Colors.teal,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Rollercoaster
                        if (insights['rollercoaster'] != null) ...[
                          _buildInsightCard(
                            'Rollercoaster',
                            insights['rollercoaster']['description'],
                            Icons.waves,
                            Colors.cyan,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Game Statistics
                        _buildInsightCard(
                          'Game Statistics',
                          insights['gameStats'],
                          Icons.bar_chart,
                          Colors.grey,
                        ),
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

    // Skip Rate Analysis - Who's the most decisive?
    final skipAnalysis = _analyzeSkipPatterns(gameState);
    if (skipAnalysis['mostDecisive'] != null) {
      insights['mostDecisive'] = skipAnalysis['mostDecisive'];
    }
    if (skipAnalysis['skipMaster'] != null) {
      insights['skipMaster'] = skipAnalysis['skipMaster'];
    }

    // Momentum Analysis - Who had the best comeback?
    final momentumAnalysis = _analyzeMomentum(gameState);
    if (momentumAnalysis['comebackKing'] != null) {
      insights['comebackKing'] = momentumAnalysis['comebackKing'];
    }
    if (momentumAnalysis['earlyBird'] != null) {
      insights['earlyBird'] = momentumAnalysis['earlyBird'];
    }

    // Category Specialist - Who's unexpectedly good at specific categories?
    final categoryAnalysis = _analyzeCategorySpecialists(gameState);
    if (categoryAnalysis['categorySpecialist'] != null) {
      insights['categorySpecialist'] = categoryAnalysis['categorySpecialist'];
    }
    if (categoryAnalysis['categoryStruggler'] != null) {
      insights['categoryStruggler'] = categoryAnalysis['categoryStruggler'];
    }

    // Efficiency Paradox - Who's efficient in unexpected ways?
    final efficiencyAnalysis = _analyzeEfficiencyParadox(gameState);
    if (efficiencyAnalysis['efficiencyParadox'] != null) {
      insights['efficiencyParadox'] = efficiencyAnalysis['efficiencyParadox'];
    }

    // Round Performance - Who performs better in later rounds?
    final roundAnalysis = _analyzeRoundPerformance(gameState);
    if (roundAnalysis['lateGameHero'] != null) {
      insights['lateGameHero'] = roundAnalysis['lateGameHero'];
    }
    if (roundAnalysis['pressurePlayer'] != null) {
      insights['pressurePlayer'] = roundAnalysis['pressurePlayer'];
    }

    // Team Chemistry - Which partnerships work best?
    final chemistryAnalysis = _analyzeTeamChemistry(gameState);
    if (chemistryAnalysis['dynamicDuo'] != null) {
      insights['dynamicDuo'] = chemistryAnalysis['dynamicDuo'];
    }

    // Consistency Analysis - Who's the most reliable?
    final consistencyAnalysis = _analyzeConsistency(gameState);
    if (consistencyAnalysis['steadyEddie'] != null) {
      insights['steadyEddie'] = consistencyAnalysis['steadyEddie'];
    }
    if (consistencyAnalysis['rollercoaster'] != null) {
      insights['rollercoaster'] = consistencyAnalysis['rollercoaster'];
    }

    // Game Statistics (keep this one as it's useful)
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

    return insights;
  }

  Map<String, dynamic> _analyzeSkipPatterns(gameState) {
    final playerSkipStats = <String, Map<String, dynamic>>{};

    for (final turn in gameState.turnHistory) {
      // Analyze conveyor skip patterns
      playerSkipStats.putIfAbsent(
          turn.conveyor,
          () => {
                'totalSkips': 0,
                'totalTurns': 0,
                'skipRate': 0.0,
                'avgScoreWhenSkipping': 0.0,
                'avgScoreWhenNotSkipping': 0.0,
                'scoresWhenSkipping': <int>[],
                'scoresWhenNotSkipping': <int>[],
              });

      final stats = playerSkipStats[turn.conveyor]!;
      stats['totalTurns'] = (stats['totalTurns'] ?? 0) + 1;
      stats['totalSkips'] = (stats['totalSkips'] ?? 0) + turn.skipsUsed;

      if (turn.skipsUsed > 0) {
        (stats['scoresWhenSkipping'] as List<int>).add(turn.score);
      } else {
        (stats['scoresWhenNotSkipping'] as List<int>).add(turn.score);
      }
    }

    // Calculate averages and find insights
    String? mostDecisive;
    String? skipMaster;
    double bestSkipEfficiency = 0.0;
    double highestSkipRate = 0.0;

    for (final entry in playerSkipStats.entries) {
      final player = entry.key;
      final stats = entry.value;
      final totalTurns = stats['totalTurns'] as int;
      final totalSkips = stats['totalSkips'] as int;

      if (totalTurns > 0) {
        final skipRate = totalSkips / totalTurns;
        stats['skipRate'] = skipRate;

        // Calculate average scores
        final scoresWhenSkipping = stats['scoresWhenSkipping'] as List<int>;
        final scoresWhenNotSkipping =
            stats['scoresWhenNotSkipping'] as List<int>;

        if (scoresWhenSkipping.isNotEmpty) {
          final avgWhenSkipping = scoresWhenSkipping.reduce((a, b) => a + b) /
              scoresWhenSkipping.length;
          stats['avgScoreWhenSkipping'] = avgWhenSkipping;
        }

        if (scoresWhenNotSkipping.isNotEmpty) {
          final avgWhenNotSkipping =
              scoresWhenNotSkipping.reduce((a, b) => a + b) /
                  scoresWhenNotSkipping.length;
          stats['avgScoreWhenNotSkipping'] = avgWhenNotSkipping;
        }

        // Most decisive: highest score improvement when skipping
        if (scoresWhenSkipping.isNotEmpty && scoresWhenNotSkipping.isNotEmpty) {
          final skipEfficiency = (stats['avgScoreWhenSkipping'] as double) -
              (stats['avgScoreWhenNotSkipping'] as double);
          if (skipEfficiency > bestSkipEfficiency) {
            bestSkipEfficiency = skipEfficiency;
            mostDecisive = player;
          }
        }

        // Skip master: highest skip rate
        if (skipRate > highestSkipRate && totalTurns >= 2) {
          highestSkipRate = skipRate;
          skipMaster = player;
        }
      }
    }

    return {
      'mostDecisive': mostDecisive != null
          ? {
              'description':
                  '$mostDecisive scores ${bestSkipEfficiency.toStringAsFixed(1)} more points when using skips',
            }
          : null,
      'skipMaster': skipMaster != null
          ? {
              'description':
                  '$skipMaster used skips in ${(highestSkipRate * 100).toStringAsFixed(0)}% of turns',
            }
          : null,
    };
  }

  Map<String, dynamic> _analyzeMomentum(gameState) {
    final teamMomentum = <int, List<int>>{};

    // Group scores by team and round
    for (final turn in gameState.turnHistory) {
      teamMomentum.putIfAbsent(turn.teamIndex, () => []);
      teamMomentum[turn.teamIndex]!.add(turn.score);
    }

    String? comebackKing;
    String? earlyBird;
    double bestComeback = 0.0;
    double bestEarlyPerformance = 0.0;

    for (final entry in teamMomentum.entries) {
      final teamIndex = entry.key;
      final scores = entry.value;

      if (scores.length >= 3) {
        // Split into early and late performance
        final earlyScores = scores.take((scores.length / 2).floor()).toList();
        final lateScores = scores.skip((scores.length / 2).floor()).toList();

        if (earlyScores.isNotEmpty && lateScores.isNotEmpty) {
          final earlyAvg =
              earlyScores.reduce((a, b) => a + b) / earlyScores.length;
          final lateAvg =
              lateScores.reduce((a, b) => a + b) / lateScores.length;
          final improvement = lateAvg - earlyAvg;

          // Comeback king: biggest improvement
          if (improvement > bestComeback) {
            bestComeback = improvement;
            final teamNames = gameState.config.teams[teamIndex].join(' & ');
            comebackKing = teamNames;
          }

          // Early bird: best early performance
          if (earlyAvg > bestEarlyPerformance) {
            bestEarlyPerformance = earlyAvg;
            final teamNames = gameState.config.teams[teamIndex].join(' & ');
            earlyBird = teamNames;
          }
        }
      }
    }

    return {
      'comebackKing': comebackKing != null
          ? {
              'description':
                  '$comebackKing improved by ${bestComeback.toStringAsFixed(1)} points in later turns',
            }
          : null,
      'earlyBird': earlyBird != null
          ? {
              'description':
                  '$earlyBird had the strongest start with ${bestEarlyPerformance.toStringAsFixed(1)} avg early score',
            }
          : null,
    };
  }

  Map<String, dynamic> _analyzeCategorySpecialists(gameState) {
    final playerCategoryStats = <String, Map<String, List<int>>>{};

    for (final turn in gameState.turnHistory) {
      playerCategoryStats.putIfAbsent(turn.conveyor, () => {});
      playerCategoryStats[turn.conveyor]!.putIfAbsent(turn.category, () => []);
      playerCategoryStats[turn.conveyor]![turn.category]!.add(turn.score);
    }

    String? categorySpecialist;
    String? categoryStruggler;
    double bestSpecialization = 0.0;
    double worstSpecialization = double.infinity;

    for (final entry in playerCategoryStats.entries) {
      final player = entry.key;
      final categories = entry.value;

      if (categories.length >= 2) {
        // Find their best and worst categories
        String? bestCategory;
        String? worstCategory;
        double bestAvg = 0.0;
        double worstAvg = double.infinity;

        for (final categoryEntry in categories.entries) {
          final category = categoryEntry.key;
          final scores = categoryEntry.value;
          final avg = scores.reduce((a, b) => a + b) / scores.length;

          if (avg > bestAvg) {
            bestAvg = avg;
            bestCategory = category;
          }
          if (avg < worstAvg) {
            worstAvg = avg;
            worstCategory = category;
          }
        }

        // Calculate specialization (difference between best and worst)
        if (bestCategory != null && worstCategory != null) {
          final specialization = bestAvg - worstAvg;

          if (specialization > bestSpecialization) {
            bestSpecialization = specialization;
            categorySpecialist = '$player in $bestCategory';
          }

          if (specialization < worstSpecialization) {
            worstSpecialization = specialization;
            categoryStruggler = '$player struggles with $worstCategory';
          }
        }
      }
    }

    return {
      'categorySpecialist': categorySpecialist != null
          ? {
              'description':
                  '$categorySpecialist (${bestSpecialization.toStringAsFixed(1)} pt difference)',
            }
          : null,
      'categoryStruggler': categoryStruggler != null
          ? {
              'description':
                  '$categoryStruggler (${worstSpecialization.toStringAsFixed(1)} pt difference)',
            }
          : null,
    };
  }

  Map<String, dynamic> _analyzeEfficiencyParadox(gameState) {
    final teamEfficiency = <int, Map<String, dynamic>>{};

    for (int i = 0; i < gameState.teamScores.length; i++) {
      final teamTurns =
          gameState.turnHistory.where((turn) => turn.teamIndex == i).toList();
      if (teamTurns.isNotEmpty) {
        final totalScore = gameState.teamScores[i];
        final totalTurns = teamTurns.length;
        final totalWords =
            teamTurns.fold(0, (sum, turn) => sum + turn.wordsGuessed.length);
        final totalSkips =
            teamTurns.fold(0, (sum, turn) => sum + turn.skipsUsed);

        // Calculate different efficiency metrics
        final pointsPerTurn = totalScore / totalTurns;
        final pointsPerWord = totalWords > 0 ? totalScore / totalWords : 0.0;
        final wordsPerTurn = totalWords / totalTurns;
        final skipEfficiency = totalSkips > 0 ? totalScore / totalSkips : 0.0;

        teamEfficiency[i] = {
          'pointsPerTurn': pointsPerTurn,
          'pointsPerWord': pointsPerWord,
          'wordsPerTurn': wordsPerTurn,
          'skipEfficiency': skipEfficiency,
          'totalScore': totalScore,
        };
      }
    }

    // Find the efficiency paradox: team with high points per word but low points per turn
    String? efficiencyParadox;
    double bestParadox = 0.0;

    for (final entry in teamEfficiency.entries) {
      final teamIndex = entry.key;
      final stats = entry.value;

      // Paradox: high efficiency per word but low overall efficiency
      final paradoxScore = (stats['pointsPerWord'] as double) /
          (stats['pointsPerTurn'] as double);
      if (paradoxScore > bestParadox && stats['pointsPerWord'] > 2.0) {
        bestParadox = paradoxScore;
        final teamNames = gameState.config.teams[teamIndex].join(' & ');
        efficiencyParadox = teamNames;
      }
    }

    return {
      'efficiencyParadox': efficiencyParadox != null
          ? {
              'description':
                  '$efficiencyParadox is efficient per word but takes fewer turns',
            }
          : null,
    };
  }

  Map<String, dynamic> _analyzeRoundPerformance(gameState) {
    final teamRoundStats = <int, Map<int, List<int>>>{};

    for (final turn in gameState.turnHistory) {
      teamRoundStats.putIfAbsent(turn.teamIndex, () => {});
      teamRoundStats[turn.teamIndex]!.putIfAbsent(turn.roundNumber, () => []);
      teamRoundStats[turn.teamIndex]![turn.roundNumber]!.add(turn.score);
    }

    String? lateGameHero;
    String? pressurePlayer;
    double bestLateGame = 0.0;
    double bestPressure = 0.0;

    for (final entry in teamRoundStats.entries) {
      final teamIndex = entry.key;
      final rounds = entry.value;

      if (rounds.length >= 2) {
        final roundNumbers = rounds.keys.toList()..sort();
        final earlyRounds =
            roundNumbers.take((roundNumbers.length / 2).floor());
        final lateRounds = roundNumbers.skip((roundNumbers.length / 2).floor());

        if (earlyRounds.isNotEmpty && lateRounds.isNotEmpty) {
          // Calculate averages for early and late rounds
          double earlyAvg = 0.0;
          double lateAvg = 0.0;
          int earlyCount = 0;
          int lateCount = 0;

          for (final round in earlyRounds) {
            final scores = rounds[round]!;
            earlyAvg += scores.reduce((a, b) => a + b);
            earlyCount += scores.length;
          }
          earlyAvg = earlyCount > 0 ? earlyAvg / earlyCount : 0.0;

          for (final round in lateRounds) {
            final scores = rounds[round]!;
            lateAvg += scores.reduce((a, b) => a + b);
            lateCount += scores.length;
          }
          lateAvg = lateCount > 0 ? lateAvg / lateCount : 0.0;

          // Late game hero: biggest improvement in later rounds
          final lateGameImprovement = lateAvg - earlyAvg;
          if (lateGameImprovement > bestLateGame) {
            bestLateGame = lateGameImprovement;
            final teamNames = gameState.config.teams[teamIndex].join(' & ');
            lateGameHero = teamNames;
          }

          // Pressure player: performs best in the final round
          final finalRound = roundNumbers.last;
          if (rounds[finalRound]!.isNotEmpty) {
            final finalRoundAvg = rounds[finalRound]!.reduce((a, b) => a + b) /
                rounds[finalRound]!.length;
            if (finalRoundAvg > bestPressure) {
              bestPressure = finalRoundAvg;
              final teamNames = gameState.config.teams[teamIndex].join(' & ');
              pressurePlayer = teamNames;
            }
          }
        }
      }
    }

    return {
      'lateGameHero': lateGameHero != null
          ? {
              'description':
                  '$lateGameHero improves by ${bestLateGame.toStringAsFixed(1)} pts in later rounds',
            }
          : null,
      'pressurePlayer': pressurePlayer != null
          ? {
              'description':
                  '$pressurePlayer scored ${bestPressure.toStringAsFixed(1)} pts in the final round',
            }
          : null,
    };
  }

  Map<String, dynamic> _analyzeTeamChemistry(gameState) {
    final partnershipStats = <String, Map<String, dynamic>>{};

    for (final turn in gameState.turnHistory) {
      final partnership = '${turn.conveyor} & ${turn.guesser}';
      partnershipStats.putIfAbsent(
          partnership,
          () => {
                'scores': <int>[],
                'totalScore': 0,
                'turns': 0,
                'avgScore': 0.0,
              });

      final stats = partnershipStats[partnership]!;
      stats['scores'] = (stats['scores'] as List<int>)..add(turn.score);
      stats['totalScore'] = (stats['totalScore'] ?? 0) + turn.score;
      stats['turns'] = (stats['turns'] ?? 0) + 1;
      stats['avgScore'] =
          (stats['totalScore'] as int) / (stats['turns'] as int);
    }

    String? dynamicDuo;
    double bestPartnership = 0.0;

    for (final entry in partnershipStats.entries) {
      final partnership = entry.key;
      final stats = entry.value;

      if ((stats['turns'] as int) >= 2) {
        final avgScore = stats['avgScore'] as double;
        if (avgScore > bestPartnership) {
          bestPartnership = avgScore;
          dynamicDuo = partnership;
        }
      }
    }

    return {
      'dynamicDuo': dynamicDuo != null
          ? {
              'description':
                  '$dynamicDuo averages ${bestPartnership.toStringAsFixed(1)} points together',
            }
          : null,
    };
  }

  Map<String, dynamic> _analyzeConsistency(gameState) {
    final playerConsistency = <String, List<int>>{};

    for (final turn in gameState.turnHistory) {
      playerConsistency.putIfAbsent(turn.conveyor, () => []);
      playerConsistency[turn.conveyor]!.add(turn.score);
    }

    String? steadyEddie;
    String? rollercoaster;
    double bestConsistency = double.infinity;
    double worstConsistency = 0.0;

    for (final entry in playerConsistency.entries) {
      final player = entry.key;
      final scores = entry.value;

      if (scores.length >= 3) {
        final avg = scores.reduce((a, b) => a + b) / scores.length;
        final variance = scores
                .map((score) => (score - avg) * (score - avg))
                .reduce((a, b) => a + b) /
            scores.length;
        final standardDeviation = sqrt(variance);
        final coefficientOfVariation =
            standardDeviation / avg; // Lower = more consistent

        if (coefficientOfVariation < bestConsistency) {
          bestConsistency = coefficientOfVariation;
          steadyEddie = player;
        }

        if (coefficientOfVariation > worstConsistency) {
          worstConsistency = coefficientOfVariation;
          rollercoaster = player;
        }
      }
    }

    return {
      'steadyEddie': steadyEddie != null
          ? {
              'description': '$steadyEddie is the most consistent player',
            }
          : null,
      'rollercoaster': rollercoaster != null
          ? {
              'description':
                  '$rollercoaster has the most unpredictable performance',
            }
          : null,
    };
  }
}
