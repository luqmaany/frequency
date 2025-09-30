class GameConfig {
  final List<String> playerNames;
  final List<List<String>> teams;
  final List<int> teamColorIndices;
  final int roundTimeSeconds;
  final int targetScore;
  final int allowedSkips;
  final bool useWeightedWordSelection;
  final List<String> selectedDeckIds;

  GameConfig({
    required this.playerNames,
    required this.teams,
    List<int>? teamColorIndices,
    required this.roundTimeSeconds,
    required this.targetScore,
    required this.allowedSkips,
    this.useWeightedWordSelection =
        true, // Default to true for better experience
    List<String>? selectedDeckIds,
  })  : teamColorIndices = teamColorIndices ?? [],
        selectedDeckIds = selectedDeckIds ?? [];

  GameConfig copyWith({
    List<String>? playerNames,
    List<List<String>>? teams,
    List<int>? teamColorIndices,
    int? roundTimeSeconds,
    int? targetScore,
    int? allowedSkips,
    bool? useWeightedWordSelection,
    List<String>? selectedDeckIds,
  }) {
    return GameConfig(
      playerNames: playerNames ?? this.playerNames,
      teams: teams ?? this.teams,
      teamColorIndices: teamColorIndices ?? this.teamColorIndices,
      roundTimeSeconds: roundTimeSeconds ?? this.roundTimeSeconds,
      targetScore: targetScore ?? this.targetScore,
      allowedSkips: allowedSkips ?? this.allowedSkips,
      useWeightedWordSelection:
          useWeightedWordSelection ?? this.useWeightedWordSelection,
      selectedDeckIds: selectedDeckIds ?? this.selectedDeckIds,
    );
  }

  // Check if there are empty slots in teams
  bool hasEmptySlotsInTeams() {
    for (final team in teams) {
      for (final player in team) {
        if (player == "") return true;
      }
    }
    return false;
  }

  // Check if deck selection is valid (minimum 4 decks required)
  bool hasValidDeckSelection() {
    return selectedDeckIds.length >= 4;
  }

  // Get the number of selected decks
  int get selectedDeckCount => selectedDeckIds.length;
}
