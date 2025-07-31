import 'package:convey/services/online_game_navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/game_mechanics_mixin.dart';
import '../widgets/game_header.dart';
import '../widgets/game_cards.dart';
import '../widgets/game_countdown.dart';
import '../widgets/team_color_button.dart';
import '../services/storage_service.dart';
import '../data/category_registry.dart';
import '../services/firestore_service.dart';

class OnlineGameScreen extends ConsumerStatefulWidget {
  final int teamIndex;
  final int roundNumber;
  final int turnNumber;
  final String category;

  // Online game parameters
  final String? sessionId;
  final String? currentTeamDeviceId;
  final Map<String, dynamic>? onlineTeam;
  final Map<String, dynamic>? sessionData;

  const OnlineGameScreen({
    super.key,
    required this.teamIndex,
    required this.roundNumber,
    required this.turnNumber,
    required this.category,
    this.sessionId,
    this.currentTeamDeviceId,
    this.onlineTeam,
    this.sessionData,
  });

  @override
  ConsumerState<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends ConsumerState<OnlineGameScreen>
    with GameMechanicsMixin<OnlineGameScreen> {
  bool _isCountdownActive = true;
  String? _currentDeviceId;
  bool _isCurrentTeamActive = false;

  @override
  String get categoryId => widget.category;

  @override
  void onTurnEnd() {
    // Use navigation service to navigate to turn over screen
    print('onTurnEnd');

    // Get the current team players for conveyor and guesser
    final teamPlayers = _getCurrentTeamPlayers();
    final conveyor = teamPlayers[0]; // First player is conveyor
    final guesser = teamPlayers[1]; // Second player is guesser

    FirestoreService.fromGameScreen(
      widget.sessionId!,
      widget.teamIndex,
      widget.roundNumber,
      widget.turnNumber,
      widget.category,
      correctCount,
      skipsLeft,
      wordsGuessed,
      wordsSkipped,
      disputedWords,
      conveyor,
      guesser,
    );
  }

  @override
  void onWordGuessed(String word) {
    // Word usage is handled in the GameCards widget
  }

  @override
  void onWordSkipped(String word) {
    // Skip logic is handled in the GameCards widget
  }

  @override
  void initState() {
    super.initState();

    // Get current device ID for online games
    _getCurrentDeviceId();

    final gameConfig = _getGameConfig();

    initializeGameMechanics(gameConfig['roundTimeSeconds'] as int,
        gameConfig['allowedSkips'] as int);
    loadInitialWords();

    // Pause timer during countdown
    pauseTimer();
  }

  Future<void> _getCurrentDeviceId() async {
    final deviceId = await StorageService.getDeviceId();
    setState(() {
      _currentDeviceId = deviceId;
      _isCurrentTeamActive = _currentDeviceId == widget.currentTeamDeviceId;
    });
  }

  // Get game configuration for both local and online games
  Map<String, dynamic> _getGameConfig() {
    // Online game: get configuration from session data
    final settings = widget.sessionData!['settings'] as Map<String, dynamic>?;
    if (settings != null) {
      return {
        'roundTimeSeconds': settings['roundTimeSeconds'] as int? ?? 60,
        'allowedSkips': settings['allowedSkips'] as int? ?? 3,
      };
    }
    // Fallback to default values if settings not found
    return {
      'roundTimeSeconds': 60,
      'allowedSkips': 3,
    };
  }

  // Get current team players safely for both local and online games
  List<String> _getCurrentTeamPlayers() {
    // Online game: get team data from online team
    final players = widget.onlineTeam!['players'] as List?;
    if (players != null && players.length == 2) {
      return players.map((p) => p.toString()).toList();
    }
    // Fallback if not enough players
    return ['Player 1 error', 'Player 2 error'];
  }

  @override
  void dispose() {
    disposeGameMechanics();
    super.dispose();
  }

  void _onCountdownComplete() {
    setState(() {
      _isCountdownActive = false;
    });
    // Resume timer when countdown completes
    resumeTimer();
  }

  @override
  Widget build(BuildContext context) {
    OnlineGameNavigationService.navigate(
      context: context,
      ref: ref,
      sessionId: widget.sessionId!,
    );

    // Show spectator screen for non-active teams in online games
    if (!_isCurrentTeamActive) {
      return _buildSpectatorScreen();
    }

    // Show actual game screen for active team or local games
    if (currentWords.isEmpty) {
      // If no words are available, end the turn immediately
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onTurnEnd();
      });
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sentiment_dissatisfied,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No more words available!',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'All words in this category have been used.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    int colorIndex;
    // Online game: use the provided color index
    colorIndex = widget.onlineTeam!['colorIndex'] as int? ?? 0;

    final teamColor = teamColors[colorIndex];

    return WillPopScope(
      onWillPop: () async {
        final shouldQuit = await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (context) => Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).dialogBackgroundColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: teamColor.border, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: teamColor.border, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Quit Game?',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: teamColor.text,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You sure you want to be a quitter?',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: TeamColorButton(
                          text: 'Cancel',
                          icon: Icons.close,
                          color: teamColor,
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TeamColorButton(
                          text: 'Quit',
                          icon: Icons.exit_to_app,
                          color: teamColor,
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
        return shouldQuit == true;
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // Title showing current players
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "${_getCurrentTeamPlayers()[0]} & ${_getCurrentTeamPlayers()[1]}'s Turn",
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Game header with timer, category, and skips
                  GameHeader(
                    timeLeft: timeLeft,
                    categoryId: categoryId,
                    skipsLeft: skipsLeft,
                    isTiebreaker: false,
                  ),

                  // Word cards with swiping mechanics
                  Expanded(
                    child: GameCards(
                      currentWords: currentWords,
                      categoryId: categoryId,
                      skipsLeft: skipsLeft,
                      showBlankCards: _isCountdownActive,
                      onWordGuessed: (word) {
                        if (!_isCountdownActive) {
                          handleWordGuessed(word);
                        }
                      },
                      onWordSkipped: (word) {
                        if (!_isCountdownActive) {
                          handleWordSkipped(word);
                        }
                      },
                      onLoadNewWord: (index) {
                        if (!_isCountdownActive) {
                          // Load new word for the specific card that was swiped
                          loadNewWord(index);
                        }
                      },
                    ),
                  ),
                ],
              ),

              // Countdown overlay
              if (_isCountdownActive)
                GameCountdown(
                  player1Name: _getCurrentTeamPlayers()[0],
                  player2Name: _getCurrentTeamPlayers()[1],
                  categoryId: categoryId,
                  onCountdownComplete: _onCountdownComplete,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpectatorScreen() {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(),
                        // Spectator icon
                        Icon(
                          Icons.visibility,
                          size: constraints.maxWidth * 0.2, // Responsive size
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(height: 24),
                        // Spectator mode title
                        Text(
                          'Spectator Mode',
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        // Category display
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: CategoryRegistry.getCategory(widget.category)
                                .color
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  CategoryRegistry.getCategory(widget.category)
                                      .color,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            CategoryRegistry.getCategory(widget.category)
                                .displayName,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: CategoryRegistry.getCategory(
                                          widget.category)
                                      .color,
                                  fontWeight: FontWeight.w600,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Team info
                        Text(
                          '${widget.onlineTeam!['teamName'] ?? 'Team ${widget.teamIndex + 1}'} is currently playing',
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Round ${widget.roundNumber}, Turn ${widget.turnNumber}',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        // Info message
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceVariant
                                .withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            'You\'ll be able to play when it\'s your team\'s turn',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.7),
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
