import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/game_navigation_service.dart';
import '../widgets/wave_background.dart';
import '../widgets/menu_button.dart';
import '../widgets/team_color_button.dart';
import '../widgets/game_mode_dialog.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../services/developer_service.dart';
import '../services/game_state_provider.dart';
import '../models/game_state.dart';
import '../models/game_config.dart';
import 'background_lab_screen.dart';
import 'how_to_play_screen.dart';
import 'game_over_screen.dart';

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
  int _titleTapCount = 0;
  bool _isDeveloperModeEnabled = false;
  Timer? _tapResetTimer;
  void _handleTitleTap() async {
    _titleTapCount++;

    // Reset tap count after 3 seconds of inactivity
    _tapResetTimer?.cancel();
    _tapResetTimer = Timer(const Duration(seconds: 3), () {
      _titleTapCount = 0;
    });

    // Check if we've reached 7 taps
    if (_titleTapCount >= 7) {
      _titleTapCount = 0;
      _tapResetTimer?.cancel();
      _showDeveloperPasswordDialog(context);
    }
  }

  void _showDeveloperPasswordDialog(BuildContext context) {
    final TextEditingController passwordController = TextEditingController();

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
                  // Dialog title
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      'Developer Mode',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Password input
                  Text(
                    'Enter developer password:',
                    style: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      filled: true,
                      fillColor: Colors.grey.shade800,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade600),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade600),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: const Color(0xFF5EB1FF), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (value) =>
                        _verifyDeveloperPassword(context, value),
                  ),
                  const SizedBox(height: 24),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTapDown: (_) async {
                            // Check vibration setting and provide haptic feedback
                            final prefs =
                                await StorageService.loadAppPreferences();
                            if (prefs['vibrationEnabled'] == true) {
                              HapticFeedback.lightImpact();
                            }
                            unawaited(ref
                                .read(soundServiceProvider)
                                .playButtonPress());
                          },
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade700.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.grey.shade600, width: 2),
                            ),
                            child: Text(
                              'Cancel',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Colors.grey.shade300,
                                    fontWeight: FontWeight.w600,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTapDown: (_) async {
                            // Check vibration setting and provide haptic feedback
                            final prefs =
                                await StorageService.loadAppPreferences();
                            if (prefs['vibrationEnabled'] == true) {
                              HapticFeedback.lightImpact();
                            }
                            unawaited(ref
                                .read(soundServiceProvider)
                                .playButtonPress());
                          },
                          onTap: () => _verifyDeveloperPassword(
                              context, passwordController.text),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5EB1FF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFF5EB1FF), width: 2),
                            ),
                            child: Text(
                              'Enter',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: const Color(0xFF5EB1FF),
                                    fontWeight: FontWeight.w600,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _verifyDeveloperPassword(BuildContext context, String password) async {
    final isValid = await DeveloperService.verifyPassword(password);

    Navigator.of(context).pop();

    if (isValid) {
      await DeveloperService.enableDeveloperMode();
      setState(() {
        _isDeveloperModeEnabled = true;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Developer mode activated!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid password'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showTestPurchaseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: Text(
            'Test Purchase',
            style: TextStyle(color: Colors.green),
          ),
          content: Text(
            'This is a developer-only feature to test purchase flows.',
            style: TextStyle(color: Colors.grey.shade300),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(color: Colors.grey.shade400),
              ),
            ),
          ],
        );
      },
    );
  }

  void _disableDeveloperMode(BuildContext context) async {
    await DeveloperService.disableDeveloperMode();
    setState(() {
      _isDeveloperModeEnabled = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Developer mode disabled'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _navigateToMockGameOver(BuildContext context) {
    // Create mock game config and initialize
    final mockConfig = _createMockGameConfig();
    ref.read(gameStateProvider.notifier).initializeGame(mockConfig);

    // Add all the turn history
    final turnHistory = _createMockTurnHistory();
    for (final turn in turnHistory) {
      ref.read(gameStateProvider.notifier).recordTurn(turn);
    }

    // Navigate to game over screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const GameOverScreen(),
      ),
    );
  }

  GameConfig _createMockGameConfig() {
    // Create mock teams
    final teams = [
      ['Alice', 'Bob'],
      ['Charlie', 'Diana'],
      ['Eve', 'Frank'],
      ['Grace', 'Henry'],
    ];

    // Create mock game config
    return GameConfig(
      playerNames: teams.expand((team) => team).toList(),
      teams: teams,
      teamColorIndices: [0, 1, 2, 3],
      roundTimeSeconds: 60,
      targetScore: 30,
      allowedSkips: 2,
      useWeightedWordSelection: true,
    );
  }

  List<TurnRecord> _createMockTurnHistory() {
    // Create mock teams
    final teams = [
      ['Alice', 'Bob'],
      ['Charlie', 'Diana'],
      ['Eve', 'Frank'],
      ['Grace', 'Henry'],
    ];

    // Create mock turn history with lots of data
    final turnHistory = <TurnRecord>[];
    final categories = [
      'People',
      'Actions',
      'Places',
      'Things',
      'Movies',
      'Food'
    ];
    final words = [
      'Albert Einstein',
      'Marilyn Monroe',
      'Leonardo da Vinci',
      'Oprah Winfrey',
      'Running',
      'Swimming',
      'Cooking',
      'Dancing',
      'Singing',
      'Painting',
      'Paris',
      'Tokyo',
      'New York',
      'London',
      'Sydney',
      'Rome',
      'Smartphone',
      'Laptop',
      'Car',
      'Book',
      'Guitar',
      'Camera',
      'Inception',
      'Titanic',
      'Avatar',
      'Star Wars',
      'The Matrix',
      'Frozen',
      'Pizza',
      'Sushi',
      'Burger',
      'Pasta',
      'Tacos',
      'Ice Cream'
    ];

    // Generate 25+ turns with varied performance
    for (int i = 0; i < 28; i++) {
      final teamIndex = i % teams.length;
      final roundNumber = (i ~/ teams.length) + 1;
      final turnNumber = (i % teams.length) + 1;
      final category = categories[i % categories.length];
      final conveyor = teams[teamIndex][0];
      final guesser = teams[teamIndex][1];

      // Vary performance to create interesting insights
      int score;
      int skipsUsed;
      List<String> wordsGuessed = [];
      List<String> wordsSkipped = [];
      Map<String, double> wordTimings = {};

      if (i < 5) {
        // Early turns - mixed performance
        score = [3, 5, 2, 4, 6][i];
        skipsUsed = [1, 0, 2, 1, 0][i];
      } else if (i < 15) {
        // Middle turns - some teams excel
        if (teamIndex == 0) {
          score = 7 + (i % 3); // Alice & Bob excel
          skipsUsed = 0;
        } else if (teamIndex == 2) {
          score = 2 + (i % 2); // Eve & Frank struggle
          skipsUsed = 2;
        } else {
          score = 4 + (i % 3);
          skipsUsed = 1;
        }
      } else {
        // Late turns - comeback stories
        if (teamIndex == 2) {
          score = 8 + (i % 2); // Eve & Frank comeback
          skipsUsed = 0;
        } else if (teamIndex == 1) {
          score = 3 + (i % 2); // Charlie & Diana decline
          skipsUsed = 2;
        } else {
          score = 5 + (i % 3);
          skipsUsed = 1;
        }
      }

      // Generate words for this turn
      final availableWords = List<String>.from(words);
      availableWords.shuffle();

      int wordsToGuess = score;
      int wordsToSkip = skipsUsed;

      for (int j = 0; j < wordsToGuess && j < availableWords.length; j++) {
        wordsGuessed.add(availableWords[j]);
        // Create realistic timing data (0.5s to 8s)
        wordTimings[availableWords[j]] = 0.5 + (j * 0.8) + (i % 3) * 0.5;
      }

      for (int j = wordsToGuess;
          j < wordsToGuess + wordsToSkip && j < availableWords.length;
          j++) {
        wordsSkipped.add(availableWords[j]);
        // Longer hesitation for skipped words (3s to 12s)
        wordTimings[availableWords[j]] = 3.0 + (j * 1.2) + (i % 4) * 0.8;
      }

      turnHistory.add(TurnRecord(
        teamIndex: teamIndex,
        roundNumber: roundNumber,
        turnNumber: turnNumber,
        conveyor: conveyor,
        guesser: guesser,
        category: category,
        score: score,
        skipsUsed: skipsUsed,
        wordsGuessed: wordsGuessed,
        wordsSkipped: wordsSkipped,
        wordTimings: wordTimings,
      ));
    }

    return turnHistory;
  }

  void _showPlayDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => const GameModeDialog(),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Check developer mode status
    _checkDeveloperModeStatus();
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

  void _checkDeveloperModeStatus() async {
    final isEnabled = await DeveloperService.isDeveloperModeEnabled();
    if (mounted) {
      setState(() {
        _isDeveloperModeEnabled = isEnabled;
      });
    }
  }

  @override
  void dispose() {
    _tapResetTimer?.cancel();
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
                        final double computed = width * 0.15; // 16% of width
                        final double fontSize = computed.clamp(44.0, 96.0);
                        final textStyle = GoogleFonts.kanit(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: Colors.white,
                        );
                        return FittedBox(
                          fit: BoxFit.scaleDown,
                          child: GestureDetector(
                            onTap: _handleTitleTap,
                            child: Text(
                              'FREQUENCY',
                              textAlign: TextAlign.center,
                              style: textStyle,
                              maxLines: 1,
                              softWrap: false,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Middle section - Centered buttons
                  Expanded(
                    child: _isDeveloperModeEnabled
                        ? SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 20),
                                _buildMainButtons(),
                                const SizedBox(height: 20),
                                _buildDeveloperButtons(),
                                const SizedBox(height: 20),
                              ],
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildMainButtons(),
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

  Widget _buildMainButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TeamColorButton(
          text: 'Play',
          color: uiColors[0], // Blue
          onPressed: () => _showPlayDialog(context),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          opacity: 0.3,
          borderWidth: 2.0,
        ),
        const SizedBox(height: 16),
        TeamColorButton(
          text: 'Decks',
          color: teamColors[4], // Coral
          onPressed: () => GameNavigationService.navigateToDecksStore(context),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          opacity: 0.3,
          borderWidth: 2.0,
        ),
        const SizedBox(height: 16),
        TeamColorButton(
          text: 'How To Play',
          color: teamColors[1], // Indigo
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const HowToPlayScreen(),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          opacity: 0.3,
          borderWidth: 2.0,
        ),
        const SizedBox(height: 16),
        TeamColorButton(
          text: 'Settings',
          color: uiColors[2], // Red
          onPressed: () => GameNavigationService.navigateToSettings(context),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          opacity: 0.3,
          borderWidth: 2.0,
        ),
      ],
    );
  }

  Widget _buildDeveloperButtons() {
    const List<Color> buttonColors = [
      Color(0xFF5EB1FF), // blue
      Color(0xFF7A5CFF), // purple
      Color(0xFFFF6680), // pink/red
      Color(0xFFFFA14A), // orange
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Colors.grey.shade600,
                Colors.transparent,
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'DEVELOPER MODE',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
        ),
        const SizedBox(height: 12),
        MenuButton(
          text: 'Categories',
          onPressed: () =>
              GameNavigationService.navigateToWordListsManager(context),
          color: buttonColors[5 % buttonColors.length],
        ),
        const SizedBox(height: 8),
        MenuButton(
          text: 'Test Purchase',
          onPressed: () => _showTestPurchaseDialog(context),
          color: Colors.green,
        ),
        const SizedBox(height: 8),
        MenuButton(
          text: 'Background Lab',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BackgroundLabScreen(),
            ),
          ),
          color: Colors.purple,
        ),
        const SizedBox(height: 8),
        MenuButton(
          text: 'Test Insights',
          onPressed: () => _navigateToMockGameOver(context),
          color: Colors.cyan,
        ),
        const SizedBox(height: 8),
        MenuButton(
          text: 'Disable Dev Mode',
          onPressed: () => _disableDeveloperMode(context),
          color: Colors.orange,
        ),
      ],
    );
  }
}
