import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'storage_service.dart';

class SoundService {
  bool _enabled = true;
  AudioPlayer? _musicPlayer;

  Future<void> init() async {
    try {
      final prefs = await StorageService.loadAppPreferences();
      _enabled = prefs['soundEnabled'] ?? true;
    } catch (_) {
      _enabled = true;
    }
  }

  void setEnabled(bool enabled) {
    _enabled = enabled;
    if (!_enabled) {
      // Ensure any ongoing music is stopped when sounds are disabled
      stopMenuMusic();
    }
  }

  Future<void> _playAssetVariants(String baseName,
      {double volume = 1.0,
      List<String> extensions = const ['wav', 'mp3']}) async {
    if (!_enabled) return;
    for (final ext in extensions) {
      final player = AudioPlayer();
      try {
        await player.setVolume(volume);
        await player.play(AssetSource('assets/sounds/$baseName.$ext'));
        // Attach completion disposal and return on first success
        player.onPlayerComplete.listen((_) {
          player.dispose();
        }, onError: (_) {
          player.dispose();
        });
        return;
      } catch (_) {
        await player.dispose();
        // Try next extension
      }
    }
  }

  Future<void> playCorrect() => _playAssetVariants('correct', volume: 1.0);
  Future<void> playSkip() => _playAssetVariants('skip', volume: 0.9);
  Future<void> playCountdownTick() =>
      _playAssetVariants('countdown_tick', volume: 0.8);
  Future<void> playCountdownEnd() =>
      _playAssetVariants('countdown_end', volume: 1.0);
  Future<void> playTurnEnd() =>
      _playAssetVariants('turn_end_buzzer', volume: 1.0);

  Future<void> playButtonPress() =>
      _playAssetVariants('button_press', volume: 0.5);

  // ===== Background music APIs =====
  Future<void> playMenuMusic({double volume = 0.5}) async {
    if (!_enabled) return;
    // If already initialized, assume playing and no-op
    if (_musicPlayer != null) return;

    // Try wav then mp3
    final candidates = ['menu.wav', 'menu.mp3'];
    for (final file in candidates) {
      final player = _musicPlayer ?? AudioPlayer();
      try {
        await player.setVolume(volume);
        await player.setReleaseMode(ReleaseMode.loop);
        await player.play(AssetSource('assets/sounds/$file'));
        _musicPlayer = player;
        return;
      } catch (_) {
        // If this attempt used a new player, dispose it
        if (_musicPlayer == null) {
          await player.dispose();
        }
        // Try next candidate
      }
    }
  }

  Future<void> stopMenuMusic() async {
    final player = _musicPlayer;
    if (player != null) {
      try {
        await player.stop();
      } catch (_) {}
      try {
        await player.dispose();
      } catch (_) {}
      _musicPlayer = null;
    }
  }

  void dispose() {}
}

final soundServiceProvider = Provider<SoundService>((ref) {
  final service = SoundService();
  service.init();
  ref.onDispose(() => service.dispose());
  return service;
});
