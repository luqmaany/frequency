import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game_navigation_service.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../screens/zen_setup_screen.dart';
import '../screens/online_lobby_screen.dart';

class GameModeDialog extends ConsumerWidget {
  const GameModeDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      alignment: const Alignment(0, 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        padding: const EdgeInsets.all(2), // Border width
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF5EB1FF), // Blue
              Color(0xFF7A5CFF), // Purple
              Color(0xFF4CD295), // Green
            ],
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(22), // 24 - 2 for border
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(18), // 20 - 2 for border
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dialog title
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  'Game Mode',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              _buildDialogOption(
                context,
                ref,
                'Local',
                'Pass and play, 4+ players',
                Icons.group,
                () {
                  Navigator.of(context).pop();
                  GameNavigationService.navigateToGameSetup(context);
                },
                const Color(0xFF5EB1FF), // blue
              ),
              const SizedBox(height: 12),
              _buildDialogOption(
                context,
                ref,
                'Zen',
                'Quick single turn, 2+ players',
                Icons.spa,
                () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ZenSetupScreen(),
                    ),
                  );
                },
                const Color(0xFF7A5CFF), // purple
              ),
              const SizedBox(height: 12),
              _buildDialogOption(
                context,
                ref,
                'Online',
                '1 or 2 devices per team, 4+ players',
                Icons.public,
                () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const OnlineLobbyScreen(),
                    ),
                  );
                },
                const Color(0xFF4CD295), // green
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogOption(
    BuildContext context,
    WidgetRef ref,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
    Color color,
  ) {
    return InkWell(
      onTapDown: (_) async {
        // Check vibration setting and provide haptic feedback
        final prefs = await StorageService.loadAppPreferences();
        if (prefs['vibrationEnabled'] == true) {
          HapticFeedback.lightImpact();
        }
        ref.read(soundServiceProvider).playButtonPress();
      },
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade300,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
