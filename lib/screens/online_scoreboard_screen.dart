import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/session_providers.dart';
import '../services/firestore_service.dart';
import '../widgets/team_color_button.dart';
import '../services/online_game_navigation_service.dart';

class OnlineScoreboardScreen extends ConsumerWidget {
  final String sessionId;

  const OnlineScoreboardScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionStreamProvider(sessionId));
    final deviceIdAsync = ref.watch(deviceIdProvider);

    // Listen for status changes and navigate away from scoreboard when it changes
    ref.listen(sessionStatusProvider(sessionId), (prev, next) {
      final status = next.value;
      if (status != null && status != 'round_end') {
        OnlineGameNavigationService.handleNavigation(
          context: context,
          ref: ref,
          sessionId: sessionId,
          status: status,
        );
      }
    });

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

        final gameState = (data['gameState'] as Map<String, dynamic>?) ?? {};
        final int rawRoundNumber = (gameState['roundNumber'] as int?) ?? 1;
        final String? status = gameState['status'] as String?;
        // When status is round_end, Firestore has already incremented the round.
        // Show the completed round on the scoreboard.
        final int roundNumber = status == 'round_end'
            ? (rawRoundNumber > 1 ? rawRoundNumber - 1 : 1)
            : rawRoundNumber;
        final List<dynamic> rawTeams = (data['teams'] as List?) ?? const [];
        final List<Map<String, dynamic>> teams =
            rawTeams.map((e) => Map<String, dynamic>.from(e as Map)).toList();

        final List<dynamic> rawHistory =
            (gameState['turnHistory'] as List?) ?? const [];
        final List<Map<String, dynamic>> turnHistory =
            rawHistory.map((e) => Map<String, dynamic>.from(e as Map)).toList();

        final int teamsCount = teams.length;
        if (teamsCount == 0) {
          return const Scaffold(
            body: Center(child: Text('Waiting for teams...')),
          );
        }

        // Compute per-round and cumulative totals using Firestore turnHistory
        final List<int> roundScores = List<int>.filled(teamsCount, 0);
        final List<int> totalScoresPrev = List<int>.filled(teamsCount, 0);
        final List<int> totalScoresCurr = List<int>.filled(teamsCount, 0);

        for (final tr in turnHistory) {
          final int teamIndex = (tr['teamIndex'] as int?) ?? 0;
          if (teamIndex < 0 || teamIndex >= teamsCount) continue;
          final int score = (tr['correctCount'] as int?) ?? 0;
          final int trRound = (tr['roundNumber'] as int?) ?? 1;

          if (trRound == roundNumber) {
            roundScores[teamIndex] += score;
          }
          if (trRound < roundNumber) {
            totalScoresPrev[teamIndex] += score;
          }
          if (trRound <= roundNumber) {
            totalScoresCurr[teamIndex] += score;
          }
        }

        final int topRoundScore = roundScores.isNotEmpty
            ? roundScores.reduce((a, b) => a > b ? a : b)
            : 0;

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

        final sortedTeamIndices = List.generate(teamsCount, (i) => i)
          ..sort((a, b) => totalScoresCurr[b].compareTo(totalScoresCurr[a]));

        final hostId = data['hostId'] as String?;

        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(27.0, 80.0, 27.0, 27.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Additional top spacing for visual comfort
                  const SizedBox(height: 4),
                  Text(
                    'Round $roundNumber',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontSize: 36, fontWeight: FontWeight.bold),
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
                          final String teamName =
                              (teams[teamIndex]['teamName'] as String?) ?? '';
                          final totalScore = totalScoresCurr[teamIndex];
                          final isTopThisRound =
                              roundScores[teamIndex] == topRoundScore &&
                                  topRoundScore > 0;

                          final int colorIndex =
                              (teams[teamIndex]['colorIndex'] as int?) ??
                                  (teamIndex % teamColors.length);
                          final colorDef =
                              teamColors[colorIndex % teamColors.length];

                          final Color backgroundColor =
                              Theme.of(context).brightness == Brightness.dark
                                  ? colorDef.border.withOpacity(0.4)
                                  : colorDef.background;
                          final Color borderColor =
                              Theme.of(context).brightness == Brightness.dark
                                  ? colorDef.background.withOpacity(0.3)
                                  : colorDef.border;
                          final Color textColor = colorDef.text;

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12.0, horizontal: 10.0),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: borderColor,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    isTopThisRound ? '$teamName 🏆' : teamName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white.withOpacity(0.95)
                                              : textColor,
                                        ),
                                  ),
                                ),
                                CircleAvatar(
                                  backgroundColor:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? colorDef.border.withOpacity(0.8)
                                          : colorDef.border,
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
                                Text(
                                  roundNumber == 1
                                      ? ''
                                      : currRanks[teamIndex] <
                                              prevRanks[teamIndex]
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
                                        : currRanks[teamIndex] <
                                                prevRanks[teamIndex]
                                            ? (Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.green.withOpacity(0.8)
                                                : Colors.green)
                                            : currRanks[teamIndex] >
                                                    prevRanks[teamIndex]
                                                ? (Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors.red
                                                        .withOpacity(0.8)
                                                    : Colors.red)
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
                  deviceIdAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (deviceId) {
                      final bool isHost = hostId != null && deviceId == hostId;
                      if (!isHost) return const SizedBox.shrink();
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: TeamColorButton(
                              text: 'Next Round',
                              icon: Icons.arrow_forward,
                              color: teamColors[2],
                              onPressed: () async {
                                await FirestoreService.fromRoundEnd(sessionId);
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
