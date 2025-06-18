import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game_setup_provider.dart';

class PlayerInput extends ConsumerStatefulWidget {
  const PlayerInput({super.key});

  @override
  ConsumerState<PlayerInput> createState() => _PlayerInputState();
}

class _PlayerInputState extends ConsumerState<PlayerInput> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _suggestedNames = [
    'Aline',
    'Nazime',
    'Arash',
    'Cameron',
    'Jhud',
    'Huzaifah',
    'Mayy',
    'Siawosh',
    'Nadine',
    'Luqmaan',
  ];
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addPlayer() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    final gameConfig = ref.read(gameSetupProvider);
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
      setState(() {
        _errorMessage = null;
      });
      return;
    }
    try {
      ref.read(gameSetupProvider.notifier).addPlayer(name);
      _controller.clear();
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: 'Player Name',
            errorText: _errorMessage,
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addPlayer,
            ),
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) => _addPlayer(),
          onChanged: (_) {
            if (_errorMessage != null) {
              setState(() {
                _errorMessage = null;
              });
            }
          },
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.start,
          children: _suggestedNames
              .where((suggestion) => !gameConfig.playerNames.any(
                  (name) => name.toLowerCase() == suggestion.toLowerCase()))
              .map((suggestion) {
            return ActionChip(
              label: Text(suggestion),
              onPressed: () {
                ref.read(gameSetupProvider.notifier).addPlayer(suggestion);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
