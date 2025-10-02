import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../widgets/team_color_button.dart';
import '../widgets/celebration_explosions_background.dart';
import '../services/online_game_navigation_service.dart';

class OnlineGameInsightsScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final Map<String, dynamic> sessionData;

  const OnlineGameInsightsScreen({
    super.key,
    required this.sessionId,
    required this.sessionData,
  });

  @override
  ConsumerState<OnlineGameInsightsScreen> createState() =>
      _OnlineGameInsightsScreenState();
}

class _OnlineGameInsightsScreenState
    extends ConsumerState<OnlineGameInsightsScreen> {
  @override
  Widget build(BuildContext context) {
    // Calculate game insights from session data
    final insights = _calculateGameInsights(widget.sessionData);

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
              gapAngleRadians: 0.8,
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
                // Centered insight cards (up to 7)
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          items.length > 7 ? 7 : items.length,
                          (index) {
                            final item = items[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                top: index == 0 ? 20 : 12,
                                bottom: index ==
                                        (items.length > 7
                                            ? 6
                                            : items.length - 1)
                                    ? 20
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
                          onPressed: () async {
                            await OnlineGameNavigationService
                                .leaveSessionAndGoHome(
                              context: context,
                              ref: ref,
                              sessionId: widget.sessionId,
                            );
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

    // Prefer seven items from different teams when possible
    final selected = <Map<String, dynamic>>[];
    final usedTeamIndexes = <int>{};
    final usedTitles = <String>{};

    // First pass: prioritize items from different teams
    for (final item in order) {
      if (selected.length >= 7) break;
      final teamIndex = item['teamIndex'] as int?;
      final title = item['title'] as String;
      if (teamIndex != null && !usedTeamIndexes.contains(teamIndex)) {
        selected.add(item);
        usedTeamIndexes.add(teamIndex);
        usedTitles.add(title);
      }
    }

    // Second pass: fill remaining slots regardless of team
    if (selected.length < 7) {
      for (final item in order) {
        if (selected.length >= 7) break;
        final title = item['title'] as String;
        if (!usedTitles.contains(title)) {
          selected.add(item);
          usedTitles.add(title);
        }
      }
    }

    return selected;
  }

  Map<String, dynamic> _calculateGameInsights(
      Map<String, dynamic> sessionData) {
    final insights = <String, dynamic>{};

    // Extract game data from session
    final gameState = sessionData['gameState'] as Map<String, dynamic>? ?? {};
    final teams = sessionData['teams'] as List? ?? [];
    final settings = sessionData['settings'] as Map<String, dynamic>? ?? {};

    // Skip Rate Analysis - Who's the most decisive?
    final skipAnalysis = _analyzeSkipPatterns(gameState, teams);
    if (skipAnalysis['mostDecisive'] != null) {
      insights['mostDecisive'] = skipAnalysis['mostDecisive'];
    }
    if (skipAnalysis['skipMaster'] != null) {
      insights['skipMaster'] = skipAnalysis['skipMaster'];
    }

    // Momentum Analysis - Who had the best comeback?
    final momentumAnalysis = _analyzeMomentum(gameState, teams);
    if (momentumAnalysis['comebackKing'] != null) {
      insights['comebackKing'] = momentumAnalysis['comebackKing'];
    }

    // Category Specialist - Who's unexpectedly good at specific categories?
    final categoryAnalysis = _analyzeCategorySpecialists(gameState, teams);
    if (categoryAnalysis['categorySpecialist'] != null) {
      insights['categorySpecialist'] = categoryAnalysis['categorySpecialist'];
    }

    // Performance Consistency
    final consistencyAnalysis = _analyzeConsistency(gameState, teams);
    if (consistencyAnalysis['steadyEddie'] != null) {
      insights['steadyEddie'] = consistencyAnalysis['steadyEddie'];
    }
    if (consistencyAnalysis['rollercoaster'] != null) {
      insights['rollercoaster'] = consistencyAnalysis['rollercoaster'];
    }

    // Pressure Performance
    final pressureAnalysis = _analyzePressurePerformance(gameState, teams);
    if (pressureAnalysis['pressurePlayer'] != null) {
      insights['pressurePlayer'] = pressureAnalysis['pressurePlayer'];
    }

    // Add overall game statistics
    insights['gameStats'] = _generateGameStats(gameState, teams, settings);

    return insights;
  }

  Map<String, dynamic> _analyzeSkipPatterns(
      Map<String, dynamic> gameState, List teams) {
    final result = <String, dynamic>{};

    // Analyze skip patterns from game state
    final teamStats = <int, Map<String, int>>{};

    for (int i = 0; i < teams.length; i++) {
      teamStats[i] = {
        'skips': 0,
        'guesses': 0,
        'total': 0,
      };
    }

    // Process game rounds and turns to count skips vs guesses
    final rounds = gameState['rounds'] as List? ?? [];
    for (final round in rounds) {
      final turns = round['turns'] as List? ?? [];
      for (final turn in turns) {
        final teamIndex = turn['teamIndex'] as int? ?? 0;
        final skips = turn['skips'] as int? ?? 0;
        final guesses = turn['guesses'] as int? ?? 0;

        if (teamStats.containsKey(teamIndex)) {
          teamStats[teamIndex]!['skips'] =
              teamStats[teamIndex]!['skips']! + skips;
          teamStats[teamIndex]!['guesses'] =
              teamStats[teamIndex]!['guesses']! + guesses;
          teamStats[teamIndex]!['total'] =
              teamStats[teamIndex]!['total']! + skips + guesses;
        }
      }
    }

    // Find most decisive team (lowest skip rate)
    double lowestSkipRate = 1.0;
    int? mostDecisiveTeam;

    for (final entry in teamStats.entries) {
      final total = entry.value['total']!;
      if (total > 0) {
        final skipRate = entry.value['skips']! / total;
        if (skipRate < lowestSkipRate) {
          lowestSkipRate = skipRate;
          mostDecisiveTeam = entry.key;
        }
      }
    }

    if (mostDecisiveTeam != null && teams.length > mostDecisiveTeam) {
      final team = teams[mostDecisiveTeam] as Map<String, dynamic>;
      final teamName =
          team['teamName'] as String? ?? 'Team ${mostDecisiveTeam + 1}';
      final skipRatePercent = (lowestSkipRate * 100).round();

      result['mostDecisive'] = {
        'description':
            '$teamName made quick decisions with only $skipRatePercent% skips!',
        'teamIndex': mostDecisiveTeam,
        'subject': teamName,
      };
    }

    // Find skip master (highest skip rate)
    double highestSkipRate = 0.0;
    int? skipMasterTeam;

    for (final entry in teamStats.entries) {
      final total = entry.value['total']!;
      if (total > 0) {
        final skipRate = entry.value['skips']! / total;
        if (skipRate > highestSkipRate) {
          highestSkipRate = skipRate;
          skipMasterTeam = entry.key;
        }
      }
    }

    if (skipMasterTeam != null &&
        teams.length > skipMasterTeam &&
        highestSkipRate > 0.3) {
      final team = teams[skipMasterTeam] as Map<String, dynamic>;
      final teamName =
          team['teamName'] as String? ?? 'Team ${skipMasterTeam + 1}';
      final skipRatePercent = (highestSkipRate * 100).round();

      result['skipMaster'] = {
        'description': '$teamName was selective with $skipRatePercent% skips!',
        'teamIndex': skipMasterTeam,
        'subject': teamName,
      };
    }

    return result;
  }

  Map<String, dynamic> _analyzeMomentum(
      Map<String, dynamic> gameState, List teams) {
    final result = <String, dynamic>{};

    // Analyze comeback patterns from game state
    final rounds = gameState['rounds'] as List? ?? [];
    if (rounds.length < 2) return result;

    final teamScores = <int, List<int>>{};

    // Initialize team scores
    for (int i = 0; i < teams.length; i++) {
      teamScores[i] = [];
    }

    // Track scores through rounds
    for (final round in rounds) {
      final roundScores = round['scores'] as Map<String, dynamic>? ?? {};
      for (final entry in roundScores.entries) {
        final teamIndex = int.tryParse(entry.key) ?? 0;
        final score = entry.value as int? ?? 0;
        if (teamScores.containsKey(teamIndex)) {
          teamScores[teamIndex]!.add(score);
        }
      }
    }

    // Find biggest comeback
    double biggestComeback = 0.0;
    int? comebackTeam;

    for (final entry in teamScores.entries) {
      final scores = entry.value;
      if (scores.length >= 2) {
        final firstHalf =
            scores.take(scores.length ~/ 2).reduce((a, b) => a + b);
        final secondHalf =
            scores.skip(scores.length ~/ 2).reduce((a, b) => a + b);
        final improvement = secondHalf - firstHalf;

        if (improvement > biggestComeback) {
          biggestComeback = improvement.toDouble();
          comebackTeam = entry.key;
        }
      }
    }

    if (comebackTeam != null &&
        teams.length > comebackTeam &&
        biggestComeback > 0) {
      final team = teams[comebackTeam] as Map<String, dynamic>;
      final teamName =
          team['teamName'] as String? ?? 'Team ${comebackTeam + 1}';

      result['comebackKing'] = {
        'description':
            '$teamName had an amazing comeback, improving by ${biggestComeback.round()} points!',
        'teamIndex': comebackTeam,
        'subject': teamName,
      };
    }

    return result;
  }

  Map<String, dynamic> _analyzeCategorySpecialists(
      Map<String, dynamic> gameState, List teams) {
    final result = <String, dynamic>{};

    // Analyze category performance
    final categoryStats = <String, Map<int, int>>{};
    final rounds = gameState['rounds'] as List? ?? [];

    for (final round in rounds) {
      final category = round['category'] as String? ?? '';
      final turns = round['turns'] as List? ?? [];

      if (!categoryStats.containsKey(category)) {
        categoryStats[category] = {};
      }

      for (final turn in turns) {
        final teamIndex = turn['teamIndex'] as int? ?? 0;
        final score = turn['score'] as int? ?? 0;

        categoryStats[category]![teamIndex] =
            (categoryStats[category]![teamIndex] ?? 0) + score;
      }
    }

    // Find category specialist
    String? bestCategory;
    int? specialistTeam;
    double bestPerformance = 0.0;

    for (final entry in categoryStats.entries) {
      final category = entry.key;
      final teamScores = entry.value;

      if (teamScores.isNotEmpty) {
        final maxScore = teamScores.values.reduce((a, b) => a > b ? a : b);
        final avgScore =
            teamScores.values.reduce((a, b) => a + b) / teamScores.length;
        final performance = maxScore / (avgScore + 1); // Avoid division by zero

        if (performance > bestPerformance && performance > 1.5) {
          bestPerformance = performance;
          bestCategory = category;
          specialistTeam =
              teamScores.entries.firstWhere((e) => e.value == maxScore).key;
        }
      }
    }

    if (specialistTeam != null &&
        teams.length > specialistTeam &&
        bestCategory != null) {
      final team = teams[specialistTeam] as Map<String, dynamic>;
      final teamName =
          team['teamName'] as String? ?? 'Team ${specialistTeam + 1}';

      result['categorySpecialist'] = {
        'description': '$teamName dominated the $bestCategory category!',
        'teamIndex': specialistTeam,
        'subject': teamName,
      };
    }

    return result;
  }

  Map<String, dynamic> _analyzeConsistency(
      Map<String, dynamic> gameState, List teams) {
    final result = <String, dynamic>{};

    // Analyze score consistency across rounds
    final rounds = gameState['rounds'] as List? ?? [];
    if (rounds.length < 3) return result;

    final teamConsistency = <int, double>{};

    for (int i = 0; i < teams.length; i++) {
      final scores = <int>[];

      for (final round in rounds) {
        final roundScores = round['scores'] as Map<String, dynamic>? ?? {};
        final score = roundScores[i.toString()] as int? ?? 0;
        scores.add(score);
      }

      if (scores.length > 1) {
        final mean = scores.reduce((a, b) => a + b) / scores.length;
        final variance =
            scores.map((s) => (s - mean) * (s - mean)).reduce((a, b) => a + b) /
                scores.length;
        final stdDev = sqrt(variance);
        final coefficient = mean > 0 ? stdDev / mean : 0.0;
        teamConsistency[i] = coefficient;
      }
    }

    // Find most consistent team (lowest coefficient of variation)
    double lowestVariation = double.infinity;
    int? steadyTeam;

    for (final entry in teamConsistency.entries) {
      if (entry.value < lowestVariation) {
        lowestVariation = entry.value;
        steadyTeam = entry.key;
      }
    }

    if (steadyTeam != null && teams.length > steadyTeam) {
      final team = teams[steadyTeam] as Map<String, dynamic>;
      final teamName = team['teamName'] as String? ?? 'Team ${steadyTeam + 1}';

      result['steadyEddie'] = {
        'description':
            '$teamName was remarkably consistent throughout the game!',
        'teamIndex': steadyTeam,
        'subject': teamName,
      };
    }

    // Find most inconsistent team (highest coefficient of variation)
    double highestVariation = 0.0;
    int? rollercoasterTeam;

    for (final entry in teamConsistency.entries) {
      if (entry.value > highestVariation && entry.value > 0.5) {
        highestVariation = entry.value;
        rollercoasterTeam = entry.key;
      }
    }

    if (rollercoasterTeam != null && teams.length > rollercoasterTeam) {
      final team = teams[rollercoasterTeam] as Map<String, dynamic>;
      final teamName =
          team['teamName'] as String? ?? 'Team ${rollercoasterTeam + 1}';

      result['rollercoaster'] = {
        'description': '$teamName had a wild ride with ups and downs!',
        'teamIndex': rollercoasterTeam,
        'subject': teamName,
      };
    }

    return result;
  }

  Map<String, dynamic> _analyzePressurePerformance(
      Map<String, dynamic> gameState, List teams) {
    final result = <String, dynamic>{};

    // Analyze performance under pressure (close games, final rounds)
    final rounds = gameState['rounds'] as List? ?? [];
    if (rounds.length < 2) return result;

    final pressureScores = <int, List<int>>{};

    // Track scores in close situations
    for (final round in rounds) {
      final roundScores = round['scores'] as Map<String, dynamic>? ?? {};
      final scores = roundScores.values.cast<int>().toList();

      if (scores.isNotEmpty) {
        final maxScore = scores.reduce((a, b) => a > b ? a : b);
        final minScore = scores.reduce((a, b) => a < b ? a : b);
        final isClose = (maxScore - minScore) <= 2; // Close game

        if (isClose) {
          for (final entry in roundScores.entries) {
            final teamIndex = int.tryParse(entry.key) ?? 0;
            final score = entry.value as int? ?? 0;

            if (!pressureScores.containsKey(teamIndex)) {
              pressureScores[teamIndex] = [];
            }
            pressureScores[teamIndex]!.add(score);
          }
        }
      }
    }

    // Find pressure player
    double bestPressurePerformance = 0.0;
    int? pressurePlayer;

    for (final entry in pressureScores.entries) {
      final scores = entry.value;
      if (scores.isNotEmpty) {
        final avgScore = scores.reduce((a, b) => a + b) / scores.length;
        if (avgScore > bestPressurePerformance) {
          bestPressurePerformance = avgScore;
          pressurePlayer = entry.key;
        }
      }
    }

    if (pressurePlayer != null &&
        teams.length > pressurePlayer &&
        bestPressurePerformance > 0) {
      final team = teams[pressurePlayer] as Map<String, dynamic>;
      final teamName =
          team['teamName'] as String? ?? 'Team ${pressurePlayer + 1}';

      result['pressurePlayer'] = {
        'description': '$teamName thrived under pressure!',
        'teamIndex': pressurePlayer,
        'subject': teamName,
      };
    }

    return result;
  }

  String _generateGameStats(Map<String, dynamic> gameState, List teams,
      Map<String, dynamic> settings) {
    final rounds = gameState['rounds'] as List? ?? [];
    final totalRounds = rounds.length;
    final totalTeams = teams.length;

    // Calculate total words guessed
    int totalWords = 0;
    for (final round in rounds) {
      final turns = round['turns'] as List? ?? [];
      for (final turn in turns) {
        final guesses = turn['guesses'] as int? ?? 0;
        totalWords += guesses;
      }
    }

    final roundTime = settings['roundTimeSeconds'] as int? ?? 60;

    return 'Played $totalRounds rounds with $totalTeams teams. $totalWords words guessed in ${roundTime}s rounds!';
  }
}
