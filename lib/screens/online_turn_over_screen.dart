import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game_setup_provider.dart';
import '../services/game_state_provider.dart';
import '../services/game_navigation_service.dart';
import '../models/game_state.dart';
import '../data/category_registry.dart';
import '../providers/category_provider.dart';
import 'package:convey/widgets/team_color_button.dart';
import '../services/firestore_service.dart';
import '../services/online_game_navigation_service.dart';
import '../services/storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class OnlineTurnOverScreen extends ConsumerStatefulWidget {
  final int teamIndex;
  final int roundNumber;
  final int turnNumber;
  final String category;
  final int correctCount;
  final int skipsLeft;
  final List<String> wordsGuessed;
  final List<String> wordsSkipped;
  final Set<String> disputedWords;
  final String? conveyor;
  final String? guesser;

  // Online game parameters
  final String? sessionId;
  final Map<String, dynamic>? sessionData;

  const OnlineTurnOverScreen({
    super.key,
    required this.teamIndex,
    required this.roundNumber,
    required this.turnNumber,
    required this.category,
    required this.correctCount,
    required this.skipsLeft,
    required this.wordsGuessed,
    required this.wordsSkipped,
    required this.disputedWords,
    this.conveyor,
    this.guesser,
    this.sessionId,
    this.sessionData,
  });

  @override
  ConsumerState<OnlineTurnOverScreen> createState() =>
      _OnlineTurnOverScreenState();
}

class _OnlineTurnOverScreenState extends ConsumerState<OnlineTurnOverScreen> {
  Set<String> _disputedWords = {};
  List<int> _confirmedTeams = [];
  int _currentTeamIndex = 0;
  bool _isCurrentTeamActive = false;
  String? _currentDeviceId;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _turnOverStateSubscription;

  static const List<Map<String, String>> _highScoreMessages = [
    {'text': 'You\'re the dynamic duo of word games!', 'emoji': '🦸‍♂️'},
    {
      'text': 'Like Batman and Robin, but with better communication!',
      'emoji': '🦇'
    },
    {
      'text': 'You two are the word game equivalent of a perfect handshake!',
      'emoji': '🤝'
    },
    {
      'text': 'More coordinated than a synchronized dance routine!',
      'emoji': '💃'
    },
    {'text': 'You\'re like a well-tuned word orchestra!', 'emoji': '🎻'},
  ];

  static const List<Map<String, String>> _lowScoreMessages = [
    {'text': 'Well... at least you tried!', 'emoji': '🤷'},
    {'text': 'Like two ships passing in the night...', 'emoji': '🚢'},
    {'text': 'You two are like a broken telephone game!', 'emoji': '📞'},
    {
      'text': 'More confused than a cat in a room full of rocking chairs!',
      'emoji': '😺'
    },
    {
      'text': 'Like trying to solve a Rubik\'s cube in the dark!',
      'emoji': '🎲'
    },
  ];

  static const List<Map<String, String>> _zeroScoreMessages = [
    {
      'text':
          'Not a single word guessed! The conveyor must be playing charades instead!',
      'emoji': '🎭'
    },
    {
      'text': 'Zero points! Did the conveyor forget how to speak?',
      'emoji': '🤐'
    },
    {
      'text': 'The guesser\'s mind-reading skills need some serious work!',
      'emoji': '🧠'
    },
    {'text': 'Maybe try using actual words next time?', 'emoji': '📝'},
    {
      'text': 'The conveyor and guesser must be speaking different languages!',
      'emoji': '🌍'
    },
  ];

  @override
  void initState() {
    super.initState();
    _disputedWords = Set.from(widget.disputedWords);

    // Get current device ID and set up online game state
    _getCurrentDeviceId();

    // Listen to turn over state changes
    if (widget.sessionId != null) {
      _listenToTurnOverState();
    }
  }

  Future<void> _getCurrentDeviceId() async {
    final deviceId = await StorageService.getDeviceId();
    setState(() {
      _currentDeviceId = deviceId;
    });
  }

