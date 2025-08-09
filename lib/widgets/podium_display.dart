import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import 'team_color_button.dart';

class PodiumDisplay extends StatefulWidget {
  final List<Map<String, dynamic>>
      teams; // [{name, score, isWinner, teamIndex}]
  final List<TeamColor> teamColors;

  const PodiumDisplay({
    super.key,
    required this.teams,
    required this.teamColors,
  });

  @override
  State<PodiumDisplay> createState() => _PodiumDisplayState();
}

class _PodiumDisplayState extends State<PodiumDisplay>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _animationController.forward();
    if (widget.teams.isNotEmpty && widget.teams[0]['isWinner'] == true) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _confettiController.play();
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Confetti for winner
        if (widget.teams.isNotEmpty && widget.teams[0]['isWinner'] == true)
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),

        // Main podium
        SizedBox(
          height: 400,
          child: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Column(
                  children: [
                    // Winner section
                    if (widget.teams.isNotEmpty)
                      _buildWinnerCard(widget.teams[0]),

                    const SizedBox(height: 30),

                    // Runner-ups section
                    Expanded(
                      child: _buildRunnerUpsSection(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWinnerCard(Map<String, dynamic> winner) {
    final teamIndex = winner['teamIndex'] as int;
    final color = widget.teamColors[teamIndex % widget.teamColors.length];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.background,
            color.background.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.border, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.border.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Winner badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
                AnimatedTextKit(
                  animatedTexts: [
                    TypewriterAnimatedText(
                      'CHAMPION',
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      speed: const Duration(milliseconds: 150),
                    ),
                  ],
                  totalRepeatCount: 1,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Team name
          Text(
            winner['name'] as String,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color.text,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: color.border, width: 2),
            ),
            child: Text(
              '${winner['score']} points',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRunnerUpsSection() {
    if (widget.teams.length <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: widget.teams.skip(1).map((team) {
        final position = widget.teams.indexOf(team);
        return _buildRunnerUpCard(team, position);
      }).toList(),
    );
  }

  Widget _buildRunnerUpCard(Map<String, dynamic> team, int position) {
    final teamIndex = team['teamIndex'] as int;
    final color = widget.teamColors[teamIndex % widget.teamColors.length];
    final isSecond = position == 1;

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.border, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.border.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Position badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color:
                    isSecond ? Colors.grey.shade300 : const Color(0xFFCD7F32),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSecond ? Icons.military_tech : Icons.star,
                    color: isSecond ? Colors.grey.shade700 : Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isSecond ? '2nd' : '3rd',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSecond ? Colors.grey.shade700 : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Team name
            Text(
              team['name'] as String,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: color.text,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Score
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.border, width: 1.5),
              ),
              child: Text(
                '${team['score']}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
