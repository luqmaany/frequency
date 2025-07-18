import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/session_providers.dart';
import '../services/storage_service.dart';
import '../screens/game_settings_screen.dart';
// Import other screens as needed

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
      final status = sessionData['status'] as String?;
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
}
