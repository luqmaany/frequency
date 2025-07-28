import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/session_providers.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';
import '../screens/game_settings_screen.dart';
import '../screens/category_selection_screen.dart';
import '../screens/game_over_screen.dart';
import '../screens/scoreboard_screen.dart';
import '../screens/role_assignment_screen.dart';
import '../screens/game_screen.dart';
import '../screens/turn_over_screen.dart';
import '../screens/word_lists_manager_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/game_screen.dart';

/// Service for handling navigation in online multiplayer games
/// Manages automatic screen transitions based on Firestore game state changes
class OnlineGameNavigationService {
  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  // Convert category name to WordCategory enum
  static WordCategory _convertCategoryNameToEnum(String categoryName) {
    switch (categoryName) {
      case 'person':
        return WordCategory.person;
      case 'action':
        return WordCategory.action;
      case 'world':
        return WordCategory.world;
      case 'random':
        return WordCategory.random;
      default:
        return WordCategory.person;
    }
  }

  // ============================================================================
  // MAIN NAVIGATION METHOD
  // ============================================================================

  /// Sets up a listener for session changes and handles automatic navigation
  /// Call this in your widget's initState to handle navigation
  static void navigate({
    required BuildContext context,
    required WidgetRef ref,
    required String sessionId,
  }) {
    ref.listen(sessionStatusProvider(sessionId), (prev, next) async {
      final status = next?.value;
      if (status == null) return;

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
          _navigateToRoleAssignment(
              context, ref, sessionId, isHost, sessionData);
        });
      }
      if (status == 'game') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigateToGameScreen(context, ref, sessionId, isHost, sessionData);
        });
      }
    });
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
      currentTeamDeviceId = currentTeam?['deviceId'] as String?;
    }

    // Convert category name to WordCategory enum
    final selectedCategory = _convertCategoryNameToEnum(selectedCategoryName);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => RoleAssignmentScreen(
          teamIndex: currentTeamIndex,
          roundNumber: gameState?['roundNumber'] as int? ?? 1,
          turnNumber: gameState?['turnNumber'] as int? ?? 1,
          category: selectedCategory,
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
    final selectedCategoryName =
        gameState?['selectedCategory'] as String? ?? 'Person';
    final selectedCategory = _convertCategoryNameToEnum(selectedCategoryName);

    // Get current team data
    Map<String, dynamic>? currentTeam;
    String? currentTeamDeviceId;
    if (teams.isNotEmpty && currentTeamIndex < teams.length) {
      currentTeam = Map<String, dynamic>.from(teams[currentTeamIndex]);
      currentTeamDeviceId = currentTeam?['deviceId'] as String?;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => GameScreen(
          teamIndex: currentTeamIndex,
          roundNumber: gameState?['roundNumber'] as int? ?? 1,
          turnNumber: gameState?['turnNumber'] as int? ?? 1,
          category: selectedCategory,
          currentTeamDeviceId: currentTeamDeviceId,
          sessionId: sessionId,
          onlineTeam: currentTeam,
          sessionData: sessionData,
        ),
      ),
    );
  }
}
