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
// Import other screens as needed
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for handling navigation in online multiplayer games
/// Manages automatic screen transitions based on Firestore game state changes
class OnlineGameNavigationService {
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
    ref.listen(sessionStreamProvider(sessionId), (prev, next) async {
      final sessionSnap = next?.value;
      final sessionData = sessionSnap?.data();
      if (sessionData == null) return;

      final gameState = sessionData['gameState'] as Map<String, dynamic>?;
      final status = gameState != null ? gameState['status'] as String? : null;
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
        print("navigate now please");
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigateToCategorySelection(
              context, ref, sessionId, isHost, sessionData);
        });
      }
      // TODO: Add more navigation logic for other statuses as needed
      // Examples: 'category_selection', 'playing', 'game_over', etc.
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
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => CategorySelectionScreen(
          teamIndex: 0,
          roundNumber: 1,
          turnNumber: 1,
          displayString: sessionData['teams'][0]['teamName'] ?? '',
        ),
      ),
    );
  }
}
