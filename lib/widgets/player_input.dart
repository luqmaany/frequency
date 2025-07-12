import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game_setup_provider.dart';
import '../services/storage_service.dart';
import '../models/game_config.dart';

class PlayerInput extends ConsumerStatefulWidget {
  const PlayerInput({super.key});

  @override
  ConsumerState<PlayerInput> createState() => _PlayerInputState();
}

class _PlayerInputState extends ConsumerState<PlayerInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<String> _suggestedNames = [];
  String? _errorMessage;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadSuggestedNames();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestedNames() async {
    final names = await StorageService.loadSuggestedNames();
    setState(() {
      _suggestedNames = names;
    });
  }

  void _addPlayer() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    final gameConfig = ref.read(gameSetupProvider);

    // Check if we've reached the maximum number of players (12)
    if (gameConfig.playerNames.length >= 12) {
      setState(() {
        _errorMessage =
            'Maximum 12 players reached. Remove players to add more.';
      });
      return;
    }

    final exists = gameConfig.playerNames
        .any((n) => n.toLowerCase() == name.toLowerCase());
    final suggested = _suggestedNames.firstWhere(
      (s) => s.toLowerCase() == name.toLowerCase(),
      orElse: () => '',
    );
    if (exists) {
      if (suggested.isNotEmpty) {
        // If it's in suggestions and already in a team, just add from suggestions (shouldn't happen, but for safety)
        ref.read(gameSetupProvider.notifier).addPlayer(suggested);
        _controller.clear();
        _focusNode.requestFocus(); // Auto-focus after adding
        setState(() {
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = '${name} is already in a team';
        });
      }
      return;
    }
    // If it's in suggestions, add from suggestions
    if (suggested.isNotEmpty) {
      ref.read(gameSetupProvider.notifier).addPlayer(suggested);
      _controller.clear();
      _focusNode.requestFocus(); // Auto-focus after adding
      setState(() {
        _errorMessage = null;
      });
      return;
    }
    try {
      ref.read(gameSetupProvider.notifier).addPlayer(name);
      _controller.clear();
      _focusNode.requestFocus(); // Auto-focus after adding
      setState(() {
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameConfig = ref.watch(gameSetupProvider);

    // Reload suggested names when game config changes (e.g., after clearing data)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_suggestedNames.isEmpty) {
        _loadSuggestedNames();
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: gameConfig.playerNames.length < 12,
          decoration: InputDecoration(
            labelText: gameConfig.playerNames.length >= 12
                ? 'Maximum players reached'
                : 'Player Name',
            errorText: _errorMessage,
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed:
                  gameConfig.playerNames.length >= 12 ? null : _addPlayer,
            ),
            border: const OutlineInputBorder(),
          ),
          onSubmitted:
              gameConfig.playerNames.length >= 12 ? null : (_) => _addPlayer(),
          onChanged: (_) {
            if (_errorMessage != null) {
              setState(() {
                _errorMessage = null;
              });
            }
          },
        ),
        const SizedBox(height: 8),
        _buildSuggestedNames(gameConfig),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSuggestedNames(GameConfig gameConfig) {
    final suggestedNames = _suggestedNames
        .where((suggestion) => !gameConfig.playerNames
            .any((name) => name.toLowerCase() == suggestion.toLowerCase()))
        .toList();

    if (suggestedNames.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Estimate items per row based on average chip width
        const chipWidth = 80.0; // Approximate width of a chip
        const spacing = 8.0;
        final itemsPerRow =
            ((constraints.maxWidth + spacing) / (chipWidth + spacing)).floor();
        final maxItemsForTwoRows = itemsPerRow * 2;

        // Calculate how many items to show (leaving space for "Show More" if needed)
        final totalPages = (suggestedNames.length / maxItemsForTwoRows).ceil();
        final isLastPage = _currentPage >= totalPages - 1;
        final itemsToShow = isLastPage
            ? suggestedNames.sublist(_currentPage * maxItemsForTwoRows)
            : suggestedNames.sublist(
                _currentPage * maxItemsForTwoRows,
                (_currentPage + 1) * maxItemsForTwoRows -
                    1 // Leave space for "Show More"
                );

        final chips = itemsToShow.map((suggestion) {
          return ActionChip(
            label: Text(suggestion),
            onPressed: gameConfig.playerNames.length >= 12
                ? null
                : () async {
                    // Move the name to the front of the queue
                    await ref
                        .read(gameSetupProvider.notifier)
                        .moveNameToQueueFront(suggestion);
                    // Add the player
                    ref.read(gameSetupProvider.notifier).addPlayer(suggestion);
                  },
          );
        }).toList();

        // Add navigation chips
        if (!isLastPage) {
          chips.add(ActionChip(
            label: const Icon(Icons.arrow_forward, size: 20),
            onPressed: () {
              setState(() {
                _currentPage++;
              });
            },
          ));
        } else if (_currentPage > 0) {
          chips.add(ActionChip(
            label: const Icon(Icons.arrow_back, size: 20),
            onPressed: () {
              setState(() {
                _currentPage--;
              });
            },
          ));
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.start,
          children: chips,
        );
      },
    );
  }
}
