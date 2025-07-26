import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game_navigation_service.dart';
import 'online_lobby_screen.dart';

// Animated gradient text widget for the title
class AnimatedGradientText extends StatefulWidget {
  final String text;
  final double fontSize;
  const AnimatedGradientText(
      {super.key, required this.text, this.fontSize = 72});

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
      duration: const Duration(seconds: 8), // Slow animation
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
            // The gradient will be 2x the width of the text, so it can flow through and loop seamlessly
            final gradientWidth = width * 2;
            // Animate from 0 to half the gradient width for a seamless loop
            final double animatedOffset = -gradientWidth * 0.5 * shift;
            return ShaderMask(
              shaderCallback: (Rect bounds) {
                return LinearGradient(
                  colors: const [
                    Colors.blue,
                    Colors.purple,
                    Colors.pink,
                    Colors.orange,
                    Colors.yellow,
                    Colors.green,
                    Colors.blue,
                    Colors.purple,
                    Colors.pink,
                    Colors.orange,
                    Colors.yellow,
                    Colors.green,
                    Colors.blue, // repeat for seamless loop
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ).createShader(
                  Rect.fromLTWH(
                      animatedOffset, 0, gradientWidth, bounds.height),
                );
              },
              child: Text(
                widget.text,
                style: TextStyle(
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.bold,
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

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Define a list of colors for the buttons
    final List<Color> buttonColors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Color picker removed
              const SizedBox(height: 30),
              const Center(
                child: AnimatedGradientText(
                  text: 'Convey',
                  fontSize: 72,
                ),
              ),

              const SizedBox(height: 48),
              _buildMenuButton(
                context,
                'Start Game',
                Icons.play_arrow_rounded,
                () => GameNavigationService.navigateToGameSetup(context),
                buttonColors[0],
              ),
              const SizedBox(height: 16),
              // --- Online Button ---
              _buildMenuButton(
                context,
                'Online',
                Icons.public_rounded,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const OnlineLobbyScreen(),
                    ),
                  );
                },
                buttonColors.length > 5
                    ? buttonColors[5 % buttonColors.length]
                    : buttonColors[1],
              ),
              const SizedBox(height: 16),
              // Removed Last Game Recap button
              _buildMenuButton(
                context,
                'Stats & History',
                Icons.bar_chart_rounded,
                () {
                  // TODO: Implement stats & history
                },
                buttonColors[4],
              ),
              const SizedBox(height: 16),
              _buildMenuButton(
                context,
                'Word Lists Manager',
                Icons.list_alt_rounded,
                () => GameNavigationService.navigateToWordListsManager(context),
                buttonColors[3],
              ),
              const SizedBox(height: 16),
              _buildMenuButton(
                context,
                'Settings',
                Icons.settings_rounded,
                () => GameNavigationService.navigateToSettings(context),
                buttonColors[2],
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
    Color color,
  ) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color buttonColor = color.withOpacity(0.35);
    final Color borderColor = isDark ? color.withOpacity(0.7) : color;
    final Color iconColor = borderColor;
    final Color textColor = isDark ? const Color(0xFFE0E0E0) : Colors.black;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: borderColor.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: iconColor),
              const SizedBox(width: 12),
              Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
