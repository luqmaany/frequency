import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game_setup_provider.dart';
import 'category_selection_screen.dart';

class RoleAssignmentScreen extends ConsumerStatefulWidget {
  final int teamIndex;
  final int roundNumber;
  final int turnNumber;

  const RoleAssignmentScreen({
    super.key,
    required this.teamIndex,
    required this.roundNumber,
    required this.turnNumber,
  });

  @override
  ConsumerState<RoleAssignmentScreen> createState() => _RoleAssignmentScreenState();
}

class _RoleAssignmentScreenState extends ConsumerState<RoleAssignmentScreen> with SingleTickerProviderStateMixin {
  String? _selectedGuesser;
  String? _selectedConveyer;
  bool _isTransitioning = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    // Automatically assign roles at start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _assignRandomRoles();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _assignRandomRoles() {
    final gameConfig = ref.read(gameSetupProvider);
    final teams = gameConfig.teams;
    
    if (teams.isEmpty || widget.teamIndex >= teams.length) {
      return;
    }

    final team = teams[widget.teamIndex];
    if (team.length < 2) {
      return;
    }

    final random = team.toList()..shuffle();
    setState(() {
      _selectedGuesser = random[0];
      _selectedConveyer = random[1];
    });
  }

  void _showTransitionScreen() {
    setState(() {
      _isTransitioning = true;
    });
  }

  void _switchRoles() {
    setState(() {
      final temp = _selectedGuesser;
      _selectedGuesser = _selectedConveyer;
      _selectedConveyer = temp;
    });
    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedGuesser == null || _selectedConveyer == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isTransitioning) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Pass the phone to',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              Text(
                _selectedConveyer!,
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Conveyer',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CategorySelectionScreen(
                        teamIndex: widget.teamIndex,
                        roundNumber: widget.roundNumber,
                        turnNumber: widget.turnNumber,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text(
                  'Ready to Begin',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Round ${widget.roundNumber} - Turn ${widget.turnNumber}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Choose Roles',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the switch button to change roles if needed',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Column(
                children: [
                  // Conveyer Box
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Text(
                              _selectedConveyer!,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
                          Positioned(
                            top: 16,
                            right: 16,
                            child: Text(
                              'Conveyer',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Switch Button
                  IconButton(
                    onPressed: _switchRoles,
                    icon: Icon(
                      Icons.swap_vert,
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Guesser Box
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Text(
                              _selectedGuesser!,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
                          Positioned(
                            top: 16,
                            right: 16,
                            child: Text(
                              'Guesser',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                _assignRandomRoles();
                _showTransitionScreen();
              },
              icon: const Icon(Icons.shuffle),
              label: const Text('Random'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _showTransitionScreen();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: const Text(
                'Begin Turn',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 