import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../services/game_setup_provider.dart';
import '../services/game_state_provider.dart';
import '../services/game_navigation_service.dart';
import '../screens/word_lists_manager_screen.dart';
import '../widgets/game_mechanics_mixin.dart';
import '../widgets/game_header.dart';
import '../widgets/game_cards.dart';
import '../widgets/game_countdown.dart';
import '../widgets/team_color_button.dart';
import '../services/storage_service.dart';
import '../utils/category_utils.dart';

class GameScreen extends ConsumerStatefulWidget {
  final int teamIndex;
  final int roundNumber;
  final int turnNumber;
  final WordCategory category;

  // Online game parameters
  final String? sessionId;
  final String? currentTeamDeviceId;
  final Map<String, dynamic>? onlineTeam;

  const GameScreen({
    super.key,
    required this.teamIndex,
    required this.roundNumber,
    required this.turnNumber,
    required this.category,
    this.sessionId,
    this.currentTeamDeviceId,
    this.onlineTeam,
  });

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with GameMechanicsMixin<GameScreen> {
  bool _isCountdownActive = true;
  String? _currentDeviceId;
  bool _isCurrentTeamActive = false;

  @override
  WordCategory get category => widget.category;

  @override
  void onTurnEnd() {
    // Use navigation service to navigate to turn over screen
    GameNavigationService.navigateToTurnOver(
      context,
      widget.teamIndex,
      widget.roundNumber,
      widget.turnNumber,
      widget.category,
      correctCount,
      skipsLeft,
      wordsGuessed,
      wordsSkipped,
      disputedWords,
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
    if (widget.sessionId != null) {
      _getCurrentDeviceId();
    } else {
      // Local game: always active
      _isCurrentTeamActive = true;
    }

    final gameConfig = ref.read(gameSetupProvider);
    initializeGameMechanics(
        gameConfig.roundTimeSeconds, gameConfig.allowedSkips);
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

  // Get current team players safely for both local and online games
  List<String> _getCurrentTeamPlayers() {
    if (widget.sessionId != null && widget.onlineTeam != null) {
      // Online game: get team data from online team
      final players = widget.onlineTeam!['players'] as List?;
      if (players != null && players.length >= 2) {
        return players.map((p) => p.toString()).toList();
      }
      // Fallback if not enough players
      return ['Player 1', 'Player 2'];
    } else {
      // Local game: get from game state provider
      final players = ref.read(currentTeamPlayersProvider);
      if (players.length >= 2) {
        return players;
      }
      // Fallback if not enough players
      return ['Player 1', 'Player 2'];
    }
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
    // Show spectator screen for non-active teams in online games
    if (widget.sessionId != null && !_isCurrentTeamActive) {
      return _buildSpectatorScreen();
    }

    // Show actual game screen for active team or local games
    if (currentWords.isEmpty) {
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

    final gameConfig = ref.watch(gameSetupProvider);
    final colorIndex = (gameConfig.teamColorIndices.length > widget.teamIndex)
        ? gameConfig.teamColorIndices[widget.teamIndex]
        : widget.teamIndex % teamColors.length;
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
                    category: category,
                    skipsLeft: skipsLeft,
                    isTiebreaker: false,
                  ),

                  // Word cards with swiping mechanics
                  Expanded(
                    child: GameCards(
                      currentWords: currentWords,
                      category: category,
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
                  category: category,
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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.visibility,
                size: 80,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(height: 24),
              Text(
                'Spectator Mode',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: CategoryUtils.getCategoryColor(widget.category)
                      .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: CategoryUtils.getCategoryColor(widget.category),
                    width: 2,
                  ),
                ),
                child: Text(
                  CategoryUtils.getCategoryName(widget.category),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: CategoryUtils.getCategoryColor(widget.category),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Team ${widget.teamIndex + 1} is currently playing',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Round ${widget.roundNumber}, Turn ${widget.turnNumber}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Text(
                'You\'ll be able to play when it\'s your team\'s turn',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
