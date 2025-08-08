import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/session_providers.dart';
import '../widgets/team_color_button.dart';

class OnlineGameOverScreen extends ConsumerWidget {
  final String sessionId;
  const OnlineGameOverScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionStreamProvider(sessionId));
    return Scaffold(
      body: SafeArea(
        child: sessionAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (docSnap) {
            final data = docSnap?.data();
            if (data == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final List<Map<String, dynamic>> teams =
                ((data['teams'] as List?) ?? const [])
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList();
            final gameState =
                (data['gameState'] as Map<String, dynamic>?) ?? {};
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

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(27, 80, 27, 27),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Game Over!',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 36,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            children:
                                List.generate(sortedTeamIndices.length, (i) {
                              final teamIndex = sortedTeamIndices[i];
                              final String teamName =
                                  (teams[teamIndex]['teamName'] as String?) ??
                                      '';
                              final int colorIndex =
                                  (teams[teamIndex]['colorIndex'] as int?) ??
                                      (teamIndex % teamColors.length);
                              final colorDef =
                                  teamColors[colorIndex % teamColors.length];
                              final totalScore = totals[teamIndex] ?? 0;
                              final isWinner = i == 0 && totalScore > 0;

                              return Container(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12.0, horizontal: 10.0),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? colorDef.border.withOpacity(0.4)
                                      : colorDef.background,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? colorDef.background.withOpacity(0.3)
                                        : colorDef.border,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        isWinner ? '$teamName 🏆' : teamName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                      .withOpacity(0.95)
                                                  : colorDef.text,
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
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(27.0),
                  child: Row(
                    children: [
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
            );
          },
        ),
      ),
    );
  }
}
