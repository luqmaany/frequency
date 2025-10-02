import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isEditing = false;
  final ScrollController _suggestionsScrollController = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestedNames();
    _suggestionsScrollController.addListener(_updateEdgeFades);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _suggestionsScrollController.removeListener(_updateEdgeFades);
    _suggestionsScrollController.dispose();
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
      return;
    }

    final exists = gameConfig.playerNames
        .any((n) => n.toLowerCase() == name.toLowerCase());
    final suggested = _suggestedNames.firstWhere(
      (s) => s.toLowerCase() == name.toLowerCase(),
      orElse: () => '',
    );

    // If already in a team, do not add (regardless of suggestions)
    if (exists) {
      setState(() {
        _errorMessage = '$name is already in a team';
      });
      return;
    }

    if (suggested.isNotEmpty) {
      // Remove from suggestions store and local list, then add
      final updated = List<String>.from(_suggestedNames)
        ..removeWhere((s) => s.toLowerCase() == suggested.toLowerCase());
      StorageService.saveSuggestedNames(updated);
      setState(() {
        _suggestedNames = updated;
      });
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

  void _startInlineEdit() {
    setState(() {
      _isEditing = true;
      _errorMessage = null;
    });
    // Defer focus until after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.clear();
      _focusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameConfig = ref.watch(gameSetupProvider);

    // Refresh suggestions whenever setup state changes (e.g., after Clear)
    ref.listen(gameSetupProvider, (previous, next) {
      _loadSuggestedNames();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_suggestedNames.isEmpty) {
        _loadSuggestedNames();
      }
    });

    // Removed keyboard visibility check; cursor is always shown while editing

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!_isEditing)
              RawChip(
                label: const Icon(Icons.add, size: 22, color: Colors.white),
                backgroundColor: Colors.grey[850],
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                labelPadding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                  side: const BorderSide(color: Colors.white, width: 1),
                ),
                onPressed: gameConfig.playerNames.length >= 12
                    ? null
                    : _startInlineEdit,
              )
            else
              Focus(
                onFocusChange: (hasFocus) {
                  if (!hasFocus) {
                    // Close editor on blur without adding
                    setState(() {
                      _isEditing = false;
                      _errorMessage = null;
                    });
                    _controller.clear();
                    _focusNode.unfocus();
                    FocusScope.of(context).unfocus();
                  }
                },
                child: RawChip(
                  backgroundColor: Colors.grey[850],
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(7)),
                    side: BorderSide(color: Colors.white, width: 1),
                  ),
                  label: ConstrainedBox(
                    constraints:
                        const BoxConstraints(minWidth: 22, maxWidth: 220),
                    child: IntrinsicWidth(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        autofocus: true,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                        cursorColor: Colors.white70,
                        // Always show cursor while editing
                        showCursor: true,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: InputDecoration(
                          isDense: true,
                          // No hint; start empty and grow with text
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          errorText: _errorMessage,
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) {
                          _addPlayer();
                          setState(() {
                            _isEditing = false;
                          });
                          _focusNode.unfocus();
                          FocusScope.of(context).unfocus();
                        },
                        onChanged: (_) {
                          if (_errorMessage != null) {
                            setState(() => _errorMessage = null);
                          }
                        },
                        onTapOutside: (_) {
                          setState(() {
                            _isEditing = false;
                            _errorMessage = null;
                          });
                          _controller.clear();
                          _focusNode.unfocus();
                          FocusScope.of(context).unfocus();
                        },
                      ),
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 0, vertical: 9),
                  onPressed: null,
                ),
              ),
            const SizedBox(width: 8),
            Expanded(child: _buildSuggestedNames(gameConfig)),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _updateEdgeFades() {
    if (!_suggestionsScrollController.hasClients) {
      if (_canScrollLeft || _canScrollRight) {
        setState(() {
          _canScrollLeft = false;
          _canScrollRight = false;
        });
      }
      return;
    }
    final position = _suggestionsScrollController.position;
    final double max = position.maxScrollExtent;
    final double offset = position.pixels;
    final bool canLeft = offset > 0.0;
    final bool canRight = offset < (max - 0.5);
    if (canLeft != _canScrollLeft || canRight != _canScrollRight) {
      setState(() {
        _canScrollLeft = canLeft;
        _canScrollRight = canRight;
      });
    }
  }

  Widget _buildSuggestedNames(GameConfig gameConfig) {
    // If at maximum players, replace suggestions row with message
    if (gameConfig.playerNames.length >= 12) {
      return const SizedBox(
        height: 50,
        child: Center(
          child: Text(
            'Maximum 12 players reached.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ),
      );
    }

    final suggestedNames = _suggestedNames
        .where((suggestion) => !gameConfig.playerNames
            .any((name) => name.toLowerCase() == suggestion.toLowerCase()))
        .toList();

    if (suggestedNames.isEmpty) {
      return const SizedBox.shrink();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _updateEdgeFades());

    return SizedBox(
      height: 50, // Fixed height for single row
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: <Color>[
              _canScrollLeft ? Colors.transparent : Colors.white,
              Colors.white,
              Colors.white,
              _canScrollRight ? Colors.transparent : Colors.white,
            ],
            stops: const <double>[0.0, 0.06, 0.94, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: SingleChildScrollView(
          controller: _suggestionsScrollController,
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children:
                suggestedNames.map((s) => _buildChip(s, gameConfig)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String suggestion, GameConfig gameConfig) {
    final bool canAdd = gameConfig.playerNames.length < 12;
    final chip = ActionChip(
      backgroundColor: Colors.grey[850],
      label: Text(suggestion),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(7),
        side: const BorderSide(color: Colors.white, width: 1),
      ),
      onPressed: canAdd
          ? () async {
              // Remove from suggestions and add to team
              final updated = List<String>.from(_suggestedNames)
                ..removeWhere(
                    (s) => s.toLowerCase() == suggestion.toLowerCase());
              await StorageService.saveSuggestedNames(updated);
              setState(() {
                _suggestedNames = updated;
              });
              ref.read(gameSetupProvider.notifier).addPlayer(suggestion);
            }
          : null,
    );

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: LongPressDraggable<String>(
        data: suggestion,
        delay: const Duration(milliseconds: 120),
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: Transform.translate(
          offset: const Offset(-30, -70),
          child: Material(
            color: Colors.transparent,
            child: Chip(
              label: Text(suggestion),
              backgroundColor: Colors.grey[800],
              side: const BorderSide(color: Colors.white),
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.5,
          child: chip,
        ),
        child: chip,
      ),
    );
  }
}