  void _listenToTurnOverState() {
    if (widget.sessionId == null) return;

    _turnOverStateSubscription = FirebaseFirestore.instance
        .collection('sessions')
        .doc(widget.sessionId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final gameState = data['gameState'] as Map<String, dynamic>?;
      final turnOverState =
          gameState?['turnOverState'] as Map<String, dynamic>?;

      if (turnOverState != null) {
        final disputedWords =
            List<String>.from(turnOverState['disputedWords'] as List? ?? []);
        final confirmedTeams =
            List<int>.from(turnOverState['confirmedTeams'] as List? ?? []);
        final currentTeamIndex = turnOverState['currentTeamIndex'] as int? ?? 0;

        if (mounted) {
          setState(() {
            _disputedWords = Set.from(disputedWords);
            _confirmedTeams = confirmedTeams;
            _currentTeamIndex = currentTeamIndex;
            _isCurrentTeamActive = _currentDeviceId != null &&
                _currentDeviceId == _getCurrentTeamDeviceId();
          });

          // Check if all teams have confirmed and advance to next turn
          final teams = widget.sessionData?['teams'] as List? ?? [];
          if (confirmedTeams.length >= teams.length && teams.isNotEmpty) {
            // All teams confirmed, advance to next team
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted && widget.sessionId != null) {
                FirestoreService.advanceToNextTeam(widget.sessionId!);
              }
            });
          }
        }
      }
    });
  }

  String? _getCurrentTeamDeviceId() {
    if (widget.sessionData == null) return null;
    final teams = widget.sessionData!['teams'] as List? ?? [];
    if (_currentTeamIndex < teams.length) {
      final team = teams[_currentTeamIndex] as Map<String, dynamic>?;
      return team?['deviceId'] as String?;
    }
    return null;
  }

  TeamColor _getCurrentTeamColor() {
    if (widget.sessionData == null) return uiColors[0];
    final teams = widget.sessionData!['teams'] as List? ?? [];
    if (widget.teamIndex < teams.length) {
      final team = teams[widget.teamIndex] as Map<String, dynamic>?;
      final colorIndex = team?['colorIndex'] as int? ?? widget.teamIndex;
      return teamColors[colorIndex % teamColors.length];
    }
    return uiColors[0];
  }

  String _getPerformanceMessage() {
    final gameConfig = ref.read(gameSetupProvider);
    final maxPossibleScore = gameConfig.roundTimeSeconds ~/
        3; // Rough estimate of max possible score
    final scorePercentage = widget.correctCount / maxPossibleScore;

    if (scorePercentage >= 0.7) {
      return _getRandomMessage(_highScoreMessages);
    } else if (widget.correctCount == 0) {
      return _getRandomMessage(_zeroScoreMessages);
    } else {
      return _getRandomMessage(_lowScoreMessages);
    }
  }

  String _getRandomMessage(List<Map<String, String>> messages) {
    // Use a deterministic seed based on the turn data to avoid constant changes
    final seed = widget.teamIndex +
        widget.roundNumber +
        widget.turnNumber +
        widget.correctCount;
    final random = messages[seed % messages.length];
    return '${random['text']} ${random['emoji']}';
  }

  void _onWordDisputed(String word) {
    if (!_isCurrentTeamActive) return; // Only current team can dispute words

    setState(() {
      if (_disputedWords.contains(word)) {
        _disputedWords.remove(word);
      } else {
        _disputedWords.add(word);
      }
    });

    // Sync disputed words to Firestore
    if (widget.sessionId != null) {
      FirestoreService.updateDisputedWords(
        widget.sessionId!,
        _disputedWords.toList(),
      );
    }
  }

  int get _disputedScore {
    return widget.correctCount - _disputedWords.length;
  }

  bool get _allTeamsConfirmed {
    if (widget.sessionId == null) return false;
    final teams = widget.sessionData?['teams'] as List? ?? [];
    return _confirmedTeams.length >= teams.length && teams.isNotEmpty;
  }

  void _confirmScore() {
    if (widget.sessionId != null) {
      // For online games, confirm score for current team

      FirestoreService.confirmScoreForTeam(widget.sessionId!, widget.teamIndex);
    } else {
      // For local games, use the existing logic
      final currentTeamPlayers = ref.read(currentTeamPlayersProvider);
      if (currentTeamPlayers.length >= 2) {
        final turnRecord = TurnRecord(
          teamIndex: widget.teamIndex,
          roundNumber: widget.roundNumber,
          turnNumber: widget.turnNumber,
          conveyor: currentTeamPlayers[0],
          guesser: currentTeamPlayers[1],
          category: CategoryRegistry.getCategory(widget.category).displayName,
          score: _disputedScore,
          skipsUsed:
              ref.read(gameSetupProvider).allowedSkips - widget.skipsLeft,
          wordsGuessed: widget.wordsGuessed
              .where((word) => !_disputedWords.contains(word))
              .toList(),
          wordsSkipped: widget.wordsSkipped,
        );

        ref.read(gameStateProvider.notifier).recordTurn(turnRecord);

        // TODO: Update word statistics using CategoryProvider
        final categoryNotifier = ref.read(categoryProvider.notifier);

        // Increment appearance count for all words that appeared in this turn
        for (final word in widget.wordsGuessed) {
          categoryNotifier.incrementWordAppearance(widget.category, word);
        }
        for (final word in widget.wordsSkipped) {
          categoryNotifier.incrementWordAppearance(widget.category, word);
        }

        // Increment guessed count only for words that were not disputed
        for (final word in widget.wordsGuessed) {
          if (!_disputedWords.contains(word)) {
            categoryNotifier.incrementWordGuessed(widget.category, word);
          }
        }

        // Use navigation service to navigate to next screen
        GameNavigationService.navigateToNextScreen(context, ref,
            teamIndex: widget.teamIndex);
      }
    }
  }

  @override
  void dispose() {
    _turnOverStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // For online games, listen to navigation changes
    if (widget.sessionId != null) {
      OnlineGameNavigationService.navigate(
        context: context,
        ref: ref,
        sessionId: widget.sessionId!,
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 40.0),
          child: Column(
            children: [
              // Category display
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? CategoryRegistry.getCategory(widget.category)
                          .color
                          .withOpacity(0.3)
                      : CategoryRegistry.getCategory(widget.category)
                          .color
                          .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? CategoryRegistry.getCategory(widget.category)
                            .color
                            .withOpacity(0.8)
                        : CategoryRegistry.getCategory(widget.category).color,
                    width: 2,
                  ),
                ),
                child: Text(
                  CategoryRegistry.getCategory(widget.category).displayName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.95)
                            : Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              // Score display
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? CategoryRegistry.getCategory(widget.category)
                          .color
                          .withOpacity(0.9)
                      : CategoryRegistry.getCategory(widget.category).color,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? CategoryRegistry.getCategory(widget.category)
                              .color
                              .withOpacity(0.4)
                          : CategoryRegistry.getCategory(widget.category)
                              .color
                              .withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  'Score: $_disputedScore',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Words Guessed:',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        if (widget.wordsGuessed.isNotEmpty) ...[
                          for (var i = 0;
                              i < widget.wordsGuessed.length;
                              i += 2)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _onWordDisputed(
                                          widget.wordsGuessed[i]),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8, horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: _disputedWords.contains(
                                                  widget.wordsGuessed[i])
                                              ? Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors.red.withOpacity(0.2)
                                                  : Colors.red.withOpacity(0.1)
                                              : Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? CategoryRegistry
                                                          .getCategory(
                                                              widget.category)
                                                      .color
                                                      .withOpacity(0.2)
                                                  : CategoryRegistry
                                                          .getCategory(
                                                              widget.category)
                                                      .color
                                                      .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: _disputedWords.contains(
                                                    widget.wordsGuessed[i])
                                                ? Colors.red
                                                : Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? CategoryRegistry
                                                            .getCategory(
                                                                widget.category)
                                                        .color
                                                        .withOpacity(0.8)
                                                    : CategoryRegistry
                                                            .getCategory(
                                                                widget.category)
                                                        .color,
                                            width: 2,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                widget.wordsGuessed[i],
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      color: Theme.of(context)
                                                                  .brightness ==
                                                              Brightness.dark
                                                          ? Colors.white
                                                              .withOpacity(0.95)
                                                          : Colors.black,
                                                    ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            if (_disputedWords.contains(
                                                widget.wordsGuessed[i]))
                                              Icon(
                                                Icons.close,
                                                color: Colors.red,
                                                size: 20,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: i + 1 < widget.wordsGuessed.length
                                        ? GestureDetector(
                                            onTap: () => _onWordDisputed(
                                                widget.wordsGuessed[i + 1]),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8,
                                                      horizontal: 12),
                                              decoration: BoxDecoration(
                                                color: _disputedWords.contains(
                                                        widget.wordsGuessed[
                                                            i + 1])
                                                    ? Theme.of(context)
                                                                .brightness ==
                                                            Brightness.dark
                                                        ? Colors.red
                                                            .withOpacity(0.2)
                                                        : Colors.red
                                                            .withOpacity(0.1)
                                                    : Theme.of(context)
                                                                .brightness ==
                                                            Brightness.dark
                                                        ? CategoryRegistry.getCategory(
                                                                widget.category)
                                                            .color
                                                            .withOpacity(0.2)
                                                        : CategoryRegistry.getCategory(
                                                                widget.category)
                                                            .color
                                                            .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: _disputedWords
                                                          .contains(widget
                                                                  .wordsGuessed[
                                                              i + 1])
                                                      ? Colors.red
                                                      : Theme.of(context)
                                                                  .brightness ==
                                                              Brightness.dark
                                                          ? CategoryRegistry
                                                                  .getCategory(
                                                                      widget
                                                                          .category)
                                                              .color
                                                              .withOpacity(0.8)
                                                          : CategoryRegistry
                                                                  .getCategory(
                                                                      widget
                                                                          .category)
                                                              .color,
                                                  width: 2,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      widget
                                                          .wordsGuessed[i + 1],
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium
                                                          ?.copyWith(
                                                            color: Theme.of(context)
                                                                        .brightness ==
                                                                    Brightness
                                                                        .dark
                                                                ? Colors.white
                                                                    .withOpacity(
                                                                        0.95)
                                                                : Colors.black,
                                                          ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                  if (_disputedWords.contains(
                                                      widget
                                                          .wordsGuessed[i + 1]))
                                                    Icon(
                                                      Icons.close,
                                                      color: Colors.red,
                                                      size: 20,
                                                    ),
                                                ],
                                              ),
                                            ),
                                          )
                                        : const SizedBox(),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 16),
                          Text(
                            _isCurrentTeamActive
                                ? 'Tap words to contest them'
                                : 'Only the current team can contest words',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: _isCurrentTeamActive
                                      ? CategoryRegistry.getCategory(
                                              widget.category)
                                          .color
                                      : Colors.grey,
                                ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? CategoryRegistry.getCategory(
                                          widget.category)
                                      .color
                                      .withOpacity(0.2)
                                  : CategoryRegistry.getCategory(
                                          widget.category)
                                      .color
                                      .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? CategoryRegistry.getCategory(
                                            widget.category)
                                        .color
                                        .withOpacity(0.8)
                                    : CategoryRegistry.getCategory(
                                            widget.category)
                                        .color,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _getPerformanceMessage(),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white.withOpacity(0.95)
                                        : Colors.black,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ] else ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 20),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.red.withOpacity(0.2)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.red.withOpacity(0.8)
                                    : Colors.red,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _getRandomMessage(_zeroScoreMessages),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white.withOpacity(0.95)
                                        : Colors.black,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                        if (widget.wordsSkipped.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Text(
                            'Words Skipped:',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 10),
                          for (var word in widget.wordsSkipped)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? CategoryRegistry.getCategory(
                                              widget.category)
                                          .color
                                          .withOpacity(0.1)
                                      : CategoryRegistry.getCategory(
                                              widget.category)
                                          .color
                                          .withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? CategoryRegistry.getCategory(
                                                widget.category)
                                            .color
                                            .withOpacity(0.5)
                                        : CategoryRegistry.getCategory(
                                                widget.category)
                                            .color
                                            .withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  word,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white.withOpacity(0.95)
                                            : Colors.black,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    // Show team confirmation circles and contested words count
                    if (widget.sessionId != null) ...[
                      const SizedBox(height: 1),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Contested words count on the left
                          if (_disputedWords.isNotEmpty)
                            Text(
                              '${_disputedWords.length} word${_disputedWords.length == 1 ? '' : 's'} contested',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Colors.red,
                                  ),
                            )
                          else
                            const SizedBox.shrink(),
                          // Team confirmation circles on the right
                          Row(
                            children: List.generate(
                              (widget.sessionData?['teams'] as List? ?? [])
                                  .length,
                              (index) {
                                final teams =
                                    widget.sessionData?['teams'] as List? ?? [];
                                final team = index < teams.length
                                    ? teams[index] as Map<String, dynamic>?
                                    : null;
                                final colorIndex =
                                    team?['colorIndex'] as int? ?? index;
                                final teamColor =
                                    teamColors[colorIndex % teamColors.length];
                                final isConfirmed =
                                    _confirmedTeams.contains(index);

                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isConfirmed
                                          ? teamColor.border
                                          : teamColor.border.withOpacity(0.3),
                                      border: Border.all(
                                        color: isConfirmed
                                            ? teamColor.border
                                            : teamColor.border.withOpacity(0.5),
                                        width: 2,
                                      ),
                                    ),
                                    child: isConfirmed
                                        ? Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 16,
                                          )
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    TeamColorButton(
                      text: _allTeamsConfirmed
                          ? (_isCurrentTeamActive ? 'Continue' : 'Waiting...')
                          : _confirmedTeams.contains(widget.teamIndex)
                              ? 'Confirmed ✓'
                              : 'Confirm Score',
                      icon: _allTeamsConfirmed
                          ? (_isCurrentTeamActive
                              ? Icons.arrow_forward
                              : Icons.hourglass_empty)
                          : _confirmedTeams.contains(widget.teamIndex)
                              ? Icons.check_circle
                              : Icons.check,
                      color: _allTeamsConfirmed
                          ? (_isCurrentTeamActive
                              ? uiColors[1]
                              : _getCurrentTeamColor()) // Use team's own color when waiting
                          : _confirmedTeams.contains(widget.teamIndex)
                              ? uiColors[1] // Green when confirmed
                              : uiColors[0], // Blue when not confirmed
                      onPressed: _allTeamsConfirmed
                          ? (_isCurrentTeamActive
                              ? _confirmScore
                              : null) // Only current team can continue
                          : _confirmedTeams.contains(widget.teamIndex)
                              ? null // Disable only for this team when confirmed
                              : _confirmScore,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
