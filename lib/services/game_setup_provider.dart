import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../models/game_config.dart';
import 'package:convey/widgets/team_color_button.dart';

class GameSetupNotifier extends StateNotifier<GameConfig> {
  GameSetupNotifier()
      : super(GameConfig(
          playerNames: [],
          teams: [],
          teamColorIndices: [],
          roundTimeSeconds: 2,
          targetScore: 2,
          allowedSkips: 3,
        ));

  List<int> _generateRandomColorIndices(int count) {
    final random = Random();
    final indices = List<int>.generate(teamColors.length, (i) => i);
    indices.shuffle(random);
    return indices.take(count).toList();
  }

  void addPlayerToTeams(String name) {
    // Try to fill the first empty slot in teams
    final updatedPlayers = [...state.playerNames, name];
    final List<List<String>> newTeams =
        state.teams.map((team) => [...team]).toList();
    List<int> newColorIndices = List<int>.from(state.teamColorIndices);
    bool filled = false;
    for (int t = 0; t < newTeams.length && !filled; t++) {
      for (int p = 0; p < newTeams[t].length; p++) {
        if (newTeams[t][p] == "") {
          newTeams[t][p] = name;
          filled = true;
          break;
        }
      }
    }
    if (!filled) {
      // Add to a new or existing team (2 per team)
      if (newTeams.isEmpty || newTeams.last.length == 2) {
        newTeams.add([name]);
        // Assign a random unused color index
        final usedIndices = newColorIndices.toSet();
        final availableIndices = List<int>.generate(teamColors.length, (i) => i)
            .where((i) => !usedIndices.contains(i))
            .toList();
        if (availableIndices.isEmpty) {
          // If all colors are used, generate a new random set
          newColorIndices = _generateRandomColorIndices(newTeams.length);
        } else {
          availableIndices.shuffle();
          newColorIndices.add(availableIndices.first);
        }
      } else {
        newTeams.last.add(name);
      }
    }
    state = state.copyWith(
        playerNames: updatedPlayers,
        teams: newTeams,
        teamColorIndices: newColorIndices);
  }

  void removePlayerAndReassignTeams(String name) {
    // Remove player from playerNames, but leave a gap in teams
    final updatedPlayers = state.playerNames.where((n) => n != name).toList();
    final List<List<String>> newTeams =
        state.teams.map((team) => [...team]).toList();
    for (int t = 0; t < newTeams.length; t++) {
      for (int p = 0; p < newTeams[t].length; p++) {
        if (newTeams[t][p] == name) {
          newTeams[t][p] = "";
        }
      }
    }
    // Remove teams where all slots are empty
    final filteredTeams = newTeams
        .where((team) => team.any((player) => player.isNotEmpty))
        .toList();
    // Update color indices to match filtered teams
    List<int> filteredColorIndices = [];
    for (int i = 0; i < newTeams.length; i++) {
      if (newTeams[i].any((player) => player.isNotEmpty)) {
        filteredColorIndices.add(state.teamColorIndices[i]);
      }
    }
    state = state.copyWith(
        playerNames: updatedPlayers,
        teams: filteredTeams,
        teamColorIndices: filteredColorIndices);
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
    final colorIndices = _generateRandomColorIndices(teams.length);
    state = state.copyWith(teams: teams, teamColorIndices: colorIndices);
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
    final colorIndices = _generateRandomColorIndices(teams.length);
    state = state.copyWith(teams: teams, teamColorIndices: colorIndices);
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
    final colorIndices = _generateRandomColorIndices(newTeams.length);
    state = state.copyWith(teams: newTeams, teamColorIndices: colorIndices);
  }

  void addPlayer(String name) {
    addPlayerToTeams(name);
  }

  void removePlayer(String name) {
    removePlayerAndReassignTeams(name);
  }

  void swapPlayers(String player1, String player2) {
    final teams = [
      ...state.teams.map((team) => [...team])
    ];
    int? team1Idx, team2Idx, player1Idx, player2Idx;
    for (int t = 0; t < teams.length; t++) {
      for (int p = 0; p < teams[t].length; p++) {
        if (teams[t][p] == player1) {
          team1Idx = t;
          player1Idx = p;
        }
        if (teams[t][p] == player2) {
          team2Idx = t;
          player2Idx = p;
        }
      }
    }
    if (team1Idx != null &&
        team2Idx != null &&
        player1Idx != null &&
        player2Idx != null) {
      final temp = teams[team1Idx][player1Idx];
      teams[team1Idx][player1Idx] = teams[team2Idx][player2Idx];
      teams[team2Idx][player2Idx] = temp;
      state = state.copyWith(teams: teams);
    }
  }

  // Utility: Check if there are empty slots in teams
  bool hasEmptySlotsInTeams() {
    for (final team in state.teams) {
      for (final player in team) {
        if (player == "") return true;
      }
    }
    return false;
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
