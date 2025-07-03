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

class GameState {
  final GameConfig config;
  final List<int> teamScores;
  final List<TurnRecord> turnHistory;
  final int currentRound;
  final int currentTurn;
  final int currentTeamIndex;
  final bool isGameOver;
  final bool isTiebreaker;
  final List<int> tiebreakerScores;
  final List<int> tiedTeamIndices;
  final bool isInTiebreaker;
  final int tiebreakerRound;
  final WordCategory? tiebreakerCategory;

  GameState({
    required this.config,
    required this.teamScores,
    required this.turnHistory,
    required this.currentRound,
    required this.currentTurn,
    required this.currentTeamIndex,
    required this.isGameOver,
    required this.isTiebreaker,
    required this.tiebreakerScores,
    required this.tiedTeamIndices,
    required this.isInTiebreaker,
    required this.tiebreakerRound,
    this.tiebreakerCategory,
  });

  GameState.initial(GameConfig config)
      : config = config,
        teamScores = List.filled(config.teams.length, 0),
        turnHistory = [],
        currentRound = 1,
        currentTurn = 1,
        currentTeamIndex = 0,
        isGameOver = false,
        isTiebreaker = false,
        tiebreakerScores = [],
        tiedTeamIndices = [],
        isInTiebreaker = false,
        tiebreakerRound = 0,
        tiebreakerCategory = null;

  GameState copyWith({
    GameConfig? config,
    List<int>? teamScores,
    List<TurnRecord>? turnHistory,
    int? currentRound,
    int? currentTurn,
    int? currentTeamIndex,
    bool? isGameOver,
    bool? isTiebreaker,
    List<int>? tiebreakerScores,
    List<int>? tiedTeamIndices,
    bool? isInTiebreaker,
    int? tiebreakerRound,
    WordCategory? tiebreakerCategory,
  }) {
    return GameState(
      config: config ?? this.config,
      teamScores: teamScores ?? this.teamScores,
      turnHistory: turnHistory ?? this.turnHistory,
      currentRound: currentRound ?? this.currentRound,
      currentTurn: currentTurn ?? this.currentTurn,
      currentTeamIndex: currentTeamIndex ?? this.currentTeamIndex,
      isGameOver: isGameOver ?? this.isGameOver,
      isTiebreaker: isTiebreaker ?? this.isTiebreaker,
      tiebreakerScores: tiebreakerScores ?? this.tiebreakerScores,
      tiedTeamIndices: tiedTeamIndices ?? this.tiedTeamIndices,
      isInTiebreaker: isInTiebreaker ?? this.isInTiebreaker,
      tiebreakerRound: tiebreakerRound ?? this.tiebreakerRound,
      tiebreakerCategory: tiebreakerCategory ?? this.tiebreakerCategory,
    );
  }

  // Helper methods
  bool isLastTeam() => currentTeamIndex == config.teams.length - 1;

  int getNextTeamIndex() => isLastTeam() ? 0 : currentTeamIndex + 1;

  int getNextRound() => isLastTeam() ? currentRound + 1 : currentRound;

  int getNextTurn() => isLastTeam() ? currentTurn + 1 : currentTurn;

  GameState advanceTurn(TurnRecord turnRecord) {
    if (isInTiebreaker) {
      return _advanceTiebreakerTurn(turnRecord);
    } else {
      return _advanceNormalTurn(turnRecord);
    }
  }

  // Private method for tiebreaker turn logic
  GameState _advanceTiebreakerTurn(TurnRecord turnRecord) {
    final newTiebreakerScores = List<int>.from(tiebreakerScores);
    final teamIndexInTiebreaker = tiedTeamIndices.indexOf(turnRecord.teamIndex);

    if (teamIndexInTiebreaker != -1) {
      newTiebreakerScores[teamIndexInTiebreaker] += turnRecord.score;
    }

    final newTurnHistory = List<TurnRecord>.from(turnHistory)..add(turnRecord);
    // Use the team that just played to find the next team in tiebreaker
    final nextTeamIndexInTiebreaker =
        (teamIndexInTiebreaker + 1) % tiedTeamIndices.length;
    final isEndOfTiebreakerRound = nextTeamIndexInTiebreaker == 0;

    bool isGameOver = false;
    List<int> newTiedTeamIndices = List.from(tiedTeamIndices);
    int newTiebreakerRound = tiebreakerRound;
    bool newIsInTiebreaker = isInTiebreaker;

    if (isEndOfTiebreakerRound) {
      final tiebreakerResult = _resolveTiebreakerRound(newTiebreakerScores);
      isGameOver = tiebreakerResult['isGameOver'] as bool;
      newTiedTeamIndices = tiebreakerResult['newTiedTeamIndices'] as List<int>;
      newTiebreakerRound = tiebreakerResult['newTiebreakerRound'] as int;
      newIsInTiebreaker = tiebreakerResult['newIsInTiebreaker'] as bool;
    }

    final nextTeamIndex = isEndOfTiebreakerRound
        ? (newTiedTeamIndices.isNotEmpty ? newTiedTeamIndices[0] : 0)
        : tiedTeamIndices[nextTeamIndexInTiebreaker];

    return copyWith(
      tiebreakerScores: newTiebreakerScores,
      turnHistory: newTurnHistory,
      currentTeamIndex: nextTeamIndex,
      currentTurn: isEndOfTiebreakerRound ? currentTurn + 1 : currentTurn,
      isGameOver: isGameOver,
      tiedTeamIndices: newTiedTeamIndices,
      tiebreakerRound: newTiebreakerRound,
      isInTiebreaker: newIsInTiebreaker,
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
      isTiebreaker: isTiebreaker,
      tiedTeamIndices: tiedTeamIndices,
    );
  }

  // Helper method to resolve tiebreaker round
  Map<String, dynamic> _resolveTiebreakerRound(List<int> tiebreakerScores) {
    final maxScore = tiebreakerScores.reduce((a, b) => a > b ? a : b);
    final teamsWithMaxScore = <int>[];

    for (int i = 0; i < tiebreakerScores.length; i++) {
      if (tiebreakerScores[i] == maxScore) {
        teamsWithMaxScore.add(tiedTeamIndices[i]);
      }
    }

    if (teamsWithMaxScore.length == 1) {
      // One team won the tiebreaker
      return {
        'isGameOver': true,
        'newTiedTeamIndices': <int>[],
        'newTiebreakerRound': tiebreakerRound,
        'newIsInTiebreaker': false,
      };
    } else {
      // Still tied, continue to next tiebreaker round
      return {
        'isGameOver': false,
        'newTiedTeamIndices': teamsWithMaxScore,
        'newTiebreakerRound': tiebreakerRound + 1,
        'newIsInTiebreaker': true,
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
    final result = copyWith(
      isInTiebreaker: true,
      tiebreakerRound: 1,
      tiebreakerScores: List.filled(tiedTeamIndices.length, 0),
      currentTeamIndex: tiedTeamIndices.isNotEmpty
          ? tiedTeamIndices[0]
          : 0, // Start with first tied team
      currentTurn: 1,
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
