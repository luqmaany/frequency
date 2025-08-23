import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show GestureTapDownCallback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import '../services/game_navigation_service.dart';
import '../services/game_state_provider.dart';
import '../models/game_state.dart';
import '../models/game_config.dart';
import 'game_over_screen.dart';
import 'online_lobby_screen.dart';
import '../widgets/wave_background.dart';
import '../services/sound_service.dart';
import 'zen_setup_screen.dart';
import '../services/transition_service.dart';
import 'mock_game_screen.dart';

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
  AppTransitionStyle _selectedStyle = AppTransitionStyle.material;
  Offset? _revealCenterFraction;

  void _startMockEndgame(BuildContext context) {
    final notifier = ref.read(gameStateProvider.notifier);
    // Build a complex config with 4 teams and target score reached
    final config = GameConfig(
      playerNames: [
        'Alice',
        'Bob',
        'Cara',
        'Dan',
        'Eve',
        'Finn',
        'Gigi',
        'Hank'
      ],
      teams: [
        ['Alice', 'Bob'],
        ['Cara', 'Dan'],
        ['Eve', 'Finn'],
        ['Gigi', 'Hank'],
      ],
      teamColorIndices: [0, 1, 2, 3],
      roundTimeSeconds: 60,
      targetScore: 50,
      allowedSkips: 3,
    );
    notifier.initializeGame(config);

    final Random rng = Random(42);
    int turnNumber = 1;
    // Simulate 8 rounds x 4 teams = 32 turns with variety to trigger insights
    for (int roundNumber = 1; roundNumber <= 8; roundNumber++) {
      for (int teamIndex = 0; teamIndex < config.teams.length; teamIndex++) {
        final i = (roundNumber - 1) * config.teams.length + teamIndex;
        final conveyor = config.teams[teamIndex][0];
        final guesser = config.teams[teamIndex][1];
        final category = 'Category ${(i % 5) + 1}';
        final skips = rng.nextInt(3);
        int score = 2 + rng.nextInt(9) - (skips > 1 ? 2 : 0);
        final words =
            List<String>.generate(3 + rng.nextInt(4), (k) => 'W${i}_$k');
        final skipped = List<String>.generate(skips, (k) => 'S${i}_$k');

        // On the final round's first team, ensure target is crossed by team 0
        if (roundNumber == 8 && teamIndex == 0) {
          final gs = ref.read(gameStateProvider);
          final current = gs?.teamScores[0] ?? 0;
          final need = max(0, config.targetScore - current + 5);
          score = max(score, need);
        }

        notifier.recordTurn(TurnRecord(
          teamIndex: teamIndex,
          roundNumber: roundNumber,
          turnNumber: turnNumber,
          conveyor: conveyor,
          guesser: guesser,
          category: category,
          score: score.clamp(0, 20),
          skipsUsed: skips,
          wordsGuessed: words,
          wordsSkipped: skipped,
        ));
      }
      turnNumber++;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GameOverScreen()),
    );
  }

  void _navigateToMockWithTransition(BuildContext context) {
    Navigator.of(context).push(
      TransitionService.buildRoute(
        const MockGameScreen(title: 'Mock Game (Transition Demo)'),
        style: _selectedStyle,
        revealCenterFraction: _revealCenterFraction,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Start menu music
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(soundServiceProvider).playMenuMusic();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Stop menu music when leaving home (safety; also stopped when gameplay starts)
    ref.read(soundServiceProvider).stopMenuMusic();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Stop music when app is not active/visible
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      ref.read(soundServiceProvider).stopMenuMusic();
    } else if (state == AppLifecycleState.resumed) {
      // Resume music when app comes back and we're still on Home
      ref.read(soundServiceProvider).playMenuMusic();
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
          // Animated waves
          const Positioned.fill(
              child: WaveBackground(
            strokeWidth: 1.5,
          )),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                    const SizedBox(height: 24),
                    _buildMenuButton(
                      context,
                      'Start Game',
                      () => GameNavigationService.navigateToGameSetup(context),
                      buttonColors[0],
                    ),
                    const SizedBox(height: 16),
                    // Transition tester controls
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Transition Style',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 8),
                          DropdownButton<AppTransitionStyle>(
                            value: _selectedStyle,
                            dropdownColor: Colors.grey.shade900,
                            iconEnabledColor: Colors.white70,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(
                                value: AppTransitionStyle.material,
                                child: Text('Material (default)'),
                              ),
                              DropdownMenuItem(
                                value: AppTransitionStyle.fade,
                                child: Text('Fade'),
                              ),
                              DropdownMenuItem(
                                value: AppTransitionStyle.slideFromRight,
                                child: Text('Slide from right'),
                              ),
                              DropdownMenuItem(
                                value: AppTransitionStyle.slideFromBottom,
                                child: Text('Slide from bottom'),
                              ),
                              DropdownMenuItem(
                                value: AppTransitionStyle.scale,
                                child: Text('Scale'),
                              ),
                              DropdownMenuItem(
                                value: AppTransitionStyle.rotation,
                                child: Text('Rotation + fade'),
                              ),
                              DropdownMenuItem(
                                value: AppTransitionStyle.circularReveal,
                                child: Text('Circular reveal'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedStyle = value;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 8),
                          _buildMenuButton(
                            context,
                            'Open Mock Game (Test Transition)',
                            () => _navigateToMockWithTransition(context),
                            buttonColors[2],
                            onTapDown: (details) {
                              final size = MediaQuery.of(context).size;
                              final dx =
                                  (details.globalPosition.dx / size.width)
                                      .clamp(0.0, 1.0);
                              final dy =
                                  (details.globalPosition.dy / size.height)
                                      .clamp(0.0, 1.0);
                              setState(() {
                                _revealCenterFraction = Offset(dx, dy);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMenuButton(
                      context,
                      'Zen Mode',
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ZenSetupScreen(),
                          ),
                        );
                      },
                      buttonColors[1],
                    ),
                    const SizedBox(height: 16),
                    _buildMenuButton(
                      context,
                      'Online',
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
                    // Removed 'Stats & History' button
                    _buildMenuButton(
                      context,
                      'Decks',
                      () => GameNavigationService.navigateToDecksStore(context),
                      buttonColors[3],
                    ),
                    const SizedBox(height: 16),
                    _buildMenuButton(
                      context,
                      'Categories',
                      () => GameNavigationService.navigateToWordListsManager(
                          context),
                      buttonColors[4 % buttonColors.length],
                    ),
                    const SizedBox(height: 16),
                    _buildMenuButton(
                      context,
                      'Settings',
                      () => GameNavigationService.navigateToSettings(context),
                      buttonColors[2],
                    ),
                    const SizedBox(height: 16),
                    _buildMenuButton(
                      context,
                      'Mock Big Game (Insights)',
                      () => _startMockEndgame(context),
                      buttonColors[0],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(
      BuildContext context, String text, VoidCallback onPressed, Color color,
      {GestureTapDownCallback? onTapDown}) {
    final HSLColor hsl = HSLColor.fromColor(color);
    final double darkerLightness = (hsl.lightness * 0.25).clamp(0.0, 1.0);
    final Color buttonColor = hsl.withLightness(darkerLightness).toColor();
    final Color borderColor = color.withOpacity(0.7);
    const Color textColor = Color(0xFFE6EEF8);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTapDown: onTapDown,
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 2.0),
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
