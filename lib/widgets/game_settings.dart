import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game_setup_provider.dart';

class GameSettings extends ConsumerStatefulWidget {
  const GameSettings({super.key});

  @override
  ConsumerState<GameSettings> createState() => _GameSettingsState();
}

class _GameSettingsState extends ConsumerState<GameSettings> {
  late final TextEditingController _roundTimeController;
  late final TextEditingController _targetScoreController;
  late final TextEditingController _allowedSkipsController;

  @override
  void initState() {
    super.initState();
    final gameConfig = ref.read(gameSetupProvider);
    _roundTimeController = TextEditingController(text: gameConfig.roundTimeSeconds.toString());
    _targetScoreController = TextEditingController(text: gameConfig.targetScore.toString());
    _allowedSkipsController = TextEditingController(text: gameConfig.allowedSkips.toString());
  }

  @override
  void dispose() {
    _roundTimeController.dispose();
    _targetScoreController.dispose();
    _allowedSkipsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _roundTimeController,
          decoration: const InputDecoration(
            labelText: 'Round Time (seconds)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final seconds = int.tryParse(value);
            if (seconds != null) {
              ref.read(gameSetupProvider.notifier).setRoundTime(seconds);
            }
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _targetScoreController,
          decoration: const InputDecoration(
            labelText: 'Target Score',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final score = int.tryParse(value);
            if (score != null) {
              ref.read(gameSetupProvider.notifier).setTargetScore(score);
            }
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _allowedSkipsController,
          decoration: const InputDecoration(
            labelText: 'Allowed Skips',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final skips = int.tryParse(value);
            if (skips != null) {
              ref.read(gameSetupProvider.notifier).setAllowedSkips(skips);
            }
          },
        ),
      ],
    );
  }
} 