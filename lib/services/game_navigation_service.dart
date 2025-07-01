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
import '../screens/game_setup_screen.dart';
import '../screens/word_lists_manager_screen.dart';
import '../services/game_state_provider.dart';

class GameNavigationService {
  // ============================================================================
  // PUBLIC NAVIGATION METHODS
  // ============================================================================

  /// Main navigation method that decides where to go based on game state
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

  /// Navigate from home screen to game setup
  static void navigateToGameSetup(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GameSetupScreen(),
      ),
    );
  }

  /// Navigate from home screen to word lists manager
  static void navigateToWordListsManager(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const WordListsManagerScreen(),
      ),
    );
  }

  /// Navigate from game setup to game settings
  static void navigateToGameSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GameSettingsScreen(),
      ),
    );
  }

  /// Navigate from category selection to role assignment
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

  /// Navigate from role assignment to game screen
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

  /// Navigate from game screen to turn over screen
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

  /// Navigate from scoreboard to next round
  static void navigateToNextRound(BuildContext context, int nextRound) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => CategorySelectionScreen(
          teamIndex: 0, // Start with first team
          roundNumber: nextRound,
          turnNumber: 1,
        ),
      ),
    );
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Check if the current team is the last team in the round
  static bool _isEndOfRound(GameState gameState, int? teamIndex) {
    // If teamIndex is provided, use it to check if it was the last team
    // Otherwise, use the current team index from the game state
    final indexToCheck = teamIndex ?? gameState.currentTeamIndex;
    return indexToCheck == gameState.config.teams.length - 1;
  }

  // ============================================================================
  // PRIVATE NAVIGATION METHODS
  // ============================================================================

  /// Navigate back to home screen
  static void _navigateToHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// Navigate to game over screen
  static void _navigateToGameOver(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const GameOverScreen()),
    );
  }

  /// Navigate to scoreboard screen
  static void _navigateToScoreboard(BuildContext context, int roundNumber) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ScoreboardScreen(roundNumber: roundNumber),
      ),
    );
  }

  /// Navigate to category selection screen
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
