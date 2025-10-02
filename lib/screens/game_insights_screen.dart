import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../services/game_state_provider.dart';
import '../widgets/team_color_button.dart';
import '../widgets/celebration_explosions_background.dart';
import '../services/firestore_service.dart';

class GameInsightsScreen extends ConsumerStatefulWidget {
  const GameInsightsScreen({super.key});

  @override
  ConsumerState<GameInsightsScreen> createState() => _GameInsightsScreenState();
}

class _GameInsightsScreenState extends ConsumerState<GameInsightsScreen> {
  // Survey state
  Set<String> selectedTopInsights = {};
  String suggestedInsights = '';
  double overallRating = 0.0;
  String additionalFeedback = '';

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
                  child: Column(
                    children: [
                      // Survey button
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: TeamColorButton(
                          text: 'Quick Feedback',
                          icon: Icons.feedback,
                          color:
                              uiColors.length > 2 ? uiColors[2] : uiColors[0],
                          onPressed: () {
                            _showSurveyDialog(context, gameState, items);
                          },
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TeamColorButton(
                              text: 'Back',
                              icon: Icons.arrow_back,
                              color: uiColors.length > 1
                                  ? uiColors[1]
                                  : uiColors[0],
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

  void _showSurveyDialog(
      BuildContext context, gameState, List<Map<String, dynamic>> items) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Quick Feedback'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question 1: Top 3 insights
                    Text(
                      'What are your top 3 favorite insights?',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ...items.map((item) => CheckboxListTile(
                          title: Text(item['title'] as String),
                          value: selectedTopInsights.contains(item['title']),
                          onChanged: (bool? value) {
                            setDialogState(() {
                              if (value == true) {
                                if (selectedTopInsights.length < 3) {
                                  selectedTopInsights
                                      .add(item['title'] as String);
                                }
                              } else {
                                selectedTopInsights
                                    .remove(item['title'] as String);
                              }
                            });
                          },
                        )),
                    const SizedBox(height: 20),

                    // Question 2: Suggested insights
                    Text(
                      'What insights would you like to see?',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        hintText:
                            'e.g., "Best comeback story", "Most creative guesses"',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      onChanged: (value) => suggestedInsights = value,
                    ),
                    const SizedBox(height: 20),

                    // Question 3: Overall rating
                    Text(
                      'Rate the insights overall:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: List.generate(5, (index) {
                        return IconButton(
                          onPressed: () =>
                              setDialogState(() => overallRating = index + 1.0),
                          icon: Icon(
                            index < overallRating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 32,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),

                    // Question 4: Additional feedback
                    Text(
                      'Any other feedback? (optional)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Share your thoughts...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      onChanged: (value) => additionalFeedback = value,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _submitSurvey();
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitSurvey() async {
    final gameState = ref.read(gameStateProvider);
    if (gameState == null) return;

    try {
      // Create survey data
      final surveyData = {
        'timestamp': DateTime.now().toIso8601String(),
        'gameId': gameState.config.teams.join('_'), // Simple game identifier
        'gameContext': {
          'teamCount': gameState.config.teams.length,
          'gameLength': gameState.currentRound,
          'totalTurns': gameState.turnHistory.length,
          'insightsShown': selectedTopInsights.toList(),
        },
        'responses': {
          'topThreeInsights': selectedTopInsights.toList(),
          'suggestedInsights': suggestedInsights,
          'overallRating': overallRating,
          'additionalFeedback': additionalFeedback,
        },
        'deviceInfo': {
          'platform':
              'mobile', // Could be enhanced with actual platform detection
          'appVersion': '1.0.0', // Could be enhanced with actual version
        }
      };

      // Write to Firestore
      await FirestoreService.writeSurveyData(surveyData);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your feedback!'),
            duration: Duration(seconds: 2),
          ),
        );

        // Survey submitted successfully
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit feedback: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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

    // Time-based insights
    addIfExists('lightningReflexes', 'Lightning Reflexes', Icons.flash_on);
    addIfExists('clutchPlayer', 'Clutch Player', Icons.whatshot);
    addIfExists('speedDemon', 'Speed Demon', Icons.speed);
    addIfExists('analysisParalysis', 'Analysis Paralysis', Icons.psychology);
    addIfExists('wordWhisperer', 'Word Whisperer', Icons.book);
    addIfExists('timeMaster', 'Time Master', Icons.schedule);

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

    // Category Specialist - Who's unexpectedly good at specific categories?
    final categoryAnalysis = _analyzeCategorySpecialists(gameState);
    if (categoryAnalysis['categorySpecialist'] != null) {
      insights['categorySpecialist'] = categoryAnalysis['categorySpecialist'];
    }
    if (categoryAnalysis['categoryStruggler'] != null) {
      insights['categoryStruggler'] = categoryAnalysis['categoryStruggler'];
    }

    // Round Performance - Who performs better under pressure?
    final roundAnalysis = _analyzeRoundPerformance(gameState);
    if (roundAnalysis['pressurePlayer'] != null) {
      insights['pressurePlayer'] = roundAnalysis['pressurePlayer'];
    }

    // Consistency Analysis - Who's the most reliable?
    final consistencyAnalysis = _analyzeConsistency(gameState);
    if (consistencyAnalysis['steadyEddie'] != null) {
      insights['steadyEddie'] = consistencyAnalysis['steadyEddie'];
    }
    if (consistencyAnalysis['rollercoaster'] != null) {
      insights['rollercoaster'] = consistencyAnalysis['rollercoaster'];
    }

    // Time-based Analysis - Speed and reaction insights
    final timeAnalysis = _analyzeTimeBasedInsights(gameState);
    if (timeAnalysis['lightningReflexes'] != null) {
      insights['lightningReflexes'] = timeAnalysis['lightningReflexes'];
    }
    if (timeAnalysis['clutchPlayer'] != null) {
      insights['clutchPlayer'] = timeAnalysis['clutchPlayer'];
    }
    if (timeAnalysis['speedDemon'] != null) {
      insights['speedDemon'] = timeAnalysis['speedDemon'];
    }
    if (timeAnalysis['analysisParalysis'] != null) {
      insights['analysisParalysis'] = timeAnalysis['analysisParalysis'];
    }
    if (timeAnalysis['wordWhisperer'] != null) {
      insights['wordWhisperer'] = timeAnalysis['wordWhisperer'];
    }
    if (timeAnalysis['timeMaster'] != null) {
      insights['timeMaster'] = timeAnalysis['timeMaster'];
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

  Map<String, dynamic> _analyzeRoundPerformance(gameState) {
    final teamRoundStats = <int, Map<int, List<int>>>{};

    for (final turn in gameState.turnHistory) {
      teamRoundStats.putIfAbsent(turn.teamIndex, () => {});
      teamRoundStats[turn.teamIndex]!.putIfAbsent(turn.roundNumber, () => []);
      teamRoundStats[turn.teamIndex]![turn.roundNumber]!.add(turn.score);
    }

    String? pressurePlayer;
    int? pressurePlayerTeamIndex;
    double bestPressure = 0.0;

    for (final entry in teamRoundStats.entries) {
      final teamIndex = entry.key;
      final rounds = entry.value;

      if (rounds.length >= 2) {
        final roundNumbers = rounds.keys.toList()..sort();

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

    return {
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

  Map<String, dynamic> _analyzeTimeBasedInsights(gameState) {
    final allWordTimings = <String, double>{}; // word -> timing
    final playerTimings = <String, List<double>>{}; // player -> [timings]
    final playerClutchScores = <String, num>{}; // player -> clutch points
    final playerTotalScores = <String, num>{}; // player -> total points

    // Collect all timing data from turn history
    for (final turn in gameState.turnHistory) {
      if (turn.wordTimings != null && turn.wordTimings!.isNotEmpty) {
        // Add to global word timings
        allWordTimings.addAll(turn.wordTimings!);

        // Track player timings (only for guessed words)
        for (final word in turn.wordsGuessed) {
          if (turn.wordTimings!.containsKey(word)) {
            playerTimings.putIfAbsent(turn.conveyor, () => []);
            playerTimings[turn.conveyor]!.add(turn.wordTimings![word]!);
          }
        }

        // Calculate clutch performance (scores in final 10 seconds)
        // For simplicity, we'll use words guessed in the last portion of the turn
        // This is a rough approximation since we don't have exact turn timing
        final totalWords = turn.wordsGuessed.length + turn.wordsSkipped.length;
        if (totalWords > 0) {
          final clutchThreshold =
              (totalWords * 0.7).ceil(); // Last 30% of words
          final clutchWords = turn.wordsGuessed
              .skip(turn.wordsGuessed.length > clutchThreshold
                  ? turn.wordsGuessed.length - clutchThreshold
                  : 0)
              .toList();

          final currentClutch = playerClutchScores[turn.conveyor] ?? 0;
          final currentTotal = playerTotalScores[turn.conveyor] ?? 0;
          playerClutchScores[turn.conveyor] =
              currentClutch + clutchWords.length;
          playerTotalScores[turn.conveyor] =
              currentTotal + turn.wordsGuessed.length;
        }
      }
    }

    // Find insights
    String? lightningReflexes;
    int? lightningReflexesTeamIndex;
    double fastestTime = double.infinity;
    String? fastestWord = '';

    String? speedDemon;
    int? speedDemonTeamIndex;
    double bestAverageSpeed = double.infinity;

    String? clutchPlayer;
    int? clutchPlayerTeamIndex;
    double bestClutchRatio = 0.0;

    String? analysisParalysis;
    int? analysisParalysisTeamIndex;
    double longestHesitation = 0.0;
    String? longestHesitationWord = '';

    String? wordWhisperer;
    int? wordWhispererTeamIndex;
    double bestCategorySpeed = double.infinity;

    String? timeMaster;
    int? timeMasterTeamIndex;
    double bestTimeConsistency = double.infinity;

    // Lightning Reflexes: Fastest individual word guess
    for (final entry in allWordTimings.entries) {
      if (entry.value < fastestTime) {
        fastestTime = entry.value;
        fastestWord = entry.key;
      }
    }

    // Find which player guessed the fastest word
    if (fastestWord != null && fastestWord.isNotEmpty) {
      for (final turn in gameState.turnHistory) {
        if (turn.wordsGuessed.contains(fastestWord)) {
          lightningReflexes =
              '$fastestWord in ${fastestTime.toStringAsFixed(1)}s';
          lightningReflexesTeamIndex =
              _teamIndexForPlayer(gameState, turn.conveyor);
          break;
        }
      }
    }

    // Speed Demon: Player with lowest average reaction time
    for (final entry in playerTimings.entries) {
      if (entry.value.length >= 3) {
        // Need at least 3 guesses
        final avgTime =
            entry.value.reduce((a, b) => a + b) / entry.value.length;
        if (avgTime < bestAverageSpeed) {
          bestAverageSpeed = avgTime;
          speedDemon = entry.key;
          speedDemonTeamIndex = _teamIndexForPlayer(gameState, entry.key);
        }
      }
    }

    // Clutch Player: Best performance in final portion of turns
    for (final entry in playerClutchScores.entries) {
      final totalScore = playerTotalScores[entry.key] ?? 0;
      if (totalScore >= 5) {
        // Need at least 5 total guesses
        final clutchRatio = entry.value / totalScore;
        if (clutchRatio > bestClutchRatio) {
          bestClutchRatio = clutchRatio;
          clutchPlayer = entry.key;
          clutchPlayerTeamIndex = _teamIndexForPlayer(gameState, entry.key);
        }
      }
    }

    // Analysis Paralysis: Longest hesitation before skipping
    for (final turn in gameState.turnHistory) {
      if (turn.wordTimings != null) {
        for (final word in turn.wordsSkipped) {
          if (turn.wordTimings!.containsKey(word) &&
              turn.wordTimings![word]! > longestHesitation) {
            longestHesitation = turn.wordTimings![word]!;
            longestHesitationWord = word;
            analysisParalysis = turn.conveyor;
            analysisParalysisTeamIndex =
                _teamIndexForPlayer(gameState, turn.conveyor);
          }
        }
      }
    }

    // Word Whisperer: Fastest at specific categories
    final playerCategorySpeeds = <String, Map<String, List<double>>>{};
    for (final turn in gameState.turnHistory) {
      if (turn.wordTimings != null) {
        playerCategorySpeeds.putIfAbsent(turn.conveyor, () => {});
        playerCategorySpeeds[turn.conveyor]!
            .putIfAbsent(turn.category, () => []);

        for (final word in turn.wordsGuessed) {
          if (turn.wordTimings!.containsKey(word)) {
            playerCategorySpeeds[turn.conveyor]![turn.category]!
                .add(turn.wordTimings![word]!);
          }
        }
      }
    }

    for (final entry in playerCategorySpeeds.entries) {
      final player = entry.key;
      final categories = entry.value;

      for (final categoryEntry in categories.entries) {
        final speeds = categoryEntry.value;
        if (speeds.length >= 3) {
          // Need at least 3 guesses in this category
          final avgSpeed = speeds.reduce((a, b) => a + b) / speeds.length;
          if (avgSpeed < bestCategorySpeed) {
            bestCategorySpeed = avgSpeed;
            wordWhisperer = '$player in ${categoryEntry.key}';
            wordWhispererTeamIndex = _teamIndexForPlayer(gameState, player);
          }
        }
      }
    }

    // Time Master: Most consistent reaction times
    for (final entry in playerTimings.entries) {
      if (entry.value.length >= 5) {
        // Need at least 5 guesses
        final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
        final variance = entry.value
                .map((time) => (time - avg) * (time - avg))
                .reduce((a, b) => a + b) /
            entry.value.length;
        final standardDeviation = sqrt(variance);
        final coefficientOfVariation =
            standardDeviation / avg; // Lower = more consistent

        if (coefficientOfVariation < bestTimeConsistency) {
          bestTimeConsistency = coefficientOfVariation;
          timeMaster = entry.key;
          timeMasterTeamIndex = _teamIndexForPlayer(gameState, entry.key);
        }
      }
    }

    return {
      'lightningReflexes': lightningReflexes != null
          ? {
              'description': 'Guessed $lightningReflexes',
              'subject': lightningReflexes,
              'teamIndex': lightningReflexesTeamIndex,
            }
          : null,
      'speedDemon': speedDemon != null
          ? {
              'description':
                  '$speedDemon averages ${bestAverageSpeed.toStringAsFixed(1)}s per guess',
              'subject': speedDemon,
              'teamIndex': speedDemonTeamIndex,
            }
          : null,
      'clutchPlayer': clutchPlayer != null
          ? {
              'description':
                  '$clutchPlayer scored ${(bestClutchRatio * 100).toStringAsFixed(0)}% in clutch moments',
              'subject': clutchPlayer,
              'teamIndex': clutchPlayerTeamIndex,
            }
          : null,
      'analysisParalysis': analysisParalysis != null
          ? {
              'description':
                  '$analysisParalysis hesitated for ${longestHesitation.toStringAsFixed(1)}s on "$longestHesitationWord"',
              'subject': analysisParalysis,
              'teamIndex': analysisParalysisTeamIndex,
            }
          : null,
      'wordWhisperer': wordWhisperer != null
          ? {
              'description':
                  '$wordWhisperer (${bestCategorySpeed.toStringAsFixed(1)}s avg)',
              'subject': wordWhisperer,
              'teamIndex': wordWhispererTeamIndex,
            }
          : null,
      'timeMaster': timeMaster != null
          ? {
              'description':
                  '$timeMaster has the most consistent reaction times',
              'subject': timeMaster,
              'teamIndex': timeMasterTeamIndex,
            }
          : null,
    };
  }
}
