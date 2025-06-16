import 'game_config.dart';

enum PlayerRole {
  conveyer,
  guesser
}

class TurnRecord {
  final int teamIndex;
  final int roundNumber;
  final int turnNumber;
  final String conveyor;
  final String guesser;
  final String category;
  final int score;
  final int skipsUsed;
  final List<String> wordsGuessed;
  final List<String> wordsSkipped;

  TurnRecord({
    required this.teamIndex,
    required this.roundNumber,
    required this.turnNumber,
    required this.conveyor,
    required this.guesser,
    required this.category,
    required this.score,
    required this.skipsUsed,
    required this.wordsGuessed,
    required this.wordsSkipped,
  });

  TurnRecord copyWith({
    int? teamIndex,
    int? roundNumber,
    int? turnNumber,
    String? conveyor,
    String? guesser,
    String? category,
    int? score,
    int? skipsUsed,
    List<String>? wordsGuessed,
    List<String>? wordsSkipped,
  }) {
    return TurnRecord(
      teamIndex: teamIndex ?? this.teamIndex,
      roundNumber: roundNumber ?? this.roundNumber,
      turnNumber: turnNumber ?? this.turnNumber,
      conveyor: conveyor ?? this.conveyor,
      guesser: guesser ?? this.guesser,
      category: category ?? this.category,
      score: score ?? this.score,
      skipsUsed: skipsUsed ?? this.skipsUsed,
      wordsGuessed: wordsGuessed ?? this.wordsGuessed,
      wordsSkipped: wordsSkipped ?? this.wordsSkipped,
    );
  }
}

class GameState {
  final GameConfig config;
  final List<int> teamScores;
  final List<TurnRecord> turnHistory;
  final int currentRound;
  final int currentTurn;
  final int currentTeamIndex;
  final bool isGameOver;

  GameState({
    required this.config,
    required this.teamScores,
    required this.turnHistory,
    required this.currentRound,
    required this.currentTurn,
    required this.currentTeamIndex,
    required this.isGameOver,
  });

  GameState.initial(GameConfig config)
      : config = config,
        teamScores = List.filled(config.teams.length, 0),
        turnHistory = [],
        currentRound = 1,
        currentTurn = 1,
        currentTeamIndex = 0,
        isGameOver = false;

  GameState copyWith({
    GameConfig? config,
    List<int>? teamScores,
    List<TurnRecord>? turnHistory,
    int? currentRound,
    int? currentTurn,
    int? currentTeamIndex,
    bool? isGameOver,
  }) {
    return GameState(
      config: config ?? this.config,
      teamScores: teamScores ?? this.teamScores,
      turnHistory: turnHistory ?? this.turnHistory,
      currentRound: currentRound ?? this.currentRound,
      currentTurn: currentTurn ?? this.currentTurn,
      currentTeamIndex: currentTeamIndex ?? this.currentTeamIndex,
      isGameOver: isGameOver ?? this.isGameOver,
    );
  }

  // Helper methods
  bool isLastTeam() => currentTeamIndex == config.teams.length - 1;
  
  int getNextTeamIndex() => isLastTeam() ? 0 : currentTeamIndex + 1;
  
  int getNextRound() => isLastTeam() ? currentRound + 1 : currentRound;
  
  int getNextTurn() => isLastTeam() ? currentTurn + 1 : currentTurn;

  GameState advanceTurn(TurnRecord turnRecord) {
    final newTeamScores = List<int>.from(teamScores);
    // Update the team's score with the disputed score
    newTeamScores[turnRecord.teamIndex] += turnRecord.score;

    final newTurnHistory = List<TurnRecord>.from(turnHistory)..add(turnRecord);
    
    final nextTeamIndex = getNextTeamIndex();
    final nextRound = getNextRound();
    final nextTurn = getNextTurn();

    // Check if any team has reached the target score AND we're at the end of a round
    final hasReachedTargetScore = newTeamScores.any((score) => score >= config.targetScore);
    final isEndOfRound = isLastTeam();
    final isGameOver = hasReachedTargetScore && isEndOfRound;

    return copyWith(
      teamScores: newTeamScores,
      turnHistory: newTurnHistory,
      currentRound: nextRound,
      currentTurn: nextTurn,
      currentTeamIndex: nextTeamIndex,
      isGameOver: isGameOver,
    );
  }

  // Get statistics for a specific player
  Map<String, dynamic> getPlayerStats(String playerName) {
    int totalScore = 0;
    int timesConveyor = 0;
    int timesGuesser = 0;
    int totalWordsGuessed = 0;
    int totalSkips = 0;
    Map<String, int> categoryStats = {};

    for (final turn in turnHistory) {
      if (turn.conveyor == playerName) {
        timesConveyor++;
        totalScore += turn.score;
        totalSkips += turn.skipsUsed;
        categoryStats[turn.category] = (categoryStats[turn.category] ?? 0) + turn.score;
      }
      if (turn.guesser == playerName) {
        timesGuesser++;
        totalWordsGuessed += turn.wordsGuessed.length;
      }
    }

    return {
      'totalScore': totalScore,
      'timesConveyor': timesConveyor,
      'timesGuesser': timesGuesser,
      'totalWordsGuessed': totalWordsGuessed,
      'totalSkips': totalSkips,
      'categoryStats': categoryStats,
    };
  }

  // Get statistics for a specific team
  Map<String, dynamic> getTeamStats(int teamIndex) {
    int totalScore = teamScores[teamIndex];
    int totalTurns = turnHistory.where((turn) => turn.teamIndex == teamIndex).length;
    int totalWordsGuessed = 0;
    int totalSkips = 0;
    Map<String, int> categoryStats = {};

    for (final turn in turnHistory.where((turn) => turn.teamIndex == teamIndex)) {
      totalWordsGuessed += turn.wordsGuessed.length;
      totalSkips += turn.skipsUsed;
      categoryStats[turn.category] = (categoryStats[turn.category] ?? 0) + turn.score;
    }

    return {
      'totalScore': totalScore,
      'totalTurns': totalTurns,
      'totalWordsGuessed': totalWordsGuessed,
      'totalSkips': totalSkips,
      'categoryStats': categoryStats,
    };
  }
} 