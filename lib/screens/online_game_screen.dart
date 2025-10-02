import 'package:convey/services/online_game_navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/game_mechanics_mixin.dart';
import '../widgets/game_header.dart';
import '../widgets/game_cards.dart';
import '../widgets/game_countdown.dart';
import '../services/sound_service.dart';
import '../widgets/team_color_button.dart';
import '../widgets/confirm_on_back.dart';
import '../widgets/quit_dialog.dart';
import '../services/storage_service.dart';
import '../data/category_registry.dart';
import '../services/firestore_service.dart';
import '../providers/session_providers.dart';

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
  bool _isTiebreakerActive = false;

  @override
  String get categoryId => widget.category;

  @override
  void onTurnEnd() {
    // Use navigation service to navigate to turn over screen
    print('onTurnEnd');
    try {
      ref.read(soundServiceProvider).playTurnEnd();
    } catch (_) {}

    final conveyor = widget.sessionData!['gameState']['currentConveyor']
        as String; // First player is conveyor
    print('conveyor: $conveyor');
    final guesser = widget.sessionData!['gameState']['currentGuesser']
        as String; // Second player is guesser
    print('guesser: $guesser');

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
      currentWords.map((w) => w.text).toList(),
      disputedWords,
      conveyor,
      guesser,
      wordTimings: wordTimings,
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
    // Ensure menu music stops when gameplay starts
    ref.read(soundServiceProvider).stopMenuMusic();

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
      _isCurrentTeamActive = _isPartOfCurrentTeam();
    });
  }

  // Check if current device is part of the current team (supports both couch and remote modes)
  bool _isPartOfCurrentTeam() {
    if (_currentDeviceId == null || widget.onlineTeam == null) {
      return false;
    }

    final teamMode = widget.onlineTeam!['teamMode'] as String? ?? 'couch';

    if (teamMode == 'couch') {
      // Couch mode: check if current device matches the team's device
      return _currentDeviceId == widget.currentTeamDeviceId;
    } else if (teamMode == 'remote') {
      // Remote mode: check if current device is in the team's devices array
      final devices = widget.onlineTeam!['devices'] as List?;
      if (devices != null) {
        return devices.any((device) => device['deviceId'] == _currentDeviceId);
      }
    }

    return false;
  }

  // Check if current device can interact with cards (only conveyor in remote mode)
  bool get _canInteractWithCards {
    if (!_isCurrentTeamActive) return false;

    final teamMode = widget.onlineTeam!['teamMode'] as String? ?? 'couch';

    if (teamMode == 'couch') {
      // Couch mode: device can always interact when it's their turn
      return true;
    } else if (teamMode == 'remote') {
      // Remote mode: only the conveyor device can interact
      final conveyorName =
          widget.sessionData?['gameState']?['currentConveyor'] as String?;
      if (conveyorName == null) return false;

      // Find which device belongs to the conveyor
      final devices = widget.onlineTeam!['devices'] as List?;
      if (devices != null) {
        for (final device in devices) {
          if (device['deviceId'] == _currentDeviceId &&
              device['playerName'] == conveyorName) {
            return true;
          }
        }
      }
    }

    return false;
  }

  // Get current player's name from device (for remote teams)
  String? _getMyPlayerName() {
    if (_currentDeviceId == null || widget.onlineTeam == null) return null;

    final teamMode = widget.onlineTeam!['teamMode'] as String? ?? 'couch';
    if (teamMode != 'remote') return null;

    final devices = widget.onlineTeam!['devices'] as List?;
    if (devices != null) {
      for (final device in devices) {
        if (device['deviceId'] == _currentDeviceId) {
          return device['playerName'] as String?;
        }
      }
    }
    return null;
  }

  // Get game configuration for both local and online games
  Map<String, dynamic> _getGameConfig() {
    // Online game: get configuration from session data
    final settings = widget.sessionData!['settings'] as Map<String, dynamic>?;
    if (settings != null) {
      final gameState =
          widget.sessionData!['gameState'] as Map<String, dynamic>?;
      final tiebreaker = gameState != null
          ? (gameState['tiebreaker'] as Map<String, dynamic>?)
          : null;
      _isTiebreakerActive = tiebreaker?['active'] == true;

      final int baseTime = settings['roundTimeSeconds'] as int? ?? 60;
      final int tieTime =
          settings['tiebreakerTimeSeconds'] as int? ?? (baseTime ~/ 2);

      return {
        'roundTimeSeconds': _isTiebreakerActive ? tieTime : baseTime,
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
    // Reset word timings so countdown time isn't counted
    resetWordTimings();
    // Resume timer when countdown completes
    resumeTimer();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sessionStatusProvider(widget.sessionId!), (prev, next) {
      final status = next.value;
      if (status != null) {
        OnlineGameNavigationService.handleNavigation(
          context: context,
          ref: ref,
          sessionId: widget.sessionId!,
          status: status,
        );
      }
    });

    // Show spectator screen for non-active teams or guessers in remote mode
    if (!_isCurrentTeamActive || !_canInteractWithCards) {
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
              SizedBox(height: 17),
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

    return ConfirmOnBack(
      dialogBuilder: (ctx) => QuitDialog(color: teamColor),
      onConfirmed: (ctx) async {
        await OnlineGameNavigationService.leaveSessionAndGoHome(
          context: ctx,
          ref: ref,
          sessionId: widget.sessionId,
        );
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
                    isTiebreaker: _isTiebreakerActive,
                  ),

                  // Word cards with swiping mechanics
                  Expanded(
                    child: GameCards(
                      currentWords: currentWords,
                      categoryId: categoryId,
                      skipsLeft: skipsLeft,
                      showBlankCards: _isCountdownActive,
                      onWordGuessed: (word) {
                        if (!_isCountdownActive && _canInteractWithCards) {
                          handleWordGuessed(word);
                        }
                      },
                      onWordSkipped: (word) {
                        if (!_isCountdownActive && _canInteractWithCards) {
                          handleWordSkipped(word);
                        }
                      },
                      onLoadNewWord: (index) {
                        if (!_isCountdownActive && _canInteractWithCards) {
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
    // Determine if this is a guesser or non-active team spectator
    final isGuesser = _isCurrentTeamActive && !_canInteractWithCards;
    final myPlayerName = _getMyPlayerName();
    final conveyorName =
        widget.sessionData?['gameState']?['currentConveyor'] as String?;
    final guesserName =
        widget.sessionData?['gameState']?['currentGuesser'] as String?;

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
                        // Role-specific icon
                        Icon(
                          isGuesser ? Icons.psychology : Icons.visibility,
                          size: constraints.maxWidth * 0.2, // Responsive size
                          color: isGuesser
                              ? Colors.blue
                              : Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(height: 24),
                        // Role-specific title
                        Text(
                          isGuesser ? 'You are the RECEIVER' : 'Spectator Mode',
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isGuesser ? Colors.blue : null,
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
                        // Team and role info
                        if (isGuesser) ...[
                          Text(
                            'Your teammate $conveyorName is conveying the words',
                            style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                        ] else ...[
                          Text(
                            '${widget.onlineTeam!['teamName'] ?? 'Team ${widget.teamIndex + 1}'} is currently playing',
                            style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 8),
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
