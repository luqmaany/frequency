import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_state.dart';
import '../models/game_config.dart';

class GameStateNotifier extends StateNotifier<GameState?> {
  // Track used words across the entire game
  final Set<String> _gameUsedWords = {};

  GameStateNotifier() : super(null);

  void initializeGame(GameConfig config) {
    _gameUsedWords.clear(); // Clear used words for new game
    state = GameState.initial(config);
  }

  // Get used words for the current game
  Set<String> get gameUsedWords => Set.from(_gameUsedWords);

  // Add words to the used words set
  void addUsedWords(List<String> words) {
    _gameUsedWords.addAll(words);
  }

  void recordTurn(TurnRecord turnRecord) {
    if (state == null) return;
    state = state!.advanceTurn(turnRecord);
  }

  void resetGame() {
    state = null;
  }

  void startTiebreaker(String categoryId) {
    if (state == null) return;
    final tiebreakerState =
        state!.startTiebreaker().copyWith(tiebreakerCategory: categoryId);
    state = tiebreakerState;
  }

  // Helper getters
  bool get isGameOver => state?.isGameOver ?? false;
  int get currentRound => state?.currentRound ?? 1;
  int get currentTurn => state?.currentTurn ?? 1;
  int get currentTeamIndex => state?.currentTeamIndex ?? 0;
  List<int> get teamScores => state?.teamScores ?? [];
  List<TurnRecord> get turnHistory => state?.turnHistory ?? [];

  // Get current team's players
  List<String> getCurrentTeamPlayers() {
    if (state == null) return [];
    return state!.config.teams[state!.currentTeamIndex];
  }

  // Get statistics
  Map<String, dynamic> getPlayerStats(String playerName) {
    return state?.getPlayerStats(playerName) ?? {};
  }

  Map<String, dynamic> getTeamStats(int teamIndex) {
    return state?.getTeamStats(teamIndex) ?? {};
  }
}

// Provider for the game state
final gameStateProvider =
    StateNotifierProvider<GameStateNotifier, GameState?>((ref) {
  return GameStateNotifier();
});

// Provider for the current team's players
final currentTeamPlayersProvider = Provider<List<String>>((ref) {
  final gameState = ref.watch(gameStateProvider);
  if (gameState == null) return [];
  return gameState.config.teams[gameState.currentTeamIndex];
});

// Provider for the current team's score
final currentTeamScoreProvider = Provider<int>((ref) {
  final gameState = ref.watch(gameStateProvider);
  if (gameState == null) return 0;
  return gameState.teamScores[gameState.currentTeamIndex];
});

// Provider for all team scores
final teamScoresProvider = Provider<List<int>>((ref) {
  final gameState = ref.watch(gameStateProvider);
  return gameState?.teamScores ?? [];
});

// Provider for game over status
final isGameOverProvider = Provider<bool>((ref) {
  final gameState = ref.watch(gameStateProvider);
  return gameState?.isGameOver ?? false;
});
