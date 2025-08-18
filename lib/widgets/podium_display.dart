import 'package:flutter/material.dart';
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
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.teams.isNotEmpty) _buildWinnerBanner(widget.teams[0]),
              const SizedBox(height: 16),
              _buildPodiumBars(),
              const SizedBox(height: 16),
              _buildOthersList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWinnerBanner(Map<String, dynamic> winner) {
    final teamIndex = winner['teamIndex'] as int;
    final color = widget.teamColors[teamIndex % widget.teamColors.length];
    final Color baseBg = Theme.of(context).colorScheme.background;
    final Color overlay = color.border.withOpacity(0.6);
    final Color cardBg = Color.alphaBlend(overlay, baseBg);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.border.withOpacity(0.9), width: 3),
        boxShadow: [
          BoxShadow(
            color: color.border.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Winner badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: color.border,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.border.withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 6),
                Text(
                  'CHAMPION',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Team name
          Text(
            winner['name'] as String,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.95),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: Color.alphaBlend(color.border.withOpacity(0.2), baseBg),
              borderRadius: BorderRadius.circular(25),
              border:
                  Border.all(color: color.border.withOpacity(0.8), width: 2),
            ),
            child: Text(
              '${winner['score']} points',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumBars() {
    if (widget.teams.isEmpty) return const SizedBox.shrink();

    // Champion is displayed as a banner; no bar needed
    // final Map<String, dynamic>? first =
    //     widget.teams.isNotEmpty ? widget.teams[0] : null;
    final Map<String, dynamic>? second =
        widget.teams.length > 1 ? widget.teams[1] : null;
    final Map<String, dynamic>? third =
        widget.teams.length > 2 ? widget.teams[2] : null;

    // Heights relative to available space
    // const double h1 = 1.0; // champion bar omitted
    const double h2 = 0.78;
    const double h3 = 0.62;

    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (second != null)
            Expanded(
                child: _buildPodiumBar(second, place: '2nd', heightFactor: h2)),
          if (second != null && third != null) const SizedBox(width: 0),
          if (third != null)
            Expanded(
                child: _buildPodiumBar(third, place: '3rd', heightFactor: h3)),
        ],
      ),
    );
  }

  Widget _buildPodiumBar(Map<String, dynamic> team,
      {required String place, required double heightFactor}) {
    final teamIndex = team['teamIndex'] as int;
    final color = widget.teamColors[teamIndex % widget.teamColors.length];
    final Color baseBg = Theme.of(context).colorScheme.background;
    final Color overlay = color.border.withOpacity(0.5);
    final Color barBg = Color.alphaBlend(overlay, baseBg);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: heightFactor,
              child: Container(
                decoration: BoxDecoration(
                  color: barBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: color.border.withOpacity(0.9), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: color.border.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      team['name'] as String,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color.alphaBlend(
                            color.border.withOpacity(0.18), baseBg),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: color.border.withOpacity(0.75), width: 1.5),
                      ),
                      child: Text(
                        '${team['score']}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (place.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            place,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOthersList() {
    if (widget.teams.length <= 3) return const SizedBox.shrink();

    final List<Map<String, dynamic>> others = widget.teams.skip(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: others.map((team) {
            final teamIndex = team['teamIndex'] as int;
            final color =
                widget.teamColors[teamIndex % widget.teamColors.length];
            final Color baseBg = Theme.of(context).colorScheme.background;
            final Color chipBg =
                Color.alphaBlend(color.border.withOpacity(0.25), baseBg);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: color.border.withOpacity(0.8), width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    team['name'] as String,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${team['score']}',
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
