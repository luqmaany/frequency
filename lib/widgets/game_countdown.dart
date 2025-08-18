import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/category_registry.dart';
import '../services/sound_service.dart';

class GameCountdown extends ConsumerStatefulWidget {
  final String player1Name;
  final String player2Name;
  final String categoryId;
  final VoidCallback onCountdownComplete;

  const GameCountdown({
    super.key,
    required this.player1Name,
    required this.player2Name,
    required this.categoryId,
    required this.onCountdownComplete,
  });

  @override
  ConsumerState<GameCountdown> createState() => _GameCountdownState();
}

class _GameCountdownState extends ConsumerState<GameCountdown>
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
        // Play tick on each number change
        ref.read(soundServiceProvider).playCountdownTick();
        _countdownAnimationController.reset();
        _countdownAnimationController.forward();
        _startCountdown();
      } else if (mounted) {
        setState(() {
          _isCountdownActive = false;
        });
        // Final beep
        ref.read(soundServiceProvider).playCountdownEnd();
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
                        color: CategoryRegistry.getCategory(widget.categoryId)
                            .color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                CategoryRegistry.getCategory(widget.categoryId)
                                    .color
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
              child: Text(
                'Get Ready!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
