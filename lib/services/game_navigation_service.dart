import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_state.dart';
import '../screens/category_selection_screen.dart';
import '../screens/game_over_screen.dart';
import '../screens/scoreboard_screen.dart';
import '../screens/game_settings_screen.dart';
import '../screens/role_assignment_screen.dart';
import '../screens/game_screen.dart';
import '../screens/turn_over_screen.dart';
import '../screens/word_lists_manager_screen.dart';
import '../utils/category_utils.dart';
import '../services/game_state_provider.dart';

class GameNavigationService {
  static void navigateToNextScreen(BuildContext context, WidgetRef ref,
      {int? teamIndex}) {
    final gameState = ref.read(gameStateProvider);
    if (gameState == null) {
      _navigateToHome(context);
      return;
    }

    // For newly initialized game, go to category selection for first team
    if (gameState.currentRound == 1 && gameState.currentTeamIndex == 0) {
      _navigateToCategorySelection(context, gameState);
      return;
    }

    if (gameState.isGameOver) {
      _navigateToGameOver(context);
    } else if (_isEndOfRound(gameState, teamIndex)) {
      _navigateToScoreboard(context, gameState.currentRound - 1);
    } else {
      _navigateToCategorySelection(context, gameState);
    }
  }

  static void navigateToGameSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GameSettingsScreen(),
      ),
    );
  }

  static void navigateToRoleAssignment(
    BuildContext context,
    int teamIndex,
    int roundNumber,
    int turnNumber,
    WordCategory category,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RoleAssignmentScreen(
          teamIndex: teamIndex,
          roundNumber: roundNumber,
          turnNumber: turnNumber,
          category: category,
        ),
      ),
    );
  }

  static void navigateToGameScreen(
    BuildContext context,
    int teamIndex,
    int roundNumber,
    int turnNumber,
    WordCategory category,
  ) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => GameScreen(
          teamIndex: teamIndex,
          roundNumber: roundNumber,
          turnNumber: turnNumber,
          category: category,
        ),
      ),
    );
  }

  static void navigateToTurnOver(
    BuildContext context,
    int teamIndex,
    int roundNumber,
    int turnNumber,
    WordCategory category,
    int correctCount,
    int skipsLeft,
    List<String> wordsGuessed,
    List<String> wordsSkipped,
    Set<String> disputedWords,
  ) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => TurnOverScreen(
          teamIndex: teamIndex,
          roundNumber: roundNumber,
          turnNumber: turnNumber,
          category: category,
          correctCount: correctCount,
          skipsLeft: skipsLeft,
          wordsGuessed: wordsGuessed,
          wordsSkipped: wordsSkipped,
          disputedWords: disputedWords,
        ),
      ),
    );
  }

  // Helper methods
  static bool _isEndOfRound(GameState gameState, int? teamIndex) {
    // If teamIndex is provided, use it to check if it was the last team
    // Otherwise, use the current team index from the game state
    final indexToCheck = teamIndex ?? gameState.currentTeamIndex;
    return indexToCheck == gameState.config.teams.length - 1;
  }

  // Navigation methods
  static void _navigateToHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  static void _navigateToGameOver(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const GameOverScreen()),
    );
  }

  static void _navigateToScoreboard(BuildContext context, int roundNumber) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ScoreboardScreen(roundNumber: roundNumber),
      ),
    );
  }

  static void _navigateToCategorySelection(
    BuildContext context,
    GameState gameState,
  ) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => CategorySelectionScreen(
          teamIndex: gameState.currentTeamIndex,
          roundNumber: gameState.currentRound,
          turnNumber: gameState.currentTurn,
        ),
      ),
    );
  }
}
