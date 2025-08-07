import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/category_registry.dart';
import 'package:convey/widgets/team_color_button.dart';
import '../services/firestore_service.dart';
import '../services/online_game_navigation_service.dart';
import '../services/storage_service.dart';
import '../providers/session_providers.dart';

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
  final String? currentTeamDeviceId; // Add device ID for interaction control

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
    this.currentTeamDeviceId,
  });

  @override
  ConsumerState<OnlineTurnOverScreen> createState() =>
      _OnlineTurnOverScreenState();
}

class _OnlineTurnOverScreenState extends ConsumerState<OnlineTurnOverScreen> {
  Set<String> _disputedWords = {};
  List<int> _confirmedTeams = [];
  bool _isCurrentTeamActive = false;
  String? _currentDeviceId;

  @override
  void initState() {
    super.initState();
    _disputedWords = Set.from(widget.disputedWords);

    // Get current device ID and set up online game state
    _getCurrentDeviceId();
  }

  Future<void> _getCurrentDeviceId() async {
    final deviceId = await StorageService.getDeviceId();
    setState(() {
      _currentDeviceId = deviceId;
    });
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
    if (_allTeamsConfirmed && _isCurrentTeamActive) {
      // All teams confirmed and current team is active - advance to next turn
      FirestoreService.fromTurnOver(
        widget.sessionId!,
        widget.teamIndex,
        widget.roundNumber,
        widget.turnNumber,
        widget.category,
        _disputedScore, // Use disputed score instead of original correctCount
        widget.skipsLeft,
        widget.wordsGuessed
            .where((word) => !_disputedWords.contains(word))
            .toList(), // Filter out disputed words
        widget.wordsSkipped,
        _disputedWords,
        widget.conveyor ?? '',
        widget.guesser ?? '',
      );
    } else {
      // Confirm score for current team
      FirestoreService.confirmScoreForTeam(widget.sessionId!, widget.teamIndex);
    }
  }

  @override
  void dispose() {
    print('🗑️ TURN OVER SCREEN: Disposing widget, cleaning up listeners...');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // For online games, listen to navigation changes
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

    // Listen to turn over state changes
    if (widget.sessionId != null) {
      ref.listen(sessionTurnOverProvider(widget.sessionId!), (previous, next) {
        if (!next.hasValue || next.value == null) return;

        final turnOverState = next.value!;
        final disputedWords =
            List<String>.from(turnOverState['disputedWords'] as List? ?? []);
        final confirmedTeams =
            List<int>.from(turnOverState['confirmedTeams'] as List? ?? []);

        if (mounted) {
          setState(() {
            _disputedWords = Set.from(disputedWords);
            _confirmedTeams = confirmedTeams;
            _isCurrentTeamActive = _currentDeviceId != null &&
                _currentDeviceId == widget.currentTeamDeviceId;
            print(
                '🔍 DEVICE INFO: Current device: $_currentDeviceId, Team device: ${widget.currentTeamDeviceId}, Is active: $_isCurrentTeamActive');
          });
        }
      });
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
