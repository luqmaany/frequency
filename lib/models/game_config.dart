class GameConfig {
  final List<String> playerNames;
  final List<List<String>> teams;
  final List<int> teamColorIndices;
  final int roundTimeSeconds;
  final int targetScore;
  final int allowedSkips;

  GameConfig({
    required this.playerNames,
    required this.teams,
    List<int>? teamColorIndices,
    required this.roundTimeSeconds,
    required this.targetScore,
    required this.allowedSkips,
  }) : teamColorIndices = teamColorIndices ?? [];

  GameConfig copyWith({
    List<String>? playerNames,
    List<List<String>>? teams,
    List<int>? teamColorIndices,
    int? roundTimeSeconds,
    int? targetScore,
    int? allowedSkips,
  }) {
    return GameConfig(
      playerNames: playerNames ?? this.playerNames,
      teams: teams ?? this.teams,
      teamColorIndices: teamColorIndices ?? this.teamColorIndices,
      roundTimeSeconds: roundTimeSeconds ?? this.roundTimeSeconds,
      targetScore: targetScore ?? this.targetScore,
      allowedSkips: allowedSkips ?? this.allowedSkips,
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
}
