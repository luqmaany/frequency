import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/session_providers.dart';
import '../services/storage_service.dart';
import '../screens/game_settings_screen.dart';
import '../screens/category_selection_screen.dart';
import '../screens/role_assignment_screen.dart';
import '../screens/online_game_screen.dart';
import '../screens/online_turn_over_screen.dart';

/// Service for handling navigation in online multiplayer games
/// Provides navigation logic that can be called from ref.listen callbacks in screens
class OnlineGameNavigationService {
  // ============================================================================
  // MAIN NAVIGATION METHOD
  // ============================================================================

  /// Handles navigation based on the current session status
  /// This method should be called from the ref.listen callback in each screen
  static void handleNavigation({
    required BuildContext context,
    required WidgetRef ref,
    required String sessionId,
    required String status,
  }) async {
    print(
        '🧭 NAVIGATION: OnlineGameNavigationService.handleNavigation($sessionId) - status: $status');

    // Get the full session data for navigation
    final sessionAsync = ref.read(sessionStreamProvider(sessionId));
    final sessionSnap = sessionAsync.value;
    final sessionData = sessionSnap?.data();
    if (sessionData == null) return;

    final hostId = sessionData['hostId'] as String?;
    final deviceId = await StorageService.getDeviceId();
    final isHost = deviceId == hostId;

    // Handle different game states
    if (status == 'settings') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToGameSettings(context, ref, sessionId, isHost);
      });
    }
    if (status == 'start_game') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToCategorySelection(
            context, ref, sessionId, isHost, sessionData);
      });
    }
    if (status == 'role_assignment') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToRoleAssignment(context, ref, sessionId, isHost, sessionData);
      });
    }
    if (status == 'game') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToGameScreen(context, ref, sessionId, isHost, sessionData);
      });
    }
    if (status == 'turn_over') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToTurnOverScreen(context, ref, sessionId, isHost, sessionData);
      });
    }
  }

  // ============================================================================
  // PRIVATE NAVIGATION HELPERS
  // ============================================================================

  /// Private helper to navigate to GameSettingsScreen
  /// Uses addPostFrameCallback to ensure safe navigation timing
  static void _navigateToGameSettings(
      BuildContext context, WidgetRef ref, String sessionId, bool isHost) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) =>
            GameSettingsScreen(isHost: isHost, sessionId: sessionId),
      ),
    );
  }

  static void _navigateToCategorySelection(BuildContext context, WidgetRef ref,
      String sessionId, bool isHost, sessionData) {
    // Get the current team's device ID from the game state
    final gameState = sessionData['gameState'] as Map<String, dynamic>?;
    final currentTeamIndex = gameState?['currentTeamIndex'] as int? ?? 0;
    final teams = sessionData['teams'] as List? ?? [];

    String? currentTeamDeviceId;
    if (teams.isNotEmpty && currentTeamIndex < teams.length) {
      final currentTeam = teams[currentTeamIndex] as Map<String, dynamic>?;
      currentTeamDeviceId = currentTeam?['deviceId'] as String?;

      // If no deviceId is stored yet, this might be an older team entry
      // In this case, we'll allow all teams to interact (fallback behavior)
      if (currentTeamDeviceId == null) {
        print(
            'Warning: Team at index $currentTeamIndex has no deviceId stored');
      }
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => CategorySelectionScreen(
          teamIndex: currentTeamIndex,
          roundNumber: gameState?['roundNumber'] as int? ?? 1,
          turnNumber: gameState?['turnNumber'] as int? ?? 1,
          displayString: teams.isNotEmpty && currentTeamIndex < teams.length
              ? (teams[currentTeamIndex]['teamName'] as String? ?? '')
              : '',
          currentTeamDeviceId: currentTeamDeviceId,
          sessionId: sessionId,
        ),
      ),
    );
  }

  static void _navigateToRoleAssignment(BuildContext context, WidgetRef ref,
      String sessionId, bool isHost, sessionData) {
    // Get the current team's device ID from the game state
    final gameState = sessionData['gameState'] as Map<String, dynamic>?;
    final currentTeamIndex = gameState?['currentTeamIndex'] as int? ?? 0;
    final teams = sessionData['teams'] as List? ?? [];
    final selectedCategoryName =
        gameState?['selectedCategory'] as String? ?? 'Person';

    // Get current team data
    Map<String, dynamic>? currentTeam;
    String? currentTeamDeviceId;
    if (teams.isNotEmpty && currentTeamIndex < teams.length) {
      currentTeam = Map<String, dynamic>.from(teams[currentTeamIndex]);
      currentTeamDeviceId = currentTeam['deviceId'] as String?;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => RoleAssignmentScreen(
          teamIndex: currentTeamIndex,
          roundNumber: gameState?['roundNumber'] as int? ?? 1,
          turnNumber: gameState?['turnNumber'] as int? ?? 1,
          categoryId: selectedCategoryName,
          sessionId: sessionId,
          onlineTeam: currentTeam,
          currentTeamDeviceId: currentTeamDeviceId,
        ),
      ),
    );
  }

  static void _navigateToGameScreen(
    BuildContext context,
    WidgetRef ref,
    String sessionId,
    bool isHost,
    sessionData,
  ) {
    final gameState = sessionData['gameState'] as Map<String, dynamic>?;
    final currentTeamIndex = gameState?['currentTeamIndex'] as int? ?? 0;
    final teams = sessionData['teams'] as List? ?? [];

    // Get current team data
    Map<String, dynamic>? currentTeam;
    String? currentTeamDeviceId;
    if (teams.isNotEmpty && currentTeamIndex < teams.length) {
      currentTeam = Map<String, dynamic>.from(teams[currentTeamIndex]);
      currentTeamDeviceId = currentTeam['deviceId'] as String?;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => OnlineGameScreen(
          teamIndex: currentTeamIndex,
          roundNumber: gameState?['roundNumber'] as int? ?? 1,
          turnNumber: gameState?['turnNumber'] as int? ?? 1,
          category: gameState?['selectedCategory'] as String? ?? 'Person',
          currentTeamDeviceId: currentTeamDeviceId,
          sessionId: sessionId,
          onlineTeam: currentTeam,
          sessionData: sessionData,
        ),
      ),
    );
  }

  static void _navigateToTurnOverScreen(
    BuildContext context,
    WidgetRef ref,
    String sessionId,
    bool isHost,
    sessionData,
  ) async {
    final gameState = sessionData['gameState'] as Map<String, dynamic>?;
    final currentTurnRecord =
        gameState?['currentTurnRecord'] as Map<String, dynamic>?;

    if (currentTurnRecord == null) {
      print('Warning: No current turn record found for turn over screen');
      return;
    }

    // Get the current device's team index
    final deviceId = await StorageService.getDeviceId();
    final teams = sessionData['teams'] as List? ?? [];
    int currentTeamIndex = 0;

    // Find which team this device belongs to
    for (int i = 0; i < teams.length; i++) {
      final team = teams[i] as Map<String, dynamic>?;
      if (team?['deviceId'] == deviceId) {
        currentTeamIndex = i;
        break;
      }
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => OnlineTurnOverScreen(
          teamIndex:
              currentTeamIndex, // Use the device's team index, not the turn record's
          roundNumber: currentTurnRecord['roundNumber'] as int? ?? 1,
          turnNumber: currentTurnRecord['turnNumber'] as int? ?? 1,
          category: currentTurnRecord['category'] as String? ?? 'Person',
          correctCount: currentTurnRecord['correctCount'] as int? ?? 0,
          skipsLeft: currentTurnRecord['skipsLeft'] as int? ?? 0,
          wordsGuessed: List<String>.from(
              currentTurnRecord['wordsGuessed'] as List? ?? []),
          wordsSkipped: List<String>.from(
              currentTurnRecord['wordsSkipped'] as List? ?? []),
          disputedWords: Set<String>.from(
              currentTurnRecord['disputedWords'] as List? ?? []),
          conveyor: currentTurnRecord['conveyor'] as String?,
          guesser: currentTurnRecord['guesser'] as String?,
          sessionId: sessionId,
          sessionData: sessionData,
        ),
      ),
    );
  }
}
