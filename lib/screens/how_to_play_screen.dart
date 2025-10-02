import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/wave_background.dart';
import '../widgets/team_color_button.dart';
import '../widgets/game_mode_dialog.dart';

class HowToPlayScreen extends ConsumerStatefulWidget {
  const HowToPlayScreen({super.key});

  @override
  ConsumerState<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends ConsumerState<HowToPlayScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 9;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showPlayDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => const GameModeDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: Stack(
        children: [
          // Animated background
          const Positioned.fill(
            child: WaveBackground(),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Title
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Text(
                      'How To Play',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                // Slideshow
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    children: [
                      _buildSlide1(context),
                      _buildSlide2(context),
                      _buildSlide3(context),
                      _buildSlide4(context),
                      _buildSlide5(context),
                      _buildSlide8(context),
                      _buildSlide6(context),
                      _buildSlide7(context),
                      _buildSlide9(context),
                    ],
                  ),
                ),

                // Page indicators
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _totalPages,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom button bar
                Container(
                  padding: const EdgeInsets.all(16),
                  child: _currentPage == _totalPages - 1
                      ? Row(
                          children: [
                            Expanded(
                              child: TeamColorButton(
                                text: 'Home',
                                icon: Icons.home,
                                color: uiColors[0],
                                onPressed: () => Navigator.of(context)
                                    .popUntil((route) => route.isFirst),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TeamColorButton(
                                text: 'Play',
                                icon: Icons.play_arrow,
                                color: uiColors[1],
                                onPressed: () => _showPlayDialog(context),
                              ),
                            ),
                          ],
                        )
                      : TeamColorButton(
                          text: 'Home',
                          icon: Icons.home,
                          color: uiColors[0],
                          onPressed: () => Navigator.of(context)
                              .popUntil((route) => route.isFirst),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Slide 1: Welcome
  Widget _buildSlide1(BuildContext context) {
    return _buildSlideContainer(
      context,
      icon: Icons.waving_hand,
      cardColor: const Color(0xFF5EB1FF), // Blue
      title: 'Welcome to Frequency!',
      content: 'The fast-paced word guessing party game for 2+ players.\n\n'
          'Swipe through to learn the basics and start playing in minutes!',
    );
  }

  // Slide 2: Teams
  Widget _buildSlide2(BuildContext context) {
    return _buildSlideContainer(context,
        icon: Icons.groups,
        cardColor: const Color(0xFF00BFAE), // Turquoise
        title: 'Teams of Two',
        content: 'Each team chooses roles each round:\n\n'
            '📡 Transmitter\n'
            'Describes the words without saying them!\n\n'
            '📻 Receiver\n'
            'Shouts out answers as fast as possible');
  }

  // Slide 3: Transmitter Rules
  Widget _buildSlide3(BuildContext context) {
    return _buildSlideContainer(
      context,
      icon: Icons.gavel,
      cardColor: const Color(0xFFFF6680), // Pink/Red
      title: 'Transmitter Rules',
      content: '📡 When describing words, you CANNOT:\n\n'
          '❌ Say the word... duh.    \n'
          '❌ Say any part of the word\n'
          '❌ Rhyme with the word     \n'
          '❌ Spell it out            \n'
          '❌ Say "starts with..."    \n\n'
          '💡 However, like we do with Uno, you can change the rules all you want!',
    );
  }

  // Slide 4: Gameplay - Cards
  Widget _buildSlide4(BuildContext context) {
    return _buildSlideContainer(
      context,
      icon: Icons.style,
      cardColor: const Color(0xFF7A5CFF), // Purple
      title: 'Two Cards, One Goal',
      content: 'Two word cards appear at once from your chosen category.\n\n'
          'The Transmitter can choose which one to describe at a time or both if that\'s possible\n\n'
          'Work together to guess them as many as possible before the timer runs out!',
    );
  }

  // Slide 5: Swipe Controls
  Widget _buildSlide5(BuildContext context) {
    return _buildSlideContainer(
      context,
      icon: Icons.swipe,
      cardColor: const Color(0xFFE91E63), // Magenta/Pink
      title: 'Swipe to Play',
      content: '👉 Swipe RIGHT\n'
          'When a word is guessed correctly ✅\n\n'
          '👈 Swipe LEFT\n'
          'To skip a tough one ⏭️\n\n'
          'You have limited skips so be careful!',
    );
  }

  // Slide 6: Game Modes
  Widget _buildSlide6(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Fixed top spacing for consistent icon position
          const Icon(
            Icons.gamepad,
            size: 80,
            color: Colors.indigo,
          ),
          const SizedBox(height: 24),
          Text(
            'Game Modes',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildModeCard(
            'Local',
            'Play with friends locally',
            Icons.group,
            const Color(0xFF5EB1FF),
          ),
          const SizedBox(height: 12),
          _buildModeCard(
            'Zen',
            'Quick single turn',
            Icons.spa,
            const Color(0xFF7A5CFF),
          ),
          const SizedBox(height: 12),
          _buildModeCard(
            'Online',
            'Play from afar',
            Icons.public,
            const Color(0xFF4CD295),
          ),
        ],
      ),
    );
  }

  // Slide 7: Word Decks
  Widget _buildSlide7(BuildContext context) {
    return _buildSlideContainer(
      context,
      icon: Icons.collections_bookmark,
      cardColor: const Color(0xFFFF9800), // Orange
      title: 'Word Decks',
      content: 'Unlock themed decks from the Decks Store:\n\n'
          '🎬 Movies & TV Shows\n'
          '⚽ Sports & Athletes\n'
          '🍕 Food & Cooking\n'
          '🔬 Science & Nature\n'
          '🎭 And many more!\n\n'
          'Mix and match for endless variety!',
    );
  }

  // Slide 8: Scoring
  Widget _buildSlide8(BuildContext context) {
    return _buildSlideContainer(context,
        icon: Icons.emoji_events,
        cardColor: const Color(0xFF4CAF50), // Green
        title: 'Scoring & Titles',
        content: 'Each transmission = 1 point\n\n'
            'But guessed words can be disputed ❌ so play by the rules!\n\n'
            'First team to reach the target score wins and manifests parallel trajectoires of neurocognitive articulation!');
  }

  // Slide 9: Ready to Play
  Widget _buildSlide9(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Fixed top spacing for consistent icon position
          const Icon(
            Icons.celebration,
            size: 80,
            color: Color(0xFF5EB1FF),
          ),
          const SizedBox(height: 24),
          Text(
            'Ready to Play?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade900, // Dark background like dialog
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF5EB1FF),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'You\'re all set!\n\nGrab some friends and hit that Play button to start a game.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        height: 1.6,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7A5CFF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF7A5CFF),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: Color(0xFF7A5CFF),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Use all your body when describing - act it out!',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                  ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Build slide container
  Widget _buildSlideContainer(
    BuildContext context, {
    required IconData icon,
    required Color cardColor,
    required String title,
    required String content,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Fixed top spacing for consistent icon position
          Icon(
            icon,
            size: 80,
            color: cardColor,
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade900, // Dark background like dialog
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: cardColor,
                width: 2,
              ),
            ),
            child: Text(
              content,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    height: 1.6,
                    fontSize: 16,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Build mode card for slide 5
  Widget _buildModeCard(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade900, // Dark background like dialog
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade300,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
