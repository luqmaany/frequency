import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_config.dart';

class GameSetupNotifier extends StateNotifier<GameConfig> {
  GameSetupNotifier()
      : super(GameConfig(
          playerNames: [],
          teams: [],
          roundTimeSeconds: 60,
          targetScore: 30,
          allowedSkips: 3,
        ));

  void addPlayer(String name) {
    state = state.copyWith(
      playerNames: [...state.playerNames, name],
    );
  }

  void removePlayer(String name) {
    state = state.copyWith(
      playerNames: state.playerNames.where((n) => n != name).toList(),
    );
  }

  void setRoundTime(int seconds) {
    state = state.copyWith(roundTimeSeconds: seconds);
  }

  void setTargetScore(int score) {
    state = state.copyWith(targetScore: score);
  }

  void setAllowedSkips(int skips) {
    state = state.copyWith(allowedSkips: skips);
  }

  void createTeams(List<List<String>> teams) {
    state = state.copyWith(teams: teams);
  }

  void randomizeTeams() {
    final players = List<String>.from(state.playerNames);
    players.shuffle();
    final teams = <List<String>>[];
    
    for (var i = 0; i < players.length; i += 2) {
      if (i + 1 < players.length) {
        teams.add([players[i], players[i + 1]]);
      }
    }
    
    state = state.copyWith(teams: teams);
  }
}

final gameSetupProvider = StateNotifierProvider<GameSetupNotifier, GameConfig>((ref) {
  return GameSetupNotifier();
}); 