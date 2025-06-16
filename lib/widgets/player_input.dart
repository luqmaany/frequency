import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game_setup_provider.dart';

class PlayerInput extends ConsumerStatefulWidget {
  const PlayerInput({super.key});

  @override
  ConsumerState<PlayerInput> createState() => _PlayerInputState();
}

class _PlayerInputState extends ConsumerState<PlayerInput> {
  final _controller = TextEditingController();
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
    if (_controller.text.isNotEmpty) {
      try {
        ref.read(gameSetupProvider.notifier).addPlayer(_controller.text);
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
                _controller.text = suggestion;
                _addPlayer();
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.start,
          children: gameConfig.playerNames.map((name) {
            return Chip(
              label: Text(name),
              onDeleted: () {
                ref.read(gameSetupProvider.notifier).removePlayer(name);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
