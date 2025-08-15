import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../models/game_config.dart';
import 'package:convey/widgets/team_color_button.dart';
import 'storage_service.dart';

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
    // New behavior: fill the first available team in color-list order
    final updatedPlayers = [...state.playerNames, name];
    final List<List<String>> newTeams =
        state.teams.map((team) => [...team]).toList();
    List<int> newColorIndices = List<int>.from(state.teamColorIndices);

    // Respect max players (12)
    if (updatedPlayers.length > 12) {
      return;
    }

    // Find first color row with capacity (<2). If team for that color doesn't
    // exist yet, create it and assign that color.
    for (int colorIdx = 0; colorIdx < teamColors.length; colorIdx++) {
      int existingTeamIndex = newColorIndices.indexOf(colorIdx);
      if (existingTeamIndex == -1) {
        // Create a new team for this color and add the player
        newTeams.add([name]);
        newColorIndices.add(colorIdx);
        state = state.copyWith(
          playerNames: updatedPlayers,
          teams: newTeams,
          teamColorIndices: newColorIndices,
        );
        _savePlayerNamesToStorage(updatedPlayers);
        return;
      } else {
        // Team exists for this color; add if it has capacity
        if (newTeams[existingTeamIndex].where((p) => p.isNotEmpty).length < 2) {
          bool placed = false;
          for (int i = 0; i < newTeams[existingTeamIndex].length; i++) {
            if (newTeams[existingTeamIndex][i].isEmpty) {
              newTeams[existingTeamIndex][i] = name;
              placed = true;
              break;
            }
          }
          if (!placed) {
            newTeams[existingTeamIndex].add(name);
          }
          state = state.copyWith(
            playerNames: updatedPlayers,
            teams: newTeams,
            teamColorIndices: newColorIndices,
          );
          _savePlayerNamesToStorage(updatedPlayers);
          return;
        }
      }
    }

    // If all color rows are full or unavailable, do nothing
  }

  // Ensure a team exists for a given color index in provided lists and return its team index
  int _ensureTeamForColorIndex(
      int colorIndex, List<List<String>> teams, List<int> colorIndices) {
    int teamIdx = colorIndices.indexOf(colorIndex);
    if (teamIdx == -1) {
      teams.add([]);
      colorIndices.add(colorIndex);
      return teams.length - 1;
    }
    return teamIdx;
  }

  void movePlayerToColor(String player, int colorIndex) {
    // Allow dragging from existing teams or from suggestions row (new player)
    final bool alreadyInPlayers =
        state.playerNames.any((n) => n.toLowerCase() == player.toLowerCase());

    final List<List<String>> newTeams =
        state.teams.map((team) => [...team]).toList();
    final List<int> newColorIndices = List<int>.from(state.teamColorIndices);

    int? fromTeamIdx;
    int? fromPlayerIdx;
    if (alreadyInPlayers) {
      // Find and temporarily remove from current team
      for (int t = 0; t < newTeams.length; t++) {
        for (int p = 0; p < newTeams[t].length; p++) {
          if (newTeams[t][p] == player) {
            fromTeamIdx = t;
            fromPlayerIdx = p;
            break;
          }
        }
        if (fromTeamIdx != null) break;
      }
      if (fromTeamIdx == null || fromPlayerIdx == null) return;
      newTeams[fromTeamIdx][fromPlayerIdx] = "";
    } else {
      // New player dragged from suggestions: respect max 12
      if (state.playerNames.length >= 12) {
        return;
      }
    }

    final int targetTeamIdx =
        _ensureTeamForColorIndex(colorIndex, newTeams, newColorIndices);
    final int filledCount =
        newTeams[targetTeamIdx].where((p) => p.isNotEmpty).length;
    if (filledCount >= 2) {
      // Target full; revert if moved from a team
      if (fromTeamIdx != null && fromPlayerIdx != null) {
        newTeams[fromTeamIdx][fromPlayerIdx] = player;
      }
      return;
    }

    // Place in first empty slot else append
    bool placed = false;
    for (int i = 0; i < newTeams[targetTeamIdx].length; i++) {
      if (newTeams[targetTeamIdx][i].isEmpty) {
        newTeams[targetTeamIdx][i] = player;
        placed = true;
        break;
      }
    }
    if (!placed) {
      newTeams[targetTeamIdx].add(player);
    }

    // Clean up: remove teams that are fully empty and compress empty slots
    final List<List<String>> filteredTeams = [];
    final List<int> filteredColors = [];
    for (int i = 0; i < newTeams.length; i++) {
      if (newTeams[i].any((p) => p.isNotEmpty)) {
        filteredTeams.add(newTeams[i].where((p) => p.isNotEmpty).toList());
        filteredColors.add(newColorIndices[i]);
      }
    }

    // Ensure we add new player to playerNames if coming from suggestions
    final List<String> updatedPlayerNames = alreadyInPlayers
        ? List<String>.from(state.playerNames)
        : [...state.playerNames, player];

    state = state.copyWith(
      playerNames: updatedPlayerNames,
      teams: filteredTeams,
      teamColorIndices: filteredColors,
    );
    _savePlayerNamesToStorage(updatedPlayerNames);
  }

  void swapWithColorPlayer(String source, String target, int colorIndex) {
    if (source.toLowerCase() == target.toLowerCase()) {
      return;
    }
    final bool sourceInPlayers =
        state.playerNames.any((n) => n.toLowerCase() == source.toLowerCase());

    // Defensive: target must exist in the specified color team
    final List<List<String>> teams = state.teams.map((t) => [...t]).toList();
    final List<int> colorIndices = List<int>.from(state.teamColorIndices);
    final int teamIdx = colorIndices.indexOf(colorIndex);
    if (teamIdx == -1) return;
    final int targetIdx = teams[teamIdx].indexOf(target);
    if (targetIdx == -1) return;

    if (sourceInPlayers) {
      // Find source position
      int? sTeamIdx;
      int? sPlayerIdx;
      for (int t = 0; t < teams.length; t++) {
        for (int p = 0; p < teams[t].length; p++) {
          if (teams[t][p] == source) {
            sTeamIdx = t;
            sPlayerIdx = p;
            break;
          }
        }
        if (sTeamIdx != null) break;
      }
      if (sTeamIdx == null || sPlayerIdx == null) return;

      // Perform swap across teams
      teams[teamIdx][targetIdx] = source;
      teams[sTeamIdx][sPlayerIdx] = target;

      // Clean up: remove empties and compress
      final List<List<String>> filteredTeams = [];
      final List<int> filteredColors = [];
      for (int i = 0; i < teams.length; i++) {
        if (teams[i].any((p) => p.isNotEmpty)) {
          filteredTeams.add(teams[i].where((p) => p.isNotEmpty).toList());
          filteredColors.add(colorIndices[i]);
        }
      }
      state = state.copyWith(
          teams: filteredTeams, teamColorIndices: filteredColors);
      return;
    }

    // Source from suggestions
    if (state.playerNames.length >= 12) {
      return;
    }
    // Replace target with source, and remove target from player list
    teams[teamIdx][targetIdx] = source;
    final List<String> updatedPlayers = [
      ...state.playerNames
          .where((n) => n.toLowerCase() != target.toLowerCase()),
      source,
    ];
    state = state.copyWith(playerNames: updatedPlayers, teams: teams);
    // Optionally push target to front of suggestions
    StorageService.moveNameToFront(target);
    _savePlayerNamesToStorage(updatedPlayers);
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

    // Save only player names to storage
    _savePlayerNamesToStorage(updatedPlayers);

    // Move removed name back to suggestions queue
    StorageService.addNamesToQueue([name]);
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
    // Teams are not saved to storage
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
    // Teams are not saved to storage
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
    // Teams are not saved to storage
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
      // Teams are not saved to storage
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

  // Save only player names to storage
  Future<void> _savePlayerNamesToStorage(List<String> playerNames) async {
    await StorageService.savePlayerNames(playerNames);
  }

  // Load only player names from storage
  Future<void> loadFromStorage() async {
    // Don't load player names into state - they should only be used as suggestions
    // The state should remain empty so users can add players fresh
    state = state.copyWith(
      playerNames: [],
      // Teams and team color indices are not loaded from storage
      teams: [],
      teamColorIndices: [],
    );
  }

  // Clear all stored data
  Future<void> clearStoredData() async {
    await StorageService.clearAllData();
    // Reset state to empty - the default names are in storage but not loaded into state
    state = GameConfig(
      playerNames: [],
      teams: [],
      teamColorIndices: [],
      roundTimeSeconds: 2,
      targetScore: 2,
      allowedSkips: 3,
    );
  }

  // Add current player names to suggestion queue
  Future<void> addCurrentPlayersToQueue() async {
    if (state.playerNames.isNotEmpty) {
      await StorageService.addNamesToQueue(state.playerNames);
    }
  }

  // Persist the current list of players found in teams to storage
  Future<void> persistTeamPlayers() async {
    final Set<String> players = {};
    for (final team in state.teams) {
      for (final p in team) {
        if (p.isNotEmpty) players.add(p);
      }
    }
    final List<String> playersList = players.toList();
    state = state.copyWith(playerNames: playersList);
    await StorageService.savePlayerNames(playersList);
  }

  // Move a name to the front of the suggestion queue
  Future<void> moveNameToQueueFront(String name) async {
    await StorageService.moveNameToFront(name);
  }

  // Clear all players from teams but keep player names available
  Future<void> clearAllPlayers() async {
    // Collect all current names (from teams and playerNames) and move to suggestions
    final Set<String> allNames = {...state.playerNames};
    for (final team in state.teams) {
      for (final player in team) {
        if (player.isNotEmpty) allNames.add(player);
      }
    }
    if (allNames.isNotEmpty) {
      await StorageService.addNamesToQueue(allNames.toList());
    }

    // Clear teams and players
    state = state.copyWith(
      playerNames: [],
      teams: [],
      teamColorIndices: [],
    );
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
