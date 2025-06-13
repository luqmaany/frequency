import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'game_setup_screen.dart';
import 'word_lists_manager_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Welcome back!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Ready to get roasted?',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 48),
              _buildMenuButton(
                context,
                'Start Game',
                Icons.play_arrow_rounded,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GameSetupScreen()),
                ),
              ),
              const SizedBox(height: 16),
              _buildMenuButton(
                context,
                'Last Game Recap',
                Icons.history_rounded,
                () {
                  // TODO: Implement last game recap
                },
              ),
              const SizedBox(height: 16),
              _buildMenuButton(
                context,
                'Settings',
                Icons.settings_rounded,
                () {
                  // TODO: Implement settings
                },
              ),
              const SizedBox(height: 16),
              _buildMenuButton(
                context,
                'Word Lists Manager',
                Icons.list_alt_rounded,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const WordListsManagerScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildMenuButton(
                context,
                'Stats & History',
                Icons.bar_chart_rounded,
                () {
                  // TODO: Implement stats & history
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String text,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
} 