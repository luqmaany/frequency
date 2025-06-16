class GameConfig {
  final List<String> playerNames;
  final List<List<String>> teams;
  final int roundTimeSeconds;
  final int targetScore;
  final int allowedSkips;

  GameConfig({
    required this.playerNames,
    required this.teams,
    required this.roundTimeSeconds,
    required this.targetScore,
    required this.allowedSkips,
  });

  GameConfig copyWith({
    List<String>? playerNames,
    List<List<String>>? teams,
    int? roundTimeSeconds,
    int? targetScore,
    int? allowedSkips,
  }) {
    return GameConfig(
      playerNames: playerNames ?? this.playerNames,
      teams: teams ?? this.teams,
      roundTimeSeconds: roundTimeSeconds ?? this.roundTimeSeconds,
      targetScore: targetScore ?? this.targetScore,
      allowedSkips: allowedSkips ?? this.allowedSkips,
    );
  }
} 