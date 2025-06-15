import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import 'dart:async';
import 'turn_screen.dart';
import 'word_lists_manager_screen.dart';
import 'role_assignment_screen.dart';
import '../services/game_state_provider.dart';

class CategorySelectionScreen extends ConsumerStatefulWidget {
  final int teamIndex;
  final int roundNumber;
  final int turnNumber;

  const CategorySelectionScreen({
    super.key,
    required this.teamIndex,
    required this.roundNumber,
    required this.turnNumber,
  });

  @override
  ConsumerState<CategorySelectionScreen> createState() => _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends ConsumerState<CategorySelectionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isSpinning = false;
  WordCategory? _selectedCategory;
  String _currentCategory = '';
  Timer? _categoryTimer;
  int _spinCount = 0;
  static const int _totalSpins = 20; // Total number of category changes
  static const int _initialDelay = 50; // Initial delay between changes in milliseconds
  static const int _finalDelay = 500; // Final delay between changes in milliseconds

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _categoryTimer?.cancel();
    super.dispose();
  }

  String _getCategoryName(WordCategory category) {
    switch (category) {
      case WordCategory.person:
        return 'Person';
      case WordCategory.action:
        return 'Action';
      case WordCategory.world:
        return 'World';
      case WordCategory.random:
        return 'Random';
    }
  }

  Color _getCategoryColor(WordCategory category) {
    switch (category) {
      case WordCategory.person:
        return Colors.blue;
      case WordCategory.action:
        return Colors.green;
      case WordCategory.world:
        return Colors.orange;
      case WordCategory.random:
        return Colors.purple;
    }
  }

  void _spinCategories() {
    if (_isSpinning) return;

    setState(() {
      _isSpinning = true;
      _selectedCategory = null;
      _spinCount = 0;
    });

    void updateCategory() {
      if (_spinCount >= _totalSpins) {
        _categoryTimer?.cancel();
        setState(() {
          _isSpinning = false;
          _selectedCategory = WordCategory.values[math.Random().nextInt(WordCategory.values.length)];
          _currentCategory = _getCategoryName(_selectedCategory!);
        });
        return;
      }

      setState(() {
        _currentCategory = _getCategoryName(WordCategory.values[math.Random().nextInt(WordCategory.values.length)]);
      });

      _spinCount++;
      // Calculate delay that increases as we get closer to the end
      final progress = _spinCount / _totalSpins;
      final delay = _initialDelay + ((_finalDelay - _initialDelay) * progress).round();
      _categoryTimer = Timer(Duration(milliseconds: delay), updateCategory);
    }

    updateCategory();
  }

  @override
  Widget build(BuildContext context) {
    final currentTeamPlayers = ref.watch(currentTeamPlayersProvider);
    
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "${currentTeamPlayers[0]} & ${currentTeamPlayers[1]}'s Turn",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                'Tap to Spin!',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: _spinCategories,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey, width: 2),
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _currentCategory.isEmpty ? 'Tap to Start' : _currentCategory,
                        key: ValueKey<String>(_currentCategory),
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: _selectedCategory != null 
                              ? _getCategoryColor(_selectedCategory!)
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              if (_selectedCategory != null)
                Text(
                  'Selected Category: ${_getCategoryName(_selectedCategory!)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _getCategoryColor(_selectedCategory!),
                  ),
                ),
              if (_selectedCategory != null)
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => RoleAssignmentScreen(
                            teamIndex: widget.teamIndex,
                            roundNumber: widget.roundNumber,
                            turnNumber: widget.turnNumber,
                            category: _selectedCategory!,
                          ),
                        ),
                      );
                    },
                    child: const Text('Start Round'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 