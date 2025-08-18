import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../models/category.dart';
import 'word_card.dart';
import '../services/sound_service.dart';

class GameCards extends ConsumerStatefulWidget {
  final List<Word> currentWords;
  final String categoryId;
  final int skipsLeft;
  final Function(String) onWordGuessed;
  final Function(String) onWordSkipped;
  final Function(int) onLoadNewWord;
  final bool showBlankCards;

  const GameCards({
    super.key,
    required this.currentWords,
    required this.categoryId,
    required this.skipsLeft,
    required this.onWordGuessed,
    required this.onWordSkipped,
    required this.onLoadNewWord,
    this.showBlankCards = false,
  });

  @override
  ConsumerState<GameCards> createState() => _GameCardsState();
}

class _GameCardsState extends ConsumerState<GameCards>
    with TickerProviderStateMixin {
  final CardSwiperController _topCardController = CardSwiperController();
  final CardSwiperController _bottomCardController = CardSwiperController();

  // Animation controllers for fade-in effects
  late AnimationController _topCardAnimationController;
  late AnimationController _bottomCardAnimationController;
  late Animation<double> _topCardAnimation;
  late Animation<double> _bottomCardAnimation;
  double _rightSwipeProgress = 0.0;
  double _leftSwipeProgress = 0.0;
  double _bottomRightSwipeProgress = 0.0;
  double _bottomLeftSwipeProgress = 0.0;
  // Removed animated hint in favor of static triple arrows

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
      return const AllowedSwipeDirection.symmetric(
          horizontal: true, vertical: false);
    } else {
      // Only allow right swipes when no skips are left
      return const AllowedSwipeDirection.only(right: true);
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

    final bool _showSwipeHint = _leftSwipeProgress == 0.0 &&
        _rightSwipeProgress == 0.0 &&
        _bottomLeftSwipeProgress == 0.0 &&
        _bottomRightSwipeProgress == 0.0;

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
                    child: Stack(
                      children: [
                        CardSwiper(
                          key: ValueKey('top_${widget.currentWords[0].text}'),
                          controller: _topCardController,
                          cardsCount: 1,
                          cardBuilder: (context,
                              index,
                              horizontalThresholdPercentage,
                              verticalThresholdPercentage) {
                            // Show red icon bubble when swiping left
                            if (horizontalThresholdPercentage < 0) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() {
                                    _leftSwipeProgress =
                                        (-horizontalThresholdPercentage)
                                            .clamp(0.0, 1.0)
                                            .toDouble();
                                  });
                                }
                              });
                            } else if (_leftSwipeProgress != 0.0) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() {
                                    _leftSwipeProgress = 0.0;
                                  });
                                }
                              });
                            }
                            // Show green icon bubble when swiping right
                            if (horizontalThresholdPercentage > 0) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() {
                                    _rightSwipeProgress =
                                        horizontalThresholdPercentage
                                            .clamp(0.0, 1.0)
                                            .toDouble();
                                  });
                                }
                              });
                            } else if (_rightSwipeProgress != 0.0) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() {
                                    _rightSwipeProgress = 0.0;
                                  });
                                }
                              });
                            }
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
                            );
                          },
                          onSwipe: (previousIndex, currentIndex, direction) {
                            if (direction == CardSwiperDirection.right) {
                              // Correct guess
                              ref.read(soundServiceProvider).playCorrect();
                              widget.onWordGuessed(widget.currentWords[0].text);
                              _loadNewWord(0);
                              return true;
                            } else if (direction == CardSwiperDirection.left) {
                              // Skip
                              if (widget.skipsLeft > 0) {
                                ref.read(soundServiceProvider).playSkip();
                                widget
                                    .onWordSkipped(widget.currentWords[0].text);
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24.0, vertical: 40.0),
                        ),
                      ],
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
                    child: Stack(
                      children: [
                        CardSwiper(
                          key:
                              ValueKey('bottom_${widget.currentWords[1].text}'),
                          controller: _bottomCardController,
                          cardsCount: 1,
                          cardBuilder: (context,
                              index,
                              horizontalThresholdPercentage,
                              verticalThresholdPercentage) {
                            // Show red icon bubble when swiping left
                            if (horizontalThresholdPercentage < 0) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() {
                                    _bottomLeftSwipeProgress =
                                        (-horizontalThresholdPercentage)
                                            .clamp(0.0, 1.0)
                                            .toDouble();
                                  });
                                }
                              });
                            } else if (_bottomLeftSwipeProgress != 0.0) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() {
                                    _bottomLeftSwipeProgress = 0.0;
                                  });
                                }
                              });
                            }
                            // Show green icon bubble when swiping right
                            if (horizontalThresholdPercentage > 0) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() {
                                    _bottomRightSwipeProgress =
                                        horizontalThresholdPercentage
                                            .clamp(0.0, 1.0)
                                            .toDouble();
                                  });
                                }
                              });
                            } else if (_bottomRightSwipeProgress != 0.0) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() {
                                    _bottomRightSwipeProgress = 0.0;
                                  });
                                }
                              });
                            }
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
                            );
                          },
                          onSwipe: (previousIndex, currentIndex, direction) {
                            if (direction == CardSwiperDirection.right) {
                              // Correct guess
                              ref.read(soundServiceProvider).playCorrect();
                              widget.onWordGuessed(widget.currentWords[1].text);
                              _loadNewWord(1);
                              return true;
                            } else if (direction == CardSwiperDirection.left) {
                              // Skip
                              if (widget.skipsLeft > 0) {
                                ref.read(soundServiceProvider).playSkip();
                                widget
                                    .onWordSkipped(widget.currentWords[1].text);
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24.0, vertical: 40.0),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        // Swipe arrows near the side icons (static triples, red on left / green on right)
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: _showSwipeHint ? 0.95 : 0.0,
              duration: const Duration(milliseconds: 150),
              child: Stack(
                children: [
                  // Left group moved toward center (further from left icon)
                  Positioned(
                    left: 65,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.keyboard_arrow_left,
                              color: Colors.red.withOpacity(1.0), size: 28),
                          const SizedBox(width: 0),
                          Icon(Icons.keyboard_arrow_left,
                              color: Colors.red.withOpacity(0.7), size: 26),
                          const SizedBox(width: 0),
                          Icon(Icons.keyboard_arrow_left,
                              color: Colors.red.withOpacity(0.4), size: 24),
                        ],
                      ),
                    ),
                  ),
                  // Right group moved toward center (further from right icon)
                  Positioned(
                    right: 65,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.keyboard_arrow_right,
                              color: Colors.green.withOpacity(0.4), size: 24),
                          const SizedBox(width: 0),
                          Icon(Icons.keyboard_arrow_right,
                              color: Colors.green.withOpacity(0.7), size: 26),
                          const SizedBox(width: 0),
                          Icon(Icons.keyboard_arrow_right,
                              color: Colors.green.withOpacity(1.0), size: 28),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Skip icon positioned between cards on the left
        Positioned(
          left: 8,
          top: 0,
          bottom: 0,
          child: Center(
            child: Transform.scale(
              scale: 1.0 +
                  0.5 *
                      (_leftSwipeProgress > 0
                          ? _leftSwipeProgress
                          : _bottomLeftSwipeProgress),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.red.withOpacity(0.8),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.block,
                  color: Colors.red.withOpacity(0.9),
                  size: 24,
                ),
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
            child: Transform.scale(
              scale: 1.0 +
                  0.5 *
                      (_rightSwipeProgress > 0
                          ? _rightSwipeProgress
                          : _bottomRightSwipeProgress),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.green.withOpacity(0.8),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.green.withOpacity(0.9),
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
