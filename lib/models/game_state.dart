import 'game_config.dart';
import '../screens/word_lists_manager_screen.dart';

enum PlayerRole { conveyor, guesser }

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

// Add GamePhase enum
enum GamePhase {
  normal,
  tiebreaker,
  gameOver,
}

// New class to hold all tiebreaker-related state
class TiebreakerState {
  final bool isActive;
  final List<int> scores;
  final List<int> tiedTeamIndices;
  final int round;
  final WordCategory? category;

  TiebreakerState({
    required this.isActive,
    required this.scores,
    required this.tiedTeamIndices,
    required this.round,
    this.category,
  });

  TiebreakerState.initial()
      : isActive = false,
        scores = [],
        tiedTeamIndices = [],
        round = 0,
        category = null;

  TiebreakerState copyWith({
    bool? isActive,
    List<int>? scores,
    List<int>? tiedTeamIndices,
    int? round,
    WordCategory? category,
  }) {
    return TiebreakerState(
      isActive: isActive ?? this.isActive,
      scores: scores ?? this.scores,
      tiedTeamIndices: tiedTeamIndices ?? this.tiedTeamIndices,
      round: round ?? this.round,
      category: category ?? this.category,
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
  final TiebreakerState tiebreaker;
  final GamePhase phase;

  GameState({
    required this.config,
    required this.teamScores,
    required this.turnHistory,
    required this.currentRound,
    required this.currentTurn,
    required this.currentTeamIndex,
    required this.isGameOver,
    required this.tiebreaker,
    required this.phase,
  });

  GameState.initial(GameConfig config)
      : config = config,
        teamScores = List.filled(config.teams.length, 0),
        turnHistory = [],
        currentRound = 1,
        currentTurn = 1,
        currentTeamIndex = 0,
        isGameOver = false,
        tiebreaker = TiebreakerState.initial(),
        phase = GamePhase.normal;

  GameState copyWith({
    GameConfig? config,
    List<int>? teamScores,
    List<TurnRecord>? turnHistory,
    int? currentRound,
    int? currentTurn,
    int? currentTeamIndex,
    bool? isGameOver,
    TiebreakerState? tiebreaker,
    GamePhase? phase,
  }) {
    return GameState(
      config: config ?? this.config,
      teamScores: teamScores ?? this.teamScores,
      turnHistory: turnHistory ?? this.turnHistory,
      currentRound: currentRound ?? this.currentRound,
      currentTurn: currentTurn ?? this.currentTurn,
      currentTeamIndex: currentTeamIndex ?? this.currentTeamIndex,
      isGameOver: isGameOver ?? this.isGameOver,
      tiebreaker: tiebreaker ?? this.tiebreaker,
      phase: phase ?? this.phase,
    );
  }

  // Helper methods
  bool isLastTeam() => currentTeamIndex == config.teams.length - 1;

  int getNextTeamIndex() => isLastTeam() ? 0 : currentTeamIndex + 1;

  int getNextRound() => isLastTeam() ? currentRound + 1 : currentRound;

  int getNextTurn() => isLastTeam() ? currentTurn + 1 : currentTurn;

  GameState advanceTurn(TurnRecord turnRecord) {
    if (phase == GamePhase.tiebreaker) {
      return _advanceTiebreakerTurn(turnRecord);
    } else {
      return _advanceNormalTurn(turnRecord);
    }
  }

  // Private method for tiebreaker turn logic
  GameState _advanceTiebreakerTurn(TurnRecord turnRecord) {
    // Guard: If no tied teams, end the game immediately
    if (tiebreaker.tiedTeamIndices.isEmpty) {
      return copyWith(isGameOver: true);
    }
    final newTiebreakerScores = List<int>.from(tiebreaker.scores);
    final teamIndexInTiebreaker =
        tiebreaker.tiedTeamIndices.indexOf(turnRecord.teamIndex);

    if (teamIndexInTiebreaker != -1) {
      newTiebreakerScores[teamIndexInTiebreaker] += turnRecord.score;
    }

    final newTurnHistory = List<TurnRecord>.from(turnHistory)..add(turnRecord);
    // Use the team that just played to find the next team in tiebreaker
    final nextTeamIndexInTiebreaker =
        (teamIndexInTiebreaker + 1) % tiebreaker.tiedTeamIndices.length;
    final isEndOfTiebreakerRound = nextTeamIndexInTiebreaker == 0;

    bool isGameOver = false;
    List<int> newTiedTeamIndices = List.from(tiebreaker.tiedTeamIndices);
    int newTiebreakerRound = tiebreaker.round;

    if (isEndOfTiebreakerRound) {
      final tiebreakerResult = _resolveTiebreakerRound(newTiebreakerScores);
      isGameOver = tiebreakerResult['isGameOver'] as bool;
      newTiedTeamIndices = tiebreakerResult['newTiedTeamIndices'] as List<int>;
      newTiebreakerRound = tiebreakerResult['newTiebreakerRound'] as int;
    }

    final nextTeamIndex = isEndOfTiebreakerRound
        ? (newTiedTeamIndices.isNotEmpty ? newTiedTeamIndices[0] : 0)
        : tiebreaker.tiedTeamIndices[nextTeamIndexInTiebreaker];

    return copyWith(
      tiebreaker: tiebreaker.copyWith(
        scores: newTiebreakerScores,
        tiedTeamIndices: newTiedTeamIndices,
        round: newTiebreakerRound,
      ),
      turnHistory: newTurnHistory,
      currentTeamIndex: nextTeamIndex,
      currentTurn: isEndOfTiebreakerRound ? currentTurn + 1 : currentTurn,
      isGameOver: isGameOver,
    );
  }

  // Private method for normal turn logic
  GameState _advanceNormalTurn(TurnRecord turnRecord) {
    final newTeamScores = List<int>.from(teamScores);
    newTeamScores[turnRecord.teamIndex] += turnRecord.score;

    final newTurnHistory = List<TurnRecord>.from(turnHistory)..add(turnRecord);
    final nextTeamIndex = getNextTeamIndex();
    final nextRound = getNextRound();
    final nextTurn = getNextTurn();

    final hasReachedTargetScore =
        newTeamScores.any((score) => score >= config.targetScore);
    final isEndOfRound = isLastTeam();

    final tiebreakerCheck =
        _checkForTiebreaker(newTeamScores, hasReachedTargetScore, isEndOfRound);
    final isTiebreaker = tiebreakerCheck['isTiebreaker'] as bool;
    final tiedTeamIndices = tiebreakerCheck['tiedTeamIndices'] as List<int>;
    final isGameOver = hasReachedTargetScore && isEndOfRound && !isTiebreaker;

    return copyWith(
      teamScores: newTeamScores,
      turnHistory: newTurnHistory,
      currentRound: nextRound,
      currentTurn: nextTurn,
      currentTeamIndex: nextTeamIndex,
      isGameOver: isGameOver,
      tiebreaker: isTiebreaker
          ? tiebreaker.copyWith(
              isActive: isTiebreaker,
              tiedTeamIndices: tiedTeamIndices,
            )
          : tiebreaker,
    );
  }

  // Helper method to resolve tiebreaker round
  Map<String, dynamic> _resolveTiebreakerRound(List<int> tiebreakerScores) {
    final maxScore = tiebreakerScores.reduce((a, b) => a > b ? a : b);
    final teamsWithMaxScore = <int>[];

    for (int i = 0; i < tiebreakerScores.length; i++) {
      if (tiebreakerScores[i] == maxScore) {
        teamsWithMaxScore.add(tiebreaker.tiedTeamIndices[i]);
      }
    }

    if (teamsWithMaxScore.length == 1) {
      // One team won the tiebreaker
      return {
        'isGameOver': true,
        'newTiedTeamIndices': <int>[],
        'newTiebreakerRound': tiebreaker.round,
      };
    } else {
      // Still tied, continue to next tiebreaker round
      return {
        'isGameOver': false,
        'newTiedTeamIndices': teamsWithMaxScore,
        'newTiebreakerRound': tiebreaker.round + 1,
      };
    }
  }

  // Helper method to check for tiebreaker conditions
  Map<String, dynamic> _checkForTiebreaker(
      List<int> teamScores, bool hasReachedTargetScore, bool isEndOfRound) {
    bool isTiebreaker = false;
    List<int> tiedTeamIndices = [];

    if (hasReachedTargetScore && isEndOfRound) {
      final teamsAtTarget =
          teamScores.where((score) => score >= config.targetScore).length;
      isTiebreaker = teamsAtTarget > 1;
      if (isTiebreaker) {
        for (int i = 0; i < teamScores.length; i++) {
          if (teamScores[i] >= config.targetScore) {
            tiedTeamIndices.add(i);
          }
        }
      }
    }

    return {
      'isTiebreaker': isTiebreaker,
      'tiedTeamIndices': tiedTeamIndices,
    };
  }

  // Start tiebreaker mode
  GameState startTiebreaker() {
    // Guard: If no tied teams, end the game immediately
    if (tiebreaker.tiedTeamIndices.isEmpty) {
      return copyWith(isGameOver: true, phase: GamePhase.gameOver);
    }
    final result = copyWith(
      tiebreaker: tiebreaker.copyWith(
        round: 1,
        scores: List.filled(tiebreaker.tiedTeamIndices.length, 0),
        isActive: true,
      ),
      currentTeamIndex: tiebreaker.tiedTeamIndices[0], // Safe, not empty
      currentTurn: 1,
      phase: GamePhase.tiebreaker, // Set phase to tiebreaker
      // Keep currentRound unchanged - don't reset it
      // Do not set tiebreakerCategory here
    );
    return result;
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
        categoryStats[turn.category] =
            (categoryStats[turn.category] ?? 0) + turn.score;
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
    int totalTurns =
        turnHistory.where((turn) => turn.teamIndex == teamIndex).length;
    int totalWordsGuessed = 0;
    int totalSkips = 0;
    Map<String, int> categoryStats = {};

    for (final turn
        in turnHistory.where((turn) => turn.teamIndex == teamIndex)) {
      totalWordsGuessed += turn.wordsGuessed.length;
      totalSkips += turn.skipsUsed;
      categoryStats[turn.category] =
          (categoryStats[turn.category] ?? 0) + turn.score;
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
