import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game_setup_provider.dart';
import '../providers/session_providers.dart';

class GameSettings extends ConsumerStatefulWidget {
  final bool readOnly;
  final String? sessionId; // If null, local mode
  const GameSettings({super.key, this.readOnly = false, this.sessionId});

  @override
  GameSettingsState createState() => GameSettingsState();
}

class GameSettingsState extends ConsumerState<GameSettings> {
  // Predefined options
  static const List<int> timeOptions = [5, 15, 30, 60, 90, 120];
  static const List<int> scoreOptions = [5, 10, 20, 30, 50];
  static const List<int> skipOptions = [0, 1, 2, 3, 4, 5];

  void _updateFirestoreSetting(String key, int value) async {
    if (widget.sessionId == null) return;
    await ref.read(updateSettingsProvider({
      'sessionId': widget.sessionId!,
      'key': key,
      'value': value,
    }).future);
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.6,
                  ),
            ),
            if (widget.readOnly) ...[
              const SizedBox(width: 8),
              Icon(Icons.lock, size: 16, color: Colors.grey.shade600),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: options.map((option) {
              final isSelected = option == currentValue;
              return Builder(
                builder: (context) {
                  final Color baseBg = Theme.of(context).colorScheme.background;
                  final double overlayAlpha = isSelected ? 0.6 : 0.2;
                  final Color background =
                      Color.alphaBlend(color.withOpacity(overlayAlpha), baseBg);
                  return GestureDetector(
                    onTap: widget.readOnly
                        ? null
                        : () {
                            if (widget.sessionId != null) {
                              _updateFirestoreSetting(settingKey, option);
                            } else {
                              final notifier =
                                  ref.read(gameSetupProvider.notifier);
                              switch (settingKey) {
                                case 'roundTimeSeconds':
                                  notifier.setRoundTime(option);
                                  break;
                                case 'targetScore':
                                  notifier.setTargetScore(option);
                                  break;
                                case 'allowedSkips':
                                  notifier.setAllowedSkips(option);
                                  break;
                              }
                            }
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: color,
                          width: 1.5,
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
                },
              );
            }).toList(),
          ),
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
        // Show fallback settings instead of loading indicator
        final fallbackSettings = {
          'roundTimeSeconds': 60,
          'targetScore': 20,
          'allowedSkips': 3,
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOptionButtons(
              title: 'Round Time (seconds)',
              options: timeOptions,
              currentValue: fallbackSettings['roundTimeSeconds'] ?? 60,
              settingKey: 'roundTimeSeconds',
              color: Colors.blue,
            ),
            _buildOptionButtons(
              title: 'Target Score',
              options: scoreOptions,
              currentValue: fallbackSettings['targetScore'] ?? 20,
              settingKey: 'targetScore',
              color: Colors.green,
            ),
            _buildOptionButtons(
              title: 'Allowed Skips',
              options: skipOptions,
              currentValue: fallbackSettings['allowedSkips'] ?? 3,
              settingKey: 'allowedSkips',
              color: Colors.orange,
            ),
          ],
        );
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
