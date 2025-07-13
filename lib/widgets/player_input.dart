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
        ref.read(gameSetupProvider.notifier).addPlayer(suggested);
        _controller.clear();
        _focusNode.requestFocus();
        setState(() {
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = '$name is already in a team';
        });
      }
      return;
    }

    if (suggested.isNotEmpty) {
      ref.read(gameSetupProvider.notifier).addPlayer(suggested);
      _controller.clear();
      _focusNode.requestFocus();
      setState(() {
        _errorMessage = null;
      });
      return;
    }

    try {
      ref.read(gameSetupProvider.notifier).addPlayer(name);
      _controller.clear();
      _focusNode.requestFocus();
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

    return SizedBox(
      height: 50, // Fixed height for single row
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children:
              suggestedNames.map((s) => _buildChip(s, gameConfig)).toList(),
        ),
      ),
    );
  }

  Widget _buildChip(String suggestion, GameConfig gameConfig) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        backgroundColor: Colors.white,
        label: Text(suggestion),
        onPressed: gameConfig.playerNames.length >= 12
            ? null
            : () async {
                await ref
                    .read(gameSetupProvider.notifier)
                    .moveNameToQueueFront(suggestion);
                ref.read(gameSetupProvider.notifier).addPlayer(suggestion);
              },
      ),
    );
  }
}
