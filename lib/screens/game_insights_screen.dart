import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../services/game_state_provider.dart';
import '../widgets/team_color_button.dart';
import '../widgets/celebration_explosions_background.dart';

class GameInsightsScreen extends ConsumerStatefulWidget {
  const GameInsightsScreen({super.key});

  @override
  ConsumerState<GameInsightsScreen> createState() => _GameInsightsScreenState();
}

class _GameInsightsScreenState extends ConsumerState<GameInsightsScreen> {
  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    if (gameState == null) return const SizedBox.shrink();

    // Calculate game insights
    final insights = _calculateGameInsights(gameState);

    // Build top 5 interesting insight items (title, description, icon)
    final List<Map<String, dynamic>> items = _selectTopInsights(insights);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: CelebrationExplosionsBackground(
              burstsPerSecond: 4.0,
              strokeWidth: 2.0,
              baseOpacity: 0.12,
              highlightOpacity: 0.55,
              ringSpacing: 8.0,
              globalOpacity: 1.0,
              totalSectors: 12,
              removedSectors: 6,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: const Center(
                    child: Text(
                      'Insights',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // Centered top 3 insight cards
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          items.length > 3 ? 3 : items.length,
                          (index) {
                            final item = items[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                top: index == 0 ? 0 : 12,
                                bottom: index ==
                                        (items.length > 3
                                            ? 2
                                            : items.length - 1)
                                    ? 0
                                    : 12,
                              ),
                              child: _buildCarouselCard(
                                context,
                                title: item['title'] as String,
                                description: item['description'] as String,
                                icon: item['icon'] as IconData,
                                colorIndex: index,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                // Bottom
                Container(
                  padding: const EdgeInsets.all(27.0),
                  decoration: const BoxDecoration(color: Colors.transparent),
                  child: Row(
                    children: [
                      Expanded(
                        child: TeamColorButton(
                          text: 'Back',
                          icon: Icons.arrow_back,
                          color:
                              uiColors.length > 1 ? uiColors[1] : uiColors[0],
                          onPressed: () {
                            // Go back to the previous screen (Game Over)
                            Navigator.of(context).pop();
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselCard(BuildContext context,
      {required String title,
      required String description,
      required IconData icon,
      required int colorIndex}) {
    final themeBg = Theme.of(context).colorScheme.background;
    final accent = teamColors[colorIndex % teamColors.length];
    final overlay = accent.border.withOpacity(0.55);
    final cardBg = Color.alphaBlend(overlay, themeBg);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 120),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.border.withOpacity(0.85), width: 2),
        boxShadow: [
          BoxShadow(
            color: accent.border.withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color.alphaBlend(accent.border.withOpacity(0.22), themeBg),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: accent.border.withOpacity(0.75), width: 1.5),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _selectTopInsights(Map<String, dynamic> insights) {
    // Build candidate list with metadata from insights
    final order = <Map<String, dynamic>>[];

    void addIfExists(String key, String title, IconData icon) {
      final entry = insights[key];
      if (entry != null) {
        order.add({
          'title': title,
          'description': entry['description'],
          'icon': icon,
          'teamIndex': entry['teamIndex'],
          'subject': entry['subject'],
        });
      }
    }

    addIfExists('mostDecisive', 'Most Decisive', Icons.flash_on);
    addIfExists('comebackKing', 'Comeback King', Icons.trending_up);
    addIfExists('dynamicDuo', 'Dynamic Duo', Icons.favorite);
    addIfExists('lateGameHero', 'Late Game Hero', Icons.sports_esports);
    addIfExists('efficiencyParadox', 'Efficiency Paradox', Icons.auto_awesome);
    addIfExists('pressurePlayer', 'Pressure Player', Icons.whatshot);
    addIfExists('skipMaster', 'Skip Master', Icons.fast_forward);
    addIfExists('categorySpecialist', 'Category Specialist', Icons.psychology);
    addIfExists('steadyEddie', 'Steady Eddie', Icons.straighten);
    addIfExists('rollercoaster', 'Rollercoaster', Icons.waves);

    // Optional global stats
    if (insights['gameStats'] != null) {
      order.add({
        'title': 'Game Statistics',
        'description': insights['gameStats'] as String,
        'icon': Icons.bar_chart,
        'teamIndex': null,
        'subject': null,
      });
    }

    // Prefer three items from different teams when possible
    final selected = <Map<String, dynamic>>[];
    final usedTeamIndexes = <int>{};
    final usedTitles = <String>{};

    for (final item in order) {
      if (selected.length >= 3) break;
      final teamIndex = item['teamIndex'] as int?;
      final title = item['title'] as String;
      if (teamIndex != null && !usedTeamIndexes.contains(teamIndex)) {
        selected.add(item);
        usedTeamIndexes.add(teamIndex);
        usedTitles.add(title);
      }
    }

    // Fill remaining slots regardless of team
    if (selected.length < 3) {
      for (final item in order) {
        if (selected.length >= 3) break;
        final title = item['title'] as String;
        if (!usedTitles.contains(title)) {
          selected.add(item);
          usedTitles.add(title);
        }
      }
    }

    return selected;
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

  int? _teamIndexForPlayer(dynamic gameState, String playerName) {
    for (int i = 0; i < gameState.config.teams.length; i++) {
      if (gameState.config.teams[i].contains(playerName)) {
        return i;
      }
    }
    return null;
  }

  int? _teamIndexForPair(dynamic gameState, String a, String b) {
    for (int i = 0; i < gameState.config.teams.length; i++) {
      final team = gameState.config.teams[i];
      if (team.contains(a) && team.contains(b)) {
        return i;
      }
    }
    // Fallback to first player's team if both not found together
    return _teamIndexForPlayer(gameState, a) ??
        _teamIndexForPlayer(gameState, b);
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
              'subject': mostDecisive,
              'teamIndex': _teamIndexForPlayer(gameState, mostDecisive),
            }
          : null,
      'skipMaster': skipMaster != null
          ? {
              'description':
                  '$skipMaster used skips in ${(highestSkipRate * 100).toStringAsFixed(0)}% of turns',
              'subject': skipMaster,
              'teamIndex': _teamIndexForPlayer(gameState, skipMaster),
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
    int? comebackKingTeamIndex;
    String? earlyBird;
    int? earlyBirdTeamIndex;
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
            comebackKingTeamIndex = teamIndex;
          }

          // Early bird: best early performance
          if (earlyAvg > bestEarlyPerformance) {
            bestEarlyPerformance = earlyAvg;
            final teamNames = gameState.config.teams[teamIndex].join(' & ');
            earlyBird = teamNames;
            earlyBirdTeamIndex = teamIndex;
          }
        }
      }
    }

    return {
      'comebackKing': comebackKing != null
          ? {
              'description':
                  '$comebackKing improved by ${bestComeback.toStringAsFixed(1)} points in later turns',
              'subject': comebackKing,
              'teamIndex': comebackKingTeamIndex,
            }
          : null,
      'earlyBird': earlyBird != null
          ? {
              'description':
                  '$earlyBird had the strongest start with ${bestEarlyPerformance.toStringAsFixed(1)} avg early score',
              'subject': earlyBird,
              'teamIndex': earlyBirdTeamIndex,
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
    int? categorySpecialistTeamIndex;
    String? categoryStruggler;
    int? categoryStrugglerTeamIndex;
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
            categorySpecialistTeamIndex =
                _teamIndexForPlayer(gameState, player);
          }

          if (specialization < worstSpecialization) {
            worstSpecialization = specialization;
            categoryStruggler = '$player struggles with $worstCategory';
            categoryStrugglerTeamIndex = _teamIndexForPlayer(gameState, player);
          }
        }
      }
    }

    return {
      'categorySpecialist': categorySpecialist != null
          ? {
              'description':
                  '$categorySpecialist (${bestSpecialization.toStringAsFixed(1)} pt difference)',
              'subject': categorySpecialist,
              'teamIndex': categorySpecialistTeamIndex,
            }
          : null,
      'categoryStruggler': categoryStruggler != null
          ? {
              'description':
                  '$categoryStruggler (${worstSpecialization.toStringAsFixed(1)} pt difference)',
              'subject': categoryStruggler,
              'teamIndex': categoryStrugglerTeamIndex,
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
    int? efficiencyParadoxTeamIndex;
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
        efficiencyParadoxTeamIndex = teamIndex;
      }
    }

    return {
      'efficiencyParadox': efficiencyParadox != null
          ? {
              'description':
                  '$efficiencyParadox is efficient per word but takes fewer turns',
              'subject': efficiencyParadox,
              'teamIndex': efficiencyParadoxTeamIndex,
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
    int? lateGameHeroTeamIndex;
    String? pressurePlayer;
    int? pressurePlayerTeamIndex;
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
            lateGameHeroTeamIndex = teamIndex;
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
              pressurePlayerTeamIndex = teamIndex;
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
              'subject': lateGameHero,
              'teamIndex': lateGameHeroTeamIndex,
            }
          : null,
      'pressurePlayer': pressurePlayer != null
          ? {
              'description':
                  '$pressurePlayer scored ${bestPressure.toStringAsFixed(1)} pts in the final round',
              'subject': pressurePlayer,
              'teamIndex': pressurePlayerTeamIndex,
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
    int? dynamicDuoTeamIndex;
    double bestPartnership = 0.0;

    for (final entry in partnershipStats.entries) {
      final partnership = entry.key;
      final stats = entry.value;

      if ((stats['turns'] as int) >= 2) {
        final avgScore = stats['avgScore'] as double;
        if (avgScore > bestPartnership) {
          bestPartnership = avgScore;
          dynamicDuo = partnership;
          final parts = partnership.split(' & ');
          if (parts.length == 2) {
            dynamicDuoTeamIndex =
                _teamIndexForPair(gameState, parts[0].trim(), parts[1].trim());
          } else {
            dynamicDuoTeamIndex = null;
          }
        }
      }
    }

    return {
      'dynamicDuo': dynamicDuo != null
          ? {
              'description':
                  '$dynamicDuo averages ${bestPartnership.toStringAsFixed(1)} points together',
              'subject': dynamicDuo,
              'teamIndex': dynamicDuoTeamIndex,
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
    int? steadyEddieTeamIndex;
    String? rollercoaster;
    int? rollercoasterTeamIndex;
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
          steadyEddieTeamIndex = _teamIndexForPlayer(gameState, player);
        }

        if (coefficientOfVariation > worstConsistency) {
          worstConsistency = coefficientOfVariation;
          rollercoaster = player;
          rollercoasterTeamIndex = _teamIndexForPlayer(gameState, player);
        }
      }
    }

    return {
      'steadyEddie': steadyEddie != null
          ? {
              'description': '$steadyEddie is the most consistent player',
              'subject': steadyEddie,
              'teamIndex': steadyEddieTeamIndex,
            }
          : null,
      'rollercoaster': rollercoaster != null
          ? {
              'description':
                  '$rollercoaster has the most unpredictable performance',
              'subject': rollercoaster,
              'teamIndex': rollercoasterTeamIndex,
            }
          : null,
    };
  }
}
