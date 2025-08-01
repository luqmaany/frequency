import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game_setup_provider.dart';
import '../providers/session_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GameSettings extends ConsumerStatefulWidget {
  final bool readOnly;
  final String? sessionId; // If null, local mode
  const GameSettings({super.key, this.readOnly = false, this.sessionId});

  @override
  GameSettingsState createState() => GameSettingsState();
}

class GameSettingsState extends ConsumerState<GameSettings> {
  // Predefined options
  static const List<int> timeOptions = [15, 30, 60, 90, 120];
  static const List<int> scoreOptions = [10, 20, 30, 50];
  static const List<int> skipOptions = [0, 1, 2, 3, 4, 5];

  void _updateFirestoreSetting(String key, int value) async {
    if (widget.sessionId == null) return;
    final doc =
        FirebaseFirestore.instance.collection('sessions').doc(widget.sessionId);
    await doc.update({'settings.$key': value});
  }

  Widget _buildOptionButtons({
    required String title,
    required List<int> options,
    required int currentValue,
    required String settingKey,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = option == currentValue;
            return GestureDetector(
              onTap: widget.readOnly
                  ? null
                  : () {
                      _updateFirestoreSetting(settingKey, option);
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? color : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? color : color.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Text(
                  option.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : color,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sessionId != null) {
      // ONLINE MODE: Use Firestore settings
      final settingsAsync =
          ref.watch(sessionSettingsProvider(widget.sessionId!));
      if (!settingsAsync.hasValue || settingsAsync.value == null) {
        return const Center(child: CircularProgressIndicator());
      }
      final settings = settingsAsync.value!;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOptionButtons(
            title: 'Round Time (seconds)',
            options: timeOptions,
            currentValue: settings['roundTimeSeconds'] as int? ?? 60,
            settingKey: 'roundTimeSeconds',
            color: Colors.blue,
          ),
          _buildOptionButtons(
            title: 'Target Score',
            options: scoreOptions,
            currentValue: settings['targetScore'] as int? ?? 30,
            settingKey: 'targetScore',
            color: Colors.green,
          ),
          _buildOptionButtons(
            title: 'Allowed Skips',
            options: skipOptions,
            currentValue: settings['allowedSkips'] as int? ?? 3,
            settingKey: 'allowedSkips',
            color: Colors.orange,
          ),
        ],
      );
    } else {
      // LOCAL MODE: Use local game setup provider
      final gameConfig = ref.watch(gameSetupProvider);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOptionButtons(
            title: 'Round Time (seconds)',
            options: timeOptions,
            currentValue: gameConfig.roundTimeSeconds,
            settingKey: 'roundTimeSeconds',
            color: Colors.blue,
          ),
          _buildOptionButtons(
            title: 'Target Score',
            options: scoreOptions,
            currentValue: gameConfig.targetScore,
            settingKey: 'targetScore',
            color: Colors.green,
          ),
          _buildOptionButtons(
            title: 'Allowed Skips',
            options: skipOptions,
            currentValue: gameConfig.allowedSkips,
            settingKey: 'allowedSkips',
            color: Colors.orange,
          ),
        ],
      );
    }
  }
}
