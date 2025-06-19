import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_config.dart';

class GameSetupNotifier extends StateNotifier<GameConfig> {
  GameSetupNotifier()
      : super(GameConfig(
          playerNames: [],
          teams: [],
          roundTimeSeconds: 10,
          targetScore: 30,
          allowedSkips: 3,
        ));

  void addPlayerToTeams(String name) {
    final updatedPlayers = [...state.playerNames, name];
    final List<List<String>> newTeams = [];
    for (int i = 0; i < updatedPlayers.length; i++) {
      if (i ~/ 2 >= newTeams.length) {
        newTeams.add([]);
      }
      newTeams[i ~/ 2].add(updatedPlayers[i]);
    }
    state = state.copyWith(playerNames: updatedPlayers, teams: newTeams);
  }

  void removePlayerAndReassignTeams(String name) {
    final updatedPlayers = state.playerNames.where((n) => n != name).toList();
    final List<List<String>> newTeams = [];
    for (int i = 0; i < updatedPlayers.length; i++) {
      if (i ~/ 2 >= newTeams.length) {
        newTeams.add([]);
      }
      newTeams[i ~/ 2].add(updatedPlayers[i]);
    }
    state = state.copyWith(playerNames: updatedPlayers, teams: newTeams);
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

  void shuffleTeams() {
    // Only shuffle players currently assigned to teams
    final players = List<String>.from(state.playerNames);
    players.shuffle();
    final List<List<String>> newTeams = [];
    for (int i = 0; i < players.length; i++) {
      if (i ~/ 2 >= newTeams.length) {
        newTeams.add([]);
      }
      newTeams[i ~/ 2].add(players[i]);
    }
    state = state.copyWith(teams: newTeams);
  }

  void addPlayer(String name) {
    addPlayerToTeams(name);
  }

  void removePlayer(String name) {
    removePlayerAndReassignTeams(name);
  }
}

final gameSetupProvider =
    StateNotifierProvider<GameSetupNotifier, GameConfig>((ref) {
  return GameSetupNotifier();
});

class SettingsValidationState {
  final bool isRoundTimeValid;
  final bool isTargetScoreValid;
  final bool isAllowedSkipsValid;

  SettingsValidationState({
    required this.isRoundTimeValid,
    required this.isTargetScoreValid,
    required this.isAllowedSkipsValid,
  });

  bool get areAllSettingsValid =>
      isRoundTimeValid && isTargetScoreValid && isAllowedSkipsValid;
}

class SettingsValidationNotifier
    extends StateNotifier<SettingsValidationState> {
  SettingsValidationNotifier()
      : super(SettingsValidationState(
          isRoundTimeValid: true,
          isTargetScoreValid: true,
          isAllowedSkipsValid: true,
        ));

  void setRoundTimeValid(bool isValid) {
    state = SettingsValidationState(
      isRoundTimeValid: isValid,
      isTargetScoreValid: state.isTargetScoreValid,
      isAllowedSkipsValid: state.isAllowedSkipsValid,
    );
  }

  void setTargetScoreValid(bool isValid) {
    state = SettingsValidationState(
      isRoundTimeValid: state.isRoundTimeValid,
      isTargetScoreValid: isValid,
      isAllowedSkipsValid: state.isAllowedSkipsValid,
    );
  }

  void setAllowedSkipsValid(bool isValid) {
    state = SettingsValidationState(
      isRoundTimeValid: state.isRoundTimeValid,
      isTargetScoreValid: state.isTargetScoreValid,
      isAllowedSkipsValid: isValid,
    );
  }
}

final settingsValidationProvider =
    StateNotifierProvider<SettingsValidationNotifier, SettingsValidationState>(
        (ref) {
  return SettingsValidationNotifier();
});
