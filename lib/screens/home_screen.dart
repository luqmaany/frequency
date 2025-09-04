import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/game_navigation_service.dart';
import 'online_lobby_screen.dart';
import '../widgets/wave_background.dart';
import '../widgets/menu_button.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import 'zen_setup_screen.dart';

/// --- Animated gradient text (unchanged except default text now "FREQUENCY") ---
class AnimatedGradientText extends StatefulWidget {
  final String text;
  final double fontSize;
  const AnimatedGradientText({
    super.key,
    required this.text,
    this.fontSize = 72,
  });

  @override
  State<AnimatedGradientText> createState() => _AnimatedGradientTextState();
}

class _AnimatedGradientTextState extends State<AnimatedGradientText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double shift = _controller.value;
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final gradientWidth = width * 2;
            final double animatedOffset = -gradientWidth * 0.5 * shift;
            return ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  colors: [
                    Color(0xFF5EB1FF), // blue
                    Color(0xFF7A5CFF), // purple
                    Color(0xFFFF6680), // pink/red
                    Color(0xFFFFA14A), // orange
                    Color(0xFFFFD166), // yellow
                    Color(0xFF4CD295), // green
                    Color(0xFF5EB1FF), // loop
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ).createShader(Rect.fromLTWH(
                  animatedOffset,
                  0,
                  gradientWidth,
                  bounds.height,
                ));
              },
              child: Text(
                widget.text,
                style: TextStyle(
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// --- HomeScreen with animated background + new title ------------------------
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  void _showPlayDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                  _buildDialogOption(
                    context,
                    'Local',
                    'Play with friends locally',
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
                    'Zen',
                    'Quick single turn',
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
                    'Online',
                    'Play from afar',
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
      },
    );
  }

  Widget _buildDialogOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
    Color color,
  ) {
    return InkWell(
      onTapDown: (_) async {
        print('$title dialog option pressed down - playing sound');

        // Check vibration setting and provide haptic feedback
        final prefs = await StorageService.loadAppPreferences();
        if (prefs['vibrationEnabled'] == true) {
          HapticFeedback.lightImpact();
        }

        unawaited(ref.read(soundServiceProvider).playButtonPress());
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Start menu music after sound service is fully initialized
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final soundService = ref.read(soundServiceProvider);
      // Wait for sound service to initialize with preferences
      await soundService.init();
      // Only play music if sound is enabled
      if (soundService.isEnabled) {
        soundService.playMenuMusic();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Stop menu music when leaving home (safety; also stopped when gameplay starts)
    // Get the sound service reference before calling super.dispose()
    try {
      final soundService = ref.read(soundServiceProvider);
      soundService.stopMenuMusic();
    } catch (e) {
      // Ignore errors if the provider is no longer accessible
      print('Could not stop menu music during dispose: $e');
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Stop music when app is not active/visible
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (mounted) {
        try {
          ref.read(soundServiceProvider).stopMenuMusic();
        } catch (e) {
          // Ignore errors if the provider is no longer accessible
          print('Could not stop menu music during lifecycle change: $e');
        }
      }
    } else if (state == AppLifecycleState.resumed) {
      // Resume music when app comes back and we're still on Home
      if (mounted) {
        try {
          final soundService = ref.read(soundServiceProvider);
          if (soundService.isEnabled) {
            soundService.playMenuMusic();
          }
        } catch (e) {
          // Ignore errors if the provider is no longer accessible
          print('Could not resume menu music during lifecycle change: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Palette aligned with the animated background hues
    const List<Color> buttonColors = [
      Color(0xFF5EB1FF), // blue
      Color(0xFF7A5CFF), // purple
      Color(0xFFFF6680), // pink/red
      Color(0xFFFFA14A), // orange
      Color(0xFF4CD295), // green
    ];

    return Scaffold(
      // Dark base so the waves pop
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Animated waves - now covers full screen
          const WaveBackground(
            strokeWidth: 1.5,
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top section - Title
                  const SizedBox(height: 30),
                  Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double width = constraints.maxWidth;
                        final double computed = width * 0.16; // 16% of width
                        final double fontSize = computed.clamp(44.0, 96.0);
                        final textStyle = GoogleFonts.kanit(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: Colors.white,
                        );
                        return Text(
                          'FREQUENCY',
                          textAlign: TextAlign.center,
                          style: textStyle,
                        );
                      },
                    ),
                  ),

                  // Middle section - Centered buttons
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MenuButton(
                          text: 'Play',
                          onPressed: () => _showPlayDialog(context),
                          color: buttonColors[0],
                        ),
                        const SizedBox(height: 16),
                        // Removed 'Stats & History' button
                        MenuButton(
                          text: 'Decks',
                          onPressed: () =>
                              GameNavigationService.navigateToDecksStore(
                                  context),
                          color: buttonColors[3],
                        ),
                        const SizedBox(height: 16),
                        MenuButton(
                          text: 'Categories',
                          onPressed: () =>
                              GameNavigationService.navigateToWordListsManager(
                                  context),
                          color: buttonColors[4 % buttonColors.length],
                        ),
                        const SizedBox(height: 16),
                        MenuButton(
                          text: 'Settings',
                          onPressed: () =>
                              GameNavigationService.navigateToSettings(context),
                          color: buttonColors[2],
                        ),
                      ],
                    ),
                  ),

                  // Bottom spacing
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
