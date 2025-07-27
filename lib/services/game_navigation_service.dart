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
import '../screens/settings_screen.dart';
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

    // Handle tiebreaker navigation
    if (gameState.isInTiebreaker) {
      _handleTiebreakerNavigation(context, gameState, teamIndex);
      return;
    }

    // Handle normal game navigation
    _handleNormalGameNavigation(context, gameState, teamIndex);
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

  /// Navigate from home screen to settings
  static void navigateToSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
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
    WordCategory? category,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RoleAssignmentScreen(
          teamIndex: teamIndex,
          roundNumber: roundNumber,
          turnNumber: turnNumber,
          category: category ?? WordCategory.values.first, // fallback
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
  static void navigateToNextRound(
      BuildContext context, WidgetRef ref, int nextRound) {
    final gameState = ref.read(gameStateProvider);
    if (gameState != null && gameState.isTiebreaker) {
      // For tiebreaker, navigate to category selection for the first tied team
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => CategorySelectionScreen(
            teamIndex: gameState.tiedTeamIndices[0],
            roundNumber: gameState.tiebreakerRound,
            turnNumber: 1,
            displayString: 'Tiebreaker Round',
          ),
        ),
      );
      return;
    }
    // Normal next round navigation
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => CategorySelectionScreen(
          teamIndex: 0, // Start with first team
          roundNumber: nextRound,
          turnNumber: 1,
          displayString: gameState != null &&
                  gameState.config.teams[0].length >= 2
              ? "${gameState.config.teams[0][0]} & ${gameState.config.teams[0][1]}'s Turn"
              : '',
        ),
      ),
    );
  }

  /// Navigate from category selection to the appropriate next screen based on game state
  static void navigateFromCategorySelection(
    BuildContext context,
    WidgetRef ref,
    int teamIndex,
    int roundNumber,
    int turnNumber,
    WordCategory category,
  ) {
    final gameState = ref.read(gameStateProvider);
    if (gameState == null) {
      _navigateToHome(context);
      return;
    }

    // Handle tiebreaker logic
    if (gameState.isTiebreaker) {
      // Start tiebreaker mode
      ref.read(gameStateProvider.notifier).startTiebreaker(category);
      // Navigate to role assignment for first tied team
      navigateToRoleAssignment(
        context,
        gameState.tiedTeamIndices.isNotEmpty ? gameState.tiedTeamIndices[0] : 0,
        gameState.tiebreakerRound,
        1,
        category,
      );
      return;
    }

    // Normal flow: navigate to role assignment
    navigateToRoleAssignment(
      context,
      teamIndex,
      roundNumber,
      turnNumber,
      category,
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
  static void _navigateToScoreboard(BuildContext context, int roundNumber,
      {GameState? gameState}) {
    // Use the tiebreaker fields from GameState
    bool isTiebreaker = false;
    List<int>? tiedTeamIndices;
    if (gameState != null) {
      isTiebreaker = gameState.isTiebreaker;
      tiedTeamIndices = gameState.tiedTeamIndices.isNotEmpty
          ? gameState.tiedTeamIndices
          : null;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ScoreboardScreen(
          roundNumber: roundNumber,
          isTiebreaker: isTiebreaker,
          tiedTeamIndices: tiedTeamIndices,
        ),
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
          displayString: gameState
                      .config.teams[gameState.currentTeamIndex].length >=
                  2
              ? "${gameState.config.teams[gameState.currentTeamIndex][0]} & ${gameState.config.teams[gameState.currentTeamIndex][1]}'s Turn"
              : '',
        ),
      ),
    );
  }

  /// Handle navigation for tiebreaker mode
  static void _handleTiebreakerNavigation(
      BuildContext context, GameState gameState, int? teamIndex) {
    final tiedTeamIndices = gameState.tiedTeamIndices;

    // Ensure we have a valid team index that's actually in the tiebreaker
    final effectiveTeamIndex = teamIndex ?? gameState.currentTeamIndex;
    final teamIndexInTiedTeams = tiedTeamIndices.indexOf(effectiveTeamIndex);

    // Safety check: if the team isn't in the tiebreaker, start with the first tied team
    if (teamIndexInTiedTeams == -1) {
      _navigateToNextTiedTeam(context, gameState, -1); // Start with first team
      return;
    }

    if (_isEndOfTiebreakerRound(teamIndexInTiedTeams, tiedTeamIndices.length)) {
      _navigateToScoreboard(context, gameState.tiebreakerRound,
          gameState: gameState);
    } else {
      _navigateToNextTiedTeam(context, gameState, teamIndexInTiedTeams);
    }
  }

  /// Handle navigation for normal game mode
  static void _handleNormalGameNavigation(
      BuildContext context, GameState gameState, int? teamIndex) {
    if (gameState.isGameOver) {
      _navigateToGameOver(context);
    } else if (_isEndOfRound(gameState, teamIndex)) {
      _navigateToScoreboard(context, gameState.currentRound - 1,
          gameState: gameState);
    } else {
      _navigateToCategorySelection(context, gameState);
    }
  }

  /// Navigate to the next tied team in tiebreaker mode
  static void _navigateToNextTiedTeam(BuildContext context, GameState gameState,
      int currentTeamIndexInTiedTeams) {
    final tiedTeamIndices = gameState.tiedTeamIndices;

    // If currentTeamIndexInTiedTeams is -1, start with the first team
    // Otherwise, get the next team in the sequence
    final nextTeamIndexInTiedTeams =
        currentTeamIndexInTiedTeams == -1 ? 0 : currentTeamIndexInTiedTeams + 1;

    final nextTiedTeamIndex = tiedTeamIndices[nextTeamIndexInTiedTeams];

    navigateToRoleAssignment(
      context,
      nextTiedTeamIndex,
      gameState.tiebreakerRound,
      gameState.currentTurn,
      gameState.tiebreakerCategory,
    );
  }

  /// Check if we're at the end of a tiebreaker round
  static bool _isEndOfTiebreakerRound(
      int teamIndexInTiedTeams, int totalTiedTeams) {
    return teamIndexInTiedTeams == totalTiedTeams - 1;
  }
}
