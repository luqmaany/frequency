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
  late TextEditingController _roundTimeController;
  late TextEditingController _targetScoreController;
  late TextEditingController _allowedSkipsController;
  bool _controllersInitialized = false;

  @override
  void dispose() {
    _roundTimeController.dispose();
    _targetScoreController.dispose();
    _allowedSkipsController.dispose();
    super.dispose();
  }

  void _updateFirestoreSetting(String key, int value) async {
    if (widget.sessionId == null) return;
    final doc =
        FirebaseFirestore.instance.collection('sessions').doc(widget.sessionId);
    await doc.update({'gameState.gameConfig.$key': value});
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sessionId != null) {
      // ONLINE MODE: Use Firestore settings
      final gameConfigAsync =
          ref.watch(sessionSettingsProvider(widget.sessionId!));
      if (!gameConfigAsync.hasValue || gameConfigAsync.value == null) {
        return const Center(child: CircularProgressIndicator());
      }
      final settings = gameConfigAsync.value!;
      // Initialize controllers only once per settings change
      if (!_controllersInitialized ||
          _roundTimeController.text !=
              settings['roundTimeSeconds'].toString() ||
          _targetScoreController.text != settings['targetScore'].toString() ||
          _allowedSkipsController.text != settings['allowedSkips'].toString()) {
        _roundTimeController = TextEditingController(
            text: settings['roundTimeSeconds'].toString());
        _targetScoreController =
            TextEditingController(text: settings['targetScore'].toString());
        _allowedSkipsController =
            TextEditingController(text: settings['allowedSkips'].toString());
        _controllersInitialized = true;
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _roundTimeController,
            enabled: !widget.readOnly,
            decoration: InputDecoration(
              labelText: 'Round Time (seconds)',
              filled: true,
              fillColor: Colors.blue.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade300, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade300, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue, width: 2),
              ),
              helperText: '10-120 seconds',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: widget.readOnly
                ? null
                : (val) {
                    final seconds = int.tryParse(val);
                    if (seconds != null && seconds >= 10 && seconds <= 120) {
                      _updateFirestoreSetting('roundTimeSeconds', seconds);
                    }
                  },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _targetScoreController,
            enabled: !widget.readOnly,
            decoration: InputDecoration(
              labelText: 'Target Score',
              filled: true,
              fillColor: Colors.green.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green.shade300, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green.shade300, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green, width: 2),
              ),
              helperText: '10-100 points',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: widget.readOnly
                ? null
                : (val) {
                    final score = int.tryParse(val);
                    if (score != null && score >= 10 && score <= 100) {
                      _updateFirestoreSetting('targetScore', score);
                    }
                  },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _allowedSkipsController,
            enabled: !widget.readOnly,
            decoration: InputDecoration(
              labelText: 'Allowed Skips',
              filled: true,
              fillColor: Colors.red.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red.shade300, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red.shade300, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
              helperText: '0-5 skips',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: widget.readOnly
                ? null
                : (val) {
                    final skips = int.tryParse(val);
                    if (skips != null && skips >= 0 && skips <= 5) {
                      _updateFirestoreSetting('allowedSkips', skips);
                    }
                  },
          ),
        ],
      );
    } else {
      // LOCAL MODE: Use gameSetupProvider
      final validationState = ref.watch(settingsValidationProvider);
      final gameConfig = ref.watch(gameSetupProvider);
      if (!_controllersInitialized) {
        _roundTimeController =
            TextEditingController(text: gameConfig.roundTimeSeconds.toString());
        _targetScoreController =
            TextEditingController(text: gameConfig.targetScore.toString());
        _allowedSkipsController =
            TextEditingController(text: gameConfig.allowedSkips.toString());
        _controllersInitialized = true;
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _roundTimeController,
            enabled: true,
            decoration: InputDecoration(
              labelText: 'Round Time (seconds)',
              filled: true,
              fillColor: Colors.blue.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade300, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade300, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue, width: 2),
              ),
              errorText: validationState.isRoundTimeValid
                  ? null
                  : 'Must be between 10 and 120 seconds',
              helperText: '10-120 seconds',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: (val) {
              final seconds = int.tryParse(val);
              if (seconds != null && seconds >= 10 && seconds <= 120) {
                ref.read(gameSetupProvider.notifier).setRoundTime(seconds);
              }
              ref.read(settingsValidationProvider.notifier).setRoundTimeValid(
                  seconds != null && seconds >= 10 && seconds <= 120);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _targetScoreController,
            enabled: true,
            decoration: InputDecoration(
              labelText: 'Target Score',
              filled: true,
              fillColor: Colors.green.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green.shade300, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green.shade300, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green, width: 2),
              ),
              errorText: validationState.isTargetScoreValid
                  ? null
                  : 'Must be between 10 and 100',
              helperText: '10-100 points',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: (val) {
              final score = int.tryParse(val);
              if (score != null && score >= 10 && score <= 100) {
                ref.read(gameSetupProvider.notifier).setTargetScore(score);
              }
              ref.read(settingsValidationProvider.notifier).setTargetScoreValid(
                  score != null && score >= 10 && score <= 100);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _allowedSkipsController,
            enabled: true,
            decoration: InputDecoration(
              labelText: 'Allowed Skips',
              filled: true,
              fillColor: Colors.red.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red.shade300, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red.shade300, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
              errorText: validationState.isAllowedSkipsValid
                  ? null
                  : 'Must be between 0 and 5',
              helperText: '0-5 skips',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: (val) {
              final skips = int.tryParse(val);
              if (skips != null && skips >= 0 && skips <= 5) {
                ref.read(gameSetupProvider.notifier).setAllowedSkips(skips);
              }
              ref
                  .read(settingsValidationProvider.notifier)
                  .setAllowedSkipsValid(
                      skips != null && skips >= 0 && skips <= 5);
            },
          ),
        ],
      );
    }
  }
}
