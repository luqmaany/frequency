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

class OnlineGameNavigationService {
  /// Call this in your widget's build or initState to handle navigation
  static void handleNavigation({
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

      // Example: Navigate to GameSettingsScreen when status is 'settings'
      if (status == 'settings') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => GameSettingsScreen(
                isHost: isHost,
                sessionId: sessionId,
              ),
            ),
          );
        });
      }
      // Add more navigation logic for other statuses as needed
    });
  }

  static Future<Map<String, dynamic>?> getSessionContext(
      String sessionId) async {
    final sessionSnap = await FirestoreService.sessionStream(sessionId).first;
    final sessionData = sessionSnap.data();
    if (sessionData == null) return null;
    final gameState = sessionData['gameState'] as Map<String, dynamic>?;
    final status = gameState != null ? gameState['status'] as String? : null;
    final hostId = sessionData['hostId'] as String?;
    final deviceId = await StorageService.getDeviceId();
    final isHost = deviceId == hostId;
    return {
      'sessionData': sessionData,
      'status': status,
      'hostId': hostId,
      'deviceId': deviceId,
      'isHost': isHost,
    };
  }

  static Future<void> navigateToNextScreen(
      BuildContext context, WidgetRef ref, String sessionId) async {
    final contextData = await getSessionContext(sessionId);
    if (contextData == null) return;
    final gameState =
        contextData['sessionData']['gameState'] as Map<String, dynamic>?;
    final status = gameState != null ? gameState['status'] as String? : null;
    // TODO: Use sessionData to determine which screen to navigate to, similar to GameNavigationService
    if (status == 'playing') {
      // For now, just navigate to CategorySelectionScreen for the first team
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => CategorySelectionScreen(
              teamIndex: 0,
              roundNumber: 1,
              turnNumber: 1,
              displayString: '',
            ),
          ),
        );
      });
      return;
    }
    // TODO: Add more navigation logic for other statuses/screens as needed
  }

  static Future<void> navigateFromSettingsScreen(
      BuildContext context, WidgetRef ref, String sessionId) async {
    final contextData = await getSessionContext(sessionId);
    if (contextData == null) return;
    // For now, just navigate to CategorySelectionScreen for the first team
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => CategorySelectionScreen(
            teamIndex: 0,
            roundNumber: 1,
            turnNumber: 1,
            displayString: '',
          ),
        ),
      );
    });
  }

  /// Helper to get teamIndex from teamId and teams array
  static int getTeamIndexById(List teams, String teamId) {
    return teams.indexWhere((team) => team['teamId'] == teamId);
  }

  /// Centralized method to start the game by updating gameState in Firestore
  static Future<void> startGame(String sessionId) async {
    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .update({
      'gameState.status': 'category_selection',
      'gameState.currentTeamIndex': 0,
      'gameState.roundNumber': 1,
      'gameState.turnNumber': 1,
      // Add other initial fields as needed
    });
  }
}
