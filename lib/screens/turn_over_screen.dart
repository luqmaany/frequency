import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../services/game_setup_provider.dart';
import '../services/game_state_provider.dart';
import '../services/game_navigation_service.dart';
import '../models/game_state.dart';
import '../data/category_registry.dart';
import '../providers/category_provider.dart';
import 'package:convey/widgets/team_color_button.dart';
import '../services/firestore_service.dart';
import '../widgets/confirm_on_back.dart';
import '../widgets/quit_dialog.dart';

class TurnOverScreen extends ConsumerStatefulWidget {
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

  const TurnOverScreen({
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
  ConsumerState<TurnOverScreen> createState() => _TurnOverScreenState();
}

class _TurnOverScreenState extends ConsumerState<TurnOverScreen> {
  Set<String> _disputedWords = {};

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
    // Use a proper random number generator instead of timestamps
    // This avoids potential issues with Firestore quota and provides better randomization
    final random = Random();
    final randomIndex = random.nextInt(messages.length);
    final randomMessage = messages[randomIndex];
    return '${randomMessage['text']} ${randomMessage['emoji']}';
  }

  void _onWordDisputed(String word) {
    setState(() {
      if (_disputedWords.contains(word)) {
        _disputedWords.remove(word);
      } else {
        _disputedWords.add(word);
      }
    });
  }

  int get _disputedScore {
    return widget.correctCount - _disputedWords.length;
  }

  void _confirmScore() {
    // Record the turn in game state with final disputed score
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
        skipsUsed: ref.read(gameSetupProvider).allowedSkips - widget.skipsLeft,
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
      if (widget.sessionId != null) {
        // For online games, advance to next team in Firestore
        FirestoreService.advanceToNextTeam(widget.sessionId!);
      } else {
        // For local games, use the existing navigation service
        GameNavigationService.navigateToNextScreen(context, ref,
            teamIndex: widget.teamIndex);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameConfig = ref.watch(gameSetupProvider);
    final colorIndex = (gameConfig.teamColorIndices.length > widget.teamIndex)
        ? gameConfig.teamColorIndices[widget.teamIndex]
        : widget.teamIndex % teamColors.length;
    final teamColor = teamColors[colorIndex];

    return ConfirmOnBack(
      dialogBuilder: (ctx) => QuitDialog(color: teamColor),
      onConfirmed: (ctx) async {
        await GameNavigationService.quitToHome(ctx, ref);
      },
      child: Scaffold(
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
                                                                .withOpacity(
                                                                    0.95)
                                                            : Colors.black,
                                                      ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              if (_disputedWords.contains(
                                                  widget.wordsGuessed[i]))
                                                const Icon(
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
                                                  color: _disputedWords.contains(widget
                                                          .wordsGuessed[i + 1])
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
                                                                  widget
                                                                      .category)
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
                                                                .withOpacity(
                                                                    0.8)
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
                                                        widget.wordsGuessed[
                                                            i + 1],
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
                                                                  : Colors
                                                                      .black,
                                                            ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    ),
                                                    if (_disputedWords.contains(
                                                        widget.wordsGuessed[
                                                            i + 1]))
                                                      const Icon(
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
                              'Tap words to contest them',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: CategoryRegistry.getCategory(
                                            widget.category)
                                        .color,
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
                            // TODO: Also display the remaining 'words left on screen' after the skipped words list
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
                      if (_disputedWords.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            '${_disputedWords.length} word${_disputedWords.length == 1 ? '' : 's'} contested',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.red,
                                ),
                          ),
                        ),
                      TeamColorButton(
                        text: 'Confirm Score',
                        icon: Icons.check,
                        color: uiColors[0],
                        onPressed: _confirmScore,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
