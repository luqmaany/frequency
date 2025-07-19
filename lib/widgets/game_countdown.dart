import 'package:flutter/material.dart';
import '../screens/word_lists_manager_screen.dart';
import '../utils/category_utils.dart';

class GameCountdown extends StatefulWidget {
  final String player1Name;
  final String player2Name;
  final WordCategory category;
  final VoidCallback onCountdownComplete;

  const GameCountdown({
    super.key,
    required this.player1Name,
    required this.player2Name,
    required this.category,
    required this.onCountdownComplete,
  });

  @override
  State<GameCountdown> createState() => _GameCountdownState();
}

class _GameCountdownState extends State<GameCountdown>
    with TickerProviderStateMixin {
  bool _isCountdownActive = true;
  int _countdownNumber = 3;
  late AnimationController _countdownAnimationController;
  late Animation<double> _countdownAnimation;

  @override
  void initState() {
    super.initState();
    _countdownAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _countdownAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _countdownAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownAnimationController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    // Start the first countdown animation immediately
    _countdownAnimationController.forward();

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _countdownNumber > 1) {
        setState(() {
          _countdownNumber--;
        });
        _countdownAnimationController.reset();
        _countdownAnimationController.forward();
        _startCountdown();
      } else if (mounted) {
        setState(() {
          _isCountdownActive = false;
        });
        widget.onCountdownComplete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCountdownActive) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Countdown display
            AnimatedBuilder(
              animation: _countdownAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.5 + (_countdownAnimation.value * 0.5),
                  child: Opacity(
                    opacity: _countdownAnimation.value,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: CategoryUtils.getCategoryColor(widget.category),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                CategoryUtils.getCategoryColor(widget.category)
                                    .withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '$_countdownNumber',
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 120,
                              ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            // Instructions
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Get Ready!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Swipe right for a correct guess\nSwipe left to skip',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.black87,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
