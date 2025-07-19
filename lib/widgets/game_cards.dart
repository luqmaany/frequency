import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../screens/word_lists_manager_screen.dart';
import 'word_card.dart';

class GameCards extends StatefulWidget {
  final List<Word> currentWords;
  final WordCategory category;
  final int skipsLeft;
  final Function(String) onWordGuessed;
  final Function(String) onWordSkipped;
  final Function(int) onLoadNewWord;
  final bool showBlankCards;

  const GameCards({
    super.key,
    required this.currentWords,
    required this.category,
    required this.skipsLeft,
    required this.onWordGuessed,
    required this.onWordSkipped,
    required this.onLoadNewWord,
    this.showBlankCards = false,
  });

  @override
  State<GameCards> createState() => _GameCardsState();
}

class _GameCardsState extends State<GameCards> with TickerProviderStateMixin {
  final CardSwiperController _topCardController = CardSwiperController();
  final CardSwiperController _bottomCardController = CardSwiperController();

  // Animation controllers for fade-in effects
  late AnimationController _topCardAnimationController;
  late AnimationController _bottomCardAnimationController;
  late Animation<double> _topCardAnimation;
  late Animation<double> _bottomCardAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _topCardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _bottomCardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _topCardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _topCardAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _bottomCardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _bottomCardAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Start initial fade-in animations for cards
    _topCardAnimationController.forward();
    _bottomCardAnimationController.forward();
  }

  @override
  void dispose() {
    _topCardController.dispose();
    _bottomCardController.dispose();
    _topCardAnimationController.dispose();
    _bottomCardAnimationController.dispose();
    super.dispose();
  }

  AllowedSwipeDirection _getAllowedSwipeDirection() {
    if (widget.skipsLeft > 0) {
      return AllowedSwipeDirection.symmetric(horizontal: true, vertical: false);
    } else {
      // Only allow right swipes when no skips are left
      return AllowedSwipeDirection.only(right: true);
    }
  }

  void _loadNewWord(int index) {
    // Trigger fade-in animation for the new card
    if (index == 0) {
      _topCardAnimationController.reset();
      _topCardAnimationController.forward();
    } else {
      _bottomCardAnimationController.reset();
      _bottomCardAnimationController.forward();
    }
    widget.onLoadNewWord(index);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentWords.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        Column(
          children: [
            // Top card
            Expanded(
              child: AnimatedBuilder(
                animation: _topCardAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _topCardAnimation.value,
                    child: CardSwiper(
                      key: ValueKey('top_${widget.currentWords[0].text}'),
                      controller: _topCardController,
                      cardsCount: 1,
                      cardBuilder: (context,
                          index,
                          horizontalThresholdPercentage,
                          verticalThresholdPercentage) {
                        if (widget.showBlankCards) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.question_mark,
                                size: 64,
                                color: Colors.grey.withOpacity(0.5),
                              ),
                            ),
                          );
                        }
                        return WordCard(
                          word: widget.currentWords[0],
                          category: widget.category,
                        );
                      },
                      onSwipe: (previousIndex, currentIndex, direction) {
                        if (direction == CardSwiperDirection.right) {
                          // Correct guess
                          widget.onWordGuessed(widget.currentWords[0].text);
                          _loadNewWord(0);
                          return true;
                        } else if (direction == CardSwiperDirection.left) {
                          // Skip
                          if (widget.skipsLeft > 0) {
                            widget.onWordSkipped(widget.currentWords[0].text);
                            _loadNewWord(0);
                            return true;
                          } else {
                            // Prevent the swipe and show feedback
                            return false;
                          }
                        }
                        return false;
                      },
                      allowedSwipeDirection: _getAllowedSwipeDirection(),
                      numberOfCardsDisplayed: 1,
                      padding: const EdgeInsets.all(24.0),
                    ),
                  );
                },
              ),
            ),
            // Bottom card
            Expanded(
              child: AnimatedBuilder(
                animation: _bottomCardAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _bottomCardAnimation.value,
                    child: CardSwiper(
                      key: ValueKey('bottom_${widget.currentWords[1].text}'),
                      controller: _bottomCardController,
                      cardsCount: 1,
                      cardBuilder: (context,
                          index,
                          horizontalThresholdPercentage,
                          verticalThresholdPercentage) {
                        if (widget.showBlankCards) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.question_mark,
                                size: 64,
                                color: Colors.grey.withOpacity(0.5),
                              ),
                            ),
                          );
                        }
                        return WordCard(
                          word: widget.currentWords[1],
                          category: widget.category,
                        );
                      },
                      onSwipe: (previousIndex, currentIndex, direction) {
                        if (direction == CardSwiperDirection.right) {
                          // Correct guess
                          widget.onWordGuessed(widget.currentWords[1].text);
                          _loadNewWord(1);
                          return true;
                        } else if (direction == CardSwiperDirection.left) {
                          // Skip
                          if (widget.skipsLeft > 0) {
                            widget.onWordSkipped(widget.currentWords[1].text);
                            _loadNewWord(1);
                            return true;
                          } else {
                            // Prevent the swipe and show feedback
                            return false;
                          }
                        }
                        return false;
                      },
                      allowedSwipeDirection: _getAllowedSwipeDirection(),
                      numberOfCardsDisplayed: 1,
                      padding: const EdgeInsets.all(24.0),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        // Skip icon positioned between cards on the left
        Positioned(
          left: 8,
          top: 0,
          bottom: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.red.withOpacity(0.2)
                    : Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.red.withOpacity(0.8)
                      : Colors.red,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.block,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.red.withOpacity(0.9)
                    : Colors.red,
                size: 24,
              ),
            ),
          ),
        ),
        // Tick icon positioned between cards on the right
        Positioned(
          right: 8,
          top: 0,
          bottom: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.green.withOpacity(0.2)
                    : Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.green.withOpacity(0.8)
                      : Colors.green,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.check,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.green.withOpacity(0.9)
                    : Colors.green,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
