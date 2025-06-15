import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game_state_provider.dart';

class GameOverScreen extends ConsumerWidget {
  const GameOverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);
    if (gameState == null) return const SizedBox.shrink();

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Game Over!',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 20),
            Text(
              'Final Scores:',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            ...gameState.teamScores.asMap().entries.map((entry) {
              final teamIndex = entry.key;
              final score = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Team ${teamIndex + 1}: $score points',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              );
            }),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                ref.read(gameStateProvider.notifier).resetGame();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('New Game'),
            ),
          ],
        ),
      ),
    );
  }
} 